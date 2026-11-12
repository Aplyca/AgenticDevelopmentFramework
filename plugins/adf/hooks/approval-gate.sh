#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). The approval gate (specs/README.md § Flow): while
# the spec folder this branch belongs to reads `status: draft` or `in-review`, nothing outside the
# specs folder is written — the developer signs off the scope, the change surface, and the assumptions
# first. The status is a fact in a file, so the gate holds whatever the agent decided; who set it is
# the reviewers' check (the `approvals:` line). A branch with no spec folder — the fast and careful
# lanes — is never stopped, and neither is a file git ignores or one outside the repository.
# APPROVAL_GATE in config.sh: "block" stops every such edit, "remind" stops the first one per session,
# empty turns the hook off.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$APPROVAL_GATE" ] || exit 0
file_path="$(json_get '.tool_input.file_path')"
[ -n "$file_path" ] || exit 0

file_path="$(physical_path "$file_path")"
root="$(repo_root_for "$file_path")"
[ -n "$root" ] || exit 0
root="$(physical_path "$root")"
relative="${file_path#"$root"/}"
[ "${relative#"$SPECS_DIR"/}" = "$relative" ] || exit 0

branch="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null)" || exit 0
spec_dir="$(branch_spec_dir "$root" "$branch")" || exit 0
status="$(spec_status "$spec_dir")"
case "$status" in draft | in-review) ;; *) exit 0 ;; esac
git -C "$root" check-ignore -q -- "$relative" 2>/dev/null && exit 0

gate "$APPROVAL_GATE" approval-gate "${spec_dir#"$root"/}/spec.md reads 'status: $status': the approval gate hasn't passed, so nothing outside $SPECS_DIR/ is written yet (specs/README.md § Flow). Finish the plan and present the gate (/adf:write-plan); the developer's sign-off is what sets 'status: approved' — never set it yourself to get past this. If this edit is work the developer already approved — a fix on a branch whose change request is in review — say so and let them decide: they approve, or set APPROVAL_GATE in .claude/hooks/config.sh."
