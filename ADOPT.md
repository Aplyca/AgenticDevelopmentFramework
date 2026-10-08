# Adopt the framework — for AI agents

You were asked to adopt, use, install, or set up the Agentic Development Framework in a project. This
page is the procedure. Don't copy files from this repository by hand: the adoption fills the skeleton
from verified facts about the project, stamps the version it came from, and lands as a draft pull
request — the `adf` plugin's `/adf:adopt` does all of that.

The project is the one the developer named, usually your session's folder. Before step 1, tell the
developer what you'll do — install the plugin for this project only, then adopt the framework on a
branch, delivered as a draft pull request — and wait for their go-ahead.

## 1. Check the project

- **Not a git repository?** Offer `git init -b <default branch>` (ask for the name; suggest `main`).
  A new project with no code yet is fine: `/adopt` has a mode for it.
- **Already adopted?** If `CLAUDE.md` has a `Skeleton source:` line, the framework is already here.
  When `.claude/settings.json` enables `adf@aplyca`, a developer joining the project has
  nothing to install: they start a new session and accept the prompt to trust the folder. Ask
  whether they want an upgrade instead; if so, follow steps 2 and 3 with `/upgrade` in place of
  `/adopt`.
- **The main checkout of a hub?** If `scripts/agent/worktree-new.sh` exists and
  `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`, stop: the hub takes no edits. Ask
  the developer to start a session in a worktree and run this there.

## 2. Install the plugin for this project only

Skip this step when `.claude/settings.json` already enables `adf@aplyca`, or `aplyca-adf@aplyca`, its
name before v2.0.0. Otherwise run,
from the project's root:

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
claude plugin marketplace update aplyca
claude plugin install adf@aplyca --scope project
```

The update refreshes a copy of the marketplace this machine added before; without it, the install
can't find `adf`. Always with `--scope project`: without it, Claude Code installs at user scope, which turns the plugin
on in every project on the machine. If `claude plugin list` also shows the plugin at user scope, tell
the developer, with the commands that remove that copy (the plugin's
[README § Install](plugins/adf/README.md#install)); don't run them.

The install changes `.claude/settings.json`. Show the developer the diff and leave it uncommitted: the
adoption's pull request carries it.

## 3. Run the adoption

The plugin's skills load when a session starts, so this session doesn't have `/adopt` yet. Either:

- **Hand over:** tell the developer to start a new session in the project and run
  `/adf:adopt` (`/adf:upgrade` for an adopted project; `/aplyca-adf:upgrade` in one adopted before
  v2.0.0, whose settings still enable `aplyca-adf@aplyca` — it renames the plugin as it upgrades).
- **Continue here:** find the marketplace's folder — the `installLocation` of `aplyca` in
  `claude plugin marketplace list --json` — then read
  `plugins/adf/skills/adopt/SKILL.md` (or `upgrade/SKILL.md`) inside it and follow it step
  by step. It is the same procedure `/adopt` runs.

Its ground rules hold either way: every filled placeholder traces to a file you read, nothing is
committed to the default branch (except a new repository's first commit, with the developer's yes),
and nothing is pushed until the developer approves.
