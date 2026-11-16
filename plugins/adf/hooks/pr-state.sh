#!/usr/bin/env bash
# SessionStart, UserPromptSubmit, and Stop hook. Tells the session, once, when its branch's pull
# request merged or closed without merging: the moment the task can close up (/adf:wrap-up, decision
# 0047). One call to the host's CLI (`gh`, or `glab` on GitLab) at session start and at most one
# every five minutes after; silent without either.
# At Stop it runs in the background (asyncRewake) and watches an open pull request while the session
# sits idle, for PR_WATCH_HOURS: a merge or close exits 2, which wakes the session (decision 0087).
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$PR_STATE" ] || exit 0
command -v gh >/dev/null 2>&1 || command -v glab >/dev/null 2>&1 || exit 0

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0
branch="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null)" || exit 0
in_words "$branch" "$PROTECTED_BRANCHES" && exit 0
event="$(json_get '.hook_event_name')"
if [ "$event" = "Stop" ]; then
  [ -n "$PR_WATCH_HOURS" ] && [[ $PR_WATCH_HOURS =~ ^[0-9]+$ ]] && [ "$PR_WATCH_HOURS" -gt 0 ] || exit 0
fi

# Per checkout: a worktree has its own git dir, so each session keeps its own record.
cache="$(git -C "$root" rev-parse --absolute-git-dir)/adf-pr-state"
now="$(date +%s)"
last_branch="" last_time=0 last_state="-" last_number=""
[ -f "$cache" ] && read -r last_branch last_time last_state last_number <<<"$(cat "$cache")"
if [ "$last_branch" != "$branch" ]; then last_time=0 last_state="-" last_number=""; fi
if [ "$event" = "UserPromptSubmit" ] && [ $((now - ${last_time:-0})) -lt 300 ]; then exit 0; fi

# A CLI can hang on a slow network: coreutils' timeout bounds it where it's installed (gtimeout on macOS).
limited() {
  if command -v timeout >/dev/null 2>&1; then timeout 5 "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout 5 "$@"
  else "$@"; fi
}
# "<number> <STATE>" from GitHub; a merge request's number carries GitLab's "!" (decision 0074).
ask_gh() {
  (cd "$root" && limited gh pr view "$branch" --json number,state --jq '"\(.number) \(.state)"' 2>/dev/null)
}
ask_glab() { # glab's --jq is recent (2026), so its JSON goes through the hooks' own reader.
  local mr state url
  mr="$(cd "$root" && limited glab mr view "$branch" --output json 2>/dev/null)" || return 1
  state="$(HOOK_INPUT="$mr" json_get '.state')" url="$(HOOK_INPUT="$mr" json_get '.web_url')"
  case "$state" in
    merged) state=MERGED ;;
    closed) state=CLOSED ;;
    opened | locked) state=OPEN ;;
    *) return 1 ;;
  esac
  echo "!${url##*/} $state"
}
# glab first when origin is on GitLab, gh first otherwise; the other answers when the first can't —
# a self-managed GitLab whose host name doesn't say so.
case "$(git -C "$root" remote get-url origin 2>/dev/null)" in
  *gitlab*) clis="glab gh" ;;
  *) clis="gh glab" ;;
esac
# ask_host — "<number> <STATE>" for the branch's pull request, from the first CLI that answers.
ask_host() {
  local cli pr
  for cli in $clis; do
    command -v "$cli" >/dev/null 2>&1 || continue
    pr="$("ask_$cli")" && [ -n "$pr" ] && { echo "$pr"; return 0; }
  done
  return 1
}
# say <ref> <state> [idle] — the line the session reads; nothing for an open pull request.
say() {
  local when=""
  [ -n "${3:-}" ] && when=" while the session waited"
  case "$2" in
    MERGED)
      echo "PR state (the pr-state hook): $1 for $branch merged$when, so the task's work is upstream. Once this turn's request is settled, offer /adf:wrap-up, unless the developer put the task on hold or asked to keep the session."
      ;;
    CLOSED)
      echo "PR state (the pr-state hook): $1 for $branch closed without merging$when, so its work isn't upstream. Ask the developer whether the task is dropped; if it is, /adf:wrap-up closes it up and keeps the branch on origin."
      ;;
  esac
}
ref_of() {
  case "$1" in
    '!'*) echo "Merge request $1" ;;
    *) echo "PR #$1" ;;
  esac
}

if [ "$event" = "Stop" ]; then
  # One watcher per checkout: a newer turn's watcher replaces this one, and a state another check
  # already reported (a prompt, a session start) ends it. The interval is overridable for the evals.
  interval="${ADF_PR_WATCH_INTERVAL:-300}"
  watcher="$(git -C "$root" rev-parse --absolute-git-dir)/adf-pr-watch"
  echo "$$" | tee "$watcher" >/dev/null
  deadline=$((now + PR_WATCH_HOURS * 3600))
  while :; do
    [ "$(cat "$watcher" 2>/dev/null)" = "$$" ] || exit 0
    if [ -f "$cache" ]; then
      read -r last_branch last_time last_state last_number <<<"$(cat "$cache")"
      [ "$last_branch" = "$branch" ] || last_state="-"
    fi
    case "$last_state" in MERGED | CLOSED) exit 0 ;; esac
    pr="$(ask_host)" || pr=""
    now="$(date +%s)"
    if [ -n "$pr" ]; then
      number="${pr%% *}" state="${pr#* }"
      printf '%s %s %s %s\n' "$branch" "$now" "$state" "$number" | tee "$cache" >/dev/null
      case "$state" in
        MERGED | CLOSED)
          rm -f "$watcher"
          say "$(ref_of "$number")" "$state" idle >&2
          exit 2
          ;;
        OPEN) ;;
        *) exit 0 ;;
      esac
    elif [ "$last_state" != OPEN ]; then
      exit 0 # no pull request to watch, and none known
    fi
    [ $((now + interval)) -lt "$deadline" ] || exit 0
    sleep "$interval"
  done
fi

pr="$(ask_host)" || pr=""
number="${pr%% *}" state="${pr#* }"
if [ -z "$pr" ]; then state="$last_state" number="$last_number"; fi
printf '%s %s %s %s\n' "$branch" "$now" "${state:--}" "$number" | tee "$cache" >/dev/null

# At session start the context is new, so say it again; on a prompt, only when the state changed.
[ "$event" = "SessionStart" ] || [ "$state" != "$last_state" ] || exit 0
say "$(ref_of "$number")" "$state"
exit 0
