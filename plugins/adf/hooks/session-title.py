# The hook output that sets the session title to the text on stdin, at most 80 characters —
# session-title.sh when jq isn't installed.
import io
import json
import sys

title = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace").read()
if len(title) > 80:
    title = title[:79] + "…"
output = {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "sessionTitle": title}}
sys.stdout.buffer.write((json.dumps(output, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8"))
