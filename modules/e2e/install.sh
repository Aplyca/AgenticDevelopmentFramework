#!/usr/bin/env sh
#
# Merges the e2e module's permissions into a repository's .claude/settings.json — never overwrites:
# existing rules keep their order, and only missing ones are added. Running the end-to-end suite and
# the smoke suite (`make e2e`, `make smoke`, or `npm --prefix e2e test`) takes no prompt, so a test-first
# loop can rerun a test as often as it needs. With the docker module, only the make tasks: `npm --prefix
# e2e test` would run the suite on the host, which Docker mode never uses — install the docker module
# first, and a rerun takes out the rule an earlier install added. Safe to run again (an upgrade picks up
# new rules the same way).
#
# Usage: modules/e2e/install.sh [path/to/repository]    (default: the current directory)
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
allow = permissions.setdefault("allow", [])
# With the docker module (its Bash(make *) rule), make tasks run the tests in either local mode, and
# Docker mode installs nothing on the host: the commands that run them on the host stay unallowed, so
# an agent that reaches for one gets a prompt. A rerun takes out the ones an earlier install added.
host = [] if "Bash(make *)" not in allow else [r for r in fragment["allow"] if not r.startswith("Bash(make ")]
removed = [r for r in allow if r in host]
allow[:] = [r for r in allow if r not in host]
allowed = append_missing(allow, [r for r in fragment["allow"] if r not in host])
save(settings_path, settings)
print(f".claude/settings.json: {len(allowed)} end-to-end test command(s) allowed"
      + (f", {len(removed)} host command(s) removed: the docker module's make tasks run them" if removed else ""))
PY
