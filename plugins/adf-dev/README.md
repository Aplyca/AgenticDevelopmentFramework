# adf-dev

The development plugin of the [Agentic Development Framework](https://github.com/aplyca/AgenticDevelopmentFramework):
the skills and agents for building, running, and checking the code. Each one comes from an optional
module, and acts only in a packaged project that installed that module. Anywhere else it says so and
stops.

| Skill | Module | What it does |
|---|---|---|
| `/adf-dev:dev-env` | [`docker`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/docker/MODULE.md) | Writes a Docker Compose local environment from its templates, or moves one to the conventions — `compose.yaml` and a `Makefile` at the root, `ops/`, ports Docker picks ([decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md)) — runs the app in Docker or natively on the host, by a setting ([decision 0034](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0034-local-environment-modes.md)), or per worktree, diagnoses it, and safely resets it |

It also carries a **mod**, written here by hand: code that runs inside Claude Code and draws in its
interface ([decision 0026](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0026-display-only-mods.md)).

| Mod | What it shows |
|---|---|
| Local environment | A line above the prompt: the local environment's URL, and whether it answers (● or ○), refreshed every 15 seconds and after each turn. `/local-url` says the same in places that don't draw. The URL is `LOCAL_URL` in `.claude/hooks/config.sh`, or, with the parallel-agents module, the worktree's `READY_URL`. Its `${APP_PORT}` is the env file's when it pins one; otherwise, with `LOCAL_SERVICE` set (`web:3000`), the port of the app on the host in native mode (`ops/.run/app.env`), or the port Docker picked, which it looks up |

It's display-only: it reads those files — only `APP_PORT` from the env file and from `ops/.run/app.env` — and requests the URL; it
never acts on a tool call or a prompt. It runs one command, read-only: `docker compose port <service>
<port>` in the checkout, for the port Docker picked
([decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md)).
It looks again after a turn, once a minute, and when the URL stops answering — never on every refresh. It needs Claude Code v2.1.287 or later in a terminal, or the
desktop app from v2.1.286, and it works in any project that turns `adf-dev` on, committed or packaged:
a mod can't be committed into a project. Its tests run with `claude plugin test plugins/adf-dev`.

It is one of the framework's plugins by concern
([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)):
`adf` carries the process, `adf-dev` development, and `adf-connect` the connections to trackers and
services. All of them are listed in the `aplyca` marketplace at the same version, and a
project pins them together.

`/adf:adopt` and `/adf:upgrade` turn it on in a packaged project that installs one of its
modules, and offer it to any project whose app runs locally, for the mod: `"adf-dev@aplyca": true` in `enabledPlugins`, and
`Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`. A committed project keeps
copies of the modules' skills instead, which `scripts/build-committed.py` writes from here, and leaves
it off.

Everything here is written by hand ([decision 0028](../../docs/decisions/0028-plugins-are-the-source.md)):
`skills/` holds the source of each development module's skill, in the form a packaged project loads it
— a Step 0 that names its module, and `/adf-dev:dev-env` — and the module's `module.json` names it.
The mod — `hooks/`, `types/`, `tests/` — is written here too. `scripts/build-plugins.sh` only keeps the
version equal to `adf`'s.
