# adf-dev

The development plugin of the [Agentic Development Framework](https://github.com/aplyca/AgenticDevelopmentFramework):
the skills and agents for building, running, and checking the code. Each one comes from an optional
module, and acts only in a packaged project that installed that module. Anywhere else it says so and
stops.

| Skill | Module | What it does |
|---|---|---|
| `/adf-dev:dev-env` | [`docker`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/docker/MODULE.md) | Sets up, connects per worktree, diagnoses, and safely resets a Docker Compose local environment |

It also carries a **mod**, written here by hand: code that runs inside Claude Code and draws in its
interface ([decision 0026](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0026-display-only-mods.md)).

| Mod | What it shows |
|---|---|
| Local environment | A line above the prompt: the local environment's URL, and whether it answers (● or ○), refreshed every 15 seconds and after each turn. `/local-url` says the same in places that don't draw. The URL is `LOCAL_URL` in `.claude/hooks/config.sh`, or, with the parallel-agents module, the worktree's `READY_URL` with its own `APP_PORT` |

It's display-only: it reads those files — only `APP_PORT` from the env file — and requests the URL; it
never acts on a tool call or a prompt. It needs Claude Code v2.1.287 or later in a terminal, or the
desktop app from v2.1.286, and it works in any project that turns `adf-dev` on, committed or packaged:
a mod can't be committed into a project. Its tests run with `claude plugin test plugins/adf-dev`.

It is one of the framework's plugins by concern
([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)):
`adf` carries the process, `adf-dev` development, and `adf-connect` the connections to trackers and
services. All of them are listed in the `aplyca` marketplace at the same version, and a
project pins them together.

`/adf:adopt` and `/adf:upgrade` turn it on in a packaged project that installs one of its
modules, and offer it to any project whose app runs locally, for the mod: `"adf-dev@aplyca": true` in `enabledPlugins`, and
`Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`. A committed project copies the
modules' skills instead and leaves it off.

`skills/` and `agents/` are generated from the modules by `scripts/build-plugins.sh` — every path
`.generated` lists. Never edit them here; change the module and run the script. The mod — `hooks/`,
`types/`, `tests/` — is written here.
