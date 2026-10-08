# The string at a dotted path (argv[1]) in a hook's event on stdin, or nothing — json_get in _lib.sh
# when jq isn't installed.
import json
import sys

try:
    node = json.load(sys.stdin)
    for key in sys.argv[1].lstrip(".").split("."):
        node = node.get(key) if isinstance(node, dict) else None
    if isinstance(node, str):
        print(node)
except ValueError:
    pass
