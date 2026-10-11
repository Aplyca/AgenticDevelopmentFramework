#!/usr/bin/env bash
# PreToolUse hook (matcher: mcp__ccd_directory__change_directory). A dispatched session opens in the
# main checkout, creates its task's worktree, and moves there with the desktop app's change_directory
# (decision 0021). The app asks the developer to approve that folder, after they already chose the task
# when they started its chip (decision 0035). This approves a move into a linked worktree of the
# session's own repository, and says nothing about any other folder, which still prompts. Empty
# APPROVE_WORKTREE_MOVE turns it off.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$APPROVE_WORKTREE_MOVE" ] || exit 0

target="$(json_get '.tool_input.path')"
case "$target" in "~") target="$HOME" ;; "~/"*) target="$HOME/${target#"~/"}" ;; esac
case "$target" in /*) ;; *) exit 0 ;; esac
[ -d "$target" ] || exit 0
target="$(cd "$target" && pwd -P)"

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || exit 0

# The target is the top of a worktree, not the main checkout, and shares the session's repository.
[ "$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)" = "$target" ] || exit 0
target_dir="$(git -C "$target" rev-parse --path-format=absolute --git-dir)"
target_common="$(git -C "$target" rev-parse --path-format=absolute --git-common-dir)"
[ "$target_dir" != "$target_common" ] || exit 0
session_common="$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
[ "$(cd "$target_common" && pwd -P)" = "$(cd "$session_common" && pwd -P)" ] || exit 0

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"The folder is a worktree of this repository, where the dispatched task works (approve-worktree-move hook)."}}'
