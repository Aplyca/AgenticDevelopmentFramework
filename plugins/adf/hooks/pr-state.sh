#!/usr/bin/env bash
# SessionStart and UserPromptSubmit hook. Tells the session, once, when its branch's pull request
# merged or closed without merging: the moment the task can close up (/adf:wrap-up, decision 0047).
# A developer who merges on the host and comes back later would otherwise find the session as they
# left it. One `gh` call at session start and at most one every five minutes after; silent without gh.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$PR_STATE" ] || exit 0
command -v gh >/dev/null 2>&1 || exit 0

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0
branch="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null)" || exit 0
in_words "$branch" "$PROTECTED_BRANCHES" && exit 0
event="$(json_get '.hook_event_name')"

# Per checkout: a worktree has its own git dir, so each session keeps its own record.
cache="$(git -C "$root" rev-parse --absolute-git-dir)/adf-pr-state"
now="$(date +%s)"
last_branch="" last_time=0 last_state="-" last_number=""
[ -f "$cache" ] && read -r last_branch last_time last_state last_number <<<"$(cat "$cache")"
if [ "$last_branch" != "$branch" ]; then last_time=0 last_state="-" last_number=""; fi
if [ "$event" != "SessionStart" ] && [ $((now - ${last_time:-0})) -lt 300 ]; then exit 0; fi

# gh can hang on a slow network: coreutils' timeout bounds it where it's installed (gtimeout on macOS).
limited() {
  if command -v timeout >/dev/null 2>&1; then timeout 5 "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout 5 "$@"
  else "$@"; fi
}
pr="$(cd "$root" && limited gh pr view "$branch" --json number,state --jq '"\(.number) \(.state)"' 2>/dev/null)" || pr=""
number="${pr%% *}" state="${pr#* }"
if [ -z "$pr" ]; then state="$last_state" number="$last_number"; fi
printf '%s %s %s %s\n' "$branch" "$now" "${state:--}" "$number" | tee "$cache" >/dev/null

# At session start the context is new, so say it again; on a prompt, only when the state changed.
[ "$event" = "SessionStart" ] || [ "$state" != "$last_state" ] || exit 0
case "$state" in
  MERGED)
    echo "PR state (the pr-state hook): PR #$number for $branch merged, so the task's work is upstream. Once this turn's request is settled, offer /adf:wrap-up, unless the developer put the task on hold or asked to keep the session."
    ;;
  CLOSED)
    echo "PR state (the pr-state hook): PR #$number for $branch closed without merging, so its work isn't upstream. Ask the developer whether the task is dropped; if it is, /adf:wrap-up closes it up and keeps the branch on origin."
    ;;
esac
exit 0
