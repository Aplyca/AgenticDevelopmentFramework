#!/usr/bin/env bash
# The running web services in .claude/launch.json, which Claude Desktop's Browser lists on a new tab:
# one row per service, named "<service> · http://localhost:<port>", and one click opens it. The
# agent's preview attaches to the same service instead of starting a dev server of its own. Run it
# after anything starts or stops a service, and the rows match what runs (P8):
#
#   - each service in Docker labeled claude.browser: "true" in compose.yaml, on the port Docker
#     published for it (docker compose ps);
#   - in native mode, the app on the host while it runs (ops/native/.run/app.env), named APP.
#
# A stopped service loses its row, so a port Docker later hands to another checkout is never listed
# here. ops/docker/Makefile runs it in `up`, `prod`, and `down`, and ops/native/native.sh when it
# starts or stops the app. Reads APP and COMPOSE from its environment.
#
# The file is this checkout's, so it's written only where git ignores it (L7). The developer's own
# entries and settings stay: the rows this script writes are the attach entries whose name is
# "<service> · <url>". A file that isn't plain JSON (comments) is left as it is. It never fails the
# task that runs it. Needs python3, and without it lists nothing.
set -uo pipefail

cd "$(dirname "$0")/../.."
FILE=.claude/launch.json
COMPOSE="${COMPOSE:-docker compose}"

if ! git check-ignore -q "$FILE" 2>/dev/null; then
  echo "launch-json.sh: git doesn't ignore $FILE, so Claude Desktop's Browser doesn't list this checkout's services: add it to .gitignore (L7)" >&2
  exit 0
fi
command -v python3 >/dev/null 2>&1 || exit 0

# What runs in Docker now: one JSON object per container (a JSON array before Compose 2.21).
RUNNING="$($COMPOSE ps --format json 2>/dev/null || true)" \
  python3 - "$FILE" "${APP:-app}" ops/native/.run/app.env <<'PY' || true
import json, os, sys

path, app, state = sys.argv[1:4]
LABEL = "claude.browser=true"

def note(message):
    print(f"launch-json.sh: {message}", file=sys.stderr)

def containers(text):
    text = text.strip()
    if text.startswith("["):
        return json.loads(text)
    return [json.loads(line) for line in text.splitlines() if line.strip()]

# The rows that should be there: service → port.
wanted = {}
try:
    found = containers(os.environ.get("RUNNING", ""))
except ValueError:
    found = []
for c in found:
    if LABEL not in str(c.get("Labels", "")).split(","):
        continue
    ports = [p.get("PublishedPort") for p in c.get("Publishers") or [] if p.get("PublishedPort")]
    if c.get("Service") and ports:
        wanted[c["Service"]] = ports[0]
try:
    with open(state, encoding="utf-8") as f:
        run = dict(line.strip().split("=", 1) for line in f if "=" in line)
    os.kill(int(run["PID"]), 0)
    wanted[app] = int(run["APP_PORT"])
except (OSError, KeyError, ValueError):
    pass

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

def row(service, port):
    url = f"http://localhost:{port}"
    return {"name": f"{service} · {url}", "url": url, "port": port}

def ours(c):
    return (isinstance(c, dict) and "runtimeExecutable" not in c and "program" not in c
            and isinstance(c.get("url"), str) and str(c.get("name", "")).endswith(" · " + c["url"]))

kept = [c for c in configs if not ours(c)]
rows = [row(service, port) for service, port in sorted(wanted.items())]
if kept + rows == configs:
    sys.exit()
data["configurations"] = kept + rows
if not data["configurations"] and set(data) <= {"version", "configurations"}:
    if os.path.exists(path):
        os.remove(path)
    sys.exit()
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path + ".tmp", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(path + ".tmp", path)
PY
