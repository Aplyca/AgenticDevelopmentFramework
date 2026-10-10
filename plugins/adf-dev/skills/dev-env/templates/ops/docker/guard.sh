#!/usr/bin/env bash
# Keeps a worktree off the main checkout's stack. A worktree whose .env was copied from the main
# checkout's — Claude Code copies it through .worktreeinclude — carries the same COMPOSE_PROJECT_NAME
# or pinned ports. There, `make up` would take over the main checkout's stack, and `make reset`
# (docker compose down -v) would delete its volumes. The mode Makefiles run this before up, down,
# services, and reset; it passes in the main checkout and in a worktree with its own values.
#
# Of either .env, it reads only COMPOSE_PROJECT_NAME and the *_PORT lines, and prints only their
# names — never a value. bash 3.2 or later.
set -euo pipefail

cd "$(dirname "$0")/../.."

# file_value <env file> <NAME> — NAME's value in an env file, unquoted; empty when it isn't there.
file_value() {
  local line value=""
  [ -f "$1" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in "$2="*) value="${line#*=}" ;; esac
  done <"$1"
  case "$value" in \"*\") value="${value#\"}" && value="${value%\"}" ;; \'*\') value="${value#\'}" && value="${value%\'}" ;; esac
  printf '%s' "$value"
}

here="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)" || exit 0
common="$(git rev-parse --path-format=absolute --git-common-dir)"
[ "$here" != "$common" ] || exit 0 # the main checkout
main="$(dirname "$common")"
[ -f .env ] && [ -f "$main/.env" ] || exit 0

names=""
while IFS= read -r line || [ -n "$line" ]; do
  name="${line%%=*}"
  case "$name" in COMPOSE_PROJECT_NAME | *_PORT) ;; *) continue ;; esac
  [[ $name =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
  mine="$(file_value .env "$name")"
  [ -n "$mine" ] && [ "$mine" = "$(file_value "$main/.env" "$name")" ] || continue
  case " $names " in *" $name "*) ;; *) names="$names $name" ;; esac
done <.env
[ -z "$names" ] && exit 0
echo "guard.sh: this worktree's .env repeats the main checkout's$names — a copy of its .env. The \
stack here would clash with that one or take it over, and make reset would delete its data. Empty \
those lines in this worktree's .env, then run it again." >&2
exit 1
