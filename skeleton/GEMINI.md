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

See `AGENTS.md` for the complete development workflow (feature development, hotfix, commit conventions).

When using Antigravity:
- Use `AGENTS.md` as the primary source of project context, conventions, and workflows
- Specs live in `specs/` — read the relevant spec before implementing
- Commit specs before implementation (`spec:` prefix) — the `git diff` scopes the work
- Follow the commit message prefixes defined in `AGENTS.md`

## Documentation references

Read these docs for context before making decisions in the relevant area:

| Document | Read when... |
|---|---|
| `docs/ARCHITECTURE.md` | Designing features, reviewing data flow |
| `docs/security/SECURITY.md` | Touching auth, data handling, API endpoints |
| `docs/infrastructure/OVERVIEW.md` | Changing deployment, CI/CD, environments |
| `docs/GLOSSARY.md` | Writing specs or user-facing text |
