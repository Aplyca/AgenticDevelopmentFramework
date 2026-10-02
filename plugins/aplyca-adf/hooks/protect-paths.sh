#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). Stops two kinds of edit that look harmless and
# aren't:
#   - hand-editing a generated file (lockfiles, generated types) — regenerate it instead;
#   - modifying an existing file in append-only history (database migrations) — published
#     history has already run somewhere; add a new file instead.
# Globs come from GENERATED_GLOBS and APPEND_ONLY_GLOBS in config.sh.
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

file_path="$(json_get '.tool_input.file_path')"
[ -n "$file_path" ] || exit 0

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="$PWD"
case "$file_path" in /*) ;; *) file_path="$cwd/$file_path" ;; esac
file_path="$(physical_path "$file_path")"

root="$(repo_root_for "$file_path")"
[ -n "$root" ] || exit 0
root="$(physical_path "$root")"
relative="${file_path#"$root"/}"

if matches_any "$relative" "$GENERATED_GLOBS"; then
  block "$relative is generated. Regenerate it with the tool that owns it (package manager, codegen) instead of editing it by hand."
fi

if [ -e "$file_path" ] && matches_any "$relative" "$APPEND_ONLY_GLOBS"; then
  block "$relative is append-only history and already exists. Add a new file (for a migration: a new timestamped migration) instead of editing this one."
fi

exit 0
