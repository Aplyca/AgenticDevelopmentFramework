#!/usr/bin/env bash
# PreToolUse hook (matchers: Edit|Write|MultiEdit, and Bash). A nudge, not a lock: the triage — the
# lane and why — belongs before the first change (AGENTS.md § Triage first), in reply text the
# developer can read. If the transcript's visible text holds no triage yet — no lane named, no
# "Triage —" heading — the session's first edit to a project file, or its first new branch, is
# stopped once with a reminder; after that, everything passes. A file outside the project (a memory
# note, a plan, a scratch file), quoted text in a command, and other Bash commands are never stopped.
# Empty TRIAGE_FIRST turns the hook off.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$TRIAGE_FIRST" ] || exit 0
[ -z "$(json_get '.agent_id')" ] || exit 0

change="this edit"
if [ "$(json_get '.tool_name')" = "Bash" ]; then
  branch='git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(switch[[:space:]]+([^;&|]*[[:space:]])?(-c|-C|--create|--force-create)([[:space:]=]|$)|checkout[[:space:]]+([^;&|]*[[:space:]])?-[bB]([[:space:]]|$)|branch[[:space:]]+[^-[:space:]|;&>]|worktree[[:space:]]+add([[:space:]]|$))'
  # Quoted text is a message, not a command: "git branch cleanup" in an echo is no new branch.
  command_text="$(json_get '.tool_input.command')"
  quoted="(\"[^\"]*\"|'[^']*')"
  while [[ $command_text =~ $quoted ]]; do command_text="${command_text/"${BASH_REMATCH[1]}"/ }"; done
  printf '%s' "$command_text" | grep -qE "$branch" || exit 0
  change="this new branch"
else
  file="$(json_get '.tool_input.file_path')"
  [ -n "$file" ] && in_project "$file" || exit 0
fi

session="$(json_get '.session_id' | tr -cd 'A-Za-z0-9_-')"
transcript="$(json_get '.transcript_path')"
[ -n "$session" ] && [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

tmp_dir="${TMPDIR:-}"
[ -d "$tmp_dir" ] || tmp_dir="/tmp"
state="$tmp_dir/claude-triage-first-$session"
[ -f "$state" ] && exit 0

# A lane named ("Fast lane", "lane: careful"), or the triage's heading — an answer's triage names no lane.
triaged="$(lane_pattern 'fast|careful|full')|triage[[:space:]]*(—|–|-)"
replies="$(transcript_replies)"

touch "$state"
printf '%s' "$replies" | grep -qiE "$triaged" && exit 0
if [ -z "$(printf '%s' "$replies" | tr -d '[:space:]')" ]; then
  seen="you haven't written any reply text in this session yet, so the developer has seen no triage — what you decided while thinking isn't shown to anyone"
else
  seen="none of your replies in this session holds a triage — a lane (fast, careful, or full) or a 'Triage —' heading — so the developer has seen none — what you decided while thinking isn't shown to anyone"
fi
block "$seen. Before $change, write the triage as your next message. For a small change, one line: 'Fast lane — <the request in your words>; done when <check>; files: <list>; model: <sonnet|opus>' — then run it again; this reminder shows once."
