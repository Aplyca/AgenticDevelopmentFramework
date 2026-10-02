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
  # What this project's worktrees need beyond what Claude Code gives its own — a port, setup or start
  # commands, a base branch other than the default — read from scripts/agent/worktree.conf.
  needs="" base_branch="" env_file=".env"
  if [ -f "$root/scripts/agent/_worktree-lib.sh" ]; then
    IFS='|' read -r needs base_branch env_file < <(bash -c '. "$1" >/dev/null 2>&1 || exit 0
      n=""; [ "${PORT_SLOTS:-0}" -gt 0 ] 2>/dev/null && n="a port"
      [ -z "$SETUP_CMD$START_CMD" ] || n="${n:+$n and }setup or start commands"
      printf "%s|%s|%s\n" "$n" "$BASE_BRANCH" "$ENV_FILE"' _ "$root/scripts/agent/_worktree-lib.sh")
  fi
  default_branch="$(git -C "$root" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
  default_branch="${default_branch#origin/}"
  other_base=""
  if [ -n "$base_branch" ] && [ -n "$default_branch" ] && [ "$base_branch" != "$default_branch" ]; then
    other_base=1
  fi
  main="$(cd "$common_dir/.." && pwd -P)"

  if [ "$checkout" = "main checkout" ]; then
    echo "- Role: DISPATCHER. This is the shared main checkout — never edit here. Each task gets its own worktree, branch, and session."
    if [ -n "$other_base" ]; then
      echo "- Start each task with /dispatch: tasks here start from $base_branch, and Claude Code's own worktrees start from $default_branch."
    elif [ -n "$needs" ]; then
      echo "- A task that runs the app starts with /dispatch (its worktree needs $needs). Any other task can start in a new session with Claude Code's worktree option — the desktop app's worktree toggle, or claude --worktree."
    else
      echo "- Start each task in a new session with Claude Code's worktree option — the desktop app's worktree toggle, or claude --worktree — or with /dispatch."
    fi
  else
    echo "- Role: WORKER. This worktree is yours for one task — start with triage (/aplyca-adf:triage)."
    # The scripts mark the worktrees they set up; ones made before the marker are named after their branch.
    folder="$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]' | tr '/' '-' | tr -cs 'a-z0-9_-' '-' | sed -E 's/^-+//; s/-+$//')"
    if [ ! -f "$git_dir/agent-worktree" ] && [ "$(basename "$root")" != "$folder" ]; then
      generated=""
      case "$branch" in
        "detached HEAD") ;;
        worktree-* | claude/*) generated=1 ;; # Claude Code's own names
        */*) ;;                               # already <type>/<slug>
        *) generated=1 ;;
      esac
      if [ "$branch" = "detached HEAD" ]; then
        echo "- Detached HEAD: after triage, create the task's branch — git switch -c <type>/<slug>."
      elif [ -n "$generated" ]; then
        echo "- The branch name is generated ($branch): after triage, rename it — git branch -m <type>/<slug> — so it joins its spec folder and /aplyca-adf:open-pr takes it."
      fi
      if [ -n "$env_file" ] && [ -f "$main/$env_file" ] && [ ! -e "$root/$env_file" ]; then
        echo "- No $env_file here. Claude Code copies it into the worktrees it creates when .worktreeinclude lists it."
      fi
      if [ -n "$other_base" ]; then
        echo "- Claude Code started this worktree from $default_branch, but tasks here start from $base_branch: ask the developer to /dispatch the task before the first commit."
      elif [ -n "$needs" ]; then
        echo "- Not set up by scripts/agent/worktree-new.sh, so it lacks $needs: fine for work that doesn't run the app. To run it, ask the developer to /dispatch the task."
      fi
    fi
  fi
fi

exit 0
