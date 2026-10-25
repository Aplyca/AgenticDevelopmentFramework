# Shared by worktree-new.sh, worktree-rm.sh, and worktree-ls.sh. Sourced, never executed.

AGENT_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_BRANCH="main"
WORKTREE_PARENT=""
PROJECT_PREFIX=""
ENV_FILE=".env"
ENV_TEMPLATE=".env.example"
PORT_RANGE_START=41000
PORT_SLOTS=0
PORT_STEP=100
PORT_OFFSET=80
ENV_OVERRIDES=''
REQUIRED_ENV=""
SETUP_CMD=""
START_CMD=""
READY_URL=""
STOP_CMD=""
ENV_INFO_CMD=""
# Settings may use ${APP_PORT}, ${SLUG}, and ${PROJECT} in single or double quotes: keep them
# literal while sourcing; expand() fills them in once the values are known.
# shellcheck disable=SC2016
APP_PORT='${APP_PORT}' SLUG='${SLUG}' PROJECT='${PROJECT}'
# shellcheck source=worktree.conf
if [ -f "$AGENT_SCRIPTS_DIR/worktree.conf" ]; then
  . "$AGENT_SCRIPTS_DIR/worktree.conf"
fi
unset APP_PORT SLUG PROJECT

to_slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr '/' '-' | tr -cs 'a-z0-9_-' '-' | sed -E 's/^-+//; s/-+$//'
}

# The main checkout, resolved from any worktree (and any working directory): the parent of the
# shared .git directory of the repository these scripts live in.
main_checkout() {
  local common
  common="$(git -C "$AGENT_SCRIPTS_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  (cd "$(dirname "$common")" && pwd)
}

worktree_parent() {
  if [ -n "$WORKTREE_PARENT" ]; then
    mkdir -p "$WORKTREE_PARENT" && (cd "$WORKTREE_PARENT" && pwd)
  else
    dirname "$1"
  fi
}

# The repository's name: origin's last path segment without .git, else the main checkout's folder.
# Used as the default prefix, so two repositories' worktrees never share a project or a lock.
repo_name() {
  local name
  name="$(git -C "$1" remote get-url origin 2>/dev/null || true)"
  name="${name%/}"
  name="${name##*/}"
  name="${name##*:}"
  name="${name%.git}"
  [ -n "$name" ] || name="$(basename "$1")"
  to_slug "$name"
}

project_name() {
  local prefix="${PROJECT_PREFIX:-$(repo_name "$1")}"
  to_slug "$prefix-$2"
}

# scripts_worktree <path> <branch> — a worktree worktree-new.sh set up. It leaves a marker in the
# worktree's own git directory; worktrees from before the marker are named after their branch.
# Any other linked worktree — Claude Code's own, from the desktop app or `claude --worktree` — is a
# worker too, without the scripts' env overrides, port, or setup (decision 0015).
scripts_worktree() {
  local git_dir
  git_dir="$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  [ -f "$git_dir/agent-worktree" ] || [ "$(basename "$1")" = "$(to_slug "$2")" ]
}

# generated_branch <branch> — a name nobody chose for the task: Claude Code's (worktree-<name>,
# claude/<name>), any name without a <type>/ prefix, or a detached HEAD.
generated_branch() {
  case "$1" in
    "(detached)" | worktree-* | claude/*) return 0 ;;
    */*) return 1 ;;
  esac
  return 0
}

# The path where a branch is checked out, if any.
worktree_of_branch() {
  git -C "$1" worktree list --porcelain |
    awk -v ref="branch refs/heads/$2" '/^worktree /{path=substr($0,10)} $0==ref{print path}'
}

# Every worktree path (main checkout included).
all_worktrees() {
  git -C "$1" worktree list --porcelain | awk '/^worktree /{print substr($0,10)}'
}

port_in_use() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
}

env_value() {
  [ -f "$1" ] && sed -n "s/^$2=//p" "$1" | tail -1 | tr -d '[:space:]'
}

# launch_entry <worktree> <port> — the app's entry in the worktree's .claude/launch.json, which Claude
# Desktop's Browser lists on a new tab: "app", at http://localhost:<port>, the port reserved for the
# worktree. Only where git ignores the file. The developer's own entries stay; a file that isn't
# plain JSON, or an "app" configuration that runs a command, is left as it is. Skipped without python3.
launch_entry() {
  if ! git -C "$1" check-ignore -q .claude/launch.json 2>/dev/null; then
    echo "Note: git doesn't ignore .claude/launch.json, so Claude Desktop's Browser doesn't list this worktree's app — add it to .gitignore." >&2
    return 0
  fi
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1/.claude/launch.json" "$2" <<'PY' || true
import json, os, sys

path, port = sys.argv[1], int(sys.argv[2])
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except FileNotFoundError:
    data = {"version": "0.0.1", "configurations": []}
except (OSError, ValueError):
    print(f"Note: {path} isn't plain JSON, so it's left as it is.", file=sys.stderr)
    sys.exit()
configs = data.get("configurations") if isinstance(data, dict) else None
if not isinstance(configs, list):
    sys.exit()
entry = {"name": "app", "url": f"http://localhost:{port}", "port": port}
index = next((i for i, c in enumerate(configs) if isinstance(c, dict) and c.get("name") == "app"), None)
if index is None:
    configs.append(entry)
elif "runtimeExecutable" in configs[index] or "program" in configs[index] or configs[index] == entry:
    sys.exit()
else:
    configs[index] = entry
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path + ".tmp", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(path + ".tmp", path)
PY
}

# expand <text> — substitute ${APP_PORT}, ${SLUG}, ${PROJECT} without eval.
expand() {
  local text="$1"
  text="${text//\$\{APP_PORT\}/${APP_PORT:-}}"
  text="${text//\$\{SLUG\}/${SLUG:-}}"
  text="${text//\$\{PROJECT\}/${PROJECT:-}}"
  printf '%s' "$text"
}

die() {
  echo "Error: $1" >&2
  exit 1
}

# fetch_origin <checkout> — fetch origin, bounded so an unattended run can't hang on a stuck
# credential prompt or a dead network. 0 when it fetched (or there's no origin), 1 when it failed,
# 2 when it timed out after 30 seconds.
fetch_origin() {
  local pid waited=0
  git -C "$1" remote get-url origin >/dev/null 2>&1 || return 0
  git -C "$1" fetch --quiet --tags origin &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    sleep 1
    waited=$((waited + 1))
    if [ "$waited" -ge 30 ]; then
      kill -9 "$pid" 2>/dev/null || true
      return 2
    fi
  done
  wait "$pid" || return 1
}
