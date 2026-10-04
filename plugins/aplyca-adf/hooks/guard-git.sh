#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Makes three git rules mechanical instead of advisory:
#   1. never bypass git hooks (--no-verify, or -n on commit)
#   2. never commit on a protected branch
#   3. never push to, force-push to, or delete a protected branch
# Protected branches come from PROTECTED_BRANCHES in config.sh. Pushing anywhere else is still
# an outward action: permissions.ask in .claude/settings.json makes a human confirm it.
# Matching works on the command text an agent writes, so it is a guardrail, not a sandbox.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

command_text="$(json_get '.tool_input.command')"
[ -n "$command_text" ] || exit 0
case "$command_text" in *git*) ;; *) exit 0 ;; esac

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="$PWD"
gitdir="$cwd"

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
double_quoted='"[^"]*"' single_quoted="'[^']*'" newline=$'\n'
while [[ $unquoted =~ $double_quoted ]]; do unquoted="${unquoted/"${BASH_REMATCH[0]}"/ Q }"; done
while [[ $unquoted =~ $single_quoted ]]; do unquoted="${unquoted/"${BASH_REMATCH[0]}"/ Q }"; done
for separator in '&&' '||' ';' '|' '&' '(' ')' '`'; do
  unquoted="${unquoted//"$separator"/$newline}"
done

while IFS= read -r segment; do
  analyze_segment "$segment"
done <<<"$unquoted"

exit 0
