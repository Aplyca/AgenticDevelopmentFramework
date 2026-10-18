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

echo "Session context (the session-context hook):"
# Git reports the main checkout's git dir and common dir alike (.git), a linked worktree's apart.
if [ "$(git -C "$root" rev-parse --git-dir 2>/dev/null)" = "$common_dir" ]; then
  checkout="main checkout"
else
  checkout="linked worktree"
fi
echo "- ${checkout}: $root — branch $branch, $changes uncommitted change(s)"

# Claude Code reads AGENTS.md only when no CLAUDE.md or CLAUDE.local.md is in the project or a folder
# above it (decision 0024). Such a file replaces this project's instructions with no error, so say so —
# unless a CLAUDE.md here still imports AGENTS.md, or the developer's settings load both.
if [ -f "$root/AGENTS.md" ] && ! grep -q '^@AGENTS.md' "$root/CLAUDE.md" 2>/dev/null &&
  ! grep -q 'claude-md-and-agents-md' "$HOME/.claude/settings.json" 2>/dev/null; then
  dir="$root"
  while :; do
    for name in CLAUDE.md CLAUDE.local.md .claude/CLAUDE.md; do
      [ -f "$dir/$name" ] && [ "$dir/$name" != "$HOME/.claude/CLAUDE.md" ] || continue
      echo "- $dir/$name replaces this project's AGENTS.md: Claude Code reads AGENTS.md only when no CLAUDE.md or CLAUDE.local.md is here or above. Read AGENTS.md now, and tell the developer: move or remove that file, or set Project instructions to claude-md-and-agents-md in /config."
      break 2
    done
    [ "$dir" = "/" ] && break
    dir="$(dirname "$dir")"
  done
fi

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

if worktree_conf="$(worktree_settings "$root")"; then
  # The parallel-agents module: its settings, which both installs commit (the scripts themselves are
  # the plugin's commands in a packaged one, decision 0027). What this project's worktrees need beyond
  # what Claude Code gives its own — a port, setup or start commands, a base branch other than the
  # default — comes from the scripts' defaults, then worktree.conf, read as data, never run.
  PORT_SLOTS=0 SETUP_CMD="" START_CMD="" BASE_BRANCH="main" ENV_FILE=".env"
  read_settings "$worktree_conf" PORT_SLOTS SETUP_CMD START_CMD BASE_BRANCH ENV_FILE
  needs=""
  [ "$PORT_SLOTS" -gt 0 ] 2>/dev/null && needs="a port"
  [ -z "$SETUP_CMD$START_CMD" ] || needs="${needs:+$needs and }setup or start commands"
  base_branch="$BASE_BRANCH" env_file="$ENV_FILE"
  default_branch="$(git -C "$root" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
  default_branch="${default_branch#origin/}"
  other_base=""
  if [ -n "$base_branch" ] && [ -n "$default_branch" ] && [ "$base_branch" != "$default_branch" ]; then
    other_base=1
  fi
  main="$(dirname "$common_dir")" # a linked worktree's common dir is absolute: <main checkout>/.git

  if [ "$checkout" = "main checkout" ]; then
    # Each task takes the session it starts in (decision 0042): after triage, /adf:dispatch creates the
    # task's worktree beside this checkout with the scripts and moves this session there. Hooks don't
    # run again after the move, so the route is spelled out here.
    echo "- Main checkout: sessions start here, and edits are stopped here. Triage the task first. A change, or an answer that runs the app, the tests, or the database, then gets its own worktree: /adf:dispatch creates it beside this checkout${base_branch:+, on a new branch from $base_branch,} and moves this session there. An answer that only reads stays here. Once this session has a task, another one goes to a new session — /adf:dispatch offers it."
  else
    echo "- Role: WORKER. One task, in its own worktree — start with triage (/adf:triage). Another task goes to a new session: /adf:dispatch offers it."
    # The scripts mark the worktrees they set up; ones made before the marker are named after their branch.
    folder="$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]' | tr '/' '-' | tr -cs 'a-z0-9_-' '-')"
    while [[ $folder == -* ]]; do folder="${folder#-}"; done
    while [[ $folder == *- ]]; do folder="${folder%-}"; done
    if [ ! -f "$git_dir/agent-worktree" ] && [ "$(basename "$root")" != "$folder" ]; then
      generated="" generated_name='^(worktree-|claude/)' # Claude Code's own names; <type>/<slug> isn't
      if [ "$branch" != "detached HEAD" ]; then
        if [[ $branch =~ $generated_name ]] || [ "${branch#*/}" = "$branch" ]; then generated=1; fi
      fi
      if [ "$branch" = "detached HEAD" ] || [ -n "$generated" ]; then
        # Claude Code's own worktree, not yet a task's: the desktop app gives every chip's session one, so
        # a dispatched worker starts here and moves to the task's worktree beside the main checkout
        # (decision 0040). Renaming this branch would keep the task nested in the main checkout.
        if [ -n "$generated" ]; then on="a generated branch ($branch)"; else on="a detached HEAD"; fi
        echo "- This session started in Claude Code's own worktree, on $on. A task's worktree sits beside the main checkout: triage the task, then /adf:dispatch creates it on the branch triage names and moves this session there. Edit and commit nothing here, and don't rename this branch: this worktree goes when the session is archived."
      else
        if [ -n "$env_file" ] && [ -f "$main/$env_file" ] && [ ! -e "$root/$env_file" ]; then
          echo "- No $env_file here. Claude Code copies it into the worktrees it creates when .worktreeinclude lists it."
        fi
        if [ -n "$other_base" ]; then
          echo "- Claude Code started this worktree from $default_branch, but tasks here start from $base_branch: ask the developer to /adf:dispatch the task before the first commit."
        elif [ -n "$needs" ]; then
          echo "- Not set up by adf-worktree-new, so it lacks $needs: fine for work that doesn't run the app. To run it, ask the developer to /adf:dispatch the task."
        fi
      fi
    fi
  fi
fi

# On the base branch, and behind origin's (as of the last fetch: no network here), the next branch
# would start from old code — and in a hub's main checkout, the dispatcher would list old specs/.
base="${base_branch:-}"
if [ -z "$base" ]; then
  base="$(git -C "$root" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
  base="${base#origin/}"
fi
if [ -n "$base" ] && [ "$branch" = "$base" ] && git -C "$root" show-ref --verify --quiet "refs/remotes/origin/$base"; then
  behind="$(git -C "$root" rev-list --count "HEAD..origin/$base" 2>/dev/null || echo 0)"
  if [ "$behind" -gt 0 ]; then
    echo "- $base is $behind commit(s) behind origin/$base (as of the last fetch): update it with git pull --ff-only before creating a branch or reading specs/."
  fi
fi

# A packaged project reads the framework's reference docs from the adf plugin, which links in
# the project's files only point at on GitHub (decision 0019) — the parallel-agents guide too, with
# the module (decision 0044).
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/docs" ] && [ ! -f "$root/docs/SPEC-MODEL.md" ]; then
  guide=""
  [ -n "${worktree_conf:-}" ] && guide=", PARALLEL-AGENTS.md"
  echo "- The framework's reference docs — SPEC-MODEL.md, COST-MODEL.md, MEMORY-STRATEGY.md, MCP-INTEGRATION.md$guide — are in ${CLAUDE_PLUGIN_ROOT}/docs/: read them there, not on GitHub."
fi

# A project stays on its pinned release (decision 0041) until someone runs /adf:upgrade, so say when a
# newer one is out. The release is the stamp's on AGENTS.md's first line (CLAUDE.md's before decision
# 0024). The newest v* tag of the framework repository is asked at most once a day, cached outside the
# repository and with a short timeout: offline, or slow, the session hears nothing. Once per session.
# ADF_RELEASES_REMOTE points the check at another repository (the tests use a local one). Files are
# written through tee: the Claude Directory refuses a redirect to a computed path.
version_lt() { # version_lt <X.Y.Z> <X.Y.Z> — the first is older
  local IFS=. i
  local -a a=($1) b=($2)
  for i in 0 1 2; do
    [ "$((10#${a[i]}))" -lt "$((10#${b[i]}))" ] && return 0
    [ "$((10#${a[i]}))" -gt "$((10#${b[i]}))" ] && return 1
  done
  return 1
}
release_line='Skeleton source: v([0-9]+)\.([0-9]+)\.([0-9]+)[^0-9.-]'
stamp="$(head -n 1 "$root/AGENTS.md" 2>/dev/null)"
[[ $stamp =~ $release_line ]] || stamp="$(head -n 1 "$root/CLAUDE.md" 2>/dev/null)"
if [ "$UPDATE_CHECK" = "1" ] && [[ $stamp =~ $release_line ]]; then
  current="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/adf"
  cache="$cache_dir/latest-release"
  now="$(date +%s)"
  checked="" latest=""
  [ -f "$cache" ] && read -r checked latest < <(cat "$cache")
  if ! [ "$checked" -le "$now" ] 2>/dev/null || [ $((now - checked)) -ge 86400 ]; then
    if mkdir -p "$cache_dir" 2>/dev/null; then
      tags="$cache_dir/tags.$$"
      GIT_TERMINAL_PROMPT=0 git ls-remote --tags --refs \
        "${ADF_RELEASES_REMOTE:-https://github.com/aplyca/AgenticDevelopmentFramework.git}" 2>/dev/null </dev/null |
        tee "$tags" >/dev/null &
      fetch=$!
      for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do # up to 2 seconds
        kill -0 "$fetch" 2>/dev/null || break
        sleep 0.1
      done
      if kill -0 "$fetch" 2>/dev/null; then
        # Not waited for: wait would wait for git too. Git, left without a reader, ends on its own.
        kill "$fetch" 2>/dev/null
      else
        newest=""
        while read -r _ ref; do
          [[ ${ref#refs/tags/} =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || continue
          tag="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
          if [ -z "$newest" ] || version_lt "$newest" "$tag"; then newest="$tag"; fi
        done < <(cat "$tags" 2>/dev/null)
        [ -n "$newest" ] && latest="$newest"
      fi
      rm -f "$tags"
      # A failed check counts too: an offline machine doesn't wait for the timeout in every session.
      printf '%s %s\n' "$now" "$latest" | tee "$cache" >/dev/null 2>&1
    fi
  fi
  if [ -n "$latest" ] && version_lt "$current" "$latest"; then
    session="$(json_get '.session_id')"
    told="$cache_dir/told-sessions"
    if [ -z "$session" ] || ! grep -qxF "$session" "$told" 2>/dev/null; then
      echo "- adf v$latest is available (this project is on v$current) — run \`/adf:upgrade\`."
      if [ -n "$session" ]; then
        { tail -n 99 "$told" 2>/dev/null; echo "$session"; } | tee "$told.$$" >/dev/null 2>&1 && mv "$told.$$" "$told" 2>/dev/null
      fi
    fi
  fi
fi

exit 0
