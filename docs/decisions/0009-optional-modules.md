# 0009: Host- and team-specific harness ships as optional modules

- **Status:** accepted; amended by [0016](0016-packaged-install.md) (a packaged install for Claude Code-only teams)
- **Date:** 2026-10-01

## Context

Field use produced valuable harness the core skeleton couldn't carry without losing portability: a
pull request template with traceability and constitution gates, issue forms that redirect
requirements to the tracker, a secret-scan workflow, a base-branch policy check, a `pre-push` hook,
and worktree scripts for parallel agents. They depend on the Git host (GitHub workflows and
templates) or on how a team works (parallel sessions). Putting them in the skeleton would force every
adopter to delete them; leaving them out meant every team rebuilt them, slightly differently.

## Decision

- A top-level `modules/` directory holds opt-in additions: `github/`, `git-hooks/`, `clickup/`,
  `parallel-agents/`. Each has a `MODULE.md` (what it adds, how to customize, limits — not copied)
  and a `files/` tree mirroring the target repository, installed with
  `cp -R modules/<name>/files/. <repo>/`. A module that changes files every repository already has
  (`clickup`: `.mcp.json`, `.claude/settings.json`) ships an install script that merges instead.
- `/adopt` offers each module from the discovered facts; the installed list is recorded in the
  `Skeleton source:` stamp (`· modules: github, parallel-agents`) so `/upgrade` updates them.
- Module scripts and configuration follow the same three-bucket upgrade taxonomy: scripts are
  overwritten, configuration (`worktree.conf`, the pull request template, `branch-policy.yml`) is
  merged.
- The **plugin stays content-free**: it installs and upgrades; the framework's content remains plain
  committed files every AI tool can read.

## Consequences

- **Positive:** the core stays lean and stack-agnostic; proven harness is reusable without forking;
  teams choose what fits.
- **Negative / cost:** more surface to test and to upgrade; modules are tested in CI
  (`evals/static/test-modules.sh`) to keep that cost honest.

## Alternatives considered

- **Everything in the skeleton.** Every adopter deletes what doesn't apply — the deletions themselves
  become upgrade conflicts.
- **Ship modules inside the plugin.** Would make the content depend on Claude Code; other tools and
  CI couldn't use it.
