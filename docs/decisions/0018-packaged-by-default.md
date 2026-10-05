# 0018: The packaged install is the default

- **Status:** accepted
- **Date:** 2026-10-04
- **Amends:** [0016](0016-packaged-install.md) — which install `/adopt` recommends

## Context

Decision 0016 added the packaged install and kept the committed install the default. Packaged takes
the framework's skills from teammates who use other AI tools and from Claude Code's cloud sessions,
and it was new: nothing had run it in a real session.

Since then:

- **Packaged has run end to end in real sessions.** Every hook in the plugin, driven by a session on
  a packaged project, and standing down on a committed one (the `plugin-hooks` suite). Adopting on it,
  and switching a committed project to it (the adopt suite's `packaged` case and the upgrade suite's
  `switch-to-packaged`). The reports are in `evals/dynamic/reports/`, dated 2026-10-04.
- **Every project pins a release tag**, so the machinery a packaged project runs is fixed, named in
  its settings, and moved only by a reviewed upgrade.
- **The committed install's cost shows on every upgrade.** A marketing-site project's upgrade touched
  82 files, mostly generic machinery that no project edits.
- **The teams adopting the framework work in Claude Code,** and the next adoption, a new project,
  starts on the packaged install.

## Decision

- **`/aplyca-adf:adopt` recommends the packaged install by default.** It recommends the committed
  install instead when the team uses another AI tool for the framework's skills (Cursor, Copilot,
  Gemini or Antigravity) or needs Claude Code's cloud sessions. It still asks.
- **The committed install stays fully supported.** The manual setup in `docs/SETUP.md` is the
  committed install, and `/aplyca-adf:upgrade` switches a project either way.
- **`/aplyca-adf:upgrade` recommends the switch to packaged** to a committed project whose team works
  in Claude Code only.
- **Existing projects keep their install.** Nothing changes for them until they choose.

## Consequences

- **Positive:**
  - A new project commits about 40 fewer files, and its upgrades are mostly a pin and the project's
    own layer.
  - One pinned release per project names exactly what it runs.
- **Negative / cost:**
  - By default, a new project depends at runtime on GitHub and this repository's tags, and CI has to
    install the plugin first.
  - Claude Code's cloud sessions don't load the plugin. A team that relies on them has to say so at
    adoption.
  - Teammates on other AI tools get `AGENTS.md` and the rules, but no skills, unless the team asks for
    the committed install.
  - The Claude Directory listing is paused, so installs come from GitHub.
  - No project has used the packaged install for weeks yet. The first adoption is the trial;
    revisit this decision if it turns up problems.

## Alternatives considered

- **Keep the committed install the default until a real project has used packaged for a few weeks.**
  0016's caution. Declined: the team is starting its next project on packaged now, and the evals
  cover its paths.
- **Packaged only.** Declined: teams that use other AI tools need the committed files.
