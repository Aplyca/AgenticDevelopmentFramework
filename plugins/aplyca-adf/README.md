# aplyca-adf plugin

The [Agentic Development Framework](../../README.md)'s plugin for Claude Code. It has two jobs:

- **Install and maintain the framework** in a repository: `/aplyca-adf:adopt`,
  `/aplyca-adf:upgrade`, and `/aplyca-adf:cost-report`, in every project that uses the framework.
- **Carry the framework's machinery for a packaged install** ([decision 0016](../../docs/decisions/0016-packaged-install.md)):
  20 skills, 8 agents, 4 workflows, and the guardrail hooks, pinned to a release. Typed as
  `/aplyca-adf:triage`, `/aplyca-adf:deep-review`, and so on.

By default, the framework ships as **committed files in each adopting repo** (the
[AGENTS.md](https://agents.md) standard plus tool-specific layers), so every AI tool — Claude Code,
Cursor, Copilot, Antigravity, Windsurf, Aider — reads the same source of truth, with no runtime
dependency on this plugin. In such a **committed** project, the plugin's copies of the machinery step
aside: its hooks stand down, and its skills and agents hand over to the committed files. They act only
where the stamp on `CLAUDE.md`'s first line says `install: packaged`. A team that works in Claude Code
only can choose that **packaged** install instead and commit about 40 fewer files
([docs/SETUP.md § Packaged install](../../docs/SETUP.md#packaged-install-claude-code-only)).

The machinery under `skills/` (except `adopt`, `upgrade`, and `cost-report`), `agents/`,
`workflows/`, and `hooks/` is generated from the skeleton by `scripts/build-aplyca-adf.sh`; never
edit it here.

## Install

Install it once per project, when the project adopts the framework. Paste this prompt into a Claude
Code session opened on the project — in the terminal, the desktop app, or an IDE:

<!-- install-prompt: keep identical in README.md and the plugin's README -->
```text
Install the aplyca-adf plugin (Agentic Development Framework) for this project only — never
at user scope.

1. Check that this folder is the root of a git repository. If .claude/settings.json already enables
   aplyca-adf@aplyca, there is nothing to install: tell me to start a new session here and accept
   the prompt to trust the folder, which turns the plugin on, and stop.
2. If scripts/agent/worktree-new.sh exists and this is the main checkout (git rev-parse --git-dir
   equals git rev-parse --git-common-dir), stop: the hub takes no edits. Tell me to run this from a
   worktree.
3. From this folder, run:
   claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
   claude plugin marketplace update aplyca
   claude plugin install aplyca-adf@aplyca --scope project
   The update refreshes a copy of the marketplace added before; without it the install can't
   find aplyca-adf.
4. Show me the diff of .claude/settings.json: it should add only the aplyca marketplace and the
   plugin. Don't commit it — /adopt or /upgrade puts it in its pull request.
5. If claude plugin list also shows the plugin at user scope, tell me, with the commands that remove
   that copy. Don't run them.
6. Tell me to start a new session here, then run /aplyca-adf:upgrade if CLAUDE.md has a
   "Skeleton source:" line, otherwise /aplyca-adf:adopt.
```

Or run the commands yourself, from the project's folder. The update refreshes a copy of the
marketplace added before, which doesn't list `aplyca-adf` yet:

```bash
cd your-project
claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
claude plugin marketplace update aplyca
claude plugin install aplyca-adf@aplyca --scope project
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
   claude plugin marketplace update aplyca
   ```

2. In a local or SSH session on the project, click **+** next to the prompt box, then **Plugins** →
   **Add plugin**. Select `aplyca-adf` and choose **this project** as the scope.

**+ → Plugins → Manage plugins** enables, disables, or uninstalls it later. Worktree sessions the app
creates load a project-scope plugin (Claude Code 2.1.200 or later). Plugins don't load in WSL
sessions, and cloud sessions don't install the plugins a repository's settings declare — run `/adopt`
and `/upgrade` in a local session.

**Installed `aplyca-framework` before?** That was this plugin's name until v1.0.0. Install
`aplyca-adf` with the prompt above, then remove the old one — from the project, and from user scope
if you ever installed it there:

```bash
claude plugin uninstall aplyca-framework@aplyca --scope project
claude plugin uninstall aplyca-framework@aplyca --scope user
claude plugin marketplace remove aplyca --scope user
```

`/aplyca-adf:upgrade` replaces the old name in the project's committed settings.

## Skills

| Skill | Purpose |
|---|---|
| `/aplyca-adf:adopt` | Bootstrap a repo: inspect it (stack, commands, branching model, tracker, Git host), choose the install (committed or packaged), copy the skeleton and the [optional modules](../../modules/README.md) you choose, fill placeholders from verified repo facts, configure the guardrail hooks, record the adoption as PDR-0001, stamp the release and modules, verify (settings schema, hook smoke tests, the `@AGENTS.md` import), and prepare a draft adoption PR. On an already-adopted repo it adds modules. Automates [docs/SETUP.md](../../docs/SETUP.md). |
| `/aplyca-adf:upgrade` | Sync an adopted repo — skeleton and installed modules — to a newer release via the three-bucket taxonomy, OLD → NEW diff discipline, and the changelog's migration steps; bump a packaged project's pinned release; offer the modules it doesn't have yet and a switch between the two installs. Automates [docs/UPGRADING.md](../../docs/UPGRADING.md). |
| `/aplyca-adf:cost-report` | What agent sessions on a project cost — calls, active time, context size, tokens, estimated cost — from Claude Code's local transcripts, with what Opus sessions would have cost on Sonnet and the expensive patterns flagged (long context, pauses past the cache lifetime, browser loops, spec-heavy small changes). Read-only; nothing leaves the machine. See the skeleton's [COST-MODEL.md](../../skeleton/docs/COST-MODEL.md). |

`/aplyca-adf:adopt` and `/aplyca-adf:upgrade` work branch-and-PR only — they never commit to a default
branch, and never push without explicit approval. `/aplyca-adf:cost-report` only reads.

**In a packaged project,** the rest of the framework comes from here too: the workflow skills
(`/aplyca-adf:triage`, `/aplyca-adf:write-spec`, `/aplyca-adf:implement`, `/aplyca-adf:review`, …), the
agents (`aplyca-adf:code-reviewer`, `aplyca-adf:spec-analyzer`, …), the `/aplyca-adf:deep-…`
workflows, and the hooks, which read the project's `.claude/hooks/config.sh`. The catalogs:
[SKILLS-REFERENCE.md](../../docs/SKILLS-REFERENCE.md) and [AGENTS-REFERENCE.md](../../docs/AGENTS-REFERENCE.md).

## For teams

These are the entries `--scope project` writes to `.claude/settings.json`, with the release pin that
`/aplyca-adf:adopt` and `/aplyca-adf:upgrade` add (they add the rest too, when the plugin was
installed another way). They work like a package manifest: a teammate who opens the project and
accepts the prompt to trust the folder gets the plugin with no install command. Claude Code fetches
the marketplace at the pinned release and loads the plugin from it, because the marketplace lists
the plugin by a relative path. A machine where nobody trusts the folder — CI — installs it first
([SETUP.md](../../docs/SETUP.md)).

```json
{
  "extraKnownMarketplaces": {
    "aplyca": {
      "source": { "source": "github", "repo": "aplyca/AgenticDevelopmentFramework", "ref": "v1.0.3" }
    }
  },
  "enabledPlugins": { "aplyca-adf@aplyca": true }
}
```

Every project pins its release with `"ref"`, and `/aplyca-adf:adopt` and `/aplyca-adf:upgrade` keep
it equal to the release in the `CLAUDE.md` stamp. In a packaged project the pin chooses the
machinery; in a committed one it keeps the plugin's copies at the same release as the committed
files, so a skill listed twice never runs a different version.

## Updating the plugin

Every project pins a release, so updating the plugin changes nothing until the pin moves.
`/aplyca-adf:upgrade` moves it to the newest release and brings the committed files along, in one pull
request; restart Claude Code after it merges. A project adopted before v1.0.0 isn't pinned and turns
on `aplyca-framework`: install `aplyca-adf` with the [install prompt](#install), then run
`/aplyca-adf:upgrade`, which renames the setting and pins the release.
