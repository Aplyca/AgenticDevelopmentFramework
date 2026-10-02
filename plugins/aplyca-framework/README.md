# aplyca-framework plugin

Installer and upgrader for the [Agentic Development Framework](../../README.md).

The framework itself ships as **committed files in each adopting repo** (the
[AGENTS.md](https://agents.md) standard plus tool-specific layers) so that every AI tool —
Claude Code, Cursor, Copilot, Antigravity, Windsurf, Aider — reads the same source of
truth. This plugin deliberately contains **no framework content**: it is the tooling that
installs and maintains those files, and measures what the agent work costs. That keeps adopted repos fully portable, with zero
runtime dependency on this plugin.

## Install

Install it in each project that uses the framework, from the project's folder:

```bash
cd your-project
claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
claude plugin install aplyca-framework@aplyca --scope project
```

Always pass `--scope`: without it, Claude Code installs at `user` scope, which turns the plugin on in
every project on your machine and offers `/adopt` in sessions that have nothing to do with the
framework.

| Scope | Recorded in | Who gets the plugin |
|---|---|---|
| `--scope project` (use this) | The project's committed `.claude/settings.json` | Everyone on the project — teammates are offered it when they trust the folder |
| `--scope local` | The project's git-ignored `.claude/settings.local.json` | You, in this checkout only — to try it before the team sees it |

In a project that uses the dispatcher hub (the parallel-agents module), only `project` works: the
committed setting reaches every task's worktree, while a local install exists only in the checkout
where you ran it. Claude Code keeps the downloaded plugin files in its own cache under your home
folder; the scope decides where the plugin is turned on.

**Installed at user scope before?** `/upgrade` offers to add the project setting in its pull request.
Once every project you use the plugin in has it, remove the user-scope copy:

```bash
claude plugin uninstall aplyca-framework@aplyca --scope user
claude plugin marketplace remove aplyca --scope user
```

## Skills

| Skill | Purpose |
|---|---|
| `/adopt` | Bootstrap a repo: inspect it (stack, commands, branching model, tracker, Git host), copy the skeleton and the [optional modules](../../modules/README.md) you choose, fill placeholders from verified repo facts, configure the guardrail hooks, record the adoption as PDR-0001, stamp the baseline SHA and modules, verify (settings schema, hook smoke tests, the `@AGENTS.md` import), and prepare a draft adoption PR. On an already-adopted repo it adds modules. Automates [docs/SETUP.md](../../docs/SETUP.md). |
| `/upgrade` | Sync an adopted repo — skeleton and installed modules — to a newer version via the three-bucket taxonomy, OLD_SHA → NEW_SHA discipline, and the changelog's migration steps, and offer the modules it doesn't have yet (installed in the same pull request when chosen). Automates [docs/UPGRADING.md](../../docs/UPGRADING.md). |
| `/cost-report` | What agent sessions on a project cost — calls, active time, context size, tokens, estimated cost — from Claude Code's local transcripts, with the expensive patterns flagged (long context, pauses past the cache lifetime, browser loops, spec-heavy small changes). Read-only; nothing leaves the machine. See the skeleton's [COST-MODEL.md](../../skeleton/docs/COST-MODEL.md). |

`/adopt` and `/upgrade` work branch-and-PR only — they never commit to a default branch, and
never push without explicit approval. `/cost-report` only reads.

## For teams

These are the entries `--scope project` writes to `.claude/settings.json`, and what `/adopt` and
`/upgrade` keep (or add, when the plugin was installed another way) so every teammate is offered the
plugin — and `/upgrade` — when they trust the repository:

```json
{
  "extraKnownMarketplaces": {
    "aplyca": {
      "source": { "source": "github", "repo": "aplyca/AgenticDevelopmentFramework" }
    }
  },
  "enabledPlugins": { "aplyca-framework@aplyca": true }
}
```

## Updating the plugin

From the project's folder:

```bash
claude plugin marketplace update aplyca
claude plugin update aplyca-framework@aplyca
```

Restart Claude Code and run `/upgrade` there; repeat in each adopted repository.
