#!/usr/bin/env bash
# PreToolUse hook (matchers: Edit|Write|MultiEdit, and Bash). A nudge, not a lock: the triage — the
# lane and why — belongs before the first change (AGENTS.md § Triage first), in reply text the
# developer can read. If the transcript's visible text states no lane yet, the session's first file
# edit or new branch is stopped once with a reminder; after that, everything passes. Other Bash
# commands are never stopped. Empty TRIAGE_FIRST turns the hook off.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

[ -n "$TRIAGE_FIRST" ] || exit 0
[ -z "$(json_get '.agent_id')" ] || exit 0

change="this edit"
if [ "$(json_get '.tool_name')" = "Bash" ]; then
  branch='git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(switch[[:space:]]+([^;&|]*[[:space:]])?(-c|-C|--create|--force-create)([[:space:]=]|$)|checkout[[:space:]]+([^;&|]*[[:space:]])?-[bB]([[:space:]]|$)|branch[[:space:]]+[^-[:space:]|;&>]|worktree[[:space:]]+add([[:space:]]|$))'
  json_get '.tool_input.command' | grep -qE "$branch" || exit 0
  change="this new branch"
fi

session="$(json_get '.session_id' | tr -cd 'A-Za-z0-9_-')"
transcript="$(json_get '.transcript_path')"
[ -n "$session" ] && [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

tmp_dir="${TMPDIR:-}"
[ -d "$tmp_dir" ] || tmp_dir="/tmp"
state="$tmp_dir/claude-triage-first-$session"
[ -f "$state" ] && exit 0

# A lane named within a few characters of the word: "Fast lane", "lane: careful".
lane='(fast|careful|full)[^a-z]?[^a-z]?[^a-z]?lane|lane[^a-z]?[^a-z]?[^a-z]?[^a-z]?[^a-z]?[^a-z]?[^a-z]?[^a-z]?(fast|careful|full)'
if command -v jq >/dev/null 2>&1; then
  replies="$(cat "$transcript" | jq -r -f "${CLAUDE_PLUGIN_ROOT}/hooks/transcript-text.jq" 2>/dev/null)"
else
  replies="$(cat "$transcript" | python3 "${CLAUDE_PLUGIN_ROOT}/hooks/transcript-text.py" 2>/dev/null)"
fi

touch "$state"
printf '%s' "$replies" | grep -qiE "$lane" && exit 0
if [ -z "$(printf '%s' "$replies" | tr -d '[:space:]')" ]; then
  seen="you haven't written any reply text in this session yet, so the developer has seen no triage — what you decided while thinking isn't shown to anyone"
else
  seen="none of your replies in this session names a lane (fast, careful, or full), so the developer has seen no triage — what you decided while thinking isn't shown to anyone"
fi
block "$seen. Before $change, write the triage as your next message. For a small change, one line: \"Fast lane — <the request in your words>; done when <check>; files: <list>; model: <sonnet|opus>.\" Then run it again; this reminder shows once."
