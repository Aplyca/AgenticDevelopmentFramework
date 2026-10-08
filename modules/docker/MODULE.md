# Module: docker

For projects whose local environment runs on Docker Compose. Adds `/dev-env`, which sets the stack
up from verified facts, gives each worktree a stack of its own when the project runs agents in
parallel, diagnoses a stack that won't start the way `/debug` diagnoses a bug, and resets one without
touching anything else on the machine. Read-only docker commands run without a prompt; every command
that deletes containers, volumes, or images asks first.

## What it adds

| File | Purpose |
|---|---|
| `.claude/settings.json` (merged) | `permissions.allow` for read-only commands (`docker compose ps`, `logs`, `port`, `ls`, `config --quiet`, `docker ps`, `volume ls`, `system df`); `permissions.ask` for destructive ones (`compose down -v` or `--rmi`, `compose rm`, `docker rm`, `rmi`, `volume rm`, every `prune`). An ask rule wins over any allow rule, so a broad `Bash(docker *)` the project already has can't skip the prompt |
| `.claude/skills/dev-env/SKILL.md` | **Committed install only.** A packaged project gets `/adf-dev:dev-env` from the development plugin, `adf-dev`, which `module.json` names ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)) |

No rule of its own: Compose and Dockerfile conventions live in the skeleton's
`.claude/rules/deployment.md` § Docker, which `/dev-env` keeps pointed at the project's files.

## Install

`/adopt` and `/upgrade` install it when you choose the module. By hand:

- **Committed install:** `cp -R modules/docker/files/. /path/to/your-repo/`, then
  `modules/docker/install.sh /path/to/your-repo`.
- **Packaged install:** leave `files/.claude/skills/` out, run
  `modules/docker/install.sh /path/to/your-repo`, and turn the plugin on in `.claude/settings.json`
  beside `aplyca-adf` — `"adf-dev@aplyca": true` in `enabledPlugins`, and
  `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`.

`install.sh` merges into `.claude/settings.json`: it keeps your rules and their order, adds only
what's missing, and is safe to run again — `/upgrade` reruns it to pick up new rules.

Then add `docker` to the `modules:` list in the stamp on `CLAUDE.md`'s first line: `/dev-env` stops
in a project whose stamp doesn't name it.

## Customize

Run `/dev-env set up` (packaged: `/adf-dev:dev-env set up`) once the module is in. It fills these
from what it verifies, and you review them:

1. **`docs/getting-started/DEV-SETUP.md`** — the Docker prerequisite, § 4 Set up local services (the
   command, the services and their ports), the command surface, and § Troubleshooting for problems
   actually met. Packaged: `/adf-dev:dev-env` joins the key commands under § AI-assisted
   development.
2. **`AGENTS.md` § Quick reference** — the start and stop commands; the local check before the
   pull request starts the stack from there.
3. **`.claude/rules/deployment.md`** — `paths:` names the project's Compose and Docker files
   (`compose.yaml` isn't in the skeleton's list), and § Docker holds the project's conventions.
4. **With `parallel-agents`** — `/dev-env worktrees` proposes the `worktree.conf` values that give
   each worktree its own stack (`COMPOSE_PROJECT_NAME=${PROJECT}`, `START_CMD`, `STOP_CMD`,
   `READY_URL`, `PORT_SLOTS`), and records what worktrees share in `docs/PARALLEL-AGENTS.md`.

## Good to know

- **The ask rules match what the agent types, not what runs.** A command inside a script —
  `make reset`, a `package.json` script, or `STOP_CMD` when `worktree-rm.sh` runs it — isn't seen,
  and an unusual form (`docker --context x volume rm`) can slip past a pattern. The rules catch the
  commands an agent usually writes; they aren't a security boundary. `/dev-env` also asks in chat
  before anything destructive.
- **In `dontAsk` mode an ask rule denies instead of prompting;** in every other mode, auto and
  bypass included, it prompts.
- **Two commands print secrets:** `docker compose config` without `--quiet` or `--services`, and
  `docker inspect`. Neither is allowed, and `/dev-env` doesn't run them.

## Verify

- `python3 -m json.tool .claude/settings.json` parses, and its `ask` list holds the docker rules.
- In a new session, `/dev-env` (packaged: `/adf-dev:dev-env`) is offered; `docker compose ps`
  runs without a prompt; asking the agent to remove the stack's volumes prompts.

## Requirements

Docker Engine or Docker Desktop with Compose v2 (`docker compose`, with `--wait`); `python3` for the
install script.
