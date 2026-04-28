# [PROJECT NAME] — Antigravity / Gemini Instructions

<!-- This file extends AGENTS.md with Antigravity and Gemini-specific features. -->
<!-- AGENTS.md contains universal project context (read by all AI tools). -->
<!-- This file adds: Antigravity agent structure references, Gemini-specific guidance. -->

## Antigravity agent structure

If this project uses Antigravity's `.agent/` directory, the structure is:

| Directory | Purpose |
|---|---|
| `.agent/rules/` | Governance rules for agent behavior |
| `.agent/skills/` | Reusable skill definitions |
| `.agent/workflows/` | Multi-step operation definitions |

<!-- CUSTOMIZE: Remove this section if your project does not use Antigravity's .agent/ structure. -->
<!-- If your project uses .claude/ for Claude Code, Antigravity reads AGENTS.md for project context instead. -->

## Development workflows

See `AGENTS.md` for the complete development workflow (feature development, hotfix, commit conventions). This project uses **multi-perspective spec-driven, test-driven, docs-first AI-assisted development** — see `docs/SPEC-MODEL.md` for the spec model.

When using Antigravity:
- Use `AGENTS.md` as the primary source of project context, conventions, and workflows
- Read `docs/SPEC-MODEL.md` to understand the multi-perspective spec model — required sections are enforced before approval
- Specs live in `specs/` — read the relevant spec (every filled section, not just Functional) before implementing
- Follow the full phase order: **spec → tests → docs → implement → review → ship**
- Commit each phase separately so the next phase has a clean diff to scope from:
  - `spec:` — the multi-perspective spec, before tests
  - `test:` — failing tests from ACs and testable requirements (Security, A11y, Perf), before docs
  - `docs:` — pre-implementable user-facing docs (admin guides, API contracts, end-user copy), before implementation. Skip cleanly when the spec lists no pre-implementable docs.
  - `feat:` / `fix:` — code that makes the tests pass; small doc reconciliations fold in here, called out in the message body
- Follow the commit message prefixes defined in `AGENTS.md` and `.claude/rules/git-workflow.md`

## Documentation references

Read these docs for context before making decisions in the relevant area:

| Document | Read when... |
|---|---|
| `docs/SPEC-MODEL.md` | Writing or reviewing any spec (the multi-perspective spec model is mandatory) |
| `docs/ARCHITECTURE.md` | Designing features, reviewing data flow |
| `docs/security/SECURITY.md` | Touching auth, data handling, API endpoints |
| `docs/infrastructure/OVERVIEW.md` | Changing deployment, CI/CD, environments |
| `docs/GLOSSARY.md` | Writing specs or user-facing text |
| `docs/architecture/decisions/` | Making or revisiting a technical decision (ADRs) |
