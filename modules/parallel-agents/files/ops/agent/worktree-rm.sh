#!/usr/bin/env bash
# Tear down a worktree created by worktree-new.sh: stop its environment (STOP_CMD), remove the
# worktree, bring the main checkout's base branch up to date with origin, and delete the worktree's
# branch only if git sees it as merged.
#
# Usage: ops/agent/worktree-rm.sh <type>/<slug | slug> [--force]
#   --force   remove even with uncommitted changes (they are lost)
set -euo pipefail
. "$(dirname "$0")/_worktree-lib.sh"

INPUT="${1:-}"
FORCE=""
[ "${2:-}" = "--force" ] && FORCE="--force"
[ -n "$INPUT" ] || { echo "Usage: $0 <type>/<slug | slug> [--force]" >&2; exit 1; }

MAIN_CHECKOUT="$(main_checkout)" || die "not inside a git repository."
SLUG="$(to_slug "$INPUT")"

WORKTREE_DIR="$(worktree_of_branch "$MAIN_CHECKOUT" "$INPUT")"
if [ -z "$WORKTREE_DIR" ]; then
  WORKTREE_DIR="$(all_worktrees "$MAIN_CHECKOUT" | awk -v slug="$SLUG" '{ n = split($0, parts, "/"); if (parts[n] == slug) print }' | head -1)"
fi
[ -n "$WORKTREE_DIR" ] && [ -d "$WORKTREE_DIR" ] || die "no worktree found for '$INPUT'."
[ "$WORKTREE_DIR" != "$MAIN_CHECKOUT" ] || die "refusing to remove the main checkout."

if [ -z "$FORCE" ] && [ -n "$(git -C "$WORKTREE_DIR" status --porcelain)" ]; then
  die "$WORKTREE_DIR has uncommitted changes. Commit or stash them, or rerun with --force (they will be lost)."
fi

BRANCH="$(git -C "$WORKTREE_DIR" branch --show-current)"
SLUG="$(basename "$WORKTREE_DIR")"
PROJECT="$(project_name "$MAIN_CHECKOUT" "$SLUG")"
APP_PORT="$(env_value "$WORKTREE_DIR/$ENV_FILE" APP_PORT || true)"

if [ -n "$STOP_CMD" ]; then
  echo "==> Stop: $(expand "$STOP_CMD")"
  (cd "$WORKTREE_DIR" && sh -c "$(expand "$STOP_CMD")") || echo "Warning: the stop command failed or nothing was running." >&2
fi

echo "==> Removing worktree $WORKTREE_DIR"
git -C "$MAIN_CHECKOUT" worktree remove $FORCE "$WORKTREE_DIR"

# A worktree goes once its work has merged, so the main checkout's base branch is behind: bring it up
# to date. The next task's branch starts from it, the dispatcher lists its specs/, every session
# reads its AGENTS.md first, and `git branch -d` below checks the merge against it. Only a
# fast-forward, only on the base branch, and never over uncommitted changes.
update_base() {
  local current behind fetched=0
  git -C "$MAIN_CHECKOUT" remote get-url origin >/dev/null 2>&1 || return 0
  echo "==> Fetching origin"
  fetch_origin "$MAIN_CHECKOUT" || fetched=$?
  if [ "$fetched" -ne 0 ]; then
    echo "Note: couldn't fetch origin, so $BASE_BRANCH in the main checkout wasn't updated." >&2
    return 0
  fi
  git -C "$MAIN_CHECKOUT" show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH" || return 0
  current="$(git -C "$MAIN_CHECKOUT" branch --show-current)"
  if [ "$current" != "$BASE_BRANCH" ]; then
    echo "Note: the main checkout is on '${current:-a detached HEAD}', not $BASE_BRANCH, so it wasn't updated."
    return 0
  fi
  if [ -n "$(git -C "$MAIN_CHECKOUT" status --porcelain --untracked-files=no)" ]; then
    echo "Note: the main checkout has uncommitted changes, so $BASE_BRANCH wasn't updated. Once they're gone: git pull --ff-only"
    return 0
  fi
  behind="$(git -C "$MAIN_CHECKOUT" rev-list --count "HEAD..origin/$BASE_BRANCH")"
  if [ "$behind" -eq 0 ]; then
    echo "==> $BASE_BRANCH in the main checkout is up to date"
  elif git -C "$MAIN_CHECKOUT" merge --ff-only --quiet "origin/$BASE_BRANCH" >/dev/null 2>&1; then
    echo "==> Updated $BASE_BRANCH in the main checkout: $behind new commit(s) from origin"
  else
    echo "Note: $BASE_BRANCH in the main checkout has commits origin doesn't, so it wasn't updated."
  fi
}
update_base

if [ -n "$BRANCH" ]; then
  if git -C "$MAIN_CHECKOUT" branch -d "$BRANCH" >/dev/null 2>&1; then
    echo "==> Deleted branch $BRANCH (merged)"
  else
    echo "Note: kept branch '$BRANCH' — git doesn't see it as merged (normal after a squash merge)."
    echo "      If its work is preserved upstream, delete it with: git branch -D $BRANCH"
  fi
fi
echo "==> Done."
