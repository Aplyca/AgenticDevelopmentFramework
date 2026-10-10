# 0034: The local environment runs in Docker or natively, by a setting, with one command surface

- **Status:** accepted
- **Date:** 2026-10-10
- **Amends:** [0032](0032-local-environment-layout.md) — point 6, the native path, and point 7, where
  the band finds the app's port

## Context

Decision 0032 gave the local environment a native path: `make native` ran the app on the host
against the backing services in Docker. It was a separate target that ran in the foreground, and
nothing else knew about it:

- `make up`, `down`, `logs`, `ps`, `test`, and `lint` all assumed Docker. A developer who worked
  natively typed different commands, and an agent or a worktree's `START_CMD` couldn't start the
  native app, because the command never returned.
- A team couldn't say "this project runs natively", and a developer couldn't say "I do".
- The band above the prompt showed the native app only when `APP_PORT` was pinned.
- A developer who ran a backing service on the host, such as their own Postgres, had no way to keep
  Docker from starting another one.

The framework is stack-agnostic, so the native run can't know how to start any particular app. It
can only run the command the project gives it.

## Decision

1. **A setting picks the mode:** `docker`, the whole stack in Docker, or `native`, the app on the
   host with its backing services in Docker. Whichever is set first wins: the command line
   (`make up DEV_MODE=native`), then the shell's `DEV_MODE`, then `DEV_MODE` in the checkout's `.env`,
   then the project's `DEFAULT_MODE` in the `Makefile`. Any other value stops `make` with a message.
   `make help` names the mode in force.
2. **One command surface.** `up`, `down`, `build`, `ps`, `logs`, `urls`, `shell`, `services`, `test`,
   `lint`, and `reset` act on the mode, so people, agents, `AGENTS.md` § Quick reference, and
   `worktree.conf` use the same commands in either one. `make native` stays: it runs the app in the
   foreground, for a person who wants its output.
3. **The stack's own commands, named in the `Makefile`:** `NATIVE_CMD`, the dev command, which listens
   on `$APP_PORT`; `NATIVE_INSTALL_CMD`, which installs dependencies on the host and which native
   mode's `make build` runs; and `TEST_CMD` and `LINT_CMD`, which run in the app's container or on the
   host. The framework never guesses them.
4. **Native `make up` runs the app in the background.** `ops/scripts/native.sh` starts it in a
   process group of its own with every `<NAME>_PORT` exported, then waits until `APP_PORT` answers. If
   the app exits first, it fails and shows the end of the log. `make down` stops the whole group. The
   app's process, port, and log stay in `ops/.run/`, which git and the Docker build ignore.
5. **Switching modes needs no cleanup.** Docker-mode `make up` stops a native app, and native
   `make up` stops the app's container.
6. **A developer's own services:** `HOST_SERVICES` in `.env` names the backing services they run on
   the host. In native mode Docker skips them, and their ports are the ones pinned in `.env`. With
   every service listed, native mode needs no Docker at all.
7. **The band reads the native app's port** from `ops/.run/app.env` when `.env` pins none. That's a
   file read, which 0026 allows, and it comes before 0032's Docker lookup.
8. **Worktrees** keep `START_CMD="make up"`, which uses the worktree's own `DEV_MODE`. `/dev-env
   worktrees` proposes `STOP_CMD="ops/scripts/native.sh stop; docker compose down -v"`.

## Consequences

- **Positive:**
  - A developer or a whole team works natively with the commands everyone else types, and an agent
    never needs to know which mode a checkout uses.
  - A worktree can run natively with its own port, since `make up` returns once the app answers.
  - A team with no backing services in Docker can use the same `Makefile`.
- **Negative / cost:**
  - **Four more `CUSTOMIZE` values in the `Makefile`.** `/dev-env set up` fills them from the
    project's manifest and docs, and a project that never runs natively leaves `NATIVE_CMD` and
    `NATIVE_INSTALL_CMD` unset; they fail with a message only when used.
  - **The `Makefile` reads two names from `.env`:** `DEV_MODE` and `HOST_SERVICES`, and nothing else.
  - **A background process outlives the terminal that started it.** `make down` stops it. A machine
    restart leaves a stale `ops/.run/app.env`, which the next command notices and removes.
  - **Native mode trusts the host:** the runtime and its version are each developer's.
    `DEV-SETUP.md` names them.

## Alternatives considered

- **Separate targets per mode** (`make up-native`, `make dev`). Declined: every doc, agent
  instruction, and `worktree.conf` would need to know each developer's choice.
- **The mode in a committed file only.** Declined: native or Docker is often one developer's
  preference, and a worktree may want the other.
- **The mode in `.env` only, with no project default.** Declined: a team that runs natively would
  have every developer set it by hand.
- **Compose profiles.** Declined in 0032, for the same reason: a plain `docker compose up` would no
  longer start the whole stack.
- **A process manager** (foreman, overmind, pm2). Declined: one more tool to install, tied to an
  ecosystem. `native.sh` needs bash and nothing else.
- **Writing the native port to `.env`.** Declined: 0032 keeps ports out of `.env` unless a person
  pins one, and the run directory is cleared when the app stops.
