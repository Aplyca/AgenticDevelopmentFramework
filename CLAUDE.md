# AI-Assisted Development Starter Kit

This is a **reference repository** for bootstrapping professional AI-assisted, spec-driven, test-driven development on any project.

It is NOT a software application. It contains a portable project skeleton, documentation, and a team onboarding guide. Do not try to build, run, or test it.

## Repository structure

- `skeleton/` — **the portable project skeleton** (copy into any software project)
  - `skeleton/AGENTS.md` — universal AI instructions (read by all AI tools)
  - `skeleton/CLAUDE.md` — Claude Code-specific features (agents, skills, rules)
  - `skeleton/GEMINI.md` — Antigravity / Gemini-specific features
  - `skeleton/.claude/` — agents, rules, skills, hooks (for target projects)
  - `skeleton/.agents/` — Antigravity compatibility (symlink to .claude/skills)
  - `skeleton/.cursor/rules/` — Cursor rule files (.mdc format)
  - `skeleton/specs/` — spec template
  - `skeleton/docs/` — documentation templates
  - `skeleton/README.md`, `CONTRIBUTING.md` — project file templates
- `.claude/` — configuration for working on **this starter kit** (not for target projects)
- `docs/` — starter kit guides (setup, onboarding)
- `README.md` — about this starter kit

## When editing this repo

- Everything inside `skeleton/` must stay **generic** — no project-specific stack, paths, or conventions
- Agent definitions learn project context from CLAUDE.md and rules at runtime
- Universal rules (code-quality, testing, security, git-workflow) apply to any language/framework
- Customizable rules (architecture, ui-ux, deployment, performance, observability) have `<!-- CUSTOMIZE -->` markers
- Skills reference CLAUDE.md and rules for project context — never hardcode specifics
