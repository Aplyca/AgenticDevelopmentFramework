# 0044: The parallel-agents guide ships in the plugin; the project keeps only its shared services (parallel-agents module)

- **Status:** accepted
- **Date:** 2026-10-18
- **Amends:** [0019](0019-reference-docs-in-the-plugin.md) — which docs stay in the project; [0008](0008-dispatcher-and-worker-worktrees.md) — what the module copies

## Context

The parallel-agents module copied `docs/PARALLEL-AGENTS.md` into every project that installed it,
and `/adf:upgrade` merged it on every release that changed it. Decision 0019 kept it in the project,
beside `TRACKER-INTEGRATION.md`, because it holds the project's settings. Only one of its sections
does, though. § Shared services, the doc's only `<!-- CUSTOMIZE -->` marker, records what the
project's worktrees share. The other 150 lines — where a session works, how a task gets its worktree,
the scripts, a server per worktree, seeing the environments, Claude Code's worktrees — are the
framework's model, the same in every project.

That model changed often. The doc changed in eight pull requests between decisions 0027 and 0042,
and `git diff v2.2.0 v2.4.0` on it is 105 lines, all framework text. An adopting project on the
packaged install reported the cost: its copy differed from the module's only in the owner line and
§ Shared services, and its upgrade to v2.4.0 merged the 105 lines into a document the team never
edits. Hooks and skills that enforce the model (`protect-hub.sh`, `session-context.sh`,
`/adf:dispatch`) move with the pin; a merged copy can lag behind them.

The reference-doc machinery already handles a doc like this. `link-reference-docs.py` treats every
file in `plugins/adf/docs/` as a reference doc. Two things were missing. `scripts/forms.py` named the
four core docs in a constant, and wrote every one into each committed install. And the guide is a
module's, which a project without the module shouldn't get.

## Decision

- **`adf` carries the guide** as `plugins/adf/docs/PARALLEL-AGENTS.md`, beside the four reference
  docs, in the plugin form: `/adf:dispatch`, `adf-worktree-new`. A packaged project reads the
  plugin's copy, and its files link the copy at the release they pin. A committed project gets
  `docs/PARALLEL-AGENTS.md` from `build-committed.py`, in the committed form, in the safe-to-overwrite
  bucket.
- **The module copies `docs/SHARED-SERVICES.md` instead:** an owner line, a pointer to the guide, and
  the `CUSTOMIZE` marker for what worktrees share, what a task may copy, and what a copy costs. It's
  the project's, and it stays merge-required. The guide's § Shared services keeps the how: start the
  copy in `START_CMD`, remove it in `STOP_CMD`, point the worktree at it through `ENV_OVERRIDES`.
- **Its own name, not the guide's.** With both named `PARALLEL-AGENTS.md`, the link script would
  rewrite the mentions of the project's page into links to the guide, and report the page as a
  reference doc still in `docs/`. The committed install would write the guide over the page, and the
  build would refuse `/adf-dev:dev-env`, which names the page and can't reach `adf`'s docs.
- **A module names its guide in `module.json`** (`"docs": ["PARALLEL-AGENTS"]`).
  - `build-committed.py` writes the guide only for the modules it's given.
  - `link-reference-docs.py` also rewrites the modules' files a project has. It expects the guide in
    a committed project's `docs/` only when the stamp names the module.
  - The session-context hook names the guide among the plugin's docs only where `worktree.conf`
    exists.
- **`/adf:upgrade` splits the old copy, in either install.** It writes `docs/SHARED-SERVICES.md` with
  the copy's owner line and what the team recorded in § Shared services. A copy otherwise unchanged
  since OLD_SHA goes (packaged) or becomes the guide (committed). One edited elsewhere is listed
  section by section for the developer, and nothing is replaced until they decide.
- **§ Shared services stays a file of its own.** `AGENTS.md` loads in every session, and the
  deployment rule is about deploys, not local worktrees. `/adf-dev:dev-env` records into the page,
  and it's the one part of the module's docs a team edits.

## Consequences

- **Positive:**
  - A packaged project's upgrades touch only what the team wrote. The framework's model of parallel
    sessions moves with the pin, with the hooks and skills that enforce it.
  - A committed project overwrites the guide instead of merging it.
  - A module can ship a guide the same way, without another constant in the scripts.
- **Negative / cost:**
  - **A one-time migration** in each project that has the module: one more file in `docs/`, and the
    mentions of § Shared services renamed.
  - **People read the guide on GitHub,** at the pinned release, in a packaged project, as with the
    other reference docs.
  - **Adding a reference doc means two lists:** `forms.REFERENCE_DOCS`, which the build now checks
    against `plugins/adf/docs/`, and, for a module's guide, its `module.json`.

## Alternatives considered

- **Keep the guide in the project** (decision 0019's choice). Declined: every release that changes
  the model costs each project a merge of text it doesn't own.
- **Keep the name `docs/PARALLEL-AGENTS.md` for the project's page,** and give the plugin's guide
  another. Declined: decisions, the changelog, and the projects' own docs name `PARALLEL-AGENTS.md`
  for the model, and the link script moves those mentions to the release without a hand edit.
- **Move § Shared services into `AGENTS.md` or `.claude/rules/deployment.md`.** Declined: see the
  last point of the decision.
