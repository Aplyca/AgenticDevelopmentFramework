# Shared helpers for the hook scripts in this directory. Sourced, never executed.
# Claude Code passes each hook its event as JSON on stdin; exit 2 blocks a PreToolUse call and
# feeds stderr back to Claude (for PostToolUse, the tool already ran and stderr reaches Claude).

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The plugin's copy of a hook (aplyca-adf, decision 0016) acts only in a packaged project — the stamp
# on CLAUDE.md's first line says `install: packaged`. A committed project runs its own copies from its
# settings, and a project that hasn't adopted the framework runs none.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] &&
  [ "$(cd "$HOOKS_DIR" && pwd -P)" != "$(cd "$CLAUDE_PROJECT_DIR/.claude/hooks" 2>/dev/null && pwd -P)" ] &&
  ! head -n 1 "$CLAUDE_PROJECT_DIR/CLAUDE.md" 2>/dev/null | grep -q 'install: packaged'; then
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
SPECS_DIR="specs"
# in_words <word> <space-separated list> — exact membership.
in_words() {
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

# read_settings <file> <KEY>… — set each listed KEY from its KEY=value line. The file is data and
# never runs: double- or single-quoted or bare values, indentation and trailing comments.
read_settings() {
  local file="$1" line setting value quote
  shift
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    setting="${line%%=*}"
    [[ $setting =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
    in_words "$setting" "$*" || continue
    value="${line#*=}"
    quote="${value:0:1}"
    if [ "$quote" = '"' ] || [ "$quote" = "'" ]; then
      value="${value:1}"
      value="${value%%"$quote"*}"
    else
      value="${value%%[[:space:]]*}"
    fi
    printf -v "$setting" '%s' "$value"
  done < <(cat "$file")
}
# The settings sit next to the scripts in a committed install. In the packaged install (the
# aplyca-adf plugin, decision 0016) the scripts come from the plugin and the settings stay the
# project's: .claude/hooks/config.sh under CLAUDE_PROJECT_DIR.
for config in "$HOOKS_DIR/config.sh" "${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.claude/hooks/config.sh}"; do
  if [ -n "$config" ] && [ -f "$config" ]; then
    read_settings "$config" PROTECTED_BRANCHES APPEND_ONLY_GLOBS GENERATED_GLOBS CAREFUL_GLOBS TRIAGE_FIRST \
      HUB_READONLY ENV_TEMPLATE ENV_IGNORE ENV_CHECK_EXCLUDE SPECS_DIR
    break
  fi
done
unset config

HOOK_INPUT="$(cat)"

# json_get <.dotted.path> — print a string field of the hook input, or nothing.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r --arg path "$1" -f "$HOOKS_DIR/json-get.jq" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 "$HOOKS_DIR/json-get.py" "$1"
  else
    echo "$(basename "$0"): install jq or python3 to enable this hook" >&2
    exit 1
  fi
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

block() {
  echo "Blocked by .claude/hooks/$(basename "$0"): $1" >&2
  exit 2
}
