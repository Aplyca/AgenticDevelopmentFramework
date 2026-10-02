#!/usr/bin/env bash
# List every worktree of this repository: branch, port, whether something is listening on it, whether
# its services are its own (--isolated) or shared, and uncommitted changes. With --info, also each
# environment's app URL and what ENV_INFO_CMD prints for it — service endpoints, the accounts to sign
# in with. Everything is derived on each run: ports, environments, and seeded accounts change, so a
# written-down copy would be wrong by the time anyone read it.
#
# Usage: scripts/agent/worktree-ls.sh [--info]
set -uo pipefail
. "$(dirname "$0")/_worktree-lib.sh"

INFO=""
case "${1:-}" in
  "") ;;
  --info) INFO=1 ;;
  *) die "unknown option '$1' (usage: $0 [--info])" ;;
esac

MAIN_CHECKOUT="$(main_checkout)" || die "not inside a git repository."

printf '\n  %-36s %-7s %-6s %-9s %-8s %s\n' 'BRANCH' 'PORT' 'STATE' 'SERVICES' 'CHANGES' 'PATH'
seen=" "
duplicates=""
builtin_tasks=""
details=""
while IFS= read -r path; do
  branch="$(git -C "$path" branch --show-current 2>/dev/null)"
  [ -n "$branch" ] || branch="(detached)"
  port="$(env_value "$path/$ENV_FILE" APP_PORT || true)"
  state="-"
  services="-"
  if [ -n "$port" ]; then
    if port_in_use "$port"; then state="up"; else state="down"; fi
    case "$seen" in *" $port "*) duplicates="$duplicates $port" ;; *) seen="$seen$port " ;; esac
    services="shared"
  fi
  [ "$(env_value "$path/$ENV_FILE" WORKTREE_ISOLATED || true)" = 1 ] && services="own"
  changes="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  label="$path"
  if [ "$path" = "$MAIN_CHECKOUT" ]; then
    label="$path (main checkout)"
  elif builtin_worktree "$path" "$MAIN_CHECKOUT"; then
    label="$path (Claude Code's own — no env file or port)"
    case "$branch" in claude/* | "(detached)") ;; */*) builtin_tasks="$builtin_tasks $branch" ;; esac
  fi
  printf '  %-36s %-7s %-6s %-9s %-8s %s\n' "$branch" "${port:--}" "$state" "$services" "$changes" "$label"

  if [ -n "$INFO" ] && [ -n "$port" ] && [ "$path" != "$MAIN_CHECKOUT" ]; then
    APP_PORT="$port"
    PORT_BASE="$(env_value "$path/$ENV_FILE" WORKTREE_PORT_BASE || true)"
    [ -n "$PORT_BASE" ] || PORT_BASE=$((port - PORT_OFFSET))
    SLUG="$(basename "$path")"
    PROJECT="$(project_name "$MAIN_CHECKOUT" "$SLUG")"
    details="$details
  $branch"
    [ -z "$READY_URL" ] || details="$details
    App: $(expand "$READY_URL")"
    if [ -n "$ENV_INFO_CMD" ]; then
      details="$details
$( (cd "$path" && sh -c "$(expand "$ENV_INFO_CMD")") 2>&1 | sed 's/^/    /')"
    fi
  fi
done < <(all_worktrees "$MAIN_CHECKOUT")

for port in $duplicates; do
  printf '\n  !! Two worktrees claim port %s — one of them is talking to the other'"'"'s app.\n     Fix one with: scripts/agent/worktree-new.sh <its branch> --refresh-env\n' "$port"
done
for branch in $builtin_tasks; do
  printf '\n  !! %s is task work in one of Claude Code'"'"'s own worktrees, which has no env file or port.\n     Move it: commit there, git worktree remove <that path>, then scripts/agent/worktree-new.sh %s\n' "$branch" "$branch"
done

if [ -n "$INFO" ]; then
  if [ -n "$details" ]; then
    printf '%s\n' "$details"
  else
    echo
    echo "  No worktree has an environment yet."
  fi
  [ -n "$ENV_INFO_CMD" ] || echo "
  Set ENV_INFO_CMD in scripts/agent/worktree.conf to print each environment's service endpoints and
  the accounts to sign in with."
fi
echo
