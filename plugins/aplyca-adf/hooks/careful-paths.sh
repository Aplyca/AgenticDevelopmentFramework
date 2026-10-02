#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). Paths the team listed in CAREFUL_GLOBS take at
# least the careful lane, whatever the size of the change. The first edit in each sensitive area
# is stopped once per session so the agent confirms the lane before going on; later edits in that
# area pass. Empty CAREFUL_GLOBS turns the hook off.
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

[ -n "$CAREFUL_GLOBS" ] || exit 0
file_path="$(json_get '.tool_input.file_path')"
[ -n "$file_path" ] || exit 0

file_path="$(physical_path "$file_path")"
root="$(repo_root_for "$file_path")"
[ -n "$root" ] || exit 0
root="$(physical_path "$root")"
relative="${file_path#"$root"/}"

matched=""
set -f
for glob in $CAREFUL_GLOBS; do
  if path_matches "$relative" "$glob"; then
    matched="$glob"
    break
  fi
done
set +f
[ -n "$matched" ] || exit 0

session="$(json_get '.session_id' | tr -cd 'A-Za-z0-9_-')"
state="${TMPDIR:-/tmp}/claude-careful-paths-${session:-unknown}"
if [ -f "$state" ] && grep -qxF -- "$matched" "$state"; then
  exit 0
fi
printf '%s\n' "$matched" >> "$state"

block "$relative is in a sensitive area ($matched — CAREFUL_GLOBS in .claude/hooks/config.sh, AGENTS.md § Sensitive areas). Changes here take at least the careful lane. If this task is in the fast lane, stop: tell the developer, move to the careful lane, and apply its checklist (specs/README.md § Lanes). If it is already careful or full, make the edit again — this check runs once per area per session."
