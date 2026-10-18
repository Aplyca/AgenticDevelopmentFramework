#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). With the parallel-agents module installed, the main
# checkout is shared: sessions start here, and each task moves to a worktree of its own before its
# first edit (the module's guide, PARALLEL-AGENTS.md). This stops any file edit in the main checkout; edits in linked
# worktrees pass. Without the module — no ops/agent/worktree.conf (scripts/agent/ before decision
# 0032), its settings, which both installs commit — it does nothing. Empty HUB_READONLY turns it off. File writes made through Bash
# aren't seen by this hook.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$HUB_READONLY" ] || exit 0

file="$(json_get '.tool_input.file_path')"
[ -n "$file" ] || exit 0
case "$file" in /*) ;; *) file="$(json_get '.cwd')/$file" ;; esac

root="$(repo_root_for "$file")"
[ -n "$root" ] || exit 0
worktree_settings "$root" >/dev/null || exit 0

[ "$(git -C "$root" rev-parse --git-dir)" = "$(git -C "$root" rev-parse --git-common-dir)" ] || exit 0

block "$root is the main checkout, which takes no edits. Give this task its own worktree first: state the triage if you haven't, then run /adf:dispatch, which creates the worktree beside this checkout on the branch triage names and moves this session there. Make the change from there."
