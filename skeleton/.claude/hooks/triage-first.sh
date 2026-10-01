#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit). A nudge, not a lock: the triage — the lane and
# why — belongs before the first file change (AGENTS.md § Triage first), in reply text the developer
# can read. If the transcript's visible text states no lane yet, the first edit of the session is
# stopped once with a reminder; after that, edits pass. Empty TRIAGE_FIRST turns the hook off.
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

[ -n "$TRIAGE_FIRST" ] || exit 0
[ -z "$(json_get '.agent_id')" ] || exit 0

session="$(json_get '.session_id' | tr -cd 'A-Za-z0-9_-')"
transcript="$(json_get '.transcript_path')"
[ -n "$session" ] && [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

state="${TMPDIR:-/tmp}/claude-triage-first-${session}"
[ -f "$state" ] && exit 0

lane='(fast|careful|full)[^a-z]{0,3}lane|lane[^a-z]{0,8}(fast|careful|full)'
if command -v jq >/dev/null 2>&1; then
  assistant_text() { jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' "$transcript" 2>/dev/null; }
else
  assistant_text() {
    python3 - "$transcript" <<'PY' 2>/dev/null
import json, sys
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get("type") == "assistant":
        for block in event.get("message", {}).get("content") or []:
            if isinstance(block, dict) and block.get("type") == "text":
                print(block.get("text", ""))
PY
  }
fi

if assistant_text | grep -qiE "$lane"; then
  echo stated > "$state"
  exit 0
fi
echo reminded > "$state"
block "no lane is stated in this session's reply text yet. Before this edit, write the triage as text the developer can read — a triage in your thinking doesn't count. For a small change, one line: \"Fast lane — <the request in your words>; done when <check>; files: <list>; model: <sonnet|opus>.\" Then make the edit again; this reminder shows once."
