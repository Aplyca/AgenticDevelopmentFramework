#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). With the docker module, `make run cmd='…'` runs a command it is
# given: in the app's container in Docker mode, on the host in native mode (dev-env's specification,
# C10). An ask rule can't tell the two apart — it matches the command, not the checkout's mode — and
# it wins over a hook's approval. So the module has no rule for `make run`, and this hook decides
# (decision 0077):
#   - it approves `make run cmd='<command>'` written on its own, when the checkout's mode is Docker
#     and the `run` task in ops/docker/Makefile hands the command to Compose as one argument;
#   - it says nothing when that call is followed by a pipe, a redirect, or another command, which
#     leaves the whole line to the permission rules;
#   - it asks before every other `make … run`: native mode, a mode it can't read, a `run` task of
#     another form, make pointed elsewhere (`cd`, `-C`, a leading assignment), or a value the
#     host's shell or make would expand (`$`, a backquote).
# The mode is read as the root Makefile reads it (M1): DEV_MODE in the environment, then in .env —
# that one line, never printed — then DEFAULT_MODE. Without the module — no ops/docker/ or
# ops/native/ Makefile, and a stamp that doesn't name docker — it does nothing. Empty
# APPROVE_CONTAINER_RUN keeps the ask in every mode. It reads the command, the mode, and the task's
# recipe; what the app's container can reach is compose.yaml's (D5), and no hook checks that.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"

# decide <allow|ask> <reason> — the reason is fixed text, with no double quote or backslash in it.
decide() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s (approve-container-run hook)."}}\n' "$1" "$2"
  exit 0
}

# has_module <folder> — the stack's mode files are there or at the checkout's root, or the stamp
# names the module (on AGENTS.md's first line; on CLAUDE.md's, in a project adopted before 0024).
mode_files() { [ -f "$1/ops/docker/Makefile" ] || [ -f "$1/ops/native/Makefile" ]; }
stamp_names_docker() { head -n 1 "$1" 2>/dev/null | grep -Eq 'modules: ([a-z0-9-]+, )*docker(,| )'; }
has_module() {
  local root
  mode_files "$1" && return 0
  root="$(repo_root_for "$1")"
  [ -n "$root" ] || return 1
  mode_files "$root" || stamp_names_docker "$root/AGENTS.md" || stamp_names_docker "$root/CLAUDE.md"
}

# dev_mode <folder> — the mode make would load there (M1, M2).
dev_mode() {
  local mode="" line default='^DEFAULT_MODE[[:space:]]*[:?]?=[[:space:]]*([A-Za-z0-9_.-]*)'
  if [ -n "${DEV_MODE+set}" ]; then
    mode="$DEV_MODE"
  elif [ -f "$1/.env" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in DEV_MODE=*) mode="${line#DEV_MODE=}" && mode="${mode%%#*}" ;; esac
    done < <(cat "$1/.env")
    mode="$(printf '%s' "$mode" | tr -d "\"' \t\r")"
  fi
  if [ -z "$mode" ] && [ -f "$1/Makefile" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      [[ $line =~ $default ]] && mode="${BASH_REMATCH[1]}"
    done < <(cat "$1/Makefile")
  fi
  printf '%s' "$mode"
}

# runs_in_container <mode file> — its `run` task hands the command to Compose's exec or run as one
# argument, from the environment ("$$cmd"), and nowhere pastes $(cmd) into the host's shell (C10).
runs_in_container() {
  local line in_task="" handed="" pasted='\$[({]cmd[)}]' compose='^[[:space:]]+@?\$\(COMPOSE\) (exec|run) .*"\$\$cmd"[[:space:]]*$'
  [ -f "$1" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      run:*) in_task=1 ;;
      [[:space:]]*)
        [ -n "$in_task" ] || continue
        [[ $line =~ $pasted ]] && return 1
        [[ $line =~ $compose ]] && handed=1
        ;;
      "" | "#"*) ;;
      *) in_task="" ;;
    esac
  done < <(cat "$1")
  [ -n "$handed" ]
}

# blank_quotes <text> — quoted text is data, not goals or operators: each quoted string becomes Q.
blank_quotes() {
  local text="$1" quoted="'[^']*'|\"([^\"\\\\]|\\\\.)*\""
  while [[ $text =~ $quoted ]]; do text="${text/"${BASH_REMATCH[0]}"/Q}"; done
  printf '%s' "$text"
}

# Without a JSON parser the command can't be read: ask, rather than leave it to the allow rule.
if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  case "$HOOK_INPUT" in
    *make*run*) has_module "${CLAUDE_PROJECT_DIR:-$PWD}" && decide ask "The command could not be read, with neither jq nor python3 installed" ;;
  esac
  exit 0
fi

command_text="$(json_get '.tool_input.command')"
case "$command_text" in *make*run*) ;; *) exit 0 ;; esac
# make, any arguments, then the goal `run`.
goal_run='(^|[;&|(`[:space:]])make([[:space:]]+[^;&|[:space:]]+)*[[:space:]]+run([[:space:];&|)`]|$)'
[[ "$(blank_quotes "$command_text")" =~ $goal_run ]] || exit 0

stack="$(json_get '.cwd')"
[ -d "$stack" ] || stack="$PWD"
has_module "$stack" || exit 0

[ -n "$APPROVE_CONTAINER_RUN" ] || decide ask "make run runs a command it is given, and APPROVE_CONTAINER_RUN is empty"
[ "$(dev_mode "$stack")" = docker ] ||
  decide ask "make run may run its command on the host: this folder is not a checkout in Docker mode"
runs_in_container "$stack/ops/docker/Makefile" ||
  decide ask "The run task in ops/docker/Makefile does not hand its command to Compose as one argument (C10)"

# cmd's value is one neither the host's shell nor make expands: single-quoted with each $ doubled,
# double-quoted with no $, backquote, or backslash, or a bare word. Any other variable the task
# takes (s=worker) is a bare word, since a recipe may paste it into the host's shell.
bare='[A-Za-z0-9_./:=@%+,-]+'
value="'([^'\$]|[\$][\$])*'|\"[^\"\$\`\\\\]*\"|$bare"
other="([[:space:]]+[a-z][a-z0-9_]*=$bare)*"
own="^[[:space:]]*make[[:space:]]+run$other[[:space:]]+cmd=($value)$other"
if [[ $command_text =~ $own ]]; then
  call="${BASH_REMATCH[0]}"
  rest="${command_text#"$call"}"
  [ -n "${rest//[[:space:]]/}" ] || decide allow "In Docker mode make run runs its command in the app's container"
  operator='^[[:space:]]*([|&;<>]|[0-9]+[<>])'
  if [[ $rest =~ $operator ]] && ! [[ "$(blank_quotes "$rest")" =~ $goal_run ]]; then
    exit 0
  fi
fi
decide ask "Only make run cmd='<command>', written on its own with nothing the host expands, runs without a prompt"
