#!/usr/bin/env sh
#
# Merges the docker module's permissions into a repository's .claude/settings.json — never
# overwrites: existing rules keep their order, and only missing ones are added. Read-only docker
# commands run without a prompt; commands that delete containers, volumes, or images always ask.
# Safe to run again (an upgrade picks up new rules the same way).
#
# Usage: modules/docker/install.sh [path/to/repository]    (default: the current directory)
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


fragment = load(os.path.join(module, "settings-fragment.json"))["permissions"]
settings_path = os.path.join(target, ".claude", "settings.json")
settings = load(settings_path)
permissions = settings.setdefault("permissions", {})
allowed = append_missing(permissions.setdefault("allow", []), fragment["allow"])
asked = append_missing(permissions.setdefault("ask", []), fragment["ask"])
save(settings_path, settings)
print(f".claude/settings.json: {len(allowed)} read-only docker command(s) allowed, "
      f"{len(asked)} destructive one(s) set to ask")
PY
