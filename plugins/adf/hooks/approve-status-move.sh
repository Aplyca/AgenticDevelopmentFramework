#!/usr/bin/env bash
# PreToolUse hook (matcher: mcp__.*). A tracker task's status follows the work on the agent's own —
# in progress, in review, delivered (decisions 0059, 0073) — but the tracker's write tools stay off
# the allow list, so each move asked the developer for a yes the process says it doesn't need. This
# approves a call to the tool APPROVE_STATUS_MOVE names when it carries nothing but the fields
# STATUS_MOVE_FIELDS lists — the task's identifier and its status, the status field last — and says
# nothing about any other call, which still prompts: a comment or any other post, and an update that
# also touches the assignee, a date, or the description. An allow rule can't tell those apart; it
# matches the tool's name alone. The hook reads the call, not whose task it is or which way the
# status moves: those stay the skills' rules. Empty APPROVE_STATUS_MOVE turns it off.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$APPROVE_STATUS_MOVE" ] || exit 0
in_words "$(json_get '.tool_name')" "$APPROVE_STATUS_MOVE" || exit 0

status_field="${STATUS_MOVE_FIELDS##* }"
[ -n "$status_field" ] || exit 0
[ -n "$(json_get ".tool_input.$status_field")" ] || exit 0
set -f
for field in $(tool_input_keys); do
  in_words "$field" "$STATUS_MOVE_FIELDS" || exit 0
done
set +f

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"The call changes only the task status, which follows the work without a prompt (approve-status-move hook)."}}'
