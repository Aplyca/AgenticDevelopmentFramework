# Shared helpers for the hook scripts in this directory. Sourced, never executed.
# Claude Code passes each hook its event as JSON on stdin; exit 2 blocks a PreToolUse call and
# feeds stderr back to Claude (for PostToolUse, the tool already ran and stderr reaches Claude).

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROTECTED_BRANCHES="main master"
APPEND_ONLY_GLOBS=""
GENERATED_GLOBS=""
ENV_TEMPLATE=""
ENV_IGNORE=""
ENV_CHECK_EXCLUDE=""
SPECS_DIR="specs"
# shellcheck source=config.sh
[ -f "$HOOKS_DIR/config.sh" ] && . "$HOOKS_DIR/config.sh"

HOOK_INPUT="$(cat)"

# json_get <jq-path> — print a string field of the hook input, or nothing.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_INPUT" | python3 -c '
import json, sys
try:
    node = json.load(sys.stdin)
    for key in sys.argv[1].lstrip(".").split("."):
        node = node.get(key) if isinstance(node, dict) else None
    if isinstance(node, str):
        print(node)
except ValueError:
    pass
' "$1"
  else
    echo "$(basename "$0"): install jq or python3 to enable this hook" >&2
    exit 1
  fi
}

# in_words <word> <space-separated list> — exact membership.
in_words() {
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

# path_matches <path-relative-to-root> <glob> — no "/" in the glob matches the file name only.
path_matches() {
  case "$2" in
    */*) [[ $1 == $2 ]] ;;
    *) [[ ${1##*/} == $2 ]] ;;
  esac
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

# physical_path <path> — the path with symlinks resolved (e.g. /tmp → /private/tmp on macOS), even
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
