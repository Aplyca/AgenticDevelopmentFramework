# Agentic Development Framework

This is the **source repository** for the Agentic Development Framework — a production-grade framework for professional **multi-perspective spec-driven, test-driven, docs-first AI-assisted development** on any project.

It is NOT a software application. It contains a portable project skeleton, optional modules, an installer plugin, documentation, evals, and a team onboarding guide. There is no app to build or run — but there are evals to run (below).

The repo slug is `AgenticDevelopmentFramework` (renamed from `ai-dev-starter-kit`; GitHub redirects the old URLs). The project is named and referenced as the **Agentic Development Framework** in all docs and external materials (formerly the AI-Assisted Development Framework).

## Repository structure

- `skeleton/` — **the portable project skeleton** (copied into any software project)
  - `skeleton/AGENTS.md` — universal AI instructions (read by all AI tools; Claude Code reads it through the `@AGENTS.md` import in `skeleton/CLAUDE.md`)
  - `skeleton/CLAUDE.md` — Claude Code layer (skills, agents, workflows, enforced guardrails)
  - `skeleton/GEMINI.md` — Antigravity / Gemini layer
  - `skeleton/.claude/` — agents, skills, workflows (`*.js`), hooks (+ `config.sh`), rules, `settings.json`
  - `skeleton/.cursor/rules/` — Cursor rule files (`.mdc`)
  - `skeleton/specs/` — `README.md` (the process) and `_templates/{spec,plan,tasks}.md`
  - `skeleton/docs/` — constitution, spec model, process (PDRs), reference, tracker integration, and documentation templates
- `modules/` — optional additions (`github/`, `git-hooks/`, `clickup/`, `parallel-agents/`, `docker/`); each has a `MODULE.md` and a `files/` tree mirroring the target repo, and a module whose skills a packaged install takes from a plugin of its own has a `plugin.json` beside them (decision 0023)
- `plugins/adf/` — the Claude Code plugin: the installer (`/adf:adopt`, `:upgrade`, `:cost-report`, written by hand) and, for the packaged install (decisions 0016, 0017, 0019, 0020), the skeleton's skills, agents, workflows, hook scripts, and four reference docs, and the `parallel-agents` module's `/dispatch` — **generated** by `scripts/build-plugins.sh` into the paths its `.generated` file lists; never edit those by hand
- `plugins/adf-dev/` — the development plugin (decision 0023): its manifest and README are written by hand; its skills and agents are **generated** by `scripts/build-plugins.sh` from the modules whose `module.json` names it (`docker`'s `/dev-env`) into the paths its `.generated` file lists; never edit those by hand. `adf-connect`, for trackers and services, is planned
- `ADOPT.md` — the adoption procedure for AI agents, which the top of `README.md` points to; keep it in step with `/adopt`
- `docs/` — framework guides (setup, upgrading, onboarding, catalogs, examples, scenarios) and `docs/decisions/` (why the framework works the way it does)
- `evals/` — static checks, hook and module functional tests, dynamic fixtures
- `.claude/` — configuration for working on **this framework repo** (not for target projects)

## When editing this repo

- Everything inside `skeleton/` and `modules/*/files/` must stay **generic** — no project-specific stack, paths, or conventions
- Agent definitions learn project context from `AGENTS.md`, `CLAUDE.md`, and rules at runtime; skills reference them — never hardcode specifics
- Universal rules (code-quality, testing, security, git-workflow) apply to any language/framework; customizable rules (architecture, ui-ux, deployment, performance, observability) have `<!-- CUSTOMIZE -->` markers
- Skill and agent frontmatter use only documented keys, hyphenated (`argument-hint`, `disable-model-invocation`, `user-invocable`) — unknown keys are silently ignored. Hooks use the nested `hooks` array and read the event from stdin
- No symlinks anywhere in the repository — the Claude Directory's checks reject them. A link a project needs (Antigravity's `.agents/skills`) is created by `/adopt`
- Relative links inside `skeleton/` must resolve inside an adopting repo — never link to framework-only docs from the skeleton
- Every change to `skeleton/` or `modules/` carries a `CHANGELOG.md` entry with its **Upgrade impact** (overwrite / merge / additive, plus migration steps when needed); significant design changes get a record in `docs/decisions/`
- After any change under `skeleton/.claude/`, to a module's skill or agent (`modules/*/files/.claude/`) or `module.json`, or to a reference doc the plugin carries (`COST-MODEL.md`, `MCP-INTEGRATION.md`, `MEMORY-STRATEGY.md`, `SPEC-MODEL.md` in `skeleton/docs/`), run `scripts/build-plugins.sh` and commit `plugins/` with it — the static checks fail on drift. `adf`'s `"version"` changes only in a release (decision 0017), and the build carries it into every other plugin's manifest (decision 0023). A new plugin needs its folder with a hand-written manifest and README, and an entry in `.claude-plugin/marketplace.json`
- Run `./evals/run-evals.sh` before committing — structural checks plus functional tests of the hooks and module scripts; CI runs the same on every pull request
- The repo is public — never include client, customer, or internal project names anywhere (files, examples, commit messages, PR descriptions); use the fictional newsletter feature from `docs/examples/` instead
