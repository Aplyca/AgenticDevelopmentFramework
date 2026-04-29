# Changelog

All notable changes to the AI-Assisted Development Framework. Versions are referenced by **commit SHA + date** — the framework does not use semver.

Adopting projects: see [`docs/UPGRADING.md`](docs/UPGRADING.md) for the procedure to pull these changes into a project that already adopted an earlier skeleton version.

For each entry, **Upgrade impact** classifies the change against the [three-bucket file taxonomy](docs/UPGRADING.md#file-taxonomy-three-buckets):
- **Overwrite** — file is safe to copy verbatim from the new skeleton
- **Merge** — file has customization expectations; reapply your customizations on top
- **Additive** — new file, no existing project version to merge against

## Unreleased

### Added
- `docs/UPGRADING.md` — guide for upgrading a target project to a newer skeleton version. Covers the three-bucket file taxonomy, OLD_SHA → NEW_SHA procedure, AI-assisted upgrade pattern, and four common scenarios.
- `CHANGELOG.md` (this file) — per-commit changelog so upgrade consumers don't have to read git log.
- `<!-- Skeleton source: [SHA] ([date]) -->` template line at the top of `skeleton/CLAUDE.md`. Adopting projects fill in their baseline SHA so future upgrades have a known starting point.
- `skeleton/.claude/settings.json` — wired the default model (`claude-sonnet-4-6`) and a starter `permissions.allow` list of universally-safe read-only commands (git status/diff/log, ls, rg, grep, find). Cuts permission-prompt interruptions and aligns the default with `docs/COST-MODEL.md` instead of relying on each user's tool-level setting.
- `skeleton/CLAUDE.md` — new "Lightweight mode — when to skip the full workflow" section with a per-change-type table (feature vs bug fix vs typo vs refactor vs tooling vs spike) and a perf tip about deleting unused rule files to shrink the auto-loaded prefill.
- `skeleton/docs/COST-MODEL.md` — new "Switching tiers in Claude Code" subsection documenting `/model`, agent `model:` frontmatter, and the `/fast` Opus-4.6-only output-speed toggle.

### Changed
- `README.md` — added pointer to `docs/UPGRADING.md` in the Get started section.
- `docs/SETUP.md` — replaced the brief "Updating" paragraph with a pointer to the full upgrading guide.
- `skeleton/CLAUDE.md` cost-model paragraph now points at `.claude/settings.json` as the source of truth for the default model.

### Upgrade impact
- **Additive**: `docs/UPGRADING.md`, `CHANGELOG.md`. Drop in.
- **Merge**: `skeleton/CLAUDE.md` (new comment line near the top, updated cost-model paragraph, new Lightweight-mode section — keep your project name and any team-specific notes); `skeleton/.claude/settings.json` (if your project added hooks or extra permissions, merge them on top of the new model + permissions block).
- **Overwrite-with-care**: `README.md` and `docs/SETUP.md` are framework-owned and not part of the skeleton, so adopting projects don't copy these. The change is internal to the framework repo.

## ed3d1a1 — 2026-04-29 — Mermaid diagrams + MCP integration

### Added
- Mermaid subsection in `specs/_template.md` with worked examples for system context, sequence, state, and ER diagrams.
- `skeleton/docs/MCP-INTEGRATION.md` — when to set up an MCP server, what to expose, reference TypeScript implementation, wiring instructions for Claude Code / Cursor / Antigravity.

### Upgrade impact
- **Overwrite**: `skeleton/docs/MCP-INTEGRATION.md` (new file).
- **Merge**: `specs/_template.md` if your team has customized the template; otherwise overwrite.
- Existing filled-in specs are project-owned and unaffected.

## 6020538 — 2026-04-29 — `/orchestrate` skill

### Added
- `skeleton/.claude/skills/orchestrate/` — dispatches multiple specialized agents in parallel for review or investigation. Built-in task types: `review`, `investigate`, `pre-commit`, `custom`.

### Notes
- Explicitly does NOT auto-progress through workflow phases — preserves the plan-then-execute discipline.
- More expensive than `/review`; use only for high-stakes diffs or multi-angle exploration.

### Upgrade impact
- **Overwrite**: skill directory.
- **Merge**: `skeleton/CLAUDE.md` skills table — add a row for `/orchestrate`.

## 348cc2d — 2026-04-29 — Memory strategy doc

### Added
- `skeleton/docs/MEMORY-STRATEGY.md` — documents the six persistence layers (`AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, specs, ADRs, persistent memory) and a decision tree for where any given fact belongs. Includes consultancy-specific guidance for per-client vs cross-client memory.

### Upgrade impact
- **Overwrite**: new file.

## a1c5736 — 2026-04-28 — `/spec-drift` skill

### Added
- `skeleton/.claude/skills/spec-drift/` — read-only audit that detects divergences between a committed spec and the current code, tests, and docs. Reports findings categorized by severity; does not fix.
- Recommended cadence: monthly per spec area.

### Upgrade impact
- **Overwrite**: skill directory.
- **Merge**: `skeleton/CLAUDE.md` skills table — add a row for `/spec-drift`.

## 4fac0ec — 2026-04-28 — Cost model and model tiering doc

### Added
- `skeleton/docs/COST-MODEL.md` — three-tier model recommendation (Haiku / Sonnet / Opus), per-skill recommendations, per-agent recommendations, prompt-caching strategy, cost attribution patterns for consultancies, tool integrations (Anthropic Console, Helicone, LiteLLM), budget enforcement guidance.

### Changed
- Agent frontmatter `model:` fields adjusted to match recommendations:
  - Haiku: `@code-reviewer`, `@security-reviewer`, `@architect`, `@ux-reviewer`
  - Sonnet: `@spec-writer`, `@test-runner`, `@debugger`

### Upgrade impact
- **Overwrite**: `skeleton/docs/COST-MODEL.md` (new file), all `.claude/agents/*` files (the `model:` field is framework-owned; if your team intentionally overrode it, document the override and re-apply after copying).

## 23f009c — 2026-04-28 — Eval framework for the framework itself

### Added
- Top-level `evals/` directory in the framework repo with static structural checks (bash + grep) and dynamic fixture-based AI-invocation evals.
- Currently 48/48 static checks passing.

### Notes
- Adopting projects do NOT get evals copied in by default. The pattern is documented in `evals/README.md` for teams that author custom skills / rules / spec patterns and want regression coverage.

### Upgrade impact
- **N/A for adopting projects** — framework-internal change. Optionally adopt the pattern for your custom artifacts; see `evals/README.md`.

## 965d253 — 2026-04-28 — Docs-first phase coverage in onboarding, examples, Antigravity guide

### Fixed
- Onboarding, worked examples, and Antigravity (`GEMINI.md`) guidance now explicitly cover the docs-first phase between tests and implement.

### Upgrade impact
- **Merge**: `skeleton/GEMINI.md` if your team uses Antigravity.
- **Overwrite**: docs/onboarding files.

## 8277b5d — 2026-04-28 — Cursor rules and agents extended to multi-perspective + docs-first

### Changed
- `.cursor/rules/*.mdc` files updated to reflect the multi-perspective spec model and the docs-first phase.

### Upgrade impact
- **Overwrite**: all `.cursor/rules/*.mdc` files.

## 9332f73 — 2026-04-28 — Docs-first delivery as a third discipline

### Added
- `/write-docs` skill — plans and writes pre-implementable user-facing docs (admin guides, API contracts, end-user copy defaults) BEFORE implementation.
- New phase added to the workflow between tests and implement; `/write-docs` skips cleanly when the spec has no pre-implementable docs.
- `docs:` commit prefix added to `git-workflow.md` for the new phase.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/skills/write-docs/`, `skeleton/.claude/rules/git-workflow.md`.
- **Merge**: `skeleton/CLAUDE.md` skills table.

## 2b22837 — 2026-04-27 — Multi-perspective spec model + repositioning

### Added
- Multi-perspective spec model: every spec captures input from all relevant roles (business, functional, security, accessibility, privacy, design, performance, testing, documentation, deployment, etc.) in one document. Mandatory sections enforced before approval.
- `skeleton/docs/SPEC-MODEL.md` — full structure and worked examples.
- `docs/scenarios/` playbooks (modifying-existing-feature, hotfix, refactor, debugging).
- `docs/examples/newsletter-signup/` end-to-end worked example on Next.js + Contentful + Vercel.

### Changed
- Framework repositioned from "starter kit" to "AI-Assisted Development Framework" in all user-facing materials. Repo slug `ai-dev-starter-kit` preserved for URL stability.

### Upgrade impact
- **Overwrite**: `skeleton/docs/SPEC-MODEL.md`, `specs/_template.md` (if unmodified by your team).
- **Merge**: `specs/_template.md` if customized; `AGENTS.md` and `CLAUDE.md` if your team's wording referenced "starter kit".

## 466d205 — 2026-04-26 — Anti-rationalization tables, verification gates, red flags

### Added
- Skills now include explicit anti-rationalization tables (common excuses for skipping a step → why they don't apply), verification gates, and red-flag patterns.

### Upgrade impact
- **Overwrite**: all `skeleton/.claude/skills/*/SKILL.md`.

## cd04fa6 — 2026-04-26 — Explicit plan-then-execute gates

### Added
- `/write-tests` and `/implement` skills now have explicit plan-then-execute gates: the AI presents a plan and waits for approval before writing tests or code.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/skills/write-tests/`, `skeleton/.claude/skills/implement/`.

## c68e165 — 2026-04-26 — TDD by committing tests before implementation

### Changed
- Workflow enforces committing tests before implementation. Tests are the verification contract that defines "done".
- `test:` commit prefix formalized in `git-workflow.md`.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/rules/git-workflow.md`, affected skills.

## e447f90 — 2026-04-26 — Initial release

### Added
- Initial skeleton with 7 specialized AI agents, 11 workflow skills, 9 engineering standards (4 universal + 5 customizable), spec template, documentation templates, AGENTS.md / CLAUDE.md / GEMINI.md, Cursor compatibility, Antigravity compatibility.

### Upgrade impact
- **N/A** — this is the baseline.

## See also

- [`docs/UPGRADING.md`](docs/UPGRADING.md) — how to apply these changes to an existing project
- [`docs/SETUP.md`](docs/SETUP.md) — initial adoption
- [`README.md`](README.md) — what's in the skeleton
