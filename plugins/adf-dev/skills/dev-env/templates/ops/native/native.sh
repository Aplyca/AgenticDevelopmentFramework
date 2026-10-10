#!/usr/bin/env bash
# The app on the host, in the background, for DEV_MODE=native: `make up` starts it and waits until it
# answers, `make down` stops it, `make logs` and `make ps` read what it left. It runs the stack's own
# dev command (NATIVE_CMD in ops/native/native.mk), so it knows nothing about the stack.
#
#   ops/native/native.sh start    start the app unless it runs, wait until its port answers
#   ops/native/native.sh stop     stop it — its whole process group — if it runs
#   ops/native/native.sh status   whether it runs, and where
#   ops/native/native.sh logs     the last 100 lines of its log
#
# ops/native/native.mk passes NATIVE_CMD and the ports.sh settings. The app's state — its process,
# its port, its log — is in ops/native/.run/, which git ignores: app.env holds PID and APP_PORT while
# it runs, and the band above the prompt reads APP_PORT there. bash 3.2 or later.
set -euo pipefail

cd "$(dirname "$0")/../.."
RUN=ops/native/.run
STATE="$RUN/app.env"
LOG="$RUN/app.log"
READY_SECONDS="${READY_SECONDS:-120}"

die() {
  echo "native.sh: $*" >&2
  exit 1
}

value() { [ -f "$STATE" ] && sed -n "s/^$1=//p" "$STATE" | tail -n 1; }
listening() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

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
  [ -n "${NATIVE_CMD:-}" ] || die "NATIVE_CMD is empty: set it in the Makefile to the app's dev command"
  pid="$(running_pid)"
  if [ -n "$pid" ]; then
    echo "==> The app already runs on the host: http://localhost:$(value APP_PORT)"
    return 0
  fi
  # Each backing service's port, and the app's own: pinned in .env, or a free one.
  # The backing services run in Docker, so their ports are the docker target's to find.
  exports="$(ops/docker/ports.sh env)" || exit 1
  eval "$exports"
  port="${APP_PORT:?ports.sh gave no APP_PORT: add APP_PORT=<service>:<port> to PORTS in the Makefile}"
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
  *) die "usage: ops/native/native.sh start | stop | status | logs" ;;
esac
