#!/usr/bin/env bash
# Stand up an isolated worktree for one task, so an agent (or you) can work without colliding with
# anyone else: its own branch, its own env file seeded from the MAIN checkout's, its own port, and —
# unless --no-start — its environment set up and started.
#
# Worktrees are siblings of the main checkout (or live under WORKTREE_PARENT), named after the
# branch with "/" turned into "-" (feat/newsletter-signup → ../feat-newsletter-signup). Ports derive
# from that name, so they're stable across runs, and are reserved under a lock so two agents
# starting at once can't claim the same one.
#
# Usage: scripts/agent/worktree-new.sh <type>/<slug> [--no-start | --setup-only] [--refresh-env] [--from <ref>]
#   (default)      create the worktree if needed, run SETUP_CMD and START_CMD, wait for READY_URL
#   --no-start     create the worktree and its env file only — what /dispatch uses
#   --setup-only   create if needed and run SETUP_CMD (e.g. host dependencies the git hooks need)
#   --refresh-env  rewrite an existing worktree's env file from the main checkout and re-claim its port
#   --from <ref>   start a NEW branch from <ref> instead of BASE_BRANCH (e.g. a release tag for a hotfix)
# Rerunning for an existing worktree never touches its branch; without --no-start it sets the
# environment up and starts it. Settings: scripts/agent/worktree.conf
set -euo pipefail
. "$(dirname "$0")/_worktree-lib.sh"

usage() {
  echo "Usage: $0 <type>/<slug> [--no-start | --setup-only] [--refresh-env] [--from <ref>]" >&2
  exit 1
}

BRANCH=""
MODE="start"
REFRESH_ENV=""
FROM_REF=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-start) [ "$MODE" = "start" ] || die "--no-start and --setup-only exclude each other."; MODE="none" ;;
    --setup-only) [ "$MODE" = "start" ] || die "--no-start and --setup-only exclude each other."; MODE="setup" ;;
    --refresh-env) REFRESH_ENV=1 ;;
    --from)
      [ $# -ge 2 ] || die "--from needs a ref."
      FROM_REF="$2"
      shift
      ;;
    --from=*) FROM_REF="${1#--from=}" ;;
    -*) die "unknown option '$1'." ;;
    *)
      [ -z "$BRANCH" ] || die "unexpected extra argument '$1'."
      BRANCH="$1"
      ;;
  esac
  shift
done
[ -n "$BRANCH" ] || usage
if ! [[ $BRANCH =~ ^[a-z]+/[a-z0-9][a-z0-9._-]*$ ]]; then
  echo "Note: '$BRANCH' isn't <type>/<slug> (e.g. feat/newsletter-signup) — continuing anyway." >&2
fi

SLUG="$(to_slug "$BRANCH")"
MAIN_CHECKOUT="$(main_checkout)" || die "not inside a git repository."
PARENT="$(worktree_parent "$MAIN_CHECKOUT")"
WORKTREE_DIR="$PARENT/$SLUG"
PROJECT="$(project_name "$MAIN_CHECKOUT" "$SLUG")"
APP_PORT=""

# --- Branch and worktree ---------------------------------------------------------------------
existing="$(worktree_of_branch "$MAIN_CHECKOUT" "$BRANCH")"
EXISTING=""
# A linked worktree's .git is a file; the main checkout's is a directory and is never "reused".
if [ "$existing" = "$WORKTREE_DIR" ] && [ -f "$WORKTREE_DIR/.git" ]; then
  EXISTING=1
  [ -z "$FROM_REF" ] || echo "Note: '$BRANCH' already has a worktree — --from is ignored." >&2
  echo "==> Worktree exists: $WORKTREE_DIR (branch left as it is)"
else
  [ -z "$existing" ] || die "'$BRANCH' is already checked out at $existing."
  [ ! -e "$WORKTREE_DIR" ] || die "$WORKTREE_DIR already exists."

  if git -C "$MAIN_CHECKOUT" remote get-url origin >/dev/null 2>&1; then
    echo "==> Fetching origin"
    # Bounded, so an unattended run can't hang on a stuck credential prompt or a dead network.
    git -C "$MAIN_CHECKOUT" fetch --quiet --tags origin &
    fetch_pid=$!
    waited=0
    while kill -0 "$fetch_pid" 2>/dev/null; do
      sleep 1
      waited=$((waited + 1))
      if [ "$waited" -ge 30 ]; then
        kill -9 "$fetch_pid" 2>/dev/null || true
        die "'git fetch origin' timed out after 30s (check credentials and network)."
      fi
    done
    wait "$fetch_pid" || die "'git fetch origin' failed."
  fi

  if git -C "$MAIN_CHECKOUT" show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH"; then
    base="origin/$BASE_BRANCH"
  else
    base="$BASE_BRANCH"
  fi

  if git -C "$MAIN_CHECKOUT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "==> Branch '$BRANCH' exists locally — reusing it"
    behind="$(git -C "$MAIN_CHECKOUT" rev-list --count "$BRANCH..$base" 2>/dev/null || echo 0)"
    if [ "$behind" -gt 0 ]; then
      echo "!! '$BRANCH' is $behind commit(s) behind $base. If it is left over from an earlier delivery" >&2
      echo "   (git keeps a branch after a squash merge), new work on it starts from old code — a change" >&2
      echo "   request gets a fresh branch: <type>/<feature-slug>-<change>." >&2
    fi
    git -C "$MAIN_CHECKOUT" worktree add --quiet "$WORKTREE_DIR" "$BRANCH"
  elif git -C "$MAIN_CHECKOUT" show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "==> Branch '$BRANCH' exists on origin — tracking it"
    git -C "$MAIN_CHECKOUT" worktree add --quiet -b "$BRANCH" "$WORKTREE_DIR" "origin/$BRANCH"
  else
    start="${FROM_REF:-$base}"
    git -C "$MAIN_CHECKOUT" rev-parse --verify --quiet "$start^{commit}" >/dev/null || die "'$start' is not a commit, branch, or tag here."
    echo "==> Creating '$BRANCH' from $start"
    git -C "$MAIN_CHECKOUT" worktree add --quiet --no-track -b "$BRANCH" "$WORKTREE_DIR" "$start"
  fi
fi

# --- Port, under a lock ------------------------------------------------------------------------
# "Taken" means listening now OR reserved in a sibling worktree's env file whose environment isn't
# up yet. Checking only the first is a race: two agents starting together both see a free port.
# The env files are the registry; the lock makes check-then-claim atomic.
LOCK_DIR="$PARENT/.$(repo_name "$MAIN_CHECKOUT")-worktree-ports.lock"
release_lock() { rm -rf "$LOCK_DIR" 2>/dev/null || true; }

WRITE_ENV=""
if [ -n "$ENV_FILE" ] && { [ -z "$EXISTING" ] || [ -n "$REFRESH_ENV" ]; }; then
  WRITE_ENV=1
fi

if [ -n "$WRITE_ENV" ] && [ "${PORT_SLOTS:-0}" -gt 0 ]; then
  waited=0
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    owner="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
    if [ -n "$owner" ] && ! kill -0 "$owner" 2>/dev/null; then
      echo "==> Clearing a stale port lock left by PID $owner"
      rm -rf "$LOCK_DIR"
      continue
    fi
    sleep 1
    waited=$((waited + 1))
    [ "$waited" -lt 60 ] || die "timed out waiting for the port lock at $LOCK_DIR (remove it if no other run is active)."
  done
  trap release_lock EXIT
  echo $$ >"$LOCK_DIR/pid"

  reserved=" "
  while IFS= read -r path; do
    [ "$path" = "$WORKTREE_DIR" ] && continue
    port="$(env_value "$path/$ENV_FILE" APP_PORT || true)"
    [ -n "$port" ] && reserved="$reserved$port "
  done < <(all_worktrees "$MAIN_CHECKOUT")

  # Refreshing keeps the worktree's own port while no sibling claims it — its app may be running on it.
  current="$(env_value "$WORKTREE_DIR/$ENV_FILE" APP_PORT || true)"
  if [ -n "$EXISTING" ] && [ -n "$current" ]; then
    case "$reserved" in *" $current "*) ;; *) APP_PORT="$current" ;; esac
  fi

  if [ -z "$APP_PORT" ]; then
    slot=$(($(printf '%s' "$SLUG" | cksum | awk '{print $1}') % PORT_SLOTS))
    attempts=0
    while [ "$attempts" -lt "$PORT_SLOTS" ]; do
      candidate=$((PORT_RANGE_START + slot * PORT_STEP + PORT_OFFSET))
      case "$reserved" in *" $candidate "*) ;; *) port_in_use "$candidate" || { APP_PORT=$candidate; break; } ;; esac
      slot=$(((slot + 1) % PORT_SLOTS))
      attempts=$((attempts + 1))
    done
    [ -n "$APP_PORT" ] || die "no free port slot after $PORT_SLOTS attempts."
  fi
elif [ "${PORT_SLOTS:-0}" -gt 0 ]; then
  APP_PORT="$(env_value "$WORKTREE_DIR/$ENV_FILE" APP_PORT || true)"
fi

# --- Env file: secrets from the MAIN checkout, identity from this worktree ---------------------
# Seeding from whichever worktree ran the script would copy its port and its local experiments,
# drifting further with every hop. The main checkout is the one canonical source.
if [ -n "$WRITE_ENV" ]; then
  source_file="$MAIN_CHECKOUT/$ENV_FILE"
  if [ -f "$source_file" ]; then
    echo "==> Writing $ENV_FILE from the main checkout's"
  else
    source_file="$WORKTREE_DIR/$ENV_TEMPLATE"
    echo "==> No $ENV_FILE in the main checkout — seeding from $ENV_TEMPLATE"
  fi

  overrides=""
  if [ -n "$APP_PORT" ]; then
    overrides="APP_PORT=$APP_PORT"
  fi
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      overrides="${overrides:+$overrides
}$(expand "$line")"
    fi
  done <<<"$ENV_OVERRIDES"

  keys="$(printf '%s\n' "$overrides" | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' | paste -sd'|' -)"
  {
    if [ -f "$source_file" ]; then
      grep -vE "^(${keys:-__none__})=|^### worktree overrides" "$source_file" || true
    fi
    if [ -n "$overrides" ]; then
      echo
      echo "### worktree overrides — generated by scripts/agent/worktree-new.sh for '$SLUG'; refresh with --refresh-env instead of editing"
      printf '%s\n' "$overrides"
    fi
  } >"$WORKTREE_DIR/$ENV_FILE.tmp"
  mv "$WORKTREE_DIR/$ENV_FILE.tmp" "$WORKTREE_DIR/$ENV_FILE"
fi

# The port is claimed once the env file exists; release the lock before any slow work.
release_lock
trap - EXIT

echo
echo "==> Worktree ready: $WORKTREE_DIR"
echo "    Branch:  $BRANCH"
echo "    Project: $PROJECT"
[ -z "$APP_PORT" ] || echo "    Port:    $APP_PORT"

missing=""
for variable in $REQUIRED_ENV; do
  grep -qE "^${variable}=.+" "$WORKTREE_DIR/$ENV_FILE" 2>/dev/null || missing="$missing $variable"
done
if [ -n "$missing" ]; then
  echo
  echo "!! Empty in $WORKTREE_DIR/$ENV_FILE:$missing"
  echo "   Fill them in the MAIN checkout's $ENV_FILE, then rerun with --refresh-env."
fi

if [ "$MODE" = "none" ]; then
  echo
  echo "--no-start: the environment is left down. When a step needs it, run from the worktree:"
  echo "  scripts/agent/worktree-new.sh $BRANCH                # set up and start"
  echo "  scripts/agent/worktree-new.sh $BRANCH --setup-only   # only what the git hooks need"
  exit 0
fi

if [ -n "$SETUP_CMD" ]; then
  echo "==> Setup: $(expand "$SETUP_CMD")"
  (cd "$WORKTREE_DIR" && sh -c "$(expand "$SETUP_CMD")")
fi
[ "$MODE" = "setup" ] && exit 0

[ -z "$missing" ] || die "not starting — required variables are empty."
if [ -n "$START_CMD" ]; then
  echo "==> Start: $(expand "$START_CMD")"
  (cd "$WORKTREE_DIR" && sh -c "$(expand "$START_CMD")")
fi
if [ -n "$READY_URL" ]; then
  url="$(expand "$READY_URL")"
  echo "==> Waiting for $url"
  waited=0
  while [ "$waited" -lt 300 ]; do
    code="$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$url" 2>/dev/null || true)"
    case "$code" in [1-5][0-9][0-9]) echo "==> Ready: HTTP $code after ${waited}s"; exit 0 ;; esac
    sleep 3
    waited=$((waited + 3))
  done
  die "$url did not respond within 300s — the environment is up but not answering; check its logs."
fi
