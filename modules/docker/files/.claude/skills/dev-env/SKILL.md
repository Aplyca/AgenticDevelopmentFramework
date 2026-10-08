---
name: dev-env
description: Set up, connect, diagnose, or safely reset this project's Docker Compose local environment — verified commands written down for people and agents, one stack per worktree with the parallel-agents module, a failing signal before any fix, and nothing deleted beyond this project's own containers and volumes without the developer's yes. Use when the next step needs the app running and there's no working stack, when the stack won't start or misbehaves, before the local check, or to reset local data.
argument-hint: "[set up | worktrees | diagnose <symptom> | reset]"
---

# Development environment (Docker Compose)

The local environment is where the change runs before anyone else sees it: the tests that need a
database, and the developer's **local check** before the draft pull request (`AGENTS.md` § Delivery
rules). This skill gets a Compose stack to that point and keeps it there. It doesn't decide *whether*
a task needs an environment — triage does (`AGENTS.md` § How work flows → Environment).

Each fact has one home, and this skill writes only what a command it ran has shown:

| Fact | Lives in |
|---|---|
| How a person sets up and starts the stack, its services and ports, problems met before | `docs/getting-started/DEV-SETUP.md` (§ 4, the command surface, § Troubleshooting) |
| The start and stop commands an agent runs | `AGENTS.md` § Quick reference |
| Compose and Dockerfile conventions | `.claude/rules/deployment.md` § Docker |
| What each worktree starts, stops, and is told | `scripts/agent/worktree.conf` (parallel-agents) |
| The procedure | this skill |

## Safety (always)

- **This project only.** Every command is scoped to this checkout's Compose project. Never prune or
  remove anything machine-wide — other projects and other worktrees' stacks live on the same Docker.
- **No secrets in the conversation.** Never run `docker compose config` without `--quiet` or
  `--services`, and never `docker inspect` a container's environment: both print resolved secrets.
  Never read `.env` (the settings deny it); `.env.example` names the variables. Logs only as
  `docker compose logs --tail 100 --no-color <service>` — never `-f`, which never returns.
- **Destructive steps wait for a yes.** Before anything that deletes containers, volumes, or images,
  name what is lost and how it comes back (the seed command), and wait for the developer. The
  module's ask rules prompt as well; if `.claude/settings.json` doesn't have them, ask in chat anyway.
- **Published ports bind to `127.0.0.1`**, never every interface.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`; in a
   project adopted before v2.0.0, `head -1 CLAUDE.md`). Unless its `modules:` list names `docker`, say
   "the docker module isn't installed in this project — `/adf:upgrade` offers it" and stop.

2. **Check where you are.** If `scripts/agent/worktree-new.sh` exists and `git rev-parse --git-dir`
   equals `git rev-parse --git-common-dir`, this is the main checkout of a hub: environments run in
   worktrees. Say so, point to `/dispatch`, and stop.

3. **Read the facts, running nothing yet:** the Compose files (`compose.yaml`, `compose.yml`,
   `docker-compose.y*ml`, and their overrides), the Dockerfiles, `.env.example`, `DEV-SETUP.md`,
   `AGENTS.md` § Quick reference, `.claude/rules/deployment.md`, and `scripts/agent/worktree.conf` when
   the project has it. Then `docker version` and `docker compose version`: this skill needs Compose
   v2 (`docker compose`, with `--wait`).

4. **Name the mode** in one line — from the argument, or from the situation: no stack yet → set up;
   parallel worktrees whose stacks collide → worktrees; something fails → diagnose; stale or broken
   local data → reset.

## Mode: set up

1. **No Compose file yet?** Writing one is an infrastructure change — `/triage` it like any change
   (the careful lane at least). Draft it to the project's conventions in `deployment.md` § Docker and
   these: pinned image tags; a healthcheck on every service another one waits for, and
   `depends_on: { <service>: { condition: service_healthy } }`; host ports from the env file, bound to
   `127.0.0.1` (`"127.0.0.1:${APP_PORT:-3000}:3000"`); no `container_name` and no top-level `name:`
   (both stop two stacks from running side by side); named volumes for data; secrets only from the
   untracked env file, every variable declared in `.env.example` without a real value.
2. **A Compose file exists:** `docker compose config --quiet` must pass. Check that every `${VAR}` it
   uses is declared in `.env.example`; an undeclared one is a gap to report, not to fill with a guess.
3. **Start it:** `docker compose up -d --wait` (`--build` the first time, or after a Dockerfile
   change), then `docker compose ps`. Every service is running, and healthy where it has a check.
4. **Verify it works:** the app answers (`curl -fsS <url>` on its health route or home page), and
   the project's quickest test that needs the stack passes against it.
5. **Write down what you verified** — a docs change, so it goes through triage too: in `DEV-SETUP.md`,
   the Docker row of Prerequisites, § 4's command and the services with their ports, and the command
   surface; in `AGENTS.md` § Quick reference, the start and stop lines; in `deployment.md`, `paths:`
   naming the project's Compose and Docker files. § Troubleshooting gets only problems you actually
   met. For example, the newsletter site: `web` (the Next.js app on `APP_PORT`) and `redis` (the
   signup rate limiter), started with `docker compose up -d --wait`.

## Mode: worktrees

Needs the parallel-agents module (`scripts/agent/worktree.conf`); without it, say so and stop.

1. **Audit isolation.** Each of these makes two worktrees' stacks collide: a top-level `name:`, a
   `container_name:`, a fixed host port. Publish only what a person opens — the app, on
   `"127.0.0.1:${APP_PORT:-3000}:3000"` — and leave backing services unpublished, or publish them on
   a random port (`"127.0.0.1::6379"`) that `docker compose port <service> <port>` reports.
2. **Propose the `worktree.conf` change** — an infrastructure change the developer approves:
   - `PORT_SLOTS` (e.g. `180`) so each worktree gets an `APP_PORT`;
   - `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'`, plus the app's own URL when it needs one —
     the project name keeps each worktree's containers, networks, and volumes apart;
   - `START_CMD="docker compose up -d --wait"` and `READY_URL='http://localhost:${APP_PORT}'`;
   - `STOP_CMD="docker compose down -v"` — it removes only this worktree's project, since
     `COMPOSE_PROJECT_NAME` is that worktree's; use `docker compose down` instead to keep data that's
     costly to rebuild;
   - the env file in `.worktreeinclude` when it holds what the stack needs.
3. **Verify in a worktree:** `scripts/agent/worktree-new.sh <branch>` starts it; `docker compose ls`
   shows its project beside another worktree's; `scripts/agent/worktree-ls.sh` shows its port; the app
   answers on that port.
4. **Record** in `docs/PARALLEL-AGENTS.md` § Shared services what worktrees share, what each one
   copies, and what a copy costs.

## Mode: diagnose

`/debug`'s order, applied to the environment.

1. **Get a failing signal** — one command that fails on this problem: `docker compose up -d --wait`,
   the state and health in `docker compose ps`, or `curl -fsS <url>`. Show the command and its output,
   trimmed, with secrets replaced by `<REDACTED>`.
2. **Check the simple things, roughly in order:** the Docker daemon isn't running (`docker info`); the
   port is taken — find its owner with `docker ps --filter publish=<port>` or `lsof -i :<port>`: it may
   be another worktree's stack or the developer's own process, so never stop it unasked; a "variable
   is not set" warning; a stale image (`--build`); an unhealthy dependency
   (`docker compose logs --tail 100 --no-color <service>`, its healthcheck); a volume holding an older
   schema (migrations or seed); another project's stack answering (a top-level `name:`, or the wrong
   `COMPOSE_PROJECT_NAME`); a platform mismatch on Apple silicon; a full disk (`docker system df`).
3. **Rank 3–5 hypotheses** when the simple things don't explain it, each with what would prove it
   wrong, and test them one at a time.
4. **The cause is in the application, not the environment?** Hand over to `/debug` with the signal.
5. **Fix:** a local step that touches only this project — start the daemon, restart this stack — just
   do it and say so. Stopping or removing anything that isn't this project's waits for a yes. A change
   to a Compose file or a Dockerfile goes through `/triage` (infrastructure: the careful lane).
6. **Report:** symptom, signal, cause, ruled out, fix, and how to verify. When the next person would
   hit the same thing, add it to `DEV-SETUP.md` § Troubleshooting.

## Mode: reset

Take the smallest step that works, and re-run the signal after each:

1. `docker compose restart <service>`
2. `docker compose up -d --force-recreate <service>`
3. `docker compose up -d --build`
4. `docker compose down`, then `up -d --wait` — containers go, volumes stay
5. `docker compose down -v` — **last, and only after** listing this project's volumes
   (`docker volume ls --filter label=com.docker.compose.project=<project>`), naming the data each one
   holds and how it comes back, and the developer's yes.

Then run the migrations and the seed the way `DEV-SETUP.md` says, and re-run the signal. Never prune
machine-wide, never touch a shared service (`docs/PARALLEL-AGENTS.md` § Shared services), and never
reset in the main checkout of a hub.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "`docker system prune -af` will clear it up" | It removes every project's stopped containers, unused images, and networks — other worktrees' and other repositories' included. Reset this project, smallest step first. |
| "Let me print `docker compose config` to see what's wrong" | It prints every resolved secret into the conversation. `--quiet` validates; `--services` lists. |
| "I'll start the stack now so it's ready" | Whether the task needs an environment is triage's call. Reading code and docs needs none. |
| "Port 3000 is taken — I'll kill whatever holds it" | It may be another worktree's stack or the developer's own process. Find the owner, report it, and ask. |
| "A fixed `container_name` and port make it predictable" | They make a second worktree's stack fail to start. Predictability comes from `COMPOSE_PROJECT_NAME` and `APP_PORT`. |
| "`down -v` will fix the migration error" | It's the last step, not the first, and it deletes data. Find the cause; reset only as far as it needs. |
| "It started on the second try, so it's fixed" | A retry that works hides a race — usually a missing healthcheck or `depends_on` condition. Find why the first one failed. |

## Red flags (stop and reassess)

- You're in the main checkout of a hub
- A command names no project but would touch every project
- You're following logs, or about to read `.env` or a resolved config
- You're editing a Compose file or a Dockerfile before triage
- The fix you're about to run deletes something, and the developer hasn't said yes

## Verification

- [ ] The module check and the hub check ran before anything else
- [ ] Every fact written down traces to a command run in this session
- [ ] No secret was printed: no unfiltered `config`, no `inspect` of the environment, no `.env`
- [ ] Every destructive step was scoped to this project, named what it removed, and had the developer's yes
- [ ] With parallel-agents: two worktrees' stacks run side by side, each under its own project and port
- [ ] After a fix or a reset, the failing signal passes

## Principles

- Signal first. A command that fails on the problem turns guessing into checking.
- This project only. The machine's Docker is shared with everything else the developer runs.
- Write down only what you verified — an unverified command in `DEV-SETUP.md` is a trap for the next person.
- The smallest reset that works.
