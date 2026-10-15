#!/usr/bin/env bash
# List every worktree of this repository: branch, uncommitted changes, and — when worktrees run a
# server — its port and whether something is listening on it. With --info, also what ENV_INFO_CMD
# prints for each one (its URLs, the accounts to sign in with). Worktrees the scripts didn't set up —
# Claude Code's own, from the desktop app or `claude --worktree` — are listed as workers too, and
# flagged while they sit on a generated branch or a detached HEAD. Everything is derived on each
# run: environments come and go, so a written-down copy would be wrong by the time anyone read it.
#
# Usage: ops/agent/worktree-ls.sh [--info]
set -uo pipefail
. "$(dirname "$0")/_worktree-lib.sh"

INFO=""
case "${1:-}" in
  "") ;;
  --info) INFO=1 ;;
  *) die "unknown option '$1' (usage: $0 [--info])" ;;
esac

MAIN_CHECKOUT="$(main_checkout)" || die "not inside a git repository."

rows=()
ports=""
seen=" "
duplicates=""
unnamed=""
details=""
while IFS= read -r path; do
  branch="$(git -C "$path" branch --show-current 2>/dev/null)"
  [ -n "$branch" ] || branch="(detached)"
  port="$( [ -z "$ENV_FILE" ] || env_value "$path/$ENV_FILE" APP_PORT || true)"
  state="-"
  if [ -n "$port" ]; then
    ports=1
    if port_in_use "$port"; then state="up"; else state="down"; fi
    case "$seen" in *" $port "*) duplicates="$duplicates $port" ;; *) seen="$seen$port " ;; esac
  fi
  changes="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  label="$path"
  outside=""
  if [ "$path" = "$MAIN_CHECKOUT" ]; then
    label="$path (main checkout)"
  elif ! scripts_worktree "$path" "$branch"; then
    outside=1
    label="$path (not from the scripts)"
    if generated_branch "$branch"; then unnamed="$unnamed
$branch|$path"; fi
  fi
  rows+=("$branch|${port:--}|$state|$changes|$label")

  if [ -n "$INFO" ] && [ -n "$ENV_INFO_CMD" ] && [ "$path" != "$MAIN_CHECKOUT" ] && [ -z "$outside" ]; then
    APP_PORT="$port"
    SLUG="$(basename "$path")"
    PROJECT="$(project_name "$MAIN_CHECKOUT" "$SLUG")"
    details="$details
  $branch
$( (cd "$path" && sh -c "$(expand "$ENV_INFO_CMD")") 2>&1 | sed 's/^/    /')"
  fi
done < <(all_worktrees "$MAIN_CHECKOUT")

echo
if [ -n "$ports" ]; then
  printf '  %-36s %-7s %-6s %-8s %s\n' 'BRANCH' 'PORT' 'STATE' 'CHANGES' 'PATH'
else
  printf '  %-36s %-8s %s\n' 'BRANCH' 'CHANGES' 'PATH'
fi
for row in "${rows[@]}"; do
  IFS='|' read -r branch port state changes label <<<"$row"
  if [ -n "$ports" ]; then
    printf '  %-36s %-7s %-6s %-8s %s\n' "$branch" "$port" "$state" "$changes" "$label"
  else
    printf '  %-36s %-8s %s\n' "$branch" "$changes" "$label"
  fi
done

for port in $duplicates; do
  printf '\n  !! Two worktrees claim port %s — one of them is talking to the other'"'"'s app.\n     Fix one with: ops/agent/worktree-new.sh <its branch> --refresh-env\n' "$port"
done
while IFS='|' read -r branch path; do
  [ -n "$path" ] || continue
  printf '\n  !! %s is on %s. Give the task its branch after triage\n     (git branch -m <type>/<slug>, or git switch -c from a detached HEAD); if its work is done, archive\n     the session in the desktop app or git worktree remove it.\n' "$path" "$( [ "$branch" = "(detached)" ] && echo "a detached HEAD" || echo "a generated branch ($branch)")"
done <<<"$unnamed"

if [ -n "$INFO" ]; then
  if [ -z "$ENV_INFO_CMD" ]; then
    echo
    echo "  Set ENV_INFO_CMD in ops/agent/worktree.conf to print what someone needs to use each"
    echo "  environment (its URLs, the accounts to sign in with)."
  elif [ -n "$details" ]; then
    printf '%s\n' "$details"
  fi
fi
echo
