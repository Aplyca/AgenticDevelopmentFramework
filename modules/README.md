# Optional modules

The skeleton is the core every adopting repository gets. Modules are **opt-in additions** for
practices that depend on the Git host, on a stack or service the project uses, on a specialty, or on
how a team runs its agents — useful, proven in real projects, but not universal.

| Module | Adds | Use it when |
|---|---|---|
| [`github/`](github/MODULE.md) | Pull request template (traceability, verified / not verified, constitution gates), issue forms that redirect requirements to the tracker, a secret-scan workflow, a base-branch policy check, `.gitleaks.toml` | The repository lives on GitHub |
| [`git-hooks/`](git-hooks/MODULE.md) | A tool-agnostic `pre-push` hook that refuses pushes to protected branches and runs the fast checks | You want local gates that apply to every git client, not only to Claude Code |
| [`clickup/`](clickup/MODULE.md) | ClickUp's official MCP server in `.mcp.json` and a read-only permission allowlist, so agents read tasks freely and every write prompts | Requirements arrive as ClickUp tasks |
| [`parallel-agents/`](parallel-agents/MODULE.md) | Worktree scripts (`worktree-new`, `-rm`, `-ls`) that give every task its own worktree, branch, env file, and port; the `/dispatch` skill, which moves each task's session to its worktree; the process doc | Several agent sessions work on the same repository at once, and each needs a running app |
| [`docker/`](docker/MODULE.md) | The `/dev-env` skill — write or migrate a Docker Compose local environment to the conventions (`compose.yaml` and a `Makefile` at the root, `ops/`, ports Docker picks), run it natively or per worktree, diagnose it, and safely reset it — and permission rules that let read-only docker commands run and make destructive ones ask. Packaged, the skill comes from the development plugin, `adf-dev` | The local stack runs on Docker Compose, or the team wants a containerized local environment |
| [`e2e/`](e2e/MODULE.md) | The `/e2e` skill — set up Playwright end-to-end tests in `e2e/` to the specification it carries, run with `make e2e` and `make smoke` against the checkout's own stack (in Docker or on the host), with one smoke test per critical flow; audit a suite, and diagnose a failing or flaky test — and permission rules that let the suite run without a prompt. Packaged, the skill comes from `adf-dev` | People use the app in a browser, and its critical flows should be checked end to end |
| [`unit/`](unit/MODULE.md) | The `/unit` skill — set up Vitest unit and integration tests to the specification it carries, run by tier (`@smoke` ⊂ `@critical` ⊂ regression) and by feature suite (a folder per feature, listed in `docs/TEST-SUITES.md`), with `npm test` and its tier scripts or `make test tier= suite=`; audit a suite — and permission rules that let the tiers run without a prompt. Packaged, the skill comes from `adf-dev` | A JavaScript or TypeScript app whose tests should run in steps and by feature |
| [`time-tracking/`](time-tracking/MODULE.md) | `docs/TIME-TRACKING.md`, the project's settings, and the `/track-time` skill — one tracker time entry per day of a task, in whole units: the AI-assisted time (the sessions, measured, plus the work outside them, estimated) or a senior developer's estimate without AI, as the developer picks. Packaged, the skill comes with `adf` | The team measures the time its tasks take, as an internal productivity measure |
| [`end-user-docs/`](end-user-docs/MODULE.md) | `docs/END-USER-DOCS.md`, the project's settings, and the `/end-user-docs` skill — a feature's end-user page, written in the doc tool end users read and never in the repository: drafted before implementation where end users can't see it, published once the feature ships, each page on the developer's yes. Packaged, the skill comes with `adf` | End users read the product's documentation in a doc tool — ClickUp Docs, Confluence, Notion |

## Installing a module

Each module has a `MODULE.md` (what it adds, prerequisites, how to customize — not copied) and a
`files/` tree that mirrors the target repository's layout:

```bash
cp -R modules/<module>/files/. /path/to/your-repo/
```

Nothing is overwritten that you didn't mean to — check `git status` and merge any file that already
existed (a pull request template, for example). The `clickup` module is the exception: it changes
files every repository already has (`.mcp.json`, `.claude/settings.json`), so it installs with
`modules/clickup/install.sh <repo>`, which merges instead of copying. The `docker` module has no
files to copy: `modules/docker/install.sh <repo>` merges its permission rules, and `/dev-env set up`
writes the stack from the skill's templates; `e2e` likewise, with `modules/e2e/install.sh <repo>`, and
`/e2e set up` writes the suite to its specification. Then follow the module's customization steps and
record the module in the `Skeleton source` line at the top of `AGENTS.md`
(`· modules: github, clickup`) so `/upgrade` knows to update it.

The framework's `/adopt` skill offers each module during adoption and installs the ones you choose.

## Modules and plugins

A module is what a project turns on and owns: committed files — CI workflows, templates, scripts,
permission rules, MCP configuration — that every AI tool and CI can read. A plugin is what Claude
Code loads: the framework's machinery, one plugin per concern
([decision 0023](../docs/decisions/0023-plugins-by-concern.md)):

| Plugin | Concern | Carries the skills and commands of |
|---|---|---|
| `adf` | The process | `parallel-agents` (`/dispatch`; the worktree scripts as `adf-worktree-new`, `-ls`, `-rm`), `time-tracking` (`/track-time`), `end-user-docs` (`/end-user-docs`) |
| `adf-dev` | Development | `docker` (`/dev-env`), `e2e` (`/e2e`), `unit` (`/unit`) |
| `adf-connect` | Trackers and services | — (its `/connect` writes a project's MCP configuration itself) |

A module's skills are machinery no project edits, so their source is the plugin its `module.json`
names, which lists them ([decision 0028](../docs/decisions/0028-plugins-are-the-source.md)); a module
with neither skills nor commands has no `module.json`. A packaged project with the module turns the
plugin on beside `adf` when it's another one — `"adf-dev@aplyca": true` in `enabledPlugins` and
`Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`. A committed project writes the
skills with `scripts/build-committed.py <repo> --modules <name>` and leaves the plugin off. Each skill
acts only where the stamp names its module, so a plugin turned on for one module never acts for
another the project doesn't have. Skill and agent names are unique across every plugin.

A module's scripts that no project edits go the same way when its `module.json` lists them under
`commands` ([decision 0027](../docs/decisions/0027-worktree-scripts-as-plugin-commands.md)): the
plugin carries each in its `bin/`, named after the plugin, on the Bash tool's PATH. A packaged project
leaves the scripts out and keeps their settings; a committed one copies them, and the command runs the
committed script.
