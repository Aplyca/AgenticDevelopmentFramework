# Shared helpers for the hook scripts in this directory. Sourced, never executed.
# Claude Code passes each hook its event as JSON on stdin; exit 2 blocks a PreToolUse call and
# feeds stderr back to Claude (for PostToolUse, the tool already ran and stderr reaches Claude).

HOOKS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks"

# The plugin's copy of a hook (adf, decision 0016) acts only in a packaged project — the stamp
# on AGENTS.md's first line says `install: packaged` (on CLAUDE.md's, in a project adopted before
# decision 0024). A committed project runs its own copies from its settings, and a project that hasn't
# adopted the framework runs none.
stamped_packaged() { head -n 1 "$1" 2>/dev/null | grep -q 'install: packaged'; }
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] &&
  [ "$(cd "${CLAUDE_PLUGIN_ROOT}/hooks" && pwd -P)" != "$(cd "$CLAUDE_PROJECT_DIR/.claude/hooks" 2>/dev/null && pwd -P)" ] &&
  ! stamped_packaged "$CLAUDE_PROJECT_DIR/AGENTS.md" && ! stamped_packaged "$CLAUDE_PROJECT_DIR/CLAUDE.md"; then
  exit 0
fi

PROTECTED_BRANCHES="main master"
APPEND_ONLY_GLOBS=""
GENERATED_GLOBS=""
ENV_TEMPLATE=""
ENV_IGNORE=""
ENV_CHECK_EXCLUDE=""
CAREFUL_GLOBS=""
TRIAGE_FIRST=""
HUB_READONLY=""
APPROVE_WORKTREE_MOVE="1"
PR_STATE="1"
SESSION_TITLE="1"
APPROVAL_GATE=""
READY_GATE=""
SPECS_DIR="specs"
# in_words <word> <space-separated list> — exact membership.
in_words() {
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

# read_settings <file> <KEY>… — set each listed KEY from its KEY=value line. The file is data and
# never runs: double- or single-quoted or bare values, indentation and trailing comments.
read_settings() {
  local file="$1" line setting value
  shift
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    setting="${line%%=*}"
    [[ $setting =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
    in_words "$setting" "$*" || continue
    value="${line#*=}"
    case "$value" in
      \"*) value="${value#\"}" && value="${value%%\"*}" ;;
      \'*) value="${value#\'}" && value="${value%%\'*}" ;;
      *) value="${value%%[[:space:]]*}" ;;
    esac
    printf -v "$setting" '%s' "$value"
  done < <(cat "$file")
}
# worktree_settings <root> — print the parallel-agents module's settings file in <root>: ops/agent/,
# or scripts/agent/ in a project that hasn't moved it there yet (decision 0032). Fails with neither.
worktree_settings() {
  local dir
  for dir in ops/agent scripts/agent; do
    if [ -f "$1/$dir/worktree.conf" ]; then
      printf '%s\n' "$1/$dir/worktree.conf"
      return 0
    fi
  done
  return 1
}

# The settings sit next to the scripts in a committed install. In the packaged install (the
# adf plugin, decision 0016) the scripts come from the plugin and the settings stay the
# project's: .claude/hooks/config.sh under CLAUDE_PROJECT_DIR.
for config in "${CLAUDE_PLUGIN_ROOT}/hooks/config.sh" "${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.claude/hooks/config.sh}"; do
  if [ -n "$config" ] && [ -f "$config" ]; then
    read_settings "$config" PROTECTED_BRANCHES APPEND_ONLY_GLOBS GENERATED_GLOBS CAREFUL_GLOBS TRIAGE_FIRST \
      HUB_READONLY APPROVE_WORKTREE_MOVE PR_STATE SESSION_TITLE APPROVAL_GATE READY_GATE ENV_TEMPLATE ENV_IGNORE \
      ENV_CHECK_EXCLUDE SPECS_DIR
    break
  fi
done
unset config

HOOK_INPUT="$(cat)"

# json_field <.dotted.path> <json> — print a string field of a JSON text, or nothing.
json_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$2" | jq -r --arg path "$1" -f "${CLAUDE_PLUGIN_ROOT}/hooks/json-get.jq" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$2" | python3 "${CLAUDE_PLUGIN_ROOT}/hooks/json-get.py" "$1"
  else
    echo "$(basename "$0"): install jq or python3 to enable this hook" >&2
    exit 1
  fi
}

# json_get <.dotted.path> — print a string field of the hook input, or nothing.
json_get() {
  json_field "$1" "$HOOK_INPUT"
}

# path_matches <path-relative-to-root> <glob> — no "/" in the glob matches the file name only.
path_matches() {
  if [ "${2#*/}" != "$2" ]; then
    [[ $1 == $2 ]]
  else
    [[ ${1##*/} == $2 ]]
  fi
}

# matches_any <path-relative-to-root> <space-separated globs>
matches_any() {
  local glob
  set -f
  for glob in $2; do
    if path_matches "$1" "$glob"; then
      set +f
      return 0
    fi
  done
  set +f
  return 1
}

# physical_path <path> — the path with symlinks resolved, such as macOS's temporary folder, even
# when the file or its parent directories don't exist yet. Git reports physical paths, so paths must
# be compared in the same form.
physical_path() {
  local path="$1" rest=""
  while [ ! -d "$path" ] && [ "$path" != "/" ]; do
    rest="/$(basename "$path")$rest"
    path="$(dirname "$path")"
  done
  printf '%s%s' "$(cd "$path" && pwd -P)" "$rest"
}

# repo_root_for <path> — the git toplevel that contains a file or directory, or nothing.
repo_root_for() {
  local dir="$1"
  [ -d "$dir" ] || dir="$(dirname "$dir")"
  while [ ! -d "$dir" ] && [ "$dir" != "/" ]; do dir="$(dirname "$dir")"; done
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null
}

# branch_spec_dir <root> <branch> — print the spec folder a work branch belongs to, or fail. A branch
# joins its folder by slug: feat/newsletter-signup → specs/007-newsletter-signup/, and a change
# request's branch (feat/newsletter-signup-topics) joins the longest folder slug it starts with.
branch_spec_dir() {
  local root="$1" slug="${2#*/}" dir folder_slug spec_dir="" best=0
  [ "$slug" != "$2" ] && [ -d "$root/$SPECS_DIR" ] || return 1
  while IFS= read -r dir; do
    folder_slug="${dir##*/}"
    [ "${folder_slug:0:1}" != "." ] && [ -f "$dir/spec.md" ] || continue
    [[ $folder_slug =~ ^[0-9]+-(.*)$ ]] && folder_slug="${BASH_REMATCH[1]}"
    if [ "$slug" = "$folder_slug" ] || [ "${slug#"$folder_slug"-}" != "$slug" ]; then
      if [ "${#folder_slug}" -gt "$best" ]; then
        spec_dir="$dir"
        best="${#folder_slug}"
      fi
    fi
  done < <(find "$root/$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  [ -n "$spec_dir" ] && printf '%s\n' "$spec_dir"
}

# spec_status <spec folder> — print the status in its spec.md's frontmatter, or nothing.
spec_status() {
  local status_line='^status:[[:space:]]*([a-z-]+)'
  [[ "$(grep -m 1 -E "$status_line" "$1/spec.md" 2>/dev/null)" =~ $status_line ]] && printf '%s' "${BASH_REMATCH[1]}"
}

# limited <command>… — run a command that can hang on a slow network for five seconds at most:
# coreutils' timeout bounds it where it's installed (gtimeout on macOS).
limited() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 5 "$@"
  else
    "$@"
  fi
}

# block <reason> — stop the call. The hook is named, not its path: the scripts run from .claude/hooks/
# in a committed install and from the adf plugin in a packaged one.
block() {
  echo "Blocked by the $(basename "$0" .sh) hook: $1" >&2
  exit 2
}

# gate <mode> <name> <reason> — a process gate whose condition doesn't hold. Mode "block" stops the
# call every time. Any other mode ("remind") stops it once per session and lets it through after:
# a nudge that leaves the call to the agent and the developer.
gate() {
  local session tmp_dir state
  [ "$1" = "block" ] && block "$3"
  session="$(json_get '.session_id' | tr -cd 'A-Za-z0-9_-')"
  tmp_dir="${TMPDIR:-}"
  [ -d "$tmp_dir" ] || tmp_dir="/tmp"
  state="$tmp_dir/claude-$2-${session:-unknown}"
  [ -f "$state" ] && return 0
  touch "$state"
  block "$3 This stop shows once per session: when the developer has said to go on, do it again."
}
