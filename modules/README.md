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
| [`docker/`](docker/MODULE.md) | The `/dev-env` skill — set up, connect per worktree, diagnose, and safely reset a Docker Compose local environment — and permission rules that let read-only docker commands run and make destructive ones ask. Packaged, the skill comes from the development plugin, `adf-dev` | The local stack runs on Docker Compose, or the team wants a containerized local environment |

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
| `adf` | The process | `parallel-agents` (`/dispatch`; the worktree scripts as `adf-worktree-new`, `-ls`, `-rm`) |
| `adf-dev` | Development | `docker` (`/dev-env`) |
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
