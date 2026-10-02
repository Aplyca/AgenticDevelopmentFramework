#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). With the parallel-agents module installed, the main
# checkout is the shared hub: the dispatcher hands each task to its own worktree and edits nothing
# here (docs/PARALLEL-AGENTS.md). This stops any file edit in the main checkout; edits in linked
# worktrees pass. Without the module — no scripts/agent/worktree-new.sh — it does nothing. Empty
# HUB_READONLY turns it off. File writes made through Bash aren't seen by this hook.
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

[ -n "$HUB_READONLY" ] || exit 0

file="$(json_get '.tool_input.file_path')"
[ -n "$file" ] || exit 0
case "$file" in /*) ;; *) file="$(json_get '.cwd')/$file" ;; esac

root="$(repo_root_for "$file")"
[ -n "$root" ] || exit 0
[ -x "$root/scripts/agent/worktree-new.sh" ] || exit 0

git_dir="$(cd "$root" && cd "$(git rev-parse --git-dir)" && pwd -P)"
common_dir="$(cd "$root" && cd "$(git rev-parse --git-common-dir)" && pwd -P)"
[ "$git_dir" = "$common_dir" ] || exit 0

block "$root is the main checkout — the shared hub, where the dispatcher edits nothing. Give the task its own worktree — a new session with Claude Code's worktree option, or /dispatch when it needs the project's worktree setup — and make this change from a session there."
