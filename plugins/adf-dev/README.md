# adf-dev

The development plugin of the [Agentic Development Framework](https://github.com/aplyca/AgenticDevelopmentFramework):
the skills and agents for building, running, and checking the code. Each one comes from an optional
module, and acts only in a packaged project that installed that module. Anywhere else it says so and
stops.

| Skill | Module | What it does |
|---|---|---|
| `/adf-dev:dev-env` | [`docker`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/docker/MODULE.md) | Sets up, connects per worktree, diagnoses, and safely resets a Docker Compose local environment |

It is one of the framework's plugins by concern
([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)):
`adf` carries the process, `adf-dev` development, and `adf-connect` (planned) the connections to
trackers and services. All of them are listed in the `aplyca` marketplace at the same version, and a
project pins them together.

`/adf:adopt` and `/adf:upgrade` turn it on in a packaged project that installs one of its
modules: `"adf-dev@aplyca": true` in `enabledPlugins`, and
`Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`. A committed project copies the
modules' skills instead and leaves it off.

`skills/` and `agents/` are generated from the modules by `scripts/build-plugins.sh` — every path
`.generated` lists. Never edit them here; change the module and run the script.
