# Shared by worktree-new.sh, worktree-rm.sh, and worktree-ls.sh. Sourced, never executed.

AGENT_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_BRANCH="main"
WORKTREE_PARENT=""
PROJECT_PREFIX=""
ENV_FILE=".env"
ENV_TEMPLATE=".env.example"
PORT_RANGE_START=41000
PORT_SLOTS=180
PORT_STEP=100
PORT_OFFSET=80
ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'
REQUIRED_ENV=""
SETUP_CMD=""
START_CMD=""
READY_URL=""
STOP_CMD=""
ISOLATED_PORTS=0
ISOLATED_ENV_OVERRIDES=""
ISOLATED_SETUP_CMD=""
ISOLATED_START_CMD=""
ISOLATED_STOP_CMD=""
ENV_INFO_CMD=""
# Settings may use ${APP_PORT}, ${PORT_BASE}, ${PORT_0}…${PORT_99}, ${SLUG}, and ${PROJECT} in single
# or double quotes: keep them literal while sourcing; expand() fills them in once the values are known.
# shellcheck disable=SC2016
APP_PORT='${APP_PORT}' PORT_BASE='${PORT_BASE}' SLUG='${SLUG}' PROJECT='${PROJECT}'
_n=0
while [ "$_n" -lt 100 ]; do
  printf -v "PORT_$_n" '${PORT_%s}' "$_n"
  _n=$((_n + 1))
done
# shellcheck source=worktree.conf
if [ -f "$AGENT_SCRIPTS_DIR/worktree.conf" ]; then
  . "$AGENT_SCRIPTS_DIR/worktree.conf"
fi
unset APP_PORT PORT_BASE SLUG PROJECT
while [ "$_n" -gt 0 ]; do
  _n=$((_n - 1))
  unset "PORT_$_n"
done

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

# builtin_worktree <path> <main checkout> — one of Claude Code's own worktrees (.claude/worktrees/),
# which get no env file, no port, and a generated branch name.
builtin_worktree() {
  case "$1" in "$2"/.claude/worktrees/*) return 0 ;; esac
  return 1
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

# expand <text> — substitute ${APP_PORT}, ${PORT_BASE}, ${PORT_N}, ${SLUG}, ${PROJECT} without eval.
# ${PORT_N} is the worktree's Nth port: its block starts at PORT_BASE (APP_PORT - PORT_OFFSET).
expand() {
  local text="$1" pattern='\$\{PORT_([0-9]+)\}'
  while [[ $text =~ $pattern ]]; do
    text="${text//"${BASH_REMATCH[0]}"/$((${PORT_BASE:-0} + 10#${BASH_REMATCH[1]}))}"
  done
  text="${text//\$\{APP_PORT\}/${APP_PORT:-}}"
  text="${text//\$\{PORT_BASE\}/${PORT_BASE:-}}"
  text="${text//\$\{SLUG\}/${SLUG:-}}"
  text="${text//\$\{PROJECT\}/${PROJECT:-}}"
  printf '%s' "$text"
}

die() {
  echo "Error: $1" >&2
  exit 1
}
