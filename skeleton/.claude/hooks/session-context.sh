#!/usr/bin/env bash
# SessionStart hook. Prints a few lines of orientation that Claude Code adds to the session's
# context: which checkout this is, the branch, and the spec folder that branch belongs to — the
# facts an agent needs for its first step (triage) and that it would otherwise guess or re-derive.
set -uo pipefail
. "$(dirname "$0")/_lib.sh"

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0

branch="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null || echo "detached HEAD")"
git_dir="$(cd "$root" && cd "$(git rev-parse --git-dir)" && pwd)"
common_dir="$(cd "$root" && cd "$(git rev-parse --git-common-dir)" && pwd)"
changes="$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

echo "Session context (.claude/hooks/session-context.sh):"
if [ "$git_dir" = "$common_dir" ]; then
  checkout="main checkout"
else
  checkout="linked worktree"
fi
echo "- ${checkout}: $root — branch $branch, $changes uncommitted change(s)"

if in_words "$branch" "$PROTECTED_BRANCHES"; then
  echo "- $branch is protected: create a work branch (<type>/<slug>) before changing anything."
fi

# A branch joins its spec folder by slug: feat/newsletter-signup → specs/007-newsletter-signup/, and a
# change request's branch (feat/newsletter-signup-topics) joins the longest folder slug it starts with.
slug="${branch#*/}"
if [ "$slug" != "$branch" ] && [ -d "$root/$SPECS_DIR" ]; then
  spec_dir=""
  best=0
  for dir in "$root/$SPECS_DIR"/*/; do
    [ -f "$dir/spec.md" ] || continue
    folder_slug="$(basename "$dir" | sed -E 's/^[0-9]+-//')"
    case "$slug" in
      "$folder_slug" | "$folder_slug"-*)
        if [ "${#folder_slug}" -gt "$best" ]; then
          spec_dir="${dir%/}"
          best="${#folder_slug}"
        fi
        ;;
    esac
  done
  if [ -n "$spec_dir" ]; then
    status="$(sed -nE 's/^status:[[:space:]]*([a-z-]+).*/\1/p' "$spec_dir/spec.md" | head -1)"
    echo "- Spec folder for this branch: ${spec_dir#"$root"/}/ (status: ${status:-unknown})"
  else
    echo "- No spec folder matches '$slug' — triage decides whether this work needs one."
  fi
fi

if [ -x "$root/scripts/agent/worktree-new.sh" ]; then
  main="$(cd "$common_dir/.." && pwd -P)"
  if [ "$checkout" = "main checkout" ]; then
    echo "- Role: DISPATCHER. This is the shared main checkout — hand each task to its own worktree (/dispatch); never edit code here."
  else
    case "$(cd "$root" && pwd -P)" in
      "$main"/.claude/worktrees/*)
        echo "- Role: NONE. This is one of Claude Code's own worktrees, which this project's scripts never set up (a generated branch, none of the project's env). Fine for reading and exploring; for task work, ask the developer to dispatch the task from the main checkout (/dispatch) and open a session in the worktree it creates."
        ;;
      *)
        echo "- Role: WORKER. This worktree is yours for one task — start with triage (/triage)."
        ;;
    esac
  fi
fi

exit 0
