#!/usr/bin/env bash
# The app's entry in .claude/launch.json, which Claude Desktop's Browser lists on a new tab: one click
# opens the app this checkout runs, and the agent's preview attaches to it instead of starting a dev
# server of its own. `make up` sets it once the app answers, with the port it has now; `make down`
# unsets it, so a port Docker hands to another checkout is never listed here (P8). Both modes use it:
# ops/docker/Makefile, and ops/native/native.sh with the app on the host.
#
#   ops/docker/launch-json.sh set <name> <port>   add or update <name>: http://localhost:<port>
#   ops/docker/launch-json.sh unset <name>        remove it, and the file once nothing else is in it
#
# The file is this checkout's, so it's written only where git ignores it (L7). The developer's own
# entries and settings stay. A file that isn't plain JSON (comments), or a configuration of that name
# that runs a command, is left as it is. It never fails the task that runs it. Needs python3, and
# without it lists nothing.
set -uo pipefail

cd "$(dirname "$0")/../.."
FILE=.claude/launch.json
action="${1:-}" name="${2:-}" port="${3:-}"

note() { echo "launch-json.sh: $*" >&2; }
usage() {
  note "usage: ops/docker/launch-json.sh set <name> <port> | unset <name>"
  exit 2
}

case "$action" in set | unset) ;; *) usage ;; esac
[ -n "$name" ] || usage
# No port published: nothing to list.
[ "$action" = unset ] || [[ $port =~ ^[0-9]+$ ]] || exit 0
if ! git check-ignore -q "$FILE" 2>/dev/null; then
  [ "$action" = unset ] || note "git doesn't ignore $FILE, so Claude Desktop's Browser doesn't list this checkout's app: add it to .gitignore (L7)"
  exit 0
fi
command -v python3 >/dev/null 2>&1 || exit 0

python3 - "$FILE" "$action" "$name" "$port" <<'PY' || true
import json, os, sys

path, action, name, port = sys.argv[1:5]

def note(message):
    print(f"launch-json.sh: {message}", file=sys.stderr)

try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    data = {"version": "0.0.1", "configurations": []}
except (OSError, ValueError):
    note(f"{path} isn't plain JSON, so it's left as it is")
    sys.exit()
configs = data.get("configurations") if isinstance(data, dict) else None
if not isinstance(configs, list):
    note(f"{path} has no configurations list, so it's left as it is")
    sys.exit()

index = next((i for i, c in enumerate(configs) if isinstance(c, dict) and c.get("name") == name), None)
if index is not None and ("runtimeExecutable" in configs[index] or "program" in configs[index]):
    if action == "set":
        note(f"{path} has a configuration named {name} that runs a command, so it's left as it is")
    sys.exit()
if action == "set":
    entry = {"name": name, "url": f"http://localhost:{port}", "port": int(port)}
    if index is None:
        configs.append(entry)
    elif configs[index] == entry:
        sys.exit()
    else:
        configs[index] = entry
elif index is None:
    sys.exit()
else:
    del configs[index]

if not configs and set(data) <= {"version", "configurations"}:
    if os.path.exists(path):
        os.remove(path)
    sys.exit()
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path + ".tmp", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(path + ".tmp", path)
PY
