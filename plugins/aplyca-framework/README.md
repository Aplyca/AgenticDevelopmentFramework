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
claude plugin marketplace add aplyca/ai-dev-starter-kit
claude plugin install aplyca-framework@aplyca
```

## Skills

| Skill | Purpose |
|---|---|
| `/adopt` | Bootstrap a repo: inspect it, copy the skeleton, fill placeholders from verified repo facts, stamp the baseline SHA, prepare an adoption PR. Automates [docs/SETUP.md](../../docs/SETUP.md). |
| `/upgrade` | Sync an adopted repo to a newer skeleton version via the three-bucket taxonomy and OLD_SHA → NEW_SHA discipline. Automates [docs/UPGRADING.md](../../docs/UPGRADING.md). |

Both skills work branch-and-PR only — they never commit to a default branch, and never
push without explicit approval.

## Updating the plugin

```bash
claude plugin marketplace update aplyca
claude plugin update aplyca-framework
```
