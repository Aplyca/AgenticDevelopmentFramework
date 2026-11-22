# The top-level field names of a tool call's input on stdin, one per line — tool_input_keys in
# _lib.sh when jq isn't installed.
import json
import sys

try:
    tool_input = json.load(sys.stdin).get("tool_input")
    if isinstance(tool_input, dict):
        print("\n".join(tool_input))
except (ValueError, AttributeError):
    pass
