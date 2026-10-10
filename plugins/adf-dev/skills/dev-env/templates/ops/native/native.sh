#!/usr/bin/env bash
# The app on the host, in the background, for DEV_MODE=native: `make up` starts it and waits until it
# answers, `make down` stops it, `make logs` and `make ps` read what it left. It runs the stack's own
# dev command (NATIVE_CMD in ops/native/Makefile), so it knows nothing about the stack.
#
#   ops/native/native.sh start    start the app unless it runs, wait until its port answers
#   ops/native/native.sh stop     stop it — its whole process group — if it runs
#   ops/native/native.sh status   whether it runs, and where
#   ops/native/native.sh logs     the last 100 lines of its log
#   ops/native/native.sh env      the `export` lines the app runs with (make test uses them)
#
# Each backing service in SERVICES runs in Docker, and the app gets its published port as
# <SERVICE>_PORT (redis → REDIS_PORT), looked up with `docker compose ps`. The app's own port is
# APP_PORT: the shell's, then the one .env pins, then a free one. A service the developer runs on the
# host is left out of SERVICES in their .env: its port is pinned there, and the app reads it itself.
#
# ops/native/Makefile passes NATIVE_CMD, SERVICES, and COMPOSE. The app's state — its process,
# its port, its log — is in ops/native/.run/, which git ignores: app.env holds PID and APP_PORT while
# it runs, and the band above the prompt reads APP_PORT there. bash 3.2 or later.
set -euo pipefail

cd "$(dirname "$0")/../.."
RUN=ops/native/.run
STATE="$RUN/app.env"
LOG="$RUN/app.log"
READY_SECONDS="${READY_SECONDS:-120}"
COMPOSE="${COMPOSE:-docker compose}"
SERVICES="${SERVICES:-}"

die() {
  echo "native.sh: $*" >&2
  exit 1
}

value() { [ -f "$STATE" ] && sed -n "s/^$1=//p" "$STATE" | tail -n 1; }
listening() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

# The port Docker published for a service, or nothing while it's down.
published() {
  $COMPOSE ps "$1" --format '{{range .Publishers}}{{if .PublishedPort}}{{.PublishedPort}} {{end}}{{end}}' 2>/dev/null |
    tr ' ' '\n' | sed -n '1p'
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

# APP_PORT as Compose would take it — the shell's, then the line .env pins — else a free one. Of
# .env, only that line is read.
app_port() {
  local port="${APP_PORT:-}"
  [ -n "$port" ] || port="$( { grep -E '^APP_PORT=' .env 2>/dev/null || true; } | tail -n 1 | cut -d= -f2- | tr -d "\"' ")"
  [ -n "$port" ] || port="$(free_port)"
  printf '%s' "$port"
}

exports() {
  local service port
  for service in $SERVICES; do
    port="$(published "$service")"
    [ -n "$port" ] || die "$service isn't running in Docker: start it (make services), or run it on the host and leave it out of SERVICES in .env"
    printf 'export %s_PORT=%s\n' "$(printf '%s' "$service" | tr 'a-z.-' 'A-Z__')" "$port"
  done
  printf 'export APP_PORT=%s\n' "$(app_port)"
}

# The app's process, when the one app.env names is still alive; else nothing, and stale state goes.
running_pid() {
  local pid
  pid="$(value PID || true)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    printf '%s' "$pid"
  else
    rm -f "$STATE"
  fi
}

start() {
  local pid port exports waited=0
  [ -n "${NATIVE_CMD:-}" ] || die "NATIVE_CMD is empty: set it in ops/native/Makefile to the app's dev command"
  pid="$(running_pid)"
  if [ -n "$pid" ]; then
    echo "==> The app already runs on the host: http://localhost:$(value APP_PORT)"
    return 0
  fi
  exports="$(exports)" || exit 1
  eval "$exports"
  port="$APP_PORT"
  mkdir -p "$RUN"
  # A process group of its own (set -m), so stop ends the dev server and every process it started.
  set -m
  nohup sh -c "$NATIVE_CMD" >"$LOG" 2>&1 </dev/null &
  pid=$!
  set +m
  printf 'PID=%s\nAPP_PORT=%s\n' "$pid" "$port" >"$STATE"
  echo "==> Starting the app on the host (log: $LOG)"
  until listening "$port"; do
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$STATE"
      tail -n 30 "$LOG" >&2 || true
      die "the app exited before it answered on port $port — its log is above"
    fi
    [ "$waited" -lt "$READY_SECONDS" ] || {
      stop
      die "the app didn't answer on port $port within ${READY_SECONDS}s: is NATIVE_CMD listening on \$APP_PORT? ($LOG)"
    }
    sleep 1
    waited=$((waited + 1))
  done
  echo "==> The app on the host: http://localhost:$port"
}

stop() {
  local pid tries=0
  pid="$(running_pid)"
  [ -n "$pid" ] || return 0
  kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null && [ "$tries" -lt 10 ]; do
    sleep 1
    tries=$((tries + 1))
  done
  kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
  rm -f "$STATE"
  echo "==> Stopped the app on the host"
}

status() {
  local pid port mark="○"
  pid="$(running_pid)"
  if [ -z "$pid" ]; then
    printf '  ○ %-10s not running on the host\n' "${APP:-app}"
    return 0
  fi
  port="$(value APP_PORT)"
  ! listening "$port" || mark="●"
  printf '  %s %-10s http://localhost:%s  (on the host, pid %s)\n' "$mark" "${APP:-app}" "$port" "$pid"
}

logs() {
  [ -f "$LOG" ] || die "no log yet: the app hasn't run on the host in this checkout"
  tail -n 100 "$LOG"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  logs) logs ;;
  env) exports ;;
  *) die "usage: ops/native/native.sh start | stop | status | logs | env" ;;
esac
