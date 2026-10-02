# aplyca-framework plugin

Installer and upgrader for the [Agentic Development Framework](../../README.md).

The framework itself ships as **committed files in each adopting repo** (the
[AGENTS.md](https://agents.md) standard plus tool-specific layers) so that every AI tool —
Claude Code, Cursor, Copilot, Antigravity, Windsurf, Aider — reads the same source of
truth. This plugin deliberately contains **no framework content**: it is the tooling that
installs and maintains those files, and measures what the agent work costs. That keeps adopted repos fully portable, with zero
runtime dependency on this plugin.

## Install

Install it in each project that uses the framework. Paste this prompt into a Claude Code session
opened on the project — in the terminal, the desktop app, or an IDE:

<!-- install-prompt: keep identical in README.md and the plugin's README -->
```text
Install the aplyca-framework plugin (Agentic Development Framework) for this project only — never
at user scope.

1. Check that this folder is the root of a git repository. If .claude/settings.json already enables
   aplyca-framework@aplyca, say so and skip to step 6.
2. If scripts/agent/worktree-new.sh exists and this is the main checkout (git rev-parse --git-dir
   equals git rev-parse --git-common-dir), stop: the hub takes no edits. Tell me to run this from a
   worktree.
3. From this folder, run:
   claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
   claude plugin install aplyca-framework@aplyca --scope project
4. Show me the diff of .claude/settings.json: it should add only the aplyca marketplace and the
   plugin. Don't commit it — /adopt or /upgrade puts it in its pull request.
5. If claude plugin list also shows the plugin at user scope, tell me, with the commands that remove
   that copy. Don't run them.
6. Tell me to start a new session here, then run /upgrade if CLAUDE.md has a "Skeleton source:"
   line, otherwise /adopt.
```

Or run the two commands yourself, from the project's folder:

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
| `--scope project` (use this) | The project's committed `.claude/settings.json` | Everyone on the project — teammates get it once they trust the folder |
| `--scope local` | The project's git-ignored `.claude/settings.local.json` | You, in this repository only — to try it before the team sees it |

In a project that uses the dispatcher hub (the parallel-agents module), use `project`: the committed
setting reaches every task's worktree on every platform, and every teammate. A local install reaches
the worktrees only on macOS and Linux with Claude Code 2.1.211 or later, which keeps
`.claude/settings.local.json` at the main checkout; on Windows it stays in the checkout where you ran
it. Claude Code keeps the downloaded plugin files in its own cache under your home folder; the scope
decides where the plugin is turned on.

### In the desktop app

The Code tab of the Claude desktop app reads the same settings files as the terminal, so an install
made with the commands above works there too. To install from the app instead:

1. Add the marketplace from a terminal in the project's folder — the app's plugin browser lists the
   plugins of marketplaces already added:

   ```bash
   claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
   ```

2. In a local or SSH session on the project, click **+** next to the prompt box, then **Plugins** →
   **Add plugin**. Select `aplyca-framework` and choose **this project** as the scope.

**+ → Plugins → Manage plugins** enables, disables, or uninstalls it later. Worktree sessions the app
creates load a project-scope plugin (Claude Code 2.1.200 or later). Plugins don't load in WSL
sessions, and cloud sessions don't install the plugins a repository's settings declare — run `/adopt`
and `/upgrade` in a local session.

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
