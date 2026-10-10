# 0032: A project's local environment — `compose.yaml` and a `Makefile` at the root, operations in `ops/`, ports Docker picks

- **Status:** accepted; amended by [0034](0034-local-environment-modes.md) (the app runs in Docker or natively: `DEV_MODE` loads `ops/make/docker.mk` or `ops/make/native.mk`, which define the same tasks)
- **Date:** 2026-10-09
- **Amends:** [0008](0008-dispatcher-and-worker-worktrees.md) — worktree ports for a Docker
  stack; [0026](0026-display-only-mods.md) — one read-only lookup the band may run;
  [0027](0027-worktree-scripts-as-plugin-commands.md) — where the module's scripts and settings live

## Context

The `docker` module's `/dev-env` drafted a Compose stack from loose conventions, and the skeleton's
files disagreed with it and with each other:

- **Fixed ports.** `/dev-env` published the app on `"127.0.0.1:${APP_PORT:-3000}:3000"`. The skeleton's
  `deployment.md`, `AGENTS.md`, and `DEV-SETUP.md` listed fixed ports (3000, 5432, 6379). With the
  parallel-agents module each worktree got one port, derived from its branch name, for the app alone.
- **Two env files.** `DEV-SETUP.md` and `README.md` said `cp .env.example .env.local`. Compose reads
  only `.env`, and the worktree scripts, `.worktreeinclude`, and the band all use `.env`.
- **How containers get their variables** was never said. `environment:` and `env_file:` appeared
  nowhere.
- **No home for operational code.** Dockerfiles at the root, `infra/**` in the deployment rule's
  paths, and the worktree tooling in `scripts/agent/`.
- **No command surface.** `make`, package scripts, and `just` were equal choices, and no target was
  defined.
- **No native path.** Every `/dev-env` mode ran the whole stack in Docker.
- **The docker module was said to copy files** (`/adopt`, `/upgrade`, `README.md`,
  `modules/README.md`), but it has no `files/`.

**How Compose behaves** (Docker Compose v5.5.1 on Docker 29.8.1, checked 2026-10-09 in a throwaway
project):

- It reads `.env` from the project directory — the folder of `compose.yaml` — and interpolates
  `${VAR}` in the Compose file from it. A value in `.env` may use the variables above it
  (`URL=postgres://${USER}@localhost:${DB_PORT}`).
- A port written `"127.0.0.1:${APP_PORT:-}:80"` with `APP_PORT` empty publishes on a free port Docker
  picks; `docker compose port web 80` prints it (`127.0.0.1:50916`). With `APP_PORT=48123`, it
  publishes there.
- The picked port changes on every `restart`, `stop`/`start`, and recreate.
- An empty `COMPOSE_PROJECT_NAME=` counts as unset: the project is named after the folder, so two
  checkouts in two folders run side by side without a setting.
- Shell variables win over `.env`; `${VAR:?message}` fails the command with the message.

## Decision

1. **Docker Compose, with `compose.yaml` at the root** as the one entry point (overrides
   `compose.<name>.yaml` beside it). The root keeps only `compose.yaml`, `Makefile`, `.env`
   (untracked), and `.env.example`.
2. **Everything else operational lives in `ops/`:** Dockerfiles and service configuration in
   `ops/docker/<service>/`, helper scripts in `ops/scripts/`, and the parallel-agents module in
   `ops/agent/` (point 8).
3. **A `Makefile` at the root is the command surface,** for people and agents alike: `help` (the
   default), `env`, `up`, `down`, `build`, `ps`, `logs`, `urls`, `shell`, `services`, `native`, `test`,
   `lint`, `reset`. `logs` never follows; `reset` is the only target that deletes data.
4. **Three levels of environment variables:**
   - **`.env`** at the root, untracked — read by Compose for interpolation. It holds the primitives
     (ports, credentials, the project name) and the host-form variables a native app reads
     (`REDIS_URL=redis://localhost:${REDIS_PORT}`).
   - **`environment:`** on each service in `compose.yaml` — what that container gets, in container
     form (`REDIS_URL: redis://redis:6379`). No `env_file:`: it hands every variable to every
     container and hides which one needs what.
   - **`.env.example`**, committed — every variable by name, without a real value. `make env` copies
     it to `.env`.
5. **Docker picks the host ports.** Every published port is `"127.0.0.1:${<NAME>_PORT:-}:<port>"`, and
   `.env.example` leaves each `*_PORT` empty. A developer who wants a fixed port sets it in their own
   `.env`. `make urls` prints the ports in use, looked up each time.
6. **A native path: the app on the host, its backing services in Docker.** `make native` starts the
   backing services, looks up their ports, exports them (`REDIS_PORT=…`) and runs the stack's own dev
   command, on `APP_PORT` when it's pinned and on a free port otherwise.
7. **The band looks up the port Docker picked** — the one exception to 0026's "mods run no process".
   When `APP_PORT` isn't set in `.env` and `LOCAL_SERVICE` (`.claude/hooks/config.sh`, e.g.
   `web:3000`) names the app's service and port, the band runs exactly
   `docker compose port <service> <port>` in the checkout's root — an argument vector, no shell, a
   short timeout. It keeps the port and looks again only after a turn or when the URL stops answering.
   The static check allows that one call and refuses every other process call in a mod.
8. **The parallel-agents module moves from `scripts/agent/` to `ops/agent/`.** The commands, hooks,
   skills, and the band read `ops/agent/` first and `scripts/agent/` after it, so a packaged project
   keeps working until `/adf:upgrade` moves the folder. The fallback goes in the next major release.
9. **Worktrees of a Docker stack need no port slots.** Each worktree's folder names its Compose
   project, and Docker picks its ports. `/dev-env worktrees` proposes
   `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'` (plus an empty `<NAME>_PORT=` for every port the
   main checkout pins), `START_CMD="make up"`, and `ENV_INFO_CMD="make urls"`. `PORT_SLOTS` stays for
   projects that run a server on the host in each worktree.
10. **A worktree never runs the main checkout's stack.** `make up`, `native`, and `reset` refuse in a
    linked worktree whose `.env` pins a port or project name equal to the main checkout's — the copy
    `.worktreeinclude` makes. Otherwise `make reset` there would delete the main checkout's volumes.
11. **Permissions:** the docker module allows `make help`, `make ps`, `make urls`, and `make logs`
    exactly, and asks before any `make` command that names `reset`.

`/dev-env set up` writes a missing stack from templates the skill carries, and audits an existing one
against these conventions, proposing the move as a careful-lane change. The docker module copies no
files.

## Consequences

- **Positive:**
  - Any number of checkouts and worktrees run the same stack side by side with no port bookkeeping.
  - One place to look for each fact: the ports in `make urls`, the variables in `.env.example`, what a
    container gets in its `environment:`, the commands in `make help`.
  - The app runs natively against the same backing services when a developer prefers it.
  - The repository root stays small.
- **Negative / cost:**
  - **A URL changes whenever its container restarts.** `make urls` and the band always show the
    current one; an app that must know its own URL (an OAuth callback, absolute links) pins its port.
  - **The band runs a process,** a narrow exception the static check holds to one argument vector.
    It needs the `docker` CLI; without it the band shows nothing.
  - **Every adopting project with parallel-agents moves a folder.** `/adf:upgrade` does it; worktrees
    branched before the move keep `scripts/agent/` until they merge.
  - **A committed install carries the templates** under `.claude/skills/dev-env/templates/`, where
    image and Dockerfile scanners may read them.
  - **Native mode shows a URL in the band only when `APP_PORT` is pinned:** the host app isn't
    Docker's, so there is nothing to look up.

## Alternatives considered

- **Fixed ports with offsets per worktree.** Declined: every stack needs bookkeeping, and a second
  project on the same machine still collides.
- **A random port chosen once and written to `.env`.** Declined in review: an allocator, a registry
  of other checkouts' files, and stale reservations, for a stability Docker offers by pinning.
- **A state file of the ports in use, which the band reads.** Declined in review: it goes stale after
  a plain `docker compose up`, and it's one more file. The lookup is one read-only command.
- **`compose.yaml` inside `ops/`.** Declined: every `docker compose` command would need `-f` or
  `COMPOSE_FILE`, including the ones agents type, and the root `.env` would no longer sit beside it.
- **`env_file:`.** Declined (point 4).
- **Compose profiles for native mode.** Declined: a plain `docker compose up` would no longer start
  the whole stack. The Makefile names the backing services instead.
- **`just` or package scripts as the command surface.** Declined: `make` is on every macOS and Linux
  machine, and one name serves every stack.
- **Keeping `scripts/agent/`.** Declined: it's operational code outside `ops/`.
