# Diagnose — the local environment fails

`/adf-dev:dev-env` reads this for the diagnose mode (step 4): something fails. It needs no
specification. `/adf:debug`'s order, applied to the environment.

1. **Get a failing signal** — one command that fails on this problem: `make up`, the state and health
   in `make ps`, or `curl -fsS` on the URL `make urls` gives. Show the command and its output,
   trimmed, with secrets replaced by `<REDACTED>`.
2. **Check the simple things, roughly in order:**
   - the Docker daemon isn't running (`docker info`);
   - a stale URL — Docker picks a new port each time a service starts, so take it from `make urls`
     again;
   - a pinned port that's taken — find its owner with `docker ps --filter publish=<port>` or
     `lsof -iTCP:<port> -sTCP:LISTEN`. It may be another worktree's stack or the developer's own
     process, so never stop it unasked; offer to unpin it instead;
   - a variable set in the shell, which wins over `.env` (`printenv <NAME>` for that one name, never
     `env`);
   - a worktree's `.env` that repeats the main checkout's pinned values (`make up` says so);
   - a "variable is not set" warning;
   - a stale image (`make build`);
   - an unhealthy dependency (`make logs s=<service>`, its healthcheck);
   - a volume holding an older schema (migrations or seed);
   - another project's stack answering (a top-level `name:`, or the wrong `COMPOSE_PROJECT_NAME`);
   - a platform mismatch on Apple silicon;
   - a full disk (`docker system df`).
3. **Rank 3–5 hypotheses** when the simple things don't explain it, each with what would prove it
   wrong, and test them one at a time.
4. **The cause is in the application, not the environment?** Hand over to `/adf:debug` with the signal.
5. **Fix:** a local step that touches only this project — start the daemon, restart this stack — just
   do it and say so. Stopping or removing anything that isn't this project's waits for a yes. A change
   to `compose.yaml`, the `Makefile`, or anything in `ops/` goes through `/adf:triage`
   (infrastructure: the careful lane).
6. **Report:** symptom, signal, cause, ruled out, fix, and how to verify. When the next person would
   hit the same thing, add it to `DEV-SETUP.md` § Troubleshooting.
