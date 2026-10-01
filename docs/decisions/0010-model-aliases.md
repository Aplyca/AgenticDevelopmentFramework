# 0010: Configure models with version-less aliases

- **Status:** accepted
- **Date:** 2026-10-01

## Context

The skeleton pinned a full model ID in `.claude/settings.json` and in the cost-model doc. Every model
release made the default stale: adopting repositories kept running an older model until someone
noticed and opened a pull request, and the framework had to ship an upgrade just to move the
default. One adopting team switched to the version-less alias and documented why.

## Decision

- `.claude/settings.json` uses `"model": "sonnet"`; agents use `haiku` / `sonnet` / `opus` in their
  frontmatter. Aliases resolve to the latest model in each family as Claude Code updates.
- `docs/COST-MODEL.md` names the current model behind each alias and the relative per-token cost, and
  tells teams to use a full model ID only when they must pin a version.
- The static evals accept an alias, `inherit`, or a full ID in agent frontmatter and settings.

## Consequences

- **Positive:** new models arrive without a configuration change or a framework upgrade.
- **Negative / cost:** behavior can shift when an alias moves to a new model; teams that need
  reproducibility pin a full ID. Older Claude Code versions resolve aliases to older models — keep
  Claude Code current.

## Alternatives considered

- **Pin full IDs and ship an upgrade per release.** Constant churn for no benefit to most teams.
