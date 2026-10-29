# adf-dev

The development plugin of the [Agentic Development Framework](https://github.com/aplyca/AgenticDevelopmentFramework):
the skills and agents for building, running, and checking the code. Each one comes from an optional
module, and acts only in a packaged project that installed that module. Anywhere else it says so and
stops.

| Skill | Module | What it does |
|---|---|---|
| `/adf-dev:dev-env` | [`docker`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/docker/MODULE.md) | Writes a local environment to the [specification](skills/dev-env/SPECIFICATION.md) it carries — its templates are an example — or audits one against it, by requirement ID: `compose.yaml` and a `Makefile` at the root, one folder per target in `ops/`, ports Docker picks ([decision 0032](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0032-local-environment-layout.md)) — runs the app in Docker or natively on the host, by a setting ([decision 0034](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0034-local-environment-modes.md)), or per worktree, diagnoses it, and safely resets it |
| `/adf-dev:e2e` | [`e2e`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/e2e/MODULE.md) | Sets up end-to-end tests to the [specification](skills/e2e/SPECIFICATION.md) it carries — no templates: it writes the project's own suite to it, and runs it until it passes — or audits a suite against it, by requirement ID: Playwright in its own `e2e/` folder, `make e2e` and `make smoke` against the checkout's own stack, in Docker or on the host, and one `@smoke` test per critical flow ([decision 0037](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0037-end-to-end-tests.md)). Diagnoses a failing or flaky test from what it kept |
| `/adf-dev:unit` | [`unit`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/unit/MODULE.md) | Sets up unit and integration tests with Vitest to the [specification](skills/unit/SPECIFICATION.md) it carries, audits them, tags each test with its tier, and groups them in feature suites ([decision 0058](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0058-test-tiers-and-feature-suites-with-vitest.md)) |

It is one of the framework's plugins by concern
([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)):
`adf` carries the process, `adf-dev` development, and `adf-connect` the connections to trackers and
services. All of them are listed in the `aplyca` marketplace at the same version, and a
project pins them together.

`/adf:adopt` and `/adf:upgrade` turn it on in a packaged project that installs one of its
modules: `"adf-dev@aplyca": true` in `enabledPlugins`, and
`Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`. A committed project keeps
copies of the modules' skills instead, which `scripts/build-committed.py` writes from here, and leaves
it off.

Everything here is written by hand ([decision 0028](../../docs/decisions/0028-plugins-are-the-source.md)):
`skills/` holds the source of each development module's skill, in the form a packaged project loads it
— a Step 0 that names its module, and `/adf-dev:dev-env`, `/adf-dev:e2e`, `/adf-dev:unit` — and the module's `module.json` names it.
`scripts/build-plugins.sh` only keeps the version equal to `adf`'s.
