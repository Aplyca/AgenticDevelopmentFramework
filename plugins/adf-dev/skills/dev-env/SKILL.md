---
name: dev-env
description: Set up, migrate, run natively, diagnose, or safely reset this project's local environment to the specification this skill carries — `compose.yaml` and a `Makefile` at the root, one folder per target in `ops/`, Docker or native by `DEV_MODE`, variables from `.env` and each service's `environment:`, host ports Docker picks unless `.env` pins them — written down for people and agents, one stack per worktree with the parallel-agents module, a failing signal before any fix, and nothing deleted beyond this project's own containers and volumes without the developer's yes. Use when the next step needs the app running and there's no working stack, when a stack should meet the specification, to run the app on the host, when the stack won't start or misbehaves, before the local check, or to reset local data.
argument-hint: "[set up | worktrees | native | diagnose <symptom> | reset]"
---

> **Step 0 — which copy.** This is the packaged copy, from the `docker` module, carried by `adf-dev` ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/dev-env/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Local environment

The local environment is where the change runs before anyone else sees it: the tests that need a
database, and the developer's **local check** before the draft pull request (`AGENTS.md` § Delivery
rules). This skill gets a Compose stack to that point and keeps it there. It doesn't decide *whether*
a task needs an environment — triage does (`AGENTS.md` § How work flows → Environment).

## The specification

**`<this skill's base directory>/SPECIFICATION.md` is what a local environment must be** — its layout
(one folder per target in `ops/`), the command surface (a root `Makefile` that loads
`ops/<DEV_MODE>/Makefile`, and the tasks every mode defines), the local modes, ports, Compose,
variables, worktrees, and deployment targets — each requirement with an ID. Read it before any mode
below. It also says where each fact lives; this skill writes only what a command it ran has shown.

**The `templates/` beside it are an example** that meets the specification, for one app (`web`) and
one backing service (`redis`). Start from them, then make the project's files fit the project: its
services, its commands, its deployment targets. Where a template and the specification disagree,
the specification wins. Name the requirement's ID whenever you report a gap or propose a change.

## Safety (always)

- **This project only.** Every command is scoped to this checkout's Compose project. Never prune or
  remove anything machine-wide — other projects and other worktrees' stacks live on the same Docker.
- **No secrets in the conversation.** Never run `docker compose config` without `--quiet` or
  `--services`, and never `docker inspect` a container's environment: both print resolved secrets.
  Never read `.env` (the settings deny it); `.env.example` names the variables, and `make urls` gives
  the ports. Logs only as `make logs` or `docker compose logs --tail 100 --no-color <service>` —
  never `-f`, which never returns.
- **Destructive steps wait for a yes.** Before anything that deletes containers, volumes, or images,
  name what is lost and how it comes back (the seed command), and wait for the developer. `make reset`
  is `docker compose down -v`. The module's ask rules prompt as well; if `.claude/settings.json`
  doesn't have them, ask in chat anyway.
- **Published ports bind to `127.0.0.1`**, never every interface.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`; in a
   project adopted before v2.0.0, `head -1 CLAUDE.md`). Unless its `modules:` list names `docker`, say
   "the docker module isn't installed in this project — `/adf:upgrade` offers it" and stop.

2. **Check where you are.** If `ops/agent/worktree.conf` (or `scripts/agent/worktree.conf`) exists
   and `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`,
   this is the main checkout of a hub: environments run in worktrees. Say so in a line, read
   nothing more, and run `/adf:dispatch` now with this command, as the developer typed it, as the
   task. Don't ask first: the chip it offers is where the developer chooses.

3. **Read the facts, running nothing yet:** the Compose files (`compose.yaml`, `compose.yml`,
   `docker-compose.y*ml`, and their overrides), the Dockerfiles wherever they are, the `Makefile`,
   `ops/`, `.env.example`, `DEV-SETUP.md`, `AGENTS.md` § Quick reference,
   `.claude/rules/deployment.md`, `.claude/hooks/config.sh`, and `ops/agent/worktree.conf` when the
   project has it. Then `docker version` and `docker compose version`: this skill needs Compose v2
   (`docker compose`, with `--wait`).

4. **Name the mode** in one line — from the argument, or from the situation: no stack yet, or one that
   doesn't meet the specification → set up; parallel worktrees whose stacks collide → worktrees; the
   app on the host, or switching between the two → native; something fails → diagnose; stale or
   broken local data → reset.

## Mode: set up

1. **No stack yet?** Writing one is an infrastructure change — `/adf:triage` it like any change (the
   careful lane at least). Copy the templates in `<this skill's base directory>/templates/` to the
   same paths in the repository — `compose.yaml`, `Makefile`, `.env.example`, `ops/docker/`, and
   `ops/native/` — never over a file that's there. Then fill every `CUSTOMIZE` from facts you
   verified, so the result meets the specification for this project:
   - the app's service, its container port, its Dockerfile, and its dev command;
   - each backing service the code uses (its client library, the variable its URL comes from),
     pinned, with a healthcheck the app's `depends_on` waits on;
   - every variable the code reads: by name in `.env.example`, and in container form in its
     service's `environment:` — a credential as `${NAME:-}`, passed through from `.env`;
   - in the `Makefile`: `APP`, `PORTS`, and `DEFAULT_MODE` (`docker` unless the team runs the app on
     the host);
   - in each mode's file, its own commands: `ops/docker/Makefile`'s `test` and `lint` in the app's container;
     `ops/native/Makefile`'s `SERVICES` (the backing services that stay in Docker), `NATIVE_CMD` (the app's dev
     command, listening on `$APP_PORT`), and its `build` (installing dependencies on the host),
     `test`, and `lint`. Each from the project's package manifest, README, or docs — never a guess at
     the stack. A project that never runs natively keeps `ops/native/Makefile` as the template wrote it.

   Then `chmod +x ops/docker/ports.sh ops/native/native.sh`, and make sure `.gitignore` has `.env`
   and `ops/native/.run/`.
2. **A stack that doesn't meet the specification?** Audit it in the order its § Conformance gives,
   and show the gaps in one table — the requirement's ID, what the project has, the change. A
   departure `.claude/rules/deployment.md` records with its reason is an exception, not a gap. The
   usual ones:
   - a Compose file away from the root, or under a legacy name;
   - Dockerfiles, service config, or scripts outside `ops/`, or in `ops/` by kind of file
     (`ops/scripts/`, `ops/make/`) rather than in their target's folder;
   - no `Makefile`, or one without the tasks;
   - `env_file:`, or a variable the code reads that no `environment:` passes;
   - a `${VAR}` that `.env.example` doesn't declare — a gap to report, not to fill with a guess;
   - a fixed host port, or one bound to every interface;
   - `container_name:` or a top-level `name:`;
   - a service another one waits for without a healthcheck and `condition: service_healthy`;
   - no `DEV_MODE`: a `Makefile` with its own `native` or `dev` targets beside the Docker ones, which
     the two mode files replace.

   The migration is an infrastructure change: propose it through `/adf:triage` (the careful lane),
   and move nothing before the developer approves. It moves files with `git mv`, adds the template's
   tasks to an existing `Makefile` without renaming the team's own, and updates whatever names the
   old paths — CI, docs, scripts.
3. **Start it:** `make env` — it creates `.env` from `.env.example` and names the credentials for the
   developer to fill in — then `docker compose config --quiet`, and `make up`, which waits until
   every service is healthy and prints where each one is. `make ps`: every service is running, and
   healthy where it has a check. After a Dockerfile change, `make build` first.
4. **Verify it works:** `curl -fsS` on the app's URL from `make urls` (its health route or home page),
   and the project's quickest test that needs the stack passes against it. With a dev command for the
   host, Mode: native too, in the mode the project doesn't default to.
5. **Write down what you verified** — a docs change, so it goes through triage too:
   - `DEV-SETUP.md`: the Docker row of Prerequisites, § 3 `make env`, § 4 `make up` and `make urls`
     with the services, § 6 the two modes — `DEV_MODE` in `.env`, and what native mode needs on the
     host — and the command surface;
   - `AGENTS.md` § Quick reference: `make up` and `make down`, and `make urls` for where the app is;
   - `.claude/hooks/config.sh`: `LOCAL_URL='http://localhost:${APP_PORT}'`, and `LOCAL_SERVICE` — the
     app's service and container port, `web:3000` — so the band above the prompt looks up the port
     Docker picked;
   - `deployment.md`: `paths:` naming `compose.yaml`, `Makefile`, `ops/**`, and `.env.example`, and in
     § Docker any convention the project adds.

   § Troubleshooting gets only problems you actually met. For example, the newsletter site: `web`
   (the Next.js app, on container port 3000) and `redis` (the signup rate limiter), started with
   `make up`, found with `make urls`.

## Mode: worktrees

Needs the parallel-agents module (`ops/agent/worktree.conf`, or `scripts/agent/worktree.conf`
before it moved); without it, say so and stop.

1. **Audit isolation (W1–W3).** A stack that meets the specification already runs once per
   worktree: the worktree's folder names its Compose project, and Docker picks its ports. What breaks that: a
   top-level `name:`, a `container_name:`, a fixed host port in `compose.yaml` — set up's migration
   fixes those — or a port or `COMPOSE_PROJECT_NAME` the main checkout's `.env` pins, which every
   worktree's copy repeats.
2. **Propose the `worktree.conf` change** — an infrastructure change the developer approves:
   - `PORT_SLOTS=0` — the ports are Docker's, so the scripts reserve none;
   - `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'`, plus an empty `<NAME>_PORT=` line for each
     port the main checkout pins — each worktree's project gets a clear name, and its ports stay
     Docker's;
   - `START_CMD="make up"` — in the worktree's mode, which its `.env` sets — and
     `STOP_CMD="ops/native/native.sh stop; docker compose down -v"`: it stops an app running on the
     host, then removes only this worktree's project, since its `COMPOSE_PROJECT_NAME` is that
     worktree's. `make down` instead keeps data that's costly to rebuild;
   - `READY_URL` empty: `make up` already waits until every service is healthy, or the app on the
     host answers;
   - `ENV_INFO_CMD="make urls"`, so `adf-worktree-ls --info` shows where each worktree's services are;
   - `.env` in `.worktreeinclude` when it holds what the stack needs.
3. **Verify in a worktree:** `adf-worktree-new <branch>` starts it; `docker compose ls` shows its
   project beside another worktree's; `adf-worktree-ls --info` shows each one's ports; the app
   answers on its own. A worktree whose `.env` repeats the main checkout's pinned values stops at
   `make up`, naming the lines to empty.
4. **Record** in `docs/PARALLEL-AGENTS.md` § Shared services what worktrees share, what each one
   copies, and what a copy costs.

## Mode: native

Where the app runs is a setting, not a different command. The root `Makefile` loads
`ops/<DEV_MODE>/Makefile`: `ops/docker/Makefile` runs the whole stack in Docker; `ops/native/Makefile` runs the app on the
host with the stack's own dev command, its backing services in Docker. Both define the same tasks.

1. **Choose the mode.** The project's default is `DEFAULT_MODE` in the `Makefile`, a change to the
   stack that goes through triage. A checkout's own choice is `DEV_MODE` in its `.env` — the
   developer's file, which they edit; never read it into the conversation. A single command can
   override both: `make up DEV_MODE=native`. `make help` names the mode and the file in force.
2. **What native mode needs,** in `ops/native/Makefile`:
   - `NATIVE_CMD` — the app's dev command, listening on `$APP_PORT` — and the `build`, `test`, and
     `lint` commands on the host, from the package manifest, the README, or the project's docs.
     Setting them is a change to the stack, through triage.
   - `SERVICES` — the backing services that stay in Docker. A developer who runs one on the host
     pins its `<NAME>_PORT` in `.env`; with nothing in Docker on that port, the app gets the pinned
     one. Empty `SERVICES`: native mode needs no Docker at all.
   - The stack's runtime on the host, at the version the project pins — a prerequisite row in
     `DEV-SETUP.md`.
   - The host-form variables in `.env` use the exported ports
     (`REDIS_URL=redis://localhost:${REDIS_PORT}`). For a stack whose env loader doesn't expand
     `${…}`, `NATIVE_CMD` passes them itself.
3. **Start it:** `make up` starts the backing services in Docker, stops the app's container if it
   runs, and starts the app in the background (`ops/native/native.sh`), with each `<NAME>_PORT`
   exported — `APP_PORT` too: pinned in `.env`, or a free one. It waits until the app answers, and
   fails with the end of its log if the app exits first. `make down` stops the app and its process
   group; `make logs` shows its log.
4. **Switching modes** needs no cleanup: `make up` in Docker mode stops an app running on the host,
   and native `make up` stops the app's container.
5. **Verify:** `make ps` shows the app on the host and only the backing services in Docker; the app
   answers on the URL `make urls` gives; the quickest test that needs the stack passes with
   `make test`. The band above the prompt reads the app's port from `ops/native/.run/app.env`.

## Mode: diagnose

`/adf:debug`'s order, applied to the environment.

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

## Mode: reset

Take the smallest step that works, and re-run the signal after each:

1. `docker compose restart <service>`
2. `docker compose up -d --force-recreate <service>`
3. `make build`, then `make up`
4. `make down`, then `make up` — containers go, volumes stay
5. `make reset` — `docker compose down -v`, then `make up` — **last, and only after** listing this
   project's volumes (`docker volume ls --filter label=com.docker.compose.project=<project>`), naming
   the data each one holds and how it comes back, and the developer's yes.

Then run the migrations and the seed the way `DEV-SETUP.md` says, and re-run the signal. Never prune
machine-wide, never touch a shared service (`docs/PARALLEL-AGENTS.md` § Shared services), and never
reset in the main checkout of a hub.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "`docker system prune -af` will clear it up" | It removes every project's stopped containers, unused images, and networks — other worktrees' and other repositories' included. Reset this project, smallest step first. |
| "Let me print `docker compose config` to see what's wrong" | It prints every resolved secret into the conversation. `--quiet` validates; `--services` lists. |
| "I'll read `.env` to see which mode this checkout uses" | `.env` holds credentials. `make help` names the mode in force. |
| "I'll add `make dev` for the native run" | Each mode's file defines the same tasks, so agents and worktrees never need to know which mode a developer chose. A task only one mode has goes in that mode's file. |
| "I'll read `.env` to find the port" | `.env` holds credentials, and a port Docker picked isn't in it at all. `make urls` looks it up. |
| "I'll start the stack now so it's ready" | Whether the task needs an environment is triage's call. Reading code and docs needs none. |
| "Port 3000 is taken — I'll kill whatever holds it" | It may be another worktree's stack or the developer's own process. Find the owner, report it, and ask. |
| "`3000:3000` is simpler — everyone knows the port" | Only one stack can hold it, so a second worktree's fails to start. Docker picks a free port and `make urls` shows it; a developer who wants a fixed one pins it in their `.env`. |
| "A fixed `container_name` makes it predictable" | It makes a second worktree's stack fail to start. The checkout's folder names the project. |
| "`env_file: .env` passes everything at once" | Every container gets every variable, credentials included, and nothing says which service needs what. Each service's `environment:` names what it gets. |
| "`make reset` will fix the migration error" | It's `docker compose down -v`: it deletes the data. It's the last step, not the first; find the cause, and reset only as far as it needs. |
| "It started on the second try, so it's fixed" | A retry that works hides a race — usually a missing healthcheck or `depends_on` condition. Find why the first one failed. |

## Red flags (stop and reassess)

- You're in the main checkout of a hub
- A command names no project but would touch every project
- You're following logs, or about to read `.env` or a resolved config
- You're about to publish a fixed host port, or one on every interface
- You're editing `compose.yaml`, the `Makefile`, or `ops/` before triage
- The fix you're about to run deletes something, and the developer hasn't said yes

## Verification

- [ ] The module check and the hub check ran before anything else
- [ ] The stack meets the specification, or its gaps — each by requirement ID — went to the developer as a careful-lane change
- [ ] Every fact written down traces to a command run in this session
- [ ] No secret was printed: no unfiltered `config`, no `inspect` of the environment, no `.env`
- [ ] Every destructive step was scoped to this project, named what it removed, and had the developer's yes
- [ ] `make urls` shows each published service, answering
- [ ] With parallel-agents: two worktrees' stacks run side by side, each under its own project and ports
- [ ] With a dev command for the host: in native mode `make up` answers on the URL `make urls` gives, with only the backing services in Docker, and `make down` stops it
- [ ] After a fix or a reset, the failing signal passes

## Principles

- Signal first. A command that fails on the problem turns guessing into checking.
- This project only. The machine's Docker is shared with everything else the developer runs.
- Ports are looked up, never written down: Docker picks them, and `make urls` says where they are.
- Write down only what you verified — an unverified command in `DEV-SETUP.md` is a trap for the next person.
- The smallest reset that works.
