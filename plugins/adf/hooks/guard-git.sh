#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Makes four delivery rules mechanical instead of advisory:
#   1. never bypass git hooks (--no-verify, or -n on commit)
#   2. never commit on a protected branch
#   3. never push to, force-push to, or delete a protected branch
#   4. a pull request opens as a draft (gh pr create needs --draft; glab mr create, --draft or --wip)
#   5. pushing a tag asks first: a tag is a release (decision 0038), whatever form the push takes
# Protected branches come from PROTECTED_BRANCHES in config.sh. An agent pushes its work branch and
# opens the draft pull request on its own once it has checked the change locally (decisions 0022,
# 0045), so rule 4 holds the draft rule that a confirmation prompt used to. The draft is where the
# preview and CI run before the agent marks it ready (0070).
# Matching works on the command text an agent writes, so it is a guardrail, not a sandbox.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

command_text="$(json_get '.tool_input.command')"
[ -n "$command_text" ] || exit 0
case "$command_text" in *git* | *gh* | *glab*) ;; *) exit 0 ;; esac

cwd="$(json_get '.cwd')"
[ -d "$cwd" ] || cwd="$PWD"
gitdir="$cwd"
event_cwd="$cwd"
switched_branch="" switched_dir="" tag_push=""
quoted_paths=()

# resolve_path <token> — the folder a cd or -C token names: a quoted one comes back from its
# placeholder (see the end of this file), and a leading ~ becomes $HOME.
resolve_path() {
  local path="$1"
  if [[ $path =~ ^@path([0-9]+)@$ ]]; then path="${quoted_paths[${BASH_REMATCH[1]}]}"; fi
  case "$path" in
    "~") [ -z "${HOME:-}" ] || path="$HOME" ;;
    "~/"*) [ -z "${HOME:-}" ] || path="$HOME/${path#\~/}" ;;
  esac
  printf '%s' "$path"
}

# A folder this hook can't read from the text (a variable, a command substitution) falls back to
# the session's own, so an unreadable path never passes as "no protected branch". A branch the same
# command line switched to with && stands for the folder's current one.
current_branch() {
  local dir="$1"
  [ -d "$dir" ] || dir="$event_cwd"
  if [ -n "$switched_branch" ] && [ "$dir" = "$switched_dir" ]; then
    printf '%s\n' "$switched_branch"
    return 0
  fi
  git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null
}

# note_switch <args of git switch or git checkout> — remember the branch the command moves to: a new
# one by its flag, an existing one only when git knows it as a branch (a path is not a branch).
note_switch() {
  local token previous="" name=""
  for token in "$@"; do
    case "$previous" in -c | -C | --create | --force-create | -b | -B) name="$token" && break ;; esac
    previous="$token"
  done
  if [ -z "$name" ] && [ $# -eq 1 ] && [[ $1 != -* ]] && [ -d "$gitdir" ] \
    && git -C "$gitdir" show-ref --verify -q "refs/heads/$1" 2>/dev/null; then
    name="$1"
  fi
  if [ -n "$name" ]; then
    switched_branch="$name"
    switched_dir="$gitdir"
  fi
  return 0
}

# is_tag <ref> — a ref the push sends or deletes is a tag: refs/tags/…, or a name git knows as a
# tag and not as a branch.
is_tag() {
  local ref="${1#+}"
  case "$ref" in refs/tags/*) return 0 ;; refs/* | "" | HEAD) return 1 ;; esac
  [ -d "$gitdir" ] || return 1
  git -C "$gitdir" show-ref --verify -q "refs/tags/$ref" 2>/dev/null \
    && ! git -C "$gitdir" show-ref --verify -q "refs/heads/$ref" 2>/dev/null
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
    # A short flag that takes its value attached ends the cluster: -uno is --untracked-files=no.
    if [[ $token =~ ^-[a-zA-Z]*n[a-zA-Z]*$ ]] && ! [[ $token =~ ^-[a-zA-Z]*[umFCcSt][a-zA-Z]*n ]]; then
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
      --tags) tags_only=1 && tag_push=1 ;;
      --follow-tags) tag_push=1 ;;
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
    if [ "$token" = "tag" ] || is_tag "$src" || is_tag "$dst"; then tag_push=1; fi
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

analyze_segment() {
  local -a tokens
  read -r -a tokens <<< "$1"
  local i=0 n=${#tokens[@]}
  [ "$n" -gt 0 ] || return 0
  # Only && carries a switch to the next command: after any other separator it may not have run.
  if [ "${tokens[0]}" = "@and@" ]; then
    i=1
  else
    switched_branch=""
  fi
  [ $i -lt $n ] || return 0
  if [ "${tokens[$i]}" = "cd" ] && [ -n "${tokens[$((i + 1))]:-}" ]; then
    local target
    target="$(resolve_path "${tokens[$((i + 1))]}")"
    case "$target" in
      /*) cwd="$target" ;;
      *) cwd="$cwd/$target" ;;
    esac
    return 0
  fi
  while [ $i -lt $n ] && [[ ${tokens[$i]} == *=* && ${tokens[$i]} != -* ]]; do i=$((i + 1)); done
  while [ $i -lt $n ]; do
    case "${tokens[$i]}" in command | exec | nohup | time | then | else | elif | do | "{" | "!") i=$((i + 1)) ;; *) break ;; esac
  done
  if [ "${tokens[$i]:-}" = "gh" ]; then
    i=$((i + 1))
    while [ $i -lt $n ]; do
      case "${tokens[$i]}" in
        -R | --repo) i=$((i + 2)) ;;
        --repo=*) i=$((i + 1)) ;;
        *) break ;;
      esac
    done
    if [ "${tokens[$i]:-}" = "pr" ]; then
      case "${tokens[$((i + 1))]:-}" in create | new) check_pr_create gh "${tokens[@]:$((i + 2))}" ;; esac
    fi
    return 0
  fi
  if [ "${tokens[$i]:-}" = "glab" ] && [ "${tokens[$((i + 1))]:-}" = "mr" ]; then
    case "${tokens[$((i + 2))]:-}" in create | new) check_pr_create glab "${tokens[@]:$((i + 3))}" ;; esac
    return 0
  fi
  [ "${tokens[$i]:-}" = "git" ] || return 0
  i=$((i + 1))
  gitdir="$cwd"
  while [ $i -lt $n ]; do
    case "${tokens[$i]}" in
      -C)
        gitdir="$(resolve_path "${tokens[$((i + 1))]:-$cwd}")"
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
    switch | checkout) note_switch "${rest[@]+"${rest[@]}"}" ;;
    merge | rebase | cherry-pick | revert | am | pull) check_no_verify "${rest[@]+"${rest[@]}"}" ;;
  esac
}

# A heredoc's body is data: drop it, keeping the line that opens it, so an apostrophe in the body
# can't pair with a quote on a later command and hide it. <<- strips leading tabs from the line
# that closes it; <<< is a here-string, not a heredoc.
heredoc='(^|[^<])<<(-?)[[:space:]]*\\?["'"'"']?([A-Za-z_][A-Za-z0-9_]*)'
delims=() dashes=() stripped="" rest="" tab=$'\t'
while IFS= read -r line || [ -n "$line" ]; do
  if [ ${#delims[@]} -gt 0 ]; then
    closing="$line"
    [ -z "${dashes[0]}" ] || closing="${line#"${line%%[!$tab]*}"}"
    if [ "$closing" = "${delims[0]}" ]; then
      delims=("${delims[@]:1}")
      dashes=("${dashes[@]:1}")
    fi
    continue
  fi
  stripped+="$line"$'\n'
  rest="$line"
  while [[ $rest =~ $heredoc ]]; do
    delims+=("${BASH_REMATCH[3]}")
    dashes+=("${BASH_REMATCH[2]}")
    rest="${rest#*"${BASH_REMATCH[0]}"}"
  done
done <<<"$command_text"

# Quoted text (commit messages, echo arguments) is data, not flags or refspecs:
# blank it out across line breaks before splitting the command into simple commands. Two kinds of
# quoted text are kept, since blanking them would hide where a command runs or what it pushes: the
# folder after cd or -C, as a placeholder resolve_path reads back, and a quoted single word that
# isn't a flag ("main", '/path/to/repo'), unwrapped.
unquoted="$stripped"
double_quoted='"[^"]*"' single_quoted="'[^']*'" newline=$'\n' kept="" chained=""
quoted_folder='(^|[[:space:];&|(])(cd|-C)[[:space:]]+("([^"]*)"|'"'([^']*)'"')'
quoted_word='("([A-Za-z0-9_/.~][A-Za-z0-9_./~:@%+=-]*)"|'"'([A-Za-z0-9_/.~][A-Za-z0-9_./~:@%+=-]*)'"')'
while [[ $unquoted =~ $quoted_folder ]]; do
  quoted_paths+=("${BASH_REMATCH[4]}${BASH_REMATCH[5]}")
  kept="${BASH_REMATCH[1]}${BASH_REMATCH[2]} @path$((${#quoted_paths[@]} - 1))@"
  unquoted="${unquoted/"${BASH_REMATCH[0]}"/$kept}"
done
while [[ $unquoted =~ $quoted_word ]]; do
  kept="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
  unquoted="${unquoted/"${BASH_REMATCH[0]}"/$kept}"
done
while [[ $unquoted =~ $double_quoted ]]; do unquoted="${unquoted/"${BASH_REMATCH[0]}"/ Q }"; done
while [[ $unquoted =~ $single_quoted ]]; do unquoted="${unquoted/"${BASH_REMATCH[0]}"/ Q }"; done
chained="$newline@and@ "
unquoted="${unquoted//"&&"/$chained}"
for separator in '||' ';' '|' '&' '(' ')' '`'; do
  unquoted="${unquoted//"$separator"/$newline}"
done

while IFS= read -r segment; do
  analyze_segment "$segment"
done <<<"$unquoted"

# Every block has had its turn: a tag push that broke no rule still asks.
if [ -n "$tag_push" ]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Pushing a tag publishes a release (decision 0038): the developer confirms it (guard-git hook)."}}'
fi
exit 0
