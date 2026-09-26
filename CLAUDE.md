# AI-Assisted Development Framework

This is the **source repository** for the AI-Assisted Development Framework — a production-grade framework for professional **multi-perspective spec-driven, test-driven, docs-first AI-assisted development** on any project.

It is NOT a software application. It contains a portable project skeleton, documentation, and a team onboarding guide. Do not try to build, run, or test it.

The repo slug is `AgenticDevelopmentFramework` (renamed from `ai-dev-starter-kit`; GitHub redirects the old URLs). The project is positioned and referenced as the **AI-Assisted Development Framework** in all docs and external materials.

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
- `.claude/` — configuration for working on **this framework repo** (not for target projects)
- `docs/` — framework guides (setup, onboarding, examples, scenarios, spec model)
- `README.md` — about the framework

## When editing this repo

- Everything inside `skeleton/` must stay **generic** — no project-specific stack, paths, or conventions
- Agent definitions learn project context from CLAUDE.md and rules at runtime
- Universal rules (code-quality, testing, security, git-workflow) apply to any language/framework
- Customizable rules (architecture, ui-ux, deployment, performance, observability) have `<!-- CUSTOMIZE -->` markers
- Skills reference CLAUDE.md and rules for project context — never hardcode specifics
- The repo is public — never include client, customer, or internal project names anywhere (files, examples, commit messages, PR descriptions); use the fictional newsletter feature from `docs/examples/` instead
