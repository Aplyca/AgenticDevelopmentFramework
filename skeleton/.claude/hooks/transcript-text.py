# The text of the assistant's replies in a session transcript (argv[1]) — triage-first.sh when jq
# isn't installed.
import json
import sys

for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get("type") == "assistant":
        for block in event.get("message", {}).get("content") or []:
            if isinstance(block, dict) and block.get("type") == "text":
                print(block.get("text", ""))
