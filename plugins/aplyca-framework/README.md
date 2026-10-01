# aplyca-framework plugin

Installer and upgrader for the [AI-Assisted Development Framework](../../README.md).

The framework itself ships as **committed files in each adopting repo** (the
[AGENTS.md](https://agents.md) standard plus tool-specific layers) so that every AI tool —
Claude Code, Cursor, Copilot, Antigravity, Windsurf, Aider — reads the same source of
truth. This plugin deliberately contains **no framework content**: it is the tooling that
installs and maintains those files. That keeps adopted repos fully portable, with zero
runtime dependency on this plugin.

## Install

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework
claude plugin install aplyca-framework@aplyca
```

## Skills

| Skill | Purpose |
|---|---|
| `/adopt` | Bootstrap a repo: inspect it (stack, commands, branching model, tracker, Git host), copy the skeleton and the [optional modules](../../modules/README.md) you choose, fill placeholders from verified repo facts, configure the guardrail hooks, record the adoption as PDR-0001, stamp the baseline SHA and modules, verify (settings schema, hook smoke tests, the `@AGENTS.md` import), and prepare a draft adoption PR. On an already-adopted repo it adds modules. Automates [docs/SETUP.md](../../docs/SETUP.md). |
| `/upgrade` | Sync an adopted repo — skeleton and installed modules — to a newer version via the three-bucket taxonomy, OLD_SHA → NEW_SHA discipline, and the changelog's migration steps. Automates [docs/UPGRADING.md](../../docs/UPGRADING.md). |

Both skills work branch-and-PR only — they never commit to a default branch, and never
push without explicit approval.

## For teams

To have every teammate offered the plugin when they trust the repository (and so get `/upgrade`),
add to the adopted repo's `.claude/settings.json` — `/adopt` offers to do it:

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

```bash
claude plugin marketplace update aplyca
claude plugin update aplyca-framework@aplyca
```

Restart Claude Code, then run `/upgrade` in each adopted repository.
