#!/usr/bin/env bash
# SessionStart hook. Prints a few lines of orientation that Claude Code adds to the session's
# context: which checkout this is, the branch, and the spec folder that branch belongs to — the
# facts an agent needs for its first step (triage) and that it would otherwise guess or re-derive.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0

branch="$(git -C "$root" symbolic-ref --short -q HEAD 2>/dev/null || echo "detached HEAD")"
git_dir="$(git -C "$root" rev-parse --absolute-git-dir 2>/dev/null)"
common_dir="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)"
changes="$(git -C "$root" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

echo "Session context (.claude/hooks/session-context.sh):"
# Git reports the main checkout's git dir and common dir alike (.git), a linked worktree's apart.
if [ "$(git -C "$root" rev-parse --git-dir 2>/dev/null)" = "$common_dir" ]; then
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
  while IFS= read -r dir; do
    folder_slug="${dir##*/}"
    [ "${folder_slug:0:1}" != "." ] && [ -f "$dir/spec.md" ] || continue
    [[ $folder_slug =~ ^[0-9]+-(.*)$ ]] && folder_slug="${BASH_REMATCH[1]}"
    if [ "$slug" = "$folder_slug" ] || [ "${slug#"$folder_slug"-}" != "$slug" ]; then
      if [ "${#folder_slug}" -gt "$best" ]; then
        spec_dir="$dir"
        best="${#folder_slug}"
      fi
    fi
  done < <(find "$root/$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  if [ -n "$spec_dir" ]; then
    status="" status_line='^status:[[:space:]]*([a-z-]+)'
    [[ "$(grep -m 1 -E "$status_line" "$spec_dir/spec.md")" =~ $status_line ]] && status="${BASH_REMATCH[1]}"
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
    # The scripts' defaults, then worktree.conf — read as data, never run.
    PORT_SLOTS=0 SETUP_CMD="" START_CMD="" BASE_BRANCH="main" ENV_FILE=".env"
    if [ -f "$root/scripts/agent/worktree.conf" ]; then
      read_settings "$root/scripts/agent/worktree.conf" PORT_SLOTS SETUP_CMD START_CMD BASE_BRANCH ENV_FILE
    fi
    [ "$PORT_SLOTS" -gt 0 ] 2>/dev/null && needs="a port"
    [ -z "$SETUP_CMD$START_CMD" ] || needs="${needs:+$needs and }setup or start commands"
    base_branch="$BASE_BRANCH" env_file="$ENV_FILE"
  fi
  default_branch="$(git -C "$root" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
  default_branch="${default_branch#origin/}"
  other_base=""
  if [ -n "$base_branch" ] && [ -n "$default_branch" ] && [ "$base_branch" != "$default_branch" ]; then
    other_base=1
  fi
  main="$(dirname "$common_dir")" # a linked worktree's common dir is absolute: <main checkout>/.git

  if [ "$checkout" = "main checkout" ]; then
    # Every task takes one route (decision 0021): /aplyca-adf:dispatch hands it to a new session that opens here,
    # creates the task's worktree beside this checkout with the scripts, and moves into it. Hooks don't
    # run again after the move, so the worker's first step is spelled out here.
    echo "- Role: DISPATCHER. This is the shared main checkout — never edit here. Give every task to /aplyca-adf:dispatch: it hands the task to a new session, which creates the task's worktree beside this checkout${base_branch:+, on a new branch from $base_branch,} and moves into it."
    echo "- A session whose prompt hands it one task and its branch (from /aplyca-adf:dispatch) is that task's worker, not the dispatcher. Its first step is the worktree: scripts/agent/worktree-new.sh <branch> --no-start, then move this session to the path it prints — change_directory in the desktop app, EnterWorktree in a terminal — and confirm with pwd before anything else."
  else
    echo "- Role: WORKER. This worktree is yours for one task — start with triage (/aplyca-adf:triage)."
    # The scripts mark the worktrees they set up; ones made before the marker are named after their branch.
    folder="$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]' | tr '/' '-' | tr -cs 'a-z0-9_-' '-')"
    while [[ $folder == -* ]]; do folder="${folder#-}"; done
    while [[ $folder == *- ]]; do folder="${folder%-}"; done
    if [ ! -f "$git_dir/agent-worktree" ] && [ "$(basename "$root")" != "$folder" ]; then
      generated="" generated_name='^(worktree-|claude/)' # Claude Code's own names; <type>/<slug> isn't
      if [ "$branch" != "detached HEAD" ]; then
        if [[ $branch =~ $generated_name ]] || [ "${branch#*/}" = "$branch" ]; then generated=1; fi
      fi
      if [ "$branch" = "detached HEAD" ]; then
        echo "- Detached HEAD: after triage, create the task's branch with git switch -c <type>/<slug>"
      elif [ -n "$generated" ]; then
        echo "- The branch name is generated ($branch): after triage, rename it — git branch -m <type>/<slug> — so it joins its spec folder and /aplyca-adf:open-pr takes it."
      fi
      if [ -n "$env_file" ] && [ -f "$main/$env_file" ] && [ ! -e "$root/$env_file" ]; then
        echo "- No $env_file here. Claude Code copies it into the worktrees it creates when .worktreeinclude lists it."
      fi
      if [ -n "$other_base" ]; then
        echo "- Claude Code started this worktree from $default_branch, but tasks here start from $base_branch: ask the developer to /aplyca-adf:dispatch the task before the first commit."
      elif [ -n "$needs" ]; then
        echo "- Not set up by scripts/agent/worktree-new.sh, so it lacks $needs: fine for work that doesn't run the app. To run it, ask the developer to /aplyca-adf:dispatch the task."
      fi
    fi
  fi
fi

# A packaged project reads the framework's reference docs from the aplyca-adf plugin, which links in
# the project's files only point at on GitHub (decision 0019).
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/docs" ] && [ ! -f "$root/docs/SPEC-MODEL.md" ]; then
  echo "- The framework's reference docs — SPEC-MODEL.md, COST-MODEL.md, MEMORY-STRATEGY.md, MCP-INTEGRATION.md — are in ${CLAUDE_PLUGIN_ROOT}/docs/: read them there, not on GitHub."
fi

exit 0
