# Module: docker

For projects whose local environment runs on Docker Compose. Adds `/dev-env`, which writes the stack
from its templates — or moves an existing one to the conventions below — runs the app natively when
the developer prefers, gives each worktree a stack of its own when the project runs agents in
parallel, diagnoses a stack that won't start the way `/debug` diagnoses a bug, and resets one without
touching anything else on the machine. Read-only docker commands run without a prompt; every command
that deletes containers, volumes, or images asks first.

## The conventions

[Decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md):

- **Docker Compose, with `compose.yaml` at the root.** The root holds only it, the `Makefile`, `.env`
  (untracked), and `.env.example`.
- **Operational code in `ops/`, one folder per target:** `ops/docker/` (its make file, `ports.sh`,
  and each service's image and config in `ops/docker/<service>/`), `ops/native/` (its make file and
  `native.sh`), the parallel-agents module in `ops/agent/`, and any deployment target the project
  adds, such as `ops/vercel/` or `ops/ecs/`. A file a tool reads from a fixed place stays there.
- **A `Makefile` for the common tasks** — `make help` lists them: `env`, `up`, `down`, `build`, `ps`,
  `logs`, `urls`, `test`, `lint`, `reset`.
- **One file per mode:** the root `Makefile` loads `ops/docker/docker.mk` or `ops/native/native.mk` —
  the app in Docker, or on the host against the backing services in Docker — by `DEV_MODE` in `.env`
  or the project's `DEFAULT_MODE`. Both define the same tasks
  ([decision 0034](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0034-local-environment-modes.md)).
- **Three levels of variables:** `.env` at the root, which Compose reads to fill each `${…}`; each
  service's `environment:` in `compose.yaml`, in container form; and `.env.example`, committed, naming
  them all. No `env_file:`.
- **Ports Docker picks:** `"127.0.0.1:${<NAME>_PORT:-}:<port>"`, empty in `.env.example`. Any number of
  checkouts and worktrees run side by side; `make urls` shows where each service is, and a developer
  pins a port in `.env` when the app must know its own URL.

## What it adds

| File | Purpose |
|---|---|
| `.claude/settings.json` (merged) | `permissions.allow` for read-only commands (`docker compose ps`, `logs`, `port`, `ls`, `config --quiet`, `docker ps`, `volume ls`, `system df`, and exactly `make help`, `make ps`, `make urls`, `make logs`); `permissions.ask` for destructive ones (`compose down -v` or `--rmi`, `compose rm`, `docker rm`, `rmi`, `volume rm`, every `prune`, and any `make` command that names `reset`). An ask rule wins over any allow rule, so a broad `Bash(docker *)` the project already has can't skip the prompt |
| `.claude/skills/dev-env/` | **Committed install only:** the skill and its `templates/`. A packaged project gets `/adf-dev:dev-env` from the development plugin, `adf-dev`, which `module.json` names ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)) |

The module copies no files into the project. `/dev-env set up` writes the stack from the skill's
templates — `compose.yaml`, the `Makefile`, `.env.example`, and two target folders:
`ops/docker/` (`docker.mk`; `ports.sh`, which looks up the ports Docker picked; and
`web/Dockerfile` with its `.dockerignore`) and `ops/native/` (`native.mk`, and `native.sh`, which
starts and stops the app on the host) — and fills in what it verifies about the project. No rule of its own: the conventions live in the skeleton's
`.claude/rules/deployment.md` § Docker, which `/dev-env` keeps pointed at the project's files.

## Install

`/adopt` and `/upgrade` install it when you choose the module. By hand:

- **Committed install:** `scripts/build-committed.py /path/to/your-repo --modules docker`, which writes
  `/dev-env` and its templates from the `adf-dev` plugin, then `modules/docker/install.sh /path/to/your-repo`.
- **Packaged install:** run `modules/docker/install.sh /path/to/your-repo`, and turn the plugin on in `.claude/settings.json`
  beside `adf` — `"adf-dev@aplyca": true` in `enabledPlugins`, and
  `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`.

`install.sh` merges into `.claude/settings.json`: it keeps your rules and their order, adds only
what's missing, and is safe to run again — `/upgrade` reruns it to pick up new rules.

Then add `docker` to the `modules:` list in the stamp on `AGENTS.md`'s first line: `/dev-env` stops
in a project whose stamp doesn't name it.

## Customize

Run `/dev-env set up` (packaged: `/adf-dev:dev-env set up`) once the module is in. It writes the stack
or proposes moving the existing one to the conventions — a careful-lane change you approve — and
fills these from what it verifies, for you to review:

1. **`docs/getting-started/DEV-SETUP.md`** — the Docker prerequisite, § 3 `make env`, § 4 `make up` and
   `make urls` with the services, § 6 the two modes, the command surface, and § Troubleshooting for
   problems actually met. Packaged: `/adf-dev:dev-env` joins the key commands under § AI-assisted
   development.
2. **`AGENTS.md` § Quick reference** — `make up`, `make down`, and `make urls`; the local check before
   the pull request starts the stack from there.
   **`.claude/hooks/config.sh`** — `LOCAL_URL='http://localhost:${APP_PORT}'`, and `LOCAL_SERVICE`, the
   app's service and container port (`web:3000`): `adf-dev`'s band above the prompt looks up the port
   Docker picked with `docker compose port` (decision 0032).
3. **`.claude/rules/deployment.md`** — `paths:` names `compose.yaml`, the `Makefile`, `ops/**`, and
   `.env.example`, and § Docker holds any convention the project adds.
4. **With `parallel-agents`** — `/dev-env worktrees` proposes the `worktree.conf` values that give
   each worktree its own stack (`PORT_SLOTS=0`, `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'`,
   `START_CMD="make up"`, `STOP_CMD`, `ENV_INFO_CMD="make urls"`), and records what worktrees share in
   `docs/PARALLEL-AGENTS.md`.

## Good to know

- **A port Docker picked changes** each time its service starts. `make urls` and the band always show
  the current one; pin it in `.env` when something outside the app has to know it.
- **The ask rules match what the agent types, not what runs.** A command inside a script — a target
  other than `reset`, a `package.json` script, or `STOP_CMD` when `adf-worktree-rm` runs it — isn't
  seen, and an unusual form (`docker --context x volume rm`) can slip past a pattern. The rules catch
  the commands an agent usually writes; they aren't a security boundary. `/dev-env` also asks in chat
  before anything destructive. The allows trust `help`, `ps`, `urls`, and `logs` to stay read-only:
  keep them that way.
- **In `dontAsk` mode an ask rule denies instead of prompting;** in every other mode, auto and
  bypass included, it prompts.
- **Two commands print secrets:** `docker compose config` without `--quiet` or `--services`, and
  `docker inspect`. Neither is allowed, and `/dev-env` doesn't run them.
- **A committed install carries the templates** under `.claude/skills/dev-env/templates/`, where an
  image or Dockerfile scanner may read them: exclude that folder if it reports them.

## Verify

- `python3 -m json.tool .claude/settings.json` parses, and its `ask` list holds the docker rules.
- In a new session, `/dev-env` (packaged: `/adf-dev:dev-env`) is offered; `docker compose ps` and
  `make urls` run without a prompt; asking the agent to remove the stack's volumes, or to run
  `make reset`, prompts.

## Requirements

Docker Engine or Docker Desktop with Compose v2 (`docker compose`, with `--wait`) and BuildKit, its
default builder; `make` and `bash` 3.2 or later, which macOS and Linux have; `python3` for the install
script.
