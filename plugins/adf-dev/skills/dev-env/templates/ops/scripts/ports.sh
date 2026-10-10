#!/usr/bin/env bash
# Where this checkout's published services are. Docker picks a free host port for each one whose
# <NAME>_PORT is empty in .env, and a new one each time the service starts, so ports are looked up
# when they're needed and never written down.
#
#   ops/scripts/ports.sh urls    each service, where it is now, and whether it answers — in native
#                                mode the app on the host, and the services the developer runs there
#   ops/scripts/ports.sh env     `export` lines for the app on the host (DEV_MODE=native, make native):
#                                each backing service's port, and the app's own — pinned in .env, or
#                                a free one
#   ops/scripts/ports.sh free    a free local port
#   ops/scripts/ports.sh guard   fails in a worktree whose .env pins the main checkout's ports or
#                                Compose project — a copy of it — so that stack is never this one's
#
# The Makefile passes PORTS, each published port as <variable>=<service>:<container port>
# ("APP_PORT=web:3000 REDIS_PORT=redis:6379"), APP, the app's service, COMPOSE, DEV_MODE, and
# HOST_SERVICES, the backing services this developer runs on the host instead of in Docker. Of .env,
# this reads only COMPOSE_PROJECT_NAME and the *_PORT variables, and prints nothing else. bash 3.2 or
# later.
set -euo pipefail

cd "$(dirname "$0")/../.."
PORTS="${PORTS:-APP_PORT=web:3000}"
APP="${APP:-web}"
COMPOSE="${COMPOSE:-docker compose}"
DEV_MODE="${DEV_MODE:-docker}"
HOST_SERVICES="${HOST_SERVICES:-}"

die() {
  echo "ports.sh: $*" >&2
  exit 1
}

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

# on_host <service> — the developer runs it on the host, not in Docker.
on_host() { case " $HOST_SERVICES " in *" $1 "*) return 0 ;; esac; return 1; }

# pinned <NAME> — the shell's value, then .env's, as Compose would take it; empty when neither has one.
pinned() {
  local value="${!1:-}"
  [ -n "$value" ] || value="$(file_value .env "$1")"
  printf '%s' "$value"
}

# listening <port> — something on this machine answers on the port.
listening() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

# published <service> <container port> — the host port Docker gave it, or nothing while it's down.
published() {
  local where
  where="$($COMPOSE port "$1" "$2" 2>/dev/null | tail -n 1)" || return 0
  case "$where" in *:[0-9]*) printf '%s' "${where##*:}" ;; esac
}

free_port() {
  local port tries=0
  # Below the range Linux hands out for outgoing connections (32768 and up).
  while [ "$tries" -lt 100 ]; do
    port=$((20000 + RANDOM % 12000))
    listening "$port" || {
      printf '%s\n' "$port"
      return 0
    }
    tries=$((tries + 1))
  done
  die "no free port found"
}

urls() {
  local entry name service port host where mark pinned
  for entry in $PORTS; do
    name="${entry%%=*}" service="${entry#*=}"
    port="${service#*:}" service="${service%%:*}"
    if [ "$service" = "$APP" ] && [ "$DEV_MODE" = native ]; then
      host="$(file_value ops/.run/app.env APP_PORT)"
      if [ -z "$host" ]; then
        printf '  ○ %-10s not running on the host  (%s)\n' "$service" "$name"
        continue
      fi
      mark="○"
      ! listening "$host" || mark="●"
      printf '  %s %-10s http://localhost:%s  (%s, on the host)\n' "$mark" "$service" "$host" "$name"
      continue
    fi
    if on_host "$service"; then
      host="$(pinned "$name")"
      if [ -z "$host" ]; then
        printf '  ○ %-10s on the host — pin %s in .env to its port\n' "$service" "$name"
        continue
      fi
      mark="○"
      ! listening "$host" || mark="●"
      printf '  %s %-10s localhost:%s  (%s, on the host)\n' "$mark" "$service" "$host" "$name"
      continue
    fi
    host="$(published "$service" "$port")"
    pinned=""
    [ -z "$(file_value .env "$name")" ] || pinned=", pinned in .env"
    if [ -z "$host" ]; then
      printf '  ○ %-10s not running  (%s%s)\n' "$service" "$name" "$pinned"
      continue
    fi
    where="localhost:$host"
    [ "$service" != "$APP" ] || where="http://$where"
    mark="○"
    ! listening "$host" || mark="●"
    printf '  %s %-10s %s  (%s%s)\n' "$mark" "$service" "$where" "$name" "$pinned"
  done
}

native_env() {
  local entry name service port host app_name="" app_port
  for entry in $PORTS; do
    name="${entry%%=*}" service="${entry#*=}"
    port="${service#*:}" service="${service%%:*}"
    if [ "$service" = "$APP" ]; then
      app_name="$name"
      continue
    fi
    if on_host "$service"; then
      # The developer's own service: its port is the one they pinned, if any.
      host="$(pinned "$name")"
      [ -z "$host" ] || printf 'export %s=%s\n' "$name" "$host"
      continue
    fi
    host="$(published "$service" "$port")"
    [ -n "$host" ] || die "$service isn't running: start the backing services first (make services)"
    printf 'export %s=%s\n' "$name" "$host"
  done
  [ -n "$app_name" ] || return 0
  # As Compose would take it: the shell's value first, then .env's, then a free port.
  app_port="$(pinned "$app_name")"
  [ -n "$app_port" ] || app_port="$(free_port)"
  printf 'export %s=%s\n' "$app_name" "$app_port"
}

guard() {
  local here common main line name names="" mine
  here="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null)" || return 0
  common="$(git rev-parse --path-format=absolute --git-common-dir)"
  [ "$here" != "$common" ] || return 0 # the main checkout
  main="$(dirname "$common")"
  [ -f .env ] && [ -f "$main/.env" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    name="${line%%=*}"
    case "$name" in COMPOSE_PROJECT_NAME | *_PORT) ;; *) continue ;; esac
    [[ $name =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
    mine="$(file_value .env "$name")"
    [ -n "$mine" ] && [ "$mine" = "$(file_value "$main/.env" "$name")" ] || continue
    case " $names " in *" $name "*) ;; *) names="$names $name" ;; esac
  done <.env
  [ -z "$names" ] && return 0
  die "this worktree's .env repeats the main checkout's$names — a copy of its .env. The stack here \
would clash with that one or take it over, and make reset would delete its data. Empty those lines \
in this worktree's .env, then run it again."
}

case "${1:-}" in
  urls) urls ;;
  env) native_env ;;
  free) free_port ;;
  guard) guard ;;
  *) die "usage: ops/scripts/ports.sh urls | env | free | guard" ;;
esac
