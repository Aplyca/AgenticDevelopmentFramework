# The local environment specification

What a project's local environment must look like, and how it behaves, in a project with the
`docker` module ([decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md),
[decision 0034](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0034-local-environment-modes.md)).
`/adf-dev:dev-env` writes a stack that meets it, audits a stack against it, and `/adf:adopt` and
`/adf:upgrade` hand a project to `/adf-dev:dev-env` to reach it.

**This file is the specification. The `templates/` beside it are an example** that meets every
requirement, for a stack with one app (`web`) and one backing service (`redis`). A project's own
files differ wherever the project differs — its services, its commands, its deployment targets —
and still conform, as long as each requirement below holds. When a template and this file
disagree, this file wins.

Each requirement has an ID (`L1`, `M3`, …) so an audit, a pull request, or a review can name the one
a project misses. A project that departs from one on purpose records it, with the reason, in
`.claude/rules/deployment.md` (§ Conformance).

## Terms

| Term | Meaning |
|---|---|
| **App** | The project's own code that serves what a person checks locally: one Compose service, `APP` |
| **Backing service** | Anything the app needs that isn't its code: a database, a cache, a queue |
| **Target** | One place the project runs: a **local mode** (`docker`, `native`) or a **deployment target** (Vercel, ECS, …) |
| **Local mode** | A way to run the app on a developer's machine, picked with `DEV_MODE` |
| **Checkout** | The main checkout or a worktree: each runs its own stack |

## Layout — `L`

- **L1.** The repository root holds the local environment's entry points and nothing else of it:
  `compose.yaml` (with any override as `compose.<name>.yaml` beside it), the `Makefile`, `.env`
  (untracked), and `.env.example`.
- **L2.** All other operational code lives in `ops/`, **one folder per target**. A target's folder
  holds everything that target needs and can move: its make file, scripts, images, and config.
  - `ops/docker/` — `Makefile`, `guard.sh`, and each service's image and config in
    `ops/docker/<service>/` (a Dockerfile, its `<Dockerfile>.dockerignore`, config files).
  - `ops/native/` — `Makefile`, `native.sh`, and `.run/`.
  - `ops/agent/` — the parallel-agents module, when installed.
  - `ops/<provider>/` — each deployment target the project adds (`ops/vercel/`, `ops/ecs/`).
- **L3.** `ops/` is never organized by kind of file: no `ops/scripts/`, `ops/make/`, `ops/config/`,
  or another folder that several targets share.
- **L4.** A target may use another target's files, where the dependency is real: native's backing
  services run in Docker, so native mode runs `ops/docker/guard.sh` too; an ECS deployment builds
  the image in `ops/docker/<service>/`. A file is never copied between targets.
- **L5.** A file a tool reads from a fixed place stays there, and the target's folder holds the rest:
  `compose.yaml` at the root (so `docker compose` needs no `-f`), `vercel.json` where Vercel reads it,
  `.github/`, a platform's own manifest. `.claude/rules/deployment.md` lists each one the project has.
- **L6.** The app's code never lives in `ops/`.
- **L7.** Git ignores `.env` and `ops/native/.run/`; each Dockerfile's `.dockerignore` excludes `.git`,
  `.env`, `.env.*` (but `.env.example`), `.claude/`, and `ops/native/.run/`.

## The command surface — `C`

- **C1.** The `Makefile` at the root is the one command surface, for people and agents alike. A task
  the team runs often gets a target instead of a command copied around. `make` with no target is
  `make help`.
- **C2.** The root `Makefile` holds only what every local mode shares: the settings (`COMPOSE`,
  `DEFAULT_MODE`, `APP`), choosing the mode (M1–M3), and the tasks `help`, `env`, and `guard`.
  It ends by loading the mode's file: `include ops/$(DEV_MODE)/Makefile`.
- **C3.** Each local mode's file, `ops/<mode>/Makefile`, defines these tasks, with the same
  meaning in every mode:

  | Task | Must |
  |---|---|
  | `up` | Start the local environment and **return** once the app answers, then print where each service is. Running it twice changes nothing |
  | `down` | Stop what `up` started. Data stays |
  | `build` | Prepare what `up` runs: rebuild the images (Docker) or install the app's dependencies on the host (native) |
  | `ps` | Show what runs, its state, and its health |
  | `logs` | Print the last lines — 100 — of every log, or of one service's (`s=<service>`). **Never follow** |
  | `urls` | Print where each service is now, and whether it answers |
  | `test` | Run the tests, where the mode runs the app |
  | `lint` | Run the linters, where the mode runs the app |
  | `reset` | **The only task that deletes data:** remove this checkout's containers and volumes, then `up` |

  A mode may add tasks of its own — Docker mode's `shell`, native mode's `services` — and `help`
  lists whatever the loaded file defines.
- **C4.** `help` names the mode in force and its file on its first line, then lists each task with
  its one-line description (`<task>: … ## <description>`).
- **C5.** `env` creates `.env` from `.env.example`, readable only by its owner, and leaves an
  existing `.env` alone.
- **C6.** `up`, `down`, `services`, and `reset` run `guard` first (P6).
- **C7.** The make files run on GNU make 3.81, which macOS ships: no `.ONESHELL`, `!=`, or `$(file …)`.
  They never `include .env`, never use a bare `export` or `.EXPORT_ALL_VARIABLES`, and never export a
  value read from `.env`. A mode file may `export` a command of its own, such as `NATIVE_CMD`.
- **C8.** Every command a task runs is the project's own — its package manager, its test runner, its
  dev server. The framework names none: a template's `CUSTOMIZE` marks each one.

## Local modes — `M`

- **M1.** `DEV_MODE` picks the local mode. The first that's set wins: the command line
  (`make up DEV_MODE=native`), the shell's `DEV_MODE`, `DEV_MODE` in the checkout's `.env`, then
  `DEFAULT_MODE` in the `Makefile`, the project's default.
- **M2.** The `Makefile` reads `DEV_MODE` from `.env` and nothing else from it.
- **M3.** A mode is a folder in `ops/` with a `Makefile`. `DEV_MODE` naming anything else — a typo,
  a deployment target, `ops/agent/` — stops `make` with a message that names the setting. A project
  adds a mode by adding a folder and its `Makefile`. A mode's `Makefile` is only ever loaded by the
  root one: run on its own (`make` inside `ops/docker/`), it stops with a message to run `make` from
  the repository root.
- **M4.** **Docker mode** (`ops/docker/`) runs the whole stack in Docker Compose. Its `up` waits until
  every service is healthy (`docker compose up -d --wait`).
- **M5.** **Native mode** (`ops/native/`) runs the app on the host with the stack's own dev command,
  `NATIVE_CMD`, which listens on `$APP_PORT`. `SERVICES` in `ops/native/Makefile` lists the backing
  services that stay in Docker; an empty list means native mode needs no Docker at all. A developer
  who runs one of them on the host leaves it out for their own runs — `SERVICES` is a `?=` setting,
  so `make up SERVICES=…` or `SERVICES` in their shell overrides it — and pins its port in `.env`,
  which the app reads.
- **M6.** Native `up` starts the backing services in `SERVICES`, then the app **in the background**,
  in a process group of its own, with every port variable exported (P4). It waits until `APP_PORT`
  answers. If the app exits first, `up` fails and prints the end of the app's log. Native `down` stops
  the whole process group.
- **M7.** While the app runs on the host, `ops/native/.run/app.env` holds exactly `PID=<pid>` and
  `APP_PORT=<port>`, and `ops/native/.run/app.log` its output. The band above the prompt reads
  `APP_PORT` from that file. A state file whose process has gone is removed by the next command.
- **M8.** Switching modes needs no cleanup: each mode's `up` stops what the other mode runs for the
  app — Docker's `up` stops a native app; native `up` stops the app's container.
- **M9.** The same task names in every mode (C3) mean an agent, a worktree's `START_CMD`, and
  `AGENTS.md` § Quick reference never need to know which mode a developer chose.

## Ports — `P`

- **P1.** Every published port is `"127.0.0.1:${<NAME>_PORT:-}:<container port>"`: bound to the
  loopback interface, from a port variable.
- **P2.** `.env.example` declares each `<NAME>_PORT` empty, so Docker picks a free host port each time
  the service starts and any number of checkouts run side by side. A developer pins a port in their
  own `.env` when something must know it in advance: an OAuth callback, an app that builds its own
  URL, a backing service they run on the host themselves.
- **P3.** Docker Compose is the one source of where a service is: nothing restates the ports
  `compose.yaml` publishes. `make urls` shows Compose's own view — each service, its published ports,
  and its health (`docker compose ps`) — plus the app's URL, and in native mode the app on the host
  (M7).
- **P4.** A service's port variable is `<SERVICE>_PORT`, its name in capitals with `-` and `.` as
  `_` (`redis` → `REDIS_PORT`); the app's is `APP_PORT`. In native mode, `native.sh` exports each
  `SERVICES` entry's published port under that name, looked up with `docker compose ps`, and
  `APP_PORT`: the shell's, else the one `.env` pins, else a free one. A service in `SERVICES` that
  isn't running stops `make up` with a message to start it.
- **P5.** Ports are looked up, never written down: only `.env`, by a person, and native mode's run
  state while the app runs (M7) record a port.
- **P6.** In a linked worktree, `ops/docker/guard.sh` fails when the worktree's `.env` repeats a port
  or the `COMPOSE_PROJECT_NAME` the main checkout's `.env` pins — a copy, which would run the main
  checkout's stack, or delete its volumes on `make reset`.
- **P7.** `guard.sh` reads only `COMPOSE_PROJECT_NAME` and the `*_PORT` lines of either `.env`, and
  `native.sh` only `APP_PORT`; neither prints a value but a port.

## Compose — `D`

- **D1.** No `container_name:` and no top-level `name:`; `.env.example` leaves `COMPOSE_PROJECT_NAME`
  empty. The checkout's folder names the Compose project.
- **D2.** Images are pinned to a version, never `latest`.
- **D3.** A service another one waits for has a `healthcheck:`, and the one that waits uses
  `depends_on` with `condition: service_healthy`.
- **D4.** Data lives in named volumes.

## Variables — `V`

- **V1.** Three levels, each fact in one:
  - `.env` at the root, untracked — what Compose reads to fill each `${…}` in `compose.yaml`, and what
    the app reads on the host. It holds the primitives (ports, credentials, `DEV_MODE`) and the
    host-form variables a native app reads (`REDIS_URL=redis://localhost:${REDIS_PORT}`).
  - each service's `environment:` in `compose.yaml` — what that container gets, in container form
    (`REDIS_URL: redis://redis:6379`), a credential as `${NAME:-}`;
  - `.env.example`, committed — every variable by name, with no real value.
- **V2.** No `env_file:`: it hands every variable to every container.
- **V3.** Every `${VAR}` in `compose.yaml` is declared in `.env.example`.
- **V4.** No agent reads `.env` into the conversation, and no task prints a resolved secret: no
  `docker compose config` without `--quiet` or `--services`, no `docker inspect` of an environment.

## Worktrees — `W` (with parallel-agents)

- **W1.** Each worktree runs its own stack: its folder names its Compose project, and its ports are
  Docker's or its own.
- **W2.** `ops/agent/worktree.conf`: `PORT_SLOTS=0`; `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'`
  plus an empty `<NAME>_PORT=` for each port the main checkout pins; `START_CMD="make up"`;
  `STOP_CMD="ops/native/native.sh stop; docker compose down -v"`; `READY_URL` empty;
  `ENV_INFO_CMD="make urls"`.
- **W3.** A worktree's mode is its own `DEV_MODE`; `make up` starts it either way (M9).

## Deployment targets — `T`

- **T1.** A deployment target gets its own folder in `ops/` (L2) and no `Makefile`, so `DEV_MODE`
  can't pick it (M3). Its tasks, when it has them, go in a file of another name
  (`ops/ecs/deploy.mk`), loaded the way the project chooses.
- **T2.** The framework ships no provider's files. `.claude/rules/deployment.md` names each target
  the project has, and the fixed-place files it keeps outside its folder (L5).

## Where each fact lives

| Fact | Lives in |
|---|---|
| The services, their healthchecks, and what each container gets | `compose.yaml` |
| Images and service config | `ops/docker/<service>/` |
| The tasks people and agents run | the `Makefile` and the mode's file (`make help`) |
| Each mode's commands | `ops/docker/Makefile`, `ops/native/Makefile` |
| The project's default mode; this checkout's | `DEFAULT_MODE` in the `Makefile`; `DEV_MODE` in `.env` |
| Every variable's name | `.env.example` |
| This checkout's credentials and pinned ports | `.env` — never read into the conversation |
| Where the services are now | `make urls` |
| The app on the host while it runs | `ops/native/.run/` |
| How a person sets up and starts the stack, and problems met before | `docs/getting-started/DEV-SETUP.md` |
| The start and stop commands an agent runs | `AGENTS.md` § Quick reference |
| The project's conventions, its deployment targets, and anything it changed here, with why | `.claude/rules/deployment.md` |
| The URL the band above the prompt shows | `LOCAL_URL` and `LOCAL_SERVICE` in `.claude/hooks/config.sh` |
| What each worktree starts, stops, and is told | `ops/agent/worktree.conf` |

## Conformance

A stack conforms when every requirement holds. `/adf-dev:dev-env` checks a stack in this order, and reports
each gap as the requirement's ID, what the project has, and the change:

1. **Layout:** L1–L7.
2. **Command surface:** C1–C8, and the mode files define every task in C3.
3. **Modes:** M1–M3 read by `make help` and `make help DEV_MODE=<each mode>`; M4–M8 by running
   `make up`, `make urls`, `make ps`, and `make down` in each mode the project uses.
4. **Ports, Compose, variables:** P1–P7, D1–D4, V1–V4.
5. **Worktrees,** with parallel-agents: W1–W3.
6. **Deployment targets:** T1–T2.

A requirement a project doesn't meet on purpose is recorded in `.claude/rules/deployment.md` with the
reason; an audit reports it as a recorded exception, not a gap.
