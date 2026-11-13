# The local environment specification

What a project's local environment must look like, and how it behaves, in a project with the
`docker` module ([decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md),
[decision 0034](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0034-local-environment-modes.md),
[decision 0056](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0056-the-running-app-in-claude-desktops-browser.md)).
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
  - `ops/docker/` — `Makefile`, `guard.sh`, `launch-json.sh`, and each service's image and config in
    `ops/docker/<service>/` (a Dockerfile, its `<Dockerfile>.dockerignore`, config files).
  - `ops/native/` — `Makefile`, `native.sh`, and `.run/`.
  - `ops/agent/` — the parallel-agents module, when installed.
  - `ops/<provider>/` — each deployment target the project adds (`ops/vercel/`, `ops/ecs/`).
- **L3.** `ops/` is never organized by kind of file: no `ops/scripts/`, `ops/make/`, `ops/config/`,
  or another folder that several targets share.
- **L4.** A target may use another target's files, where the dependency is real: native's backing
  services run in Docker, so native mode runs `ops/docker/guard.sh` too, and `ops/docker/launch-json.sh`
  for its rows in Claude Desktop's Browser (P8); an ECS deployment builds the image in
  `ops/docker/<service>/`. A file is never copied between targets.
- **L5.** A file a tool reads from a fixed place stays there, and the target's folder holds the rest:
  `compose.yaml` at the root (so `docker compose` needs no `-f`), `vercel.json` where Vercel reads it,
  `.github/`, a platform's own manifest. `.claude/rules/deployment.md` lists each one the project has.
- **L6.** The app's code never lives in `ops/`.
- **L7.** Git ignores `.env`, `ops/native/.run/`, and `.claude/launch.json` (P8); each Dockerfile's
  `.dockerignore` excludes `.git`, `.env`, `.env.*` (but `.env.example`), `.claude/`, and
  `ops/native/.run/`.

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
  | `stop` | Stop what `up` started — its processes and containers end, freeing memory and CPU — and remove nothing: containers, volumes, and data stay, and `up` starts it again (C12) |
  | `down` | Stop what `up` started and remove its containers. Data stays |
  | `build` | Prepare what `up` runs: rebuild the images (Docker) or install the app's dependencies on the host (native) |
  | `ps` | Show what runs, its state, and its health |
  | `logs` | Print the last lines — 100 — of every log, or of one service's (`s=<service>`). **Never follow** |
  | `urls` | Print where each service is now, and whether it answers |
  | `test` | Run the tests, where the mode runs the app. `t=<filter>` runs only the matching ones — a file, or what the test runner takes to select tests. `tier=<smoke\|critical\|regression>` runs a tier and `suite=<name>` one feature suite, when the project has the `unit` module ([decision 0058](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0058-test-tiers-and-feature-suites-with-vitest.md)); `make e2e` takes the same two |
  | `lint` | Run the linters, where the mode runs the app. `f=<files>` lints only those |
  | `format` | Rewrite files to the project's formatting, where the mode runs the app; `f=<files>` formats only those. A stack with no formatter keeps the task, saying so |
  | `typecheck` | Run the type checker, where the mode runs the app. A stack with none keeps the task, saying so |
  | `run` | Run the command in `cmd`, where the mode runs the app: in the app's container (Docker), on the host (native). The command reaches that shell as one argument (C10) |
  | `reset` | **The only task that deletes data:** remove this checkout's containers and volumes, then `up` |

  A mode may add tasks of its own — Docker mode's `shell`, native mode's `services` — and `help`
  lists whatever the loaded file defines. The filters mean an agent runs the one test or file it
  changed through a task; a command no task covers goes through `run` (C10).
- **C4.** `help` names the mode in force and its file on its first line, then lists each task with
  its one-line description (`<task>: … ## <description>`).
- **C5.** `env` creates `.env` from `.env.example`, readable only by its owner, and leaves an
  existing `.env` alone.
- **C6.** `up`, `stop`, `down`, `services`, and `reset` run `guard` first (P6).
- **C7.** The make files run on GNU make 3.81, which macOS ships: no `.ONESHELL`, `!=`, or `$(file …)`.
  They never `include .env`, never use a bare `export` or `.EXPORT_ALL_VARIABLES`, and never export a
  value read from `.env`. A mode file may `export` a command of its own, such as `NATIVE_CMD`.
- **C8.** Every command a task runs is the project's own — its package manager, its test runner, its
  dev server. The framework names none: a template's `CUSTOMIZE` marks each one.
- **C9.** Every task runs without a prompt, except `run` where its command runs on the host
  (C10). `.claude/settings.json` allows `Bash(make *)` and `Bash(docker *)`, and the docker module
  adds no ask rule: both act on this project's local stack, whose data comes back from the seed
  ([decision 0078](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0078-docker-and-make-run-without-a-prompt.md)).
  A prompt isn't what protects data: an agent deletes it — `reset`, a project's `db-drop` — only
  on the developer's yes in chat (C12). A project that wants a prompt for a task adds its own ask
  rule, `Bash(make <task>*)`, which wins over the allow. No task an agent runs waits for input or never
  returns — `logs` with `--tail`, never `-f` or `--follow` — so an agent that runs one is never left
  waiting; a task that does, such as Docker mode's `shell`, says "for people" in its description.
- **C10.** **`run` is the one task that runs a command it's given, and the way an agent runs a
  command no task covers:** `make run cmd='<command>'`
  ([decision 0077](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0077-the-container-is-the-boundary-for-make-run.md)).
  - **Docker mode runs it in the app's container, without a prompt:**
    `$(COMPOSE) exec -T $(APP) sh -c "$$cmd"`. Tests, linters, the package manager, a one-off
    script: in Docker mode an agent runs them through a named task or through `run`, never on the
    host, whose runtime and dependencies aren't the project's.
  - **Native mode runs it on the host, and asks first,** every time.
  - **The command reaches its shell as one argument.** The recipe passes the environment's `cmd` —
    `"$$cmd"` — and never pastes `$(cmd)`, which hands the command's quotes and separators to the
    host's shell. `make` still expands a `$` in the value, so one meant for the command is written
    `$$`, inside single quotes: `make run cmd='echo $$HOME'`.
  - **A hook decides, not a rule.** An ask rule can't read the checkout's mode, and it wins over a
    hook's approval, so `.claude/settings.json` has no rule for `make run`. The
    approve-container-run hook reads the mode as M1 resolves it, the `run` recipe in
    `ops/docker/Makefile`, and the call. It approves `make run cmd='<command>'` written on its own,
    in Docker mode, with the recipe above and a value neither the host's shell nor `make` expands.
    It asks before any other: native mode, a mode it can't read, a recipe of another form, `make`
    pointed at another folder or given another setting, a `$` or a backquote the host would expand.
    A call followed by a pipe or another command is
    left to the permission rules. Empty `APPROVE_CONTAINER_RUN` in `.claude/hooks/config.sh` keeps
    the ask in every mode.
  - **What the container bounds:** the host outside the checkout — the home directory, other
    repositories and worktrees, SSH keys, the Docker daemon — as long as `compose.yaml` hands the
    app's service none of it (D5).
  - **What it doesn't bound:**
    - the checkout, mounted with its `.git` and its `.env`: a command can change or delete any file
      in it;
    - the credentials: `.env` is readable from inside, and so is the container's environment;
    - local data: the backing services answer on the stack's network, so a command can change or
      drop it without `make reset`;
    - the network: a command reaches whatever a credential in `.env` authorizes, and can send
      anything out.

    So the boundary limits a mistake to this checkout and its local data, and protects no secret
    in `.env`: keep production credentials out of it. The rules that hold on the host hold in the
    container, where no hook reads the command: none prints a secret (V4), changes
    the mode (M10), or commits or pushes.
  - **Any other task that runs a command it's given on the host** (`make exec`, `make sh c=…`) is
    for people, and gets an ask rule: `Bash(make <task>*)`.
  - A command agents keep running through `run` is worth a task of its own: a reviewer reads a
    task's name, and it takes `t=` or `f=` (C3).
- **C11.** **A production-like run, when the project has one, is the optional task `prod`, in every
  local mode.** It builds the app the way a deploy does, serves it, and returns once it answers,
  then prints where it is. It's for what only the production build shows — a bug the preview has
  and the dev server doesn't, a check before a deploy — so an agent never runs the stack's build
  and start commands on the host, or switches modes, to get one (M10).
  - **Docker mode:** a service `<APP>-prod` in Compose's `prod` profile, so `make up` never starts
    it, built from the app Dockerfile's `prod` stage, with no source mount, and published on
    `APP_PROD_PORT` (P1, P2). `make prod` builds and starts it beside the dev server.
  - **Native mode:** `NATIVE_PROD_CMD`, the production build and server listening on `$APP_PORT`,
    runs through `native.sh` in place of the dev server, on its port, until the next `make up`.
  - `make urls` shows it, `make logs` prints its log (`s=<APP>-prod` in Docker mode), and
    `make stop` and `make down` stop it.

  A project without a production-like run deletes the task, the service, and the stage. Then an
  agent that needs one says so, and asks.
- **C12.** **One word for each state of the local environment** — Docker's own — in the tasks, the
  docs, and what an agent says ([decision 0071](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0071-stop-the-local-environment-once-ready.md)):

  | Word | What happens | What stays | Back with | Task, and who runs it |
  |---|---|---|---|---|
  | **Stop** | The processes and containers end, after a graceful shutdown: memory and CPU are freed | Containers and the files in them, volumes, data, images, dependencies | `make up`, in seconds; a port Docker picked can change | `make stop` — the agent, once its pull request is ready |
  | **Pause** | Docker's `pause`: the processes freeze in place — CPU is freed, memory is still held | Everything, ports included | `docker compose unpause` | None: it frees no memory |
  | **Down** | Stop, then the containers and networks are removed | Named volumes — the data — images, dependencies; files written inside a container are lost | `make up`, which recreates the containers | `make down` — `/adf:wrap-up` after the merge, or the developer |
  | **Kill** | The processes end at once, with no graceful shutdown | Containers and volumes, but a database can lose unsaved writes | `make up` | None: an agent kills only a process it started that ignores a stop |
  | **Remove** | Containers, networks, and volumes are deleted: the data is gone. Images stay | Images, dependencies, the code | `make up` from scratch — rebuild, re-seed, re-migrate | `make reset` (remove, then start fresh), and a worktree's `STOP_CMD`, which removes despite its name, when `/adf:wrap-up` removes the worktree — only on the developer's yes |

  Native mode's app takes the same words: `stop` and `down` end its process group, and the backing
  services follow the rows above.

## Local modes — `M`

- **M1.** `DEV_MODE` picks the local mode. The first that's set wins: the command line
  (`make up DEV_MODE=native`), the shell's `DEV_MODE`, `DEV_MODE` in the checkout's `.env`, then
  `DEFAULT_MODE` in the `Makefile`, the project's default. The first two are for people (M10).
- **M2.** The make files read two settings from `.env` and nothing else from it: `DEV_MODE` and
  `SERVICES` (M5). An empty value means the project's default; the command line and the shell win
  over `.env`.
- **M3.** A mode is a folder in `ops/` with a `Makefile`. `DEV_MODE` naming anything else — a typo,
  a deployment target, `ops/agent/` — stops `make` with a message that names the setting. A project
  adds a mode by adding a folder and its `Makefile`. A mode's `Makefile` is only ever loaded by the
  root one: run on its own (`make` inside `ops/docker/`), it stops with a message to run `make` from
  the repository root.
- **M4.** **Docker mode** (`ops/docker/`) runs the whole stack in Docker Compose. Its `up` waits until
  every service is healthy (`docker compose up -d --wait`).
- **M5.** **Native mode** (`ops/native/`) runs the app on the host with the stack's own dev command,
  `NATIVE_CMD`, which listens on `$APP_PORT`. `SERVICES` names the backing services that stay in
  Docker, the same way `DEV_MODE` names the mode: the command line, then the shell, then the
  checkout's `.env`, then `DEFAULT_SERVICES` in `ops/native/Makefile`, the project's list. A developer
  who runs some on the host sets their own list in `.env` (`SERVICES=postgres`) and pins the others'
  ports there, which the app reads; `SERVICES=none` means native mode needs no Docker at all.
- **M6.** Native `up` starts the backing services in `SERVICES`, then the app **in the background**,
  in a process group of its own, with every port variable exported (P4). It waits until `APP_PORT`
  answers. If the app exits first, `up` fails and prints the end of the app's log. Native `stop` and
  `down` stop the whole process group; `stop` leaves the backing services' containers in place, and
  `down` removes them.
- **M7.** While the app runs on the host, `ops/native/.run/app.env` holds exactly `PID=<pid>` and
  `APP_PORT=<port>`, and `ops/native/.run/app.log` its output. `ops/docker/launch-json.sh` reads
  `APP_PORT` from that file (P8). `ops/native/.run/app.kind` holds `prod` while the production build runs
  (C11), and is absent for the dev server. A state file whose process has gone is removed by the
  next command.
- **M8.** Switching modes needs no cleanup: each mode's `up` stops what the other mode runs for the
  app — Docker's `up` stops a native app; native `up` stops the app's container.
- **M9.** The same task names in every mode (C3) mean an agent, a worktree's `START_CMD`, and
  `AGENTS.md` § Quick reference never need to know which mode a developer chose.
- **M10.** **An agent runs and checks everything in the mode this checkout is configured for, and
  only the developer changes it** (M1, M5). An agent never sets `DEV_MODE` or `SERVICES` on a
  command or in the shell, and never changes them in `.env` or `DEFAULT_MODE` in the `Makefile` —
  not even when asked. Asked for another mode, or given a task that can't run in this one, it says
  what the task needs and which setting to change, and stops; the developer changes it, and the
  next run is in the new mode. The other mode's files are checked by reading them, never by running
  them. The docker module denies what would change the mode: a `make` command or a leading
  assignment that sets either one, an `export` of it, and an edit to `.env`.

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
- **P5.** Ports are looked up, never written down: only `.env`, by a person, and what the app leaves
  while it runs — native mode's run state (M7) and its rows in Claude Desktop's Browser (P8) — record
  a port.
- **P6.** In a linked worktree, `ops/docker/guard.sh` fails when the worktree's `.env` repeats a port
  or the `COMPOSE_PROJECT_NAME` the main checkout's `.env` pins — a copy, which would run the main
  checkout's stack, or delete its volumes on `make reset`.
- **P7.** `guard.sh` reads only `COMPOSE_PROJECT_NAME` and the `*_PORT` lines of either `.env`, and
  `native.sh` only `APP_PORT`; neither prints a value but a port.
- **P8.** `.claude/launch.json` lists each web service that runs now, and Claude Desktop's Browser
  shows each entry on a new tab:
  - **Which services:** each one in `compose.yaml` labeled `claude.browser: "true"` — one with pages
    a person opens: the app, its production build, an admin UI, a mail catcher; never a backing
    service. In native mode, the app on the host too, while it runs (M7).
  - **The row:** an attach entry, named `<service> · http://localhost:<port>`, with that `url` and
    `port` and no command. A localhost `url` can't carry a path, so a page inside an app is never a
    row.
  - **When:** `ops/docker/launch-json.sh` makes the rows match what runs. `up`, `prod`, `stop`, `down`,
    and native mode's `services` run it, and so does `native.sh` when it starts or stops the app. A
    stopped service loses its row, so a port Docker later hands to another checkout is never listed
    here.
  - **How:** only where git ignores the file (L7). It keeps the developer's own entries and settings —
    its rows are the attach entries named `<service> · <url>` — leaves a file with comments as it is,
    and never fails the task.

## Compose — `D`

- **D1.** No `container_name:` and no top-level `name:`; `.env.example` leaves `COMPOSE_PROJECT_NAME`
  empty. The checkout's folder names the Compose project.
- **D2.** Images are pinned to a version, never `latest`.
- **D3.** A service another one waits for has a `healthcheck:`, and the one that waits uses
  `depends_on` with `condition: service_healthy`.
- **D4.** Data lives in named volumes.
- **D5.** The app's service gets nothing of the host but the checkout. Its volumes are the checkout
  and named volumes — never the Docker socket, the home directory, or another path outside the
  checkout — and it isn't `privileged`, with no `pid: host` or `network_mode: host`. `make run`
  runs any command there without a prompt (C10), so what the service reaches is what an agent
  reaches. A project whose app needs one of those sets `APPROVE_CONTAINER_RUN=""`
  (`.claude/hooks/config.sh`) and records the exception. No hook checks this: the audit does.

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
| Whether `make run` needs a prompt | the checkout's mode and the `run` recipe in `ops/docker/Makefile`, which the approve-container-run hook reads; `APPROVE_CONTAINER_RUN` in `.claude/hooks/config.sh` (C10) |
| Every variable's name | `.env.example` |
| This checkout's credentials and pinned ports | `.env` — never read into the conversation |
| Where the services are now | `make urls` |
| The app on the host while it runs | `ops/native/.run/` |
| Which services Claude Desktop's Browser lists | the `claude.browser: "true"` label in `compose.yaml` (P8) |
| Their rows, while they run | `.claude/launch.json`, untracked, kept by the tasks that start and stop them (P8) |
| How the production build is built and served | the Dockerfile's `prod` stage and `<APP>-prod` in `compose.yaml`; `NATIVE_PROD_CMD` in `ops/native/Makefile` |
| How a person sets up and starts the stack, and problems met before | `docs/getting-started/DEV-SETUP.md` |
| The start and stop commands an agent runs | `AGENTS.md` § Quick reference |
| The project's conventions, its deployment targets, and anything it changed here, with why | `.claude/rules/deployment.md` |
| The URL the agent walks in the local check | `LOCAL_URL` in `.claude/hooks/config.sh` |
| What each worktree starts, stops, and is told | `ops/agent/worktree.conf` |

## Conformance

A stack conforms when every requirement holds. `/adf-dev:dev-env` checks a stack in this order, and reports
each gap as the requirement's ID, what the project has, and the change:

1. **Layout:** L1–L7.
2. **Command surface:** C1–C12, and the mode files define every task in C3, and `prod` in both or
   in neither.
3. **Modes:** M1–M8 by running `make help`, `make up`, `make urls`, `make ps`, `make stop`, `make up`
   again, and `make down` in
   the configured mode, and by reading the other mode's file against them — never by running it
   (M10); M10 by the deny rules.
4. **Ports, Compose, variables:** P1–P8, D1–D5, V1–V4.
5. **Worktrees,** with parallel-agents: W1–W3.
6. **Deployment targets:** T1–T2.

A requirement a project doesn't meet on purpose is recorded in `.claude/rules/deployment.md` with the
reason; an audit reports it as a recorded exception, not a gap.
