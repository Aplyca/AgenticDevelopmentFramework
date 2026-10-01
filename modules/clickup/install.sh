#!/usr/bin/env sh
#
# Merges the ClickUp MCP server and its read-only permissions into a repository — never
# overwrites: other MCP servers, existing permissions, and a customized "clickup" entry are kept.
# Safe to run again (an upgrade picks up new read-only patterns the same way).
#
# Usage: modules/clickup/install.sh [path/to/repository]    (default: the current directory)
#
set -eu

MODULE_DIR=$(cd "$(dirname "$0")" && pwd)
TARGET=${1:-.}

[ -d "$TARGET" ] || { echo "install.sh: no such directory: $TARGET" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "install.sh: python3 is required" >&2; exit 1; }

python3 - "$MODULE_DIR" "$TARGET" <<'PY'
import json
import os
import sys

module, target = sys.argv[1], sys.argv[2]


def load(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError as e:
            sys.exit(f"install.sh: {path} is not valid JSON ({e}); fix it and run again")


def save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


def append_missing(items, additions):
    added = [a for a in additions if a not in items]
    items.extend(added)
    return added


mcp_path = os.path.join(target, ".mcp.json")
mcp = load(mcp_path)
servers = mcp.setdefault("mcpServers", {})
for name, config in load(os.path.join(module, "files", ".mcp.json"))["mcpServers"].items():
    if name not in servers:
        servers[name] = config
        print(f".mcp.json: added the '{name}' server")
    elif servers[name] == config:
        print(f".mcp.json: '{name}' server already present")
    else:
        print(f".mcp.json: kept your existing '{name}' server configuration")
save(mcp_path, mcp)

fragment = load(os.path.join(module, "settings-fragment.json"))
settings_path = os.path.join(target, ".claude", "settings.json")
settings = load(settings_path)
enabled = append_missing(settings.setdefault("enabledMcpjsonServers", []), fragment["enabledMcpjsonServers"])
allowed = append_missing(settings.setdefault("permissions", {}).setdefault("allow", []),
                         fragment["permissions"]["allow"])
save(settings_path, settings)
print(f".claude/settings.json: {len(enabled)} server(s) enabled, {len(allowed)} read-only permission(s) added")
PY
