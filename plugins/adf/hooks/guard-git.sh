#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Makes five delivery rules mechanical instead of advisory:
#   1. never bypass git hooks (--no-verify, or -n on commit)
#   2. never commit on a protected branch
#   3. never push to, force-push to, or delete a protected branch
#   4. a pull request opens as a draft (gh pr create needs --draft; glab mr create, --draft or --wip)
#   5. a pull request is marked ready (gh pr ready; glab mr update --ready) only once its description
#      carries the review instructions and CI is neither failing nor still running
# Protected branches come from PROTECTED_BRANCHES in config.sh. An agent pushes its work branch and
# opens the draft pull request on its own once it has checked the change locally (decisions 0022,
# 0045), so rule 4 holds the draft rule that a confirmation prompt used to. The draft is where the
# preview and CI run before the agent marks it ready (0070). Rule 5 checks the two ready conditions
# that are facts on the host, with one read of the pull request (decision 0074); whether every
# criterion was walked stays the agent's to do and the reviewers' to see. READY_GATE in config.sh:
# "block" stops it every time, "remind" once per session, empty turns rule 5 off. A pull request the
# hook can't read — no gh or glab, no network — is let through.
# Matching works on the command text an agent writes, so it is a guardrail, not a sandbox.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

command_text="$(json_get '.tool_input.command')"
[ -n "$command_text" ] || exit 0
case "$command_text" in *git* | *gh* | *glab*) ;; *) exit 0 ;; esac

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="$PWD"
gitdir="$cwd"
newline=$'\n'

current_branch() {
  git -C "$1" symbolic-ref --short -q HEAD 2>/dev/null
}

is_protected() {
  [ -n "$1" ] && in_words "$1" "$PROTECTED_BRANCHES"
}

check_no_verify() {
  local token
  for token in "$@"; do
    if [ "$token" = "--no-verify" ]; then
      block "--no-verify skips the project's git hooks. Fix what the hook reports instead of bypassing it."
    fi
  done
}

check_commit() {
  local token branch
  check_no_verify "$@"
  for token in "$@"; do
    if [[ $token =~ ^-[a-zA-Z]*n[a-zA-Z]*$ ]]; then
      block "'git commit $token' includes -n (--no-verify), which skips the project's git hooks."
    fi
  done
  branch="$(current_branch "$gitdir")"
  if is_protected "$branch"; then
    block "'$branch' is protected — commit on a work branch: git switch -c <type>/<slug>"
  fi
}

check_push() {
  local token remote="" dst src branch skip_next="" tags_only=""
  local -a refspecs=()
  check_no_verify "$@"
  for token in "$@"; do
    if [ -n "$skip_next" ]; then
      skip_next=""
      continue
    fi
    case "$token" in
      --all | --mirror) block "'git push $token' would push protected branches. Push the work branch by name." ;;
      -n | --dry-run) return 0 ;;
      --tags) tags_only=1 ;;
      --repo=*) remote="${token#--repo=}" ;;
      -o | --push-option | --receive-pack | --exec) skip_next=1 ;;
      -*) ;;
      *)
        if [ -z "$remote" ]; then remote="$token"; else refspecs+=("$token"); fi
        ;;
    esac
  done
  branch="$(current_branch "$gitdir")"
  if [ ${#refspecs[@]} -eq 0 ]; then
    if [ -z "$tags_only" ] && is_protected "$branch"; then
      block "pushing from '$branch', which is protected. Changes reach it through a pull request."
    fi
    return 0
  fi
  for token in "${refspecs[@]}"; do
    token="${token#+}"
    src="${token%%:*}"
    if [[ $token == *:* ]]; then dst="${token#*:}"; else dst="$src"; fi
    [ "$dst" = "HEAD" ] && dst="$branch"
    dst="${dst#refs/heads/}"
    if is_protected "$dst"; then
      block "'git push … $token' targets '$dst', which is protected. Changes reach it through a pull request."
    fi
  done
}

check_pr_create() {
  local cli="$1" token
  shift
  for token in "$@"; do
    # glab's -d is --description, so only gh takes a short flag.
    case "$cli:$token" in gh:--draft | gh:-d | glab:--draft | glab:--wip) return 0 ;; esac
  done
  case "$cli" in
    glab) block "'glab mr create' without --draft. Merge requests open as drafts; the agent marks one ready once its own tests and review pass — locally, on the preview, and CI." ;;
    *) block "'gh pr create' without --draft. Pull requests open as drafts; the agent marks one ready once its own tests and review pass — locally, on the preview, and CI." ;;
  esac
}

check_pr_ready() {
  local cli="$1" what="pull request" token selector="" repo="" skip_next="" ready="" view states body section label word
  local failed="" pending=""
  shift
  [ -n "$READY_GATE" ] || return 0
  # Which pull request: gh's only flag with a value is the repository, so its first bare word is the
  # number, URL, or branch. glab's update takes many, so only a first word counts.
  if [ "$cli" = glab ]; then
    case "${1:-}" in -* | "") ;; *) selector="$1" ;; esac
  fi
  for token in "$@"; do
    if [ -n "$skip_next" ]; then
      repo="$token"
      skip_next=""
      continue
    fi
    case "$token" in
      --undo) return 0 ;;
      -R | --repo) skip_next=1 ;;
      --repo=*) repo="${token#--repo=}" ;;
      -r | --ready) ready=1 ;;
      -*) ;;
      *) [ "$cli" = glab ] || [ -n "$selector" ] || selector="$token" ;;
    esac
  done
  if [ "$cli" = glab ]; then
    [ -n "$ready" ] || return 0
    what="merge request"
    view="$(cd "$cwd" 2>/dev/null && limited glab mr view ${selector:+"$selector"} ${repo:+--repo "$repo"} --output json 2>/dev/null)" || return 0
    body="$(json_field '.description' "$view")"
    states="$(json_field '.head_pipeline.status' "$view")"
  else
    # One line of CI's states for the last commit, then the description.
    view="$(cd "$cwd" 2>/dev/null && limited gh pr view ${selector:+"$selector"} ${repo:+--repo "$repo"} --json body,statusCheckRollup --jq '([.statusCheckRollup[]? | .conclusion, .state, .status | strings] | join(" ")) + "\n" + (.body // "")' 2>/dev/null)" || return 0
    states="${view%%"$newline"*}"
    body="${view#*"$newline"}"
  fi

  # The review instructions: text between the markers beyond the template's comments and empty labels.
  local open='<!-- adf:how-to-verify -->' close='<!-- /adf:how-to-verify -->' comment='<!--([^-]|-[^-]|--[^>])*-->'
  section="${body#*"$open"}"
  if [ "$section" = "$body" ]; then section=""; else section="${section%%"$close"*}"; fi
  while [[ $section =~ $comment ]]; do section="${section/"${BASH_REMATCH[0]}"/}"; done
  for label in '**Where:**' '**Look at:**' '**Tests:**'; do section="${section//"$label"/}"; done
  section="${section//[0-9]./}"
  if [ -z "$(printf '%s' "$section" | tr -d '[:space:]')" ]; then
    gate "$READY_GATE" ready-gate "this $what's description has no review instructions: 'How to review and test' — the text between the adf:how-to-verify markers — is missing or still the empty template. Write it first (/adf:open-pr, step 8): where to review it, the steps to try and what to expect, what to look at, the tests. Then mark it ready."
  fi

  states="$(printf '%s' "$states" | tr '[:upper:]' '[:lower:]')"
  set -f
  for word in $states; do
    case "$word" in
      failure | failed | error | cancelled | canceled | timed_out | action_required | startup_failure) failed=1 ;;
      pending | in_progress | queued | expected | waiting | requested | created | waiting_for_resource | preparing | running | scheduled) pending=1 ;;
    esac
  done
  set +f
  if [ -n "$failed" ]; then
    gate "$READY_GATE" ready-gate "CI is failing on this $what, and ready asks people to review it. Fix it on the branch, push, and mark it ready once CI is green. A failure the reviewers accept is the developer's call: they mark it ready, or set READY_GATE in .claude/hooks/config.sh."
  fi
  if [ -n "$pending" ]; then
    gate "$READY_GATE" ready-gate "CI hasn't finished on this $what. Wait for it as a background command — never a polling loop — and mark it ready once it's green."
  fi
  return 0
}

analyze_segment() {
  local -a tokens
  read -r -a tokens <<< "$1"
  local i=0 n=${#tokens[@]}
  [ "$n" -gt 0 ] || return 0
  if [ "${tokens[0]}" = "cd" ] && [ -n "${tokens[1]:-}" ]; then
    case "${tokens[1]}" in
      /*) cwd="${tokens[1]}" ;;
      *) cwd="$cwd/${tokens[1]}" ;;
    esac
    return 0
  fi
  while [ $i -lt $n ] && [[ ${tokens[$i]} == *=* && ${tokens[$i]} != -* ]]; do i=$((i + 1)); done
  case "${tokens[$i]:-}" in command | exec | nohup | time) i=$((i + 1)) ;; esac
  if [ "${tokens[$i]:-}" = "gh" ] && [ "${tokens[$((i + 1))]:-}" = "pr" ]; then
    case "${tokens[$((i + 2))]:-}" in
      create) check_pr_create gh "${tokens[@]:$((i + 3))}" ;;
      ready) check_pr_ready gh "${tokens[@]:$((i + 3))}" ;;
    esac
    return 0
  fi
  if [ "${tokens[$i]:-}" = "glab" ] && [ "${tokens[$((i + 1))]:-}" = "mr" ]; then
    case "${tokens[$((i + 2))]:-}" in
      create | new) check_pr_create glab "${tokens[@]:$((i + 3))}" ;;
      update) check_pr_ready glab "${tokens[@]:$((i + 3))}" ;;
    esac
    return 0
  fi
  [ "${tokens[$i]:-}" = "git" ] || return 0
  i=$((i + 1))
  gitdir="$cwd"
  while [ $i -lt $n ]; do
    case "${tokens[$i]}" in
      -C)
        gitdir="${tokens[$((i + 1))]:-$cwd}"
        [[ $gitdir == /* ]] || gitdir="$cwd/$gitdir"
        i=$((i + 2))
        ;;
      -c) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  local subcommand="${tokens[$i]:-}"
  local -a rest=("${tokens[@]:$((i + 1))}")
  case "$subcommand" in
    commit) check_commit "${rest[@]+"${rest[@]}"}" ;;
    push) check_push "${rest[@]+"${rest[@]}"}" ;;
    merge | rebase | cherry-pick | revert | am | pull) check_no_verify "${rest[@]+"${rest[@]}"}" ;;
  esac
}

# Quoted text (commit messages, heredoc bodies, echo arguments) is data, not flags or refspecs:
# blank it out across line breaks before splitting the command into simple commands.
unquoted="$command_text"
double_quoted='"[^"]*"' single_quoted="'[^']*'"
while [[ $unquoted =~ $double_quoted ]]; do unquoted="${unquoted/"${BASH_REMATCH[0]}"/ Q }"; done
while [[ $unquoted =~ $single_quoted ]]; do unquoted="${unquoted/"${BASH_REMATCH[0]}"/ Q }"; done
for separator in '&&' '||' ';' '|' '&' '(' ')' '`'; do
  unquoted="${unquoted//"$separator"/$newline}"
done

while IFS= read -r segment; do
  analyze_segment "$segment"
done <<<"$unquoted"

exit 0
