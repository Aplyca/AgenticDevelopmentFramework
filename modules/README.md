# Optional modules

The skeleton is the core every adopting repository gets. Modules are **opt-in additions** for
practices that depend on the Git host, on a stack or service the project uses, on a specialty, or on
how a team runs its agents — useful, proven in real projects, but not universal.

| Module | Adds | Use it when |
|---|---|---|
| [`github/`](github/MODULE.md) | Pull request template (traceability, verified / not verified, constitution gates), issue forms that redirect requirements to the tracker, a secret-scan workflow, a base-branch policy check, `.gitleaks.toml` | The repository lives on GitHub |
| [`git-hooks/`](git-hooks/MODULE.md) | A tool-agnostic `pre-push` hook that refuses pushes to protected branches and runs the fast checks | You want local gates that apply to every git client, not only to Claude Code |
| [`clickup/`](clickup/MODULE.md) | ClickUp's official MCP server in `.mcp.json` and a read-only permission allowlist, so agents read tasks freely and every write prompts | Requirements arrive as ClickUp tasks |
| [`parallel-agents/`](parallel-agents/MODULE.md) | Worktree scripts (`worktree-new`, `-rm`, `-ls`) that give every task its own worktree, branch, env file, and port; the `/dispatch` skill; the dispatcher/worker process doc | Several agent sessions work on the same repository at once, and each needs a running app |
| [`docker/`](docker/MODULE.md) | The `/dev-env` skill — set up, connect per worktree, diagnose, and safely reset a Docker Compose local environment — and permission rules that let read-only docker commands run and make destructive ones ask. Packaged, the skill comes from the module's plugin, `adf-docker` | The local stack runs on Docker Compose, or the team wants a containerized local environment |

## Installing a module

Each module has a `MODULE.md` (what it adds, prerequisites, how to customize — not copied) and a
`files/` tree that mirrors the target repository's layout:

```bash
cp -R modules/<module>/files/. /path/to/your-repo/
```

Nothing is overwritten that you didn't mean to — check `git status` and merge any file that already
existed (a pull request template, for example). The `clickup` module is the exception: it changes
files every repository already has (`.mcp.json`, `.claude/settings.json`), so it installs with
`modules/clickup/install.sh <repo>`, which merges instead of copying. The `docker` module copies,
then merges its permission rules with `modules/docker/install.sh <repo>`. Then follow the module's customization steps and
record the module in the `Skeleton source` line at the top of `CLAUDE.md`
(`· modules: github, clickup`) so `/upgrade` knows to update it.

The framework's `/adopt` skill offers each module during adoption and installs the ones you choose.

## A module's own plugin

A module's skills and agents are machinery no project edits, so a packaged install takes them from a
plugin instead of committing them ([decision 0023](../docs/decisions/0023-area-plugins-for-modules.md)).
A module with a `plugin.json` beside its `MODULE.md` gets one of its own, `adf-<module>`, which
`scripts/build-plugins.sh` generates from the module's `files/.claude/` into `plugins/adf-<module>/`
and lists in the `aplyca` marketplace, at the framework's version. A packaged project with the module
leaves its `.claude/skills/` out and turns the plugin on beside `aplyca-adf` —
`"adf-<module>@aplyca": true` in `enabledPlugins` and `Read(~/.claude/plugins/cache/aplyca/adf-<module>/**)`
in `permissions.allow`. A committed project copies the skills and leaves the plugin off. The
`parallel-agents` module's `/dispatch` predates this and still comes from `aplyca-adf`.

The manifest takes `name` (`adf-<module>`), `description`, `category`, and `keywords` — the version
comes from `aplyca-adf`. Skill and agent names are unique across every plugin.
