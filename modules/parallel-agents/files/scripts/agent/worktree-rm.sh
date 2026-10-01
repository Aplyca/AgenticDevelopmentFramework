#!/usr/bin/env bash
# Tear down a worktree created by worktree-new.sh: stop its environment (STOP_CMD), remove the
# worktree, and delete its branch only if git sees it as merged.
#
# Usage: scripts/agent/worktree-rm.sh <type>/<slug | slug> [--force]
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

if [ -n "$BRANCH" ]; then
  if git -C "$MAIN_CHECKOUT" branch -d "$BRANCH" >/dev/null 2>&1; then
    echo "==> Deleted branch $BRANCH (merged)"
  else
    echo "Note: kept branch '$BRANCH' — git doesn't see it as merged (normal after a squash merge)."
    echo "      If its work is preserved upstream, delete it with: git branch -D $BRANCH"
  fi
fi
echo "==> Done."
