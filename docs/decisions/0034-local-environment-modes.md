# 0034: The local environment runs in Docker or natively, one Makefile per mode

- **Status:** accepted
- **Date:** 2026-10-10
- **Amends:** [0032](0032-local-environment-layout.md) — point 3, the command surface; point 6, the
  native path; and point 7, where the band finds the app's port

## Context

Decision 0032 gave the local environment a native path: `make native` ran the app on the host
against the backing services in Docker. It was a separate target that ran in the foreground, and
nothing else knew about it:

- `make up`, `down`, `logs`, `ps`, `test`, and `lint` all assumed Docker. A developer who worked
  natively typed different commands, and an agent or a worktree's `START_CMD` couldn't start the
  native app, because the command never returned.
- A team couldn't say "this project runs natively", and a developer couldn't say "I do".
- The band above the prompt showed the native app only when `APP_PORT` was pinned.

A first version put both modes in one `Makefile`, with a conditional in every task. It worked, but
each task read as two, and a project couldn't see one mode's commands without the other's.

The framework is stack-agnostic, so the native run can't know how to start any particular app. It
can only run the command the project gives it.

## Decision

1. **One file per mode.** The root `Makefile` holds what both modes share: the settings, choosing
   the mode, `help`, `env`, and the worktree guard. It then loads `ops/make/<mode>.mk`:
   `ops/make/docker.mk` runs the whole stack in Docker, and `ops/make/native.mk` runs the app on the
   host against its backing services in Docker. They sit in `ops/` because the root keeps only
   `compose.yaml`, the `Makefile`, `.env`, and `.env.example` (0032).
2. **A setting picks the file:** `DEV_MODE`. Whichever is set first wins: the command line
   (`make up DEV_MODE=native`), then the shell, then the checkout's `.env`, then `DEFAULT_MODE` in the
   `Makefile`. A mode with no file stops `make` with a message. A project can add a mode by adding a
   file. `make help` names the mode and its file, and lists that file's tasks.
3. **The same tasks in each file:** `up`, `down`, `build`, `ps`, `logs`, `urls`, `test`, `lint`, and
   `reset`, plus `shell` in Docker mode and `services` in native mode. People, agents,
   `AGENTS.md` § Quick reference, and `worktree.conf` type the same commands in either mode. Each
   file holds its own commands inline: the tests in the app's container, or on the host.
4. **Native `make up` runs the app in the background.** `NATIVE_CMD` in `native.mk` is the stack's
   own dev command, listening on `$APP_PORT`. `ops/scripts/native.sh` starts it in a process group
   of its own with every `<NAME>_PORT` exported, then waits until `APP_PORT` answers. If the app
   exits first, it fails and shows the end of the log. `make down` stops the whole group. The app's
   process, port, and log stay in `ops/.run/`, which git and the Docker build ignore. `make native`
   goes: the mode replaces it.
5. **Switching modes needs no cleanup.** Docker-mode `make up` stops an app running on the host, and
   native `make up` stops the app's container.
6. **A developer's own services need no setting.** `SERVICES` in `native.mk` lists the backing
   services that stay in Docker; empty, native mode needs no Docker at all. A developer who runs one
   on the host pins its `<NAME>_PORT` in `.env`. When nothing in Docker publishes it, `ports.sh`
   gives the app that port, and `make urls` shows the service on the host.
7. **The band reads the native app's port** from `ops/.run/app.env` when `.env` pins none. That's a
   file read, which 0026 allows, and it comes before 0032's Docker lookup.
8. **Worktrees** keep `START_CMD="make up"`, which loads the worktree's own mode. `/dev-env
   worktrees` proposes `STOP_CMD="ops/scripts/native.sh stop; docker compose down -v"`.

## Consequences

- **Positive:**
  - A developer or a whole team works natively with the commands everyone else types, and an agent
    never needs to know which mode a checkout uses.
  - Each mode reads as plain make: one recipe per task, no conditionals.
  - A worktree can run natively with its own port, since `make up` returns once the app answers.
- **Negative / cost:**
  - **Two files keep the same task names.** The static check asserts that both define the full
    set.
  - **The `Makefile` reads one name from `.env`:** `DEV_MODE`, and nothing else.
  - **A background process outlives the terminal that started it.** `make down` stops it. A machine
    restart leaves a stale `ops/.run/app.env`, which the next command notices and removes.
  - **Native mode trusts the host:** the runtime and its version are each developer's.
    `DEV-SETUP.md` names them.

## Alternatives considered

- **One `Makefile` with a conditional per task.** Built first, then replaced at review: every task
  read as two.
- **Separate targets per mode** (`make up-native`, `make dev`). Declined: every doc, agent
  instruction, and `worktree.conf` would need to know each developer's choice.
- **The mode in a committed file only.** Declined: native or Docker is often one developer's
  preference, and a worktree may want the other.
- **A list of the services a developer runs on the host** (`HOST_SERVICES`). Built first, then
  dropped: the pinned port already says it.
- **Compose profiles.** Declined in 0032, for the same reason: a plain `docker compose up` would no
  longer start the whole stack.
- **A process manager** (foreman, overmind, pm2). Declined: one more tool to install, tied to an
  ecosystem. `native.sh` needs bash and nothing else.
