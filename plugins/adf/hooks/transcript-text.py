# The text of the assistant's replies in a session transcript on stdin — triage-first.sh when jq
# isn't installed.
import io
import json
import sys

for line in io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace"):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get("type") == "assistant":
        for block in event.get("message", {}).get("content") or []:
            if isinstance(block, dict) and block.get("type") == "text":
                print(block.get("text", ""))
