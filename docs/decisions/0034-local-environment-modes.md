# 0034: The local environment runs in Docker or natively, and `ops/` has one folder per target

- **Status:** accepted
- **Date:** 2026-10-10
- **Amends:** [0032](0032-local-environment-layout.md) — point 2, how `ops/` is organized; point 3,
  the command surface; point 6, the native path; and point 7, where the band finds the app's port

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

Decision 0032 also organized `ops/` by kind of file: images in `ops/docker/<service>/`, scripts in
`ops/scripts/`, and, in the first version here, make files in `ops/make/`. The native mode was spread
over three folders, and a project adding a deployment target such as Vercel or ECS had no place for
it that kept its files together.

The framework is stack-agnostic, so the native run can't know how to start any particular app. It
can only run the command the project gives it.

## Decision

1. **`ops/` has one folder per target,** and each target keeps everything it needs there — its make
   file, scripts, images, and config:
   - `ops/docker/`: `docker.mk`, `ports.sh`, and each service's image and config in
     `ops/docker/<service>/`;
   - `ops/native/`: `native.mk`, `native.sh`, and `.run/`, which git ignores;
   - `ops/agent/`: the parallel-agents module (0032, point 8);
   - any deployment target the project adds, such as `ops/vercel/` or `ops/ecs/`. The framework
     ships none: it stays provider-agnostic, and `deployment.md` holds the convention.

   Targets may use each other's files: native's backing services run in Docker, so `native.sh` asks
   `ops/docker/ports.sh` for their ports, and an ECS deployment builds the image in `ops/docker/web/`.
   Nothing goes in a shared `scripts/` or `make/` folder. A file a tool reads from a fixed place
   stays there: `compose.yaml` at the root (0032), `vercel.json`, `.github/`.
2. **One make file per local mode.** The root `Makefile` holds what both modes share: the settings,
   choosing the mode, `help`, `env`, and the worktree guard. It then loads `ops/<mode>/<mode>.mk`:
   `ops/docker/docker.mk` runs the whole stack in Docker, and `ops/native/native.mk` runs the app on
   the host against its backing services in Docker. A target folder with `<name>.mk` is a local mode;
   a deployment target has none, so `DEV_MODE` can't pick it.
3. **A setting picks the file:** `DEV_MODE`. Whichever is set first wins: the command line
   (`make up DEV_MODE=native`), then the shell, then the checkout's `.env`, then `DEFAULT_MODE` in the
   `Makefile`. A mode with no file stops `make` with a message. A project can add a mode by adding a
   file. `make help` names the mode and its file, and lists that file's tasks.
4. **The same tasks in each file:** `up`, `down`, `build`, `ps`, `logs`, `urls`, `test`, `lint`, and
   `reset`, plus `shell` in Docker mode and `services` in native mode. People, agents,
   `AGENTS.md` § Quick reference, and `worktree.conf` type the same commands in either mode. Each
   file holds its own commands inline: the tests in the app's container, or on the host.
5. **Native `make up` runs the app in the background.** `NATIVE_CMD` in `native.mk` is the stack's
   own dev command, listening on `$APP_PORT`. `ops/native/native.sh` starts it in a process group
   of its own with every `<NAME>_PORT` exported, then waits until `APP_PORT` answers. If the app
   exits first, it fails and shows the end of the log. `make down` stops the whole group. The app's
   process, port, and log stay in `ops/native/.run/`, which git and the Docker build ignore.
   `make native` goes: the mode replaces it.
6. **Switching modes needs no cleanup.** Docker-mode `make up` stops an app running on the host, and
   native `make up` stops the app's container.
7. **A developer's own services need no setting.** `SERVICES` in `native.mk` lists the backing
   services that stay in Docker; empty, native mode needs no Docker at all. A developer who runs one
   on the host pins its `<NAME>_PORT` in `.env`. When nothing in Docker publishes it, `ports.sh`
   gives the app that port, and `make urls` shows the service on the host.
8. **The band reads the native app's port** from `ops/native/.run/app.env` when `.env` pins none.
   That's a file read, which 0026 allows, and it comes before 0032's Docker lookup.
9. **Worktrees** keep `START_CMD="make up"`, which loads the worktree's own mode. `/dev-env
   worktrees` proposes `STOP_CMD="ops/native/native.sh stop; docker compose down -v"`.

10. **A specification is the source, and the templates are an example of it.**
    `plugins/adf-dev/skills/dev-env/SPECIFICATION.md` states every requirement above, and 0032's that
    still hold, each with an ID (`L1`, `C3`, `M7`, …), a table of where each fact lives, and the order
    an audit checks them in. It sits beside the skill, so it travels with it in both installs: a
    packaged project reads it in the plugin, and a committed one gets it in `.claude/skills/dev-env/`.
    `/dev-env` writes a stack to it and audits one against it, naming gaps by ID; `/adf:adopt` and
    `/adf:upgrade` hand a project to `/dev-env` rather than copy the templates. A project records each
    requirement it departs from on purpose, by ID and with the reason, in `deployment.md`
    § Conformance. The static check reads the tasks every mode must define from the specification
    and asserts the templates define them.

## Consequences

- **Positive:**
  - A developer or a whole team works natively with the commands everyone else types, and an agent
    never needs to know which mode a checkout uses.
  - Each mode reads as plain make: one recipe per task, no conditionals.
  - Adding or dropping a target is adding or deleting one folder, and a reader finds all of a
    target's files in one place.
  - A worktree can run natively with its own port, since `make up` returns once the app answers.
- **Negative / cost:**
  - **Two files keep the same task names.** The static check asserts that both define the full
    set.
  - **The `Makefile` reads one name from `.env`:** `DEV_MODE`, and nothing else.
  - **A background process outlives the terminal that started it.** `make down` stops it. A machine
    restart leaves a stale `ops/native/.run/app.env`, which the next command notices and removes.
  - **Native mode trusts the host:** the runtime and its version are each developer's.
    `DEV-SETUP.md` names them.

## Alternatives considered

- **The conventions in the skill's text and the templates only,** as 0032 had them. Replaced: an
  adopting agent copied the templates' shape, the example's service names included, and an audit
  had no way to say which rule a gap broke.
- **The specification in the plugin's `docs/`,** like `adf`'s reference docs. Declined: a committed
  install would write it into the project's own `docs/`, beside the project's setup guide, while
  beside the skill it travels with the skill and its templates.
- **`ops/` by kind of file** (`ops/scripts/`, `ops/make/`, `ops/docker/<service>/`), as 0032 had it.
  Replaced: one target's files sat in three folders, and a new target had nowhere of its own.
- **Calling the layout Domain-Driven Design.** Declined as a name, kept as a principle: DDD models the
  business domain, in the app's code (`architecture.md`); infrastructure targets aren't domains. The
  idea borrowed is cohesion by context rather than by layer.

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
