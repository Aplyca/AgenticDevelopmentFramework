# Module: docker

For projects whose local environment runs on Docker Compose. Adds `/dev-env`, which writes the stack
to the [local environment specification](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/plugins/adf-dev/skills/dev-env/SPECIFICATION.md) it carries — or audits an existing one against it and
proposes the move — runs the app natively when
the developer prefers, gives each worktree a stack of its own when the project runs agents in
parallel, diagnoses a stack that won't start the way `/debug` diagnoses a bug, and resets one without
touching anything else on the machine. Docker and `make` commands run without a prompt; only `make run` asks, where
it runs on the host.

## The conventions

The [specification](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/plugins/adf-dev/skills/dev-env/SPECIFICATION.md) is the source, each requirement with an ID that an audit names; the
skill's templates are an example that meets it. In short ([decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md),
[0034](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0034-local-environment-modes.md)):

- **Docker Compose, with `compose.yaml` at the root.** The root holds only it, the `Makefile`, `.env`
  (untracked), and `.env.example`.
- **Operational code in `ops/`, one folder per target:** `ops/docker/` (its make file, `guard.sh`,
  and each service's image and config in `ops/docker/<service>/`), `ops/native/` (its make file and
  `native.sh`), the parallel-agents module in `ops/agent/`, and any deployment target the project
  adds, such as `ops/vercel/` or `ops/ecs/`. A file a tool reads from a fixed place stays there.
- **A `Makefile` for the common tasks** — `make help` lists them: `env`, `up`, `down`, `build`, `ps`,
  `logs`, `urls`, `test`, `lint`, `run`, `reset`, and the optional `prod`: the production build, served
  beside the dev server in Docker mode, so no agent builds and serves it on the host
  ([decision 0052](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0052-production-build-in-the-configured-mode.md)).
- **One file per mode:** the root `Makefile` loads `ops/docker/Makefile` or `ops/native/Makefile` —
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
| `.claude/settings.json` (merged) | `permissions.allow` for `docker *` and `make *`: the stack's commands and the project's tasks run without a prompt, and no ask rule names an exception — they act on this project's local stack, whose data comes back from the seed ([decision 0078](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0078-docker-and-make-run-without-a-prompt.md)). `permissions.deny` for what would change the local mode, which only the developer does (M10): a `make` command or a leading assignment that sets `DEV_MODE` or `SERVICES`, an `export` of either, and an edit to `.env`. `make run` has no rule: the `approve-container-run.sh` hook, which the `adf` plugin carries, decides it by the checkout's mode (C10, [decision 0077](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0077-the-container-is-the-boundary-for-make-run.md)) |
| `.claude/skills/dev-env/` | **Committed install only:** the skill, its `SPECIFICATION.md`, and its `templates/`. A packaged project gets `/adf-dev:dev-env` from the development plugin, `adf-dev`, which `module.json` names ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)) |

The module copies no files into the project. `/dev-env set up` writes the stack to the
specification, starting from the skill's templates — `compose.yaml`, the `Makefile`, `.env.example`, and two target folders:
`ops/docker/` (its `Makefile`; `guard.sh`, which keeps a worktree off the main checkout's stack;
`launch-json.sh`, which lists the running web services in Claude Desktop's Browser; and `web/Dockerfile` with
its `.dockerignore`) and `ops/native/` (its `Makefile`, and `native.sh`, which starts and stops the app
on the host) — and fills in what it verifies about the project. No rule of
its own: the skeleton's `.claude/rules/deployment.md` § Docker is the project's copy of the
conventions, and its § Conformance records each requirement the project departs from on purpose.

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
2. **`AGENTS.md` § Quick reference** — `make up`, `make stop` (keeps containers and data),
   `make down` (removes containers; data stays), and `make urls`, and `make prod` for
   the production build (or "none"); the local check before the pull request starts the stack from
   there.
   **`.claude/hooks/config.sh`** — `LOCAL_URL='http://localhost:${APP_PORT}'`.
3. **`.claude/rules/deployment.md`** — `paths:` names `compose.yaml`, the `Makefile`, `ops/**`, and
   `.env.example`, and § Docker holds any convention the project adds.
4. **With `parallel-agents`** — `/dev-env worktrees` proposes the `worktree.conf` values that give
   each worktree its own stack (`PORT_SLOTS=0`, `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'`,
   `START_CMD="make up"`, `STOP_CMD`, `ENV_INFO_CMD="make urls"`), and records what worktrees share in
   `docs/SHARED-SERVICES.md`.

## Good to know

- **Stop, down, and remove are different states** (the specification's C12): `make stop` frees
  memory and CPU and keeps everything — the agent runs it once its pull request is ready; `make down`
  removes the containers and keeps the data — `/wrap-up` runs it after the merge; `make reset`
  removes the data too, on the developer's yes in chat. There's no pause or kill task: a pause frees no memory, and
  a kill can lose a database's unsaved writes.
- **A port Docker picked changes** each time its service starts. `make urls` and Claude Desktop's Browser always show
  the current one; pin it in `.env` when something outside the app has to know it.
- **Claude Desktop's Browser lists the running web services** on a new tab, one row each —
  `web · http://localhost:55123` — and one click opens it. A service is listed when `compose.yaml`
  labels it `claude.browser: "true"`: the template labels the app and its production build. `make up`,
  `make prod`, `make stop`, and `make down` keep the rows in `.claude/launch.json` matching what runs
  ([decision 0056](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0056-the-running-app-in-claude-desktops-browser.md)).
  The file is each checkout's own, so git ignores it, and nothing is written where it doesn't. The
  developer's own entries stay.
- **No docker or make command prompts.** That includes what deletes this stack's data
  (`make reset`, `docker compose down -v`), `docker push`, `docker run` with any mount, and a prune,
  which reaches other projects' stopped containers and unused images. What holds an agent back is
  instruction: `/dev-env` and `AGENTS.md` say it removes data only on the developer's yes in chat,
  touches this project only, and never prints a resolved config. A team that wants a prompt for one
  of them adds its own rule to `permissions.ask`; an ask rule wins over the allow. `/dev-env` adds
  one for a project's own task that runs a command it's given on the host (C10). `Bash(make *)`
  trusts the project's Makefile, so review a Makefile change as code that runs without a prompt.
- **`make run cmd='<command>'` runs any command in the app's container, with no prompt, in Docker
  mode;** in native mode it runs on the host and asks. A hook decides, since a rule can't read the
  mode: it approves the call written on its own, with nothing the host's shell or `make` would
  expand — a `$` for the container is written `$$`, in single quotes — and a `run` task that hands
  the command to Compose as one argument. Anything else asks. The container keeps a command off the
  host outside the checkout. It doesn't protect the checkout, the stack's local data, or the
  credentials in `.env`, which a command inside can read and use: keep production credentials out
  of `.env`. `APPROVE_CONTAINER_RUN=""` in `.claude/hooks/config.sh` asks in every mode — set it
  when the app's service mounts the Docker socket or a path outside the checkout (D5).
- **Two commands print secrets:** `docker compose config` without `--quiet` or `--services`, and
  `docker inspect`. Both run without a prompt, so the rule is the guard: `/dev-env` doesn't run them.
- **A committed install carries the templates** under `.claude/skills/dev-env/templates/`, where an
  image or Dockerfile scanner may read them: exclude that folder if it reports them.

## Verify

- `python3 -m json.tool .claude/settings.json` parses, and its `allow` list holds `Bash(docker *)` and `Bash(make *)`.
- In a new session, `/dev-env` (packaged: `/adf-dev:dev-env`) is offered; `docker compose ps`,
  `make up`, and `make test` run without a prompt; asked to reset the stack, the agent names what
  is lost and waits for a yes in chat.
- In Docker mode `make run cmd='pwd'` runs in the app's container without a prompt. With
  `DEV_MODE=native` in `.env`, the same command prompts.

## Requirements

Docker Engine or Docker Desktop with Compose v2 (`docker compose`, with `--wait`) and BuildKit, its
default builder; `make` and `bash` 3.2 or later, which macOS and Linux have; `python3` for the install
script, and for the app's entry in Claude Desktop's Browser, which is skipped without it.
