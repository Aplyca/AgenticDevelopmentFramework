#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). With the parallel-agents module installed, the main
# checkout is the shared hub: the dispatcher hands each task to its own worktree and edits nothing
# here (docs/PARALLEL-AGENTS.md). This stops any file edit in the main checkout; edits in linked
# worktrees pass. Without the module — no scripts/agent/worktree.conf, its settings, which both
# installs commit — it does nothing. Empty HUB_READONLY turns it off. File writes made through Bash
# aren't seen by this hook.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$HUB_READONLY" ] || exit 0

file="$(json_get '.tool_input.file_path')"
[ -n "$file" ] || exit 0
case "$file" in /*) ;; *) file="$(json_get '.cwd')/$file" ;; esac

root="$(repo_root_for "$file")"
[ -n "$root" ] || exit 0
[ -f "$root/scripts/agent/worktree.conf" ] || exit 0

[ "$(git -C "$root" rev-parse --git-dir)" = "$(git -C "$root" rev-parse --git-common-dir)" ] || exit 0

block "$root is the main checkout — the shared hub, where the dispatcher edits nothing. Give the task to /adf:dispatch, which hands it to a new session in a worktree of its own, and make this change from that session. If this session is a dispatched task's worker, create its worktree first (adf-worktree-new <branch> --no-start) and move this session there."
