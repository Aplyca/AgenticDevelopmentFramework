#!/usr/bin/env bash
#
# Checks a plugin-docs run from the session's output, which carries the subagents' tool calls too:
# whether Claude read the plugin's copy of a reference doc, whether anything asked for permission, and
# whether it fell back to the web. Prints ✓ or ✘ per check, then the reads it made. Read-only.
# Usage: inspect.sh <run copy> <session output .jsonl> <case>
#
work="$1" out="$2" case_name="$3"
python3 - "$out" "$case_name" <<'PY'
import json, sys
out, case = sys.argv[1], sys.argv[2]
reads, results, denials, fetched, context = {}, {}, [], False, False
for line in open(out, encoding="utf-8", errors="replace"):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if "The framework's reference docs — SPEC-MODEL.md" in line:
        context = True
    if not isinstance(event, dict):
        continue
    if event.get("type") == "result":
        denials += event.get("permission_denials") or []
    message = event.get("message")
    content = message.get("content") if isinstance(message, dict) else None
    for block in content if isinstance(content, list) else []:
        if block.get("type") == "tool_use" and block.get("name") == "Read":
            reads[block["id"]] = block.get("input", {}).get("file_path", "")
        elif block.get("type") == "tool_use" and block.get("name") == "WebFetch":
            fetched = True
        elif block.get("type") == "tool_result":
            text = block.get("content")
            results[block.get("tool_use_id")] = (bool(block.get("is_error")), text if isinstance(text, str) else json.dumps(text))

def read_ok(doc, heading):
    return any(path.endswith("/plugins/adf/docs/" + doc) and not results.get(i, (True, ""))[0] and heading in results[i][1]
               for i, path in reads.items())

plugin_denials = [d for d in denials if "/plugins/adf/" in json.dumps(d.get("tool_input", {}))]
def check(label, ok):
    print(f"- {'✓' if ok else '✘'} {label}")

print("### Checks")
if case == "agent-spec-model":
    check("the spec-analyzer agent read the plugin's SPEC-MODEL.md", read_ok("SPEC-MODEL.md", "# Spec model"))
    check("nothing asked to read the plugin's folder", not plugin_denials)
elif case == "session-docs":
    check("the session context named the plugin's docs folder", context)
    check("Claude read the plugin's MEMORY-STRATEGY.md", read_ok("MEMORY-STRATEGY.md", "# Memory strategy"))
    check("nothing asked to read the plugin's folder", not plugin_denials)
    check("no web fetch", not fetched)
elif case == "without-rule":
    check("without the rule, reading the plugin's folder asks first (denied headless)", bool(plugin_denials))
print("### Reads")
print("```")
for i, path in reads.items():
    error, text = results.get(i, (None, ""))
    print(f"{'denied/error' if error else 'ok':12} {path}")
print("```")
PY
