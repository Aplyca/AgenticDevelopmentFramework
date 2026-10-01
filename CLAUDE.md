# Agentic Development Framework

This is the **source repository** for the Agentic Development Framework — a production-grade framework for professional **multi-perspective spec-driven, test-driven, docs-first AI-assisted development** on any project.

It is NOT a software application. It contains a portable project skeleton, optional modules, an installer plugin, documentation, evals, and a team onboarding guide. There is no app to build or run — but there are evals to run (below).

The repo slug is `AgenticDevelopmentFramework` (renamed from `ai-dev-starter-kit`; GitHub redirects the old URLs). The project is named and referenced as the **Agentic Development Framework** in all docs and external materials (formerly the Agentic Development Framework).

## Repository structure

- `skeleton/` — **the portable project skeleton** (copied into any software project)
  - `skeleton/AGENTS.md` — universal AI instructions (read by all AI tools; Claude Code reads it through the `@AGENTS.md` import in `skeleton/CLAUDE.md`)
  - `skeleton/CLAUDE.md` — Claude Code layer (skills, agents, workflows, enforced guardrails)
  - `skeleton/GEMINI.md` — Antigravity / Gemini layer
  - `skeleton/.claude/` — agents, skills, workflows (`*.js`), hooks (+ `config.sh`), rules, `settings.json`
  - `skeleton/.agents/` — Antigravity compatibility (symlink to `.claude/skills`)
  - `skeleton/.cursor/rules/` — Cursor rule files (`.mdc`)
  - `skeleton/specs/` — `README.md` (the process) and `_templates/{spec,plan,tasks}.md`
  - `skeleton/docs/` — constitution, spec model, process (PDRs), reference, tracker integration, and documentation templates
- `modules/` — optional additions (`github/`, `git-hooks/`, `clickup/`, `parallel-agents/`); each has a `MODULE.md` and a `files/` tree mirroring the target repo
- `plugins/aplyca-framework/` — the Claude Code installer plugin (`/adopt`, `/upgrade`); contains no framework content
- `docs/` — framework guides (setup, upgrading, onboarding, catalogs, examples, scenarios) and `docs/decisions/` (why the framework works the way it does)
- `evals/` — static checks, hook and module functional tests, dynamic fixtures
- `.claude/` — configuration for working on **this framework repo** (not for target projects)

## When editing this repo

- Everything inside `skeleton/` and `modules/*/files/` must stay **generic** — no project-specific stack, paths, or conventions
- Agent definitions learn project context from `AGENTS.md`, `CLAUDE.md`, and rules at runtime; skills reference them — never hardcode specifics
- Universal rules (code-quality, testing, security, git-workflow) apply to any language/framework; customizable rules (architecture, ui-ux, deployment, performance, observability) have `<!-- CUSTOMIZE -->` markers
- Skill and agent frontmatter use only documented keys, hyphenated (`argument-hint`, `disable-model-invocation`, `user-invocable`) — unknown keys are silently ignored. Hooks use the nested `hooks` array and read the event from stdin
- Relative links inside `skeleton/` must resolve inside an adopting repo — never link to framework-only docs from the skeleton
- Every change to `skeleton/` or `modules/` carries a `CHANGELOG.md` entry with its **Upgrade impact** (overwrite / merge / additive, plus migration steps when needed); significant design changes get a record in `docs/decisions/`
- Run `./evals/run-evals.sh` before committing — structural checks plus functional tests of the hooks and module scripts; CI runs the same on every pull request
- The repo is public — never include client, customer, or internal project names anywhere (files, examples, commit messages, PR descriptions); use the fictional newsletter feature from `docs/examples/` instead
