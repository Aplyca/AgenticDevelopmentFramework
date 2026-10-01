#!/usr/bin/env bash
# List every worktree of this repository: branch, port, whether something is listening on it, and
# uncommitted changes. Everything is derived on each run — ports and environments change, so a
# written-down copy would be wrong by the time anyone read it.
#
# Usage: scripts/agent/worktree-ls.sh
set -uo pipefail
. "$(dirname "$0")/_worktree-lib.sh"

MAIN_CHECKOUT="$(main_checkout)" || die "not inside a git repository."

printf '\n  %-36s %-7s %-6s %-8s %s\n' 'BRANCH' 'PORT' 'STATE' 'CHANGES' 'PATH'
seen=" "
duplicates=""
while IFS= read -r path; do
  branch="$(git -C "$path" branch --show-current 2>/dev/null)"
  [ -n "$branch" ] || branch="(detached)"
  port="$(env_value "$path/$ENV_FILE" APP_PORT || true)"
  state="-"
  if [ -n "$port" ]; then
    if port_in_use "$port"; then state="up"; else state="down"; fi
    case "$seen" in *" $port "*) duplicates="$duplicates $port" ;; *) seen="$seen$port " ;; esac
  fi
  changes="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  label="$path"
  [ "$path" = "$MAIN_CHECKOUT" ] && label="$path (main checkout)"
  printf '  %-36s %-7s %-6s %-8s %s\n' "$branch" "${port:--}" "$state" "$changes" "$label"
done < <(all_worktrees "$MAIN_CHECKOUT")

for port in $duplicates; do
  printf '\n  !! Two worktrees claim port %s — one of them is talking to the other'"'"'s app.\n     Fix one with: scripts/agent/worktree-new.sh <its branch> --refresh-env\n' "$port"
done
echo
