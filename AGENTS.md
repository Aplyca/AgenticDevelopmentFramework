# Agentic Development Framework

This is the **source repository** for the Agentic Development Framework — a production-grade framework for professional **multi-perspective spec-driven, test-driven, docs-first AI-assisted development** on any project.

It is NOT a software application. It contains the framework's plugins (its machinery and installer), a portable project skeleton, optional modules, documentation, evals, and a team onboarding guide. There is no app to build or run — but there are evals to run (below).

The repo slug is `AgenticDevelopmentFramework` (renamed from `ai-dev-starter-kit`; GitHub redirects the old URLs). The project is named and referenced as the **Agentic Development Framework** in all docs and external materials (formerly the AI-Assisted Development Framework).

## Repository structure

- `skeleton/` — **the portable project skeleton**: the layer every adopting project commits and edits as its own (decision 0028)
  - `skeleton/AGENTS.md` — universal AI instructions, read natively by Claude Code and most other AI tools (Gemini CLI through the settings file below); its first line is the framework's stamp
  - `skeleton/.claude/rules/claude-code.md` — the Claude Code layer (skills, agents, workflows, enforced guardrails): a rule with no `paths:`, loaded in every session. There is no `CLAUDE.md` (decision 0024): Claude Code would read it instead of `AGENTS.md`
  - `skeleton/.gemini/settings.json` — points Gemini CLI at `AGENTS.md`. There is no `GEMINI.md` (decision 0025): Antigravity reads `AGENTS.md` natively
  - `skeleton/.claude/` — rules, `settings.json`, and `hooks/config.sh` (the hooks' project settings); the skills, agents, workflows, and hook scripts come from `plugins/adf/`
  - `skeleton/.cursor/rules/` — Cursor rule files (`.mdc`)
  - `skeleton/specs/` — `README.md` (the process) and `_templates/{spec,plan,tasks}.md`
  - `skeleton/docs/` — constitution, process (PDRs), reference, tracker integration, and documentation templates
- `plugins/adf/` — **the source of the framework's machinery** (decision 0028): the skills, agents, workflows, hook scripts, and four reference docs, written in the form a packaged project loads (`/adf:triage`, `@adf:code-reviewer`, `${CLAUDE_PLUGIN_ROOT}/docs/…`, a Step 0 per skill and agent), plus the `parallel-agents` module's `/dispatch` and the installer (`/adf:adopt`, `:upgrade`, `:cost-report`). `scripts/build-committed.py` writes a committed project's copies from it. Only `bin/` (the module commands, decision 0027) and the spec-model, agent-checklist, and skill-steps lines in its workflows (decisions 0029, 0030) are **generated** by `scripts/build-plugins.sh`; never edit those by hand
- `plugins/adf-dev/` — the development plugin (decision 0023): the `docker` module's `/dev-env`, and its mod — the local-environment band (`hooks/`, `types/`, `tests/`), display-only (decision 0026), tested with `claude plugin test`
- `modules/` — optional additions (`github/`, `git-hooks/`, `clickup/`, `parallel-agents/`, `docker/`); each has a `MODULE.md` and, for the files a project commits, a `files/` tree mirroring the target repo. A module whose plugin carries its skills or commands names them in `module.json` (decisions 0023, 0027)
- `plugins/adf-connect/` — the connections plugin: `/adf-connect:connect`, written by hand, which writes a project's MCP configuration from a catalog of safe defaults; the servers stay in each project (decision 0023)
- `ADOPT.md` — the adoption procedure for AI agents, which the top of `README.md` points to; keep it in step with `/adopt`
- `docs/` — framework guides (setup, upgrading, onboarding, catalogs, examples, scenarios) and `docs/decisions/` (why the framework works the way it does)
- `evals/` — static checks, hook and module functional tests, dynamic fixtures
- `.claude/` — configuration for working on **this framework repo** (not for target projects)
- This file is `AGENTS.md`, read natively by Claude Code and other tools; don't add a `CLAUDE.md` or `CLAUDE.local.md`, which Claude Code would read instead

## When editing this repo

- Everything inside `skeleton/`, `modules/*/files/`, and the plugins' machinery must stay **generic** — no project-specific stack, paths, or conventions
- Agent definitions learn project context from `AGENTS.md` and the rules at runtime; skills reference them — never hardcode specifics
- Universal rules (code-quality, testing, security, git-workflow) apply to any language/framework; customizable rules (architecture, ui-ux, deployment, performance, observability) have `<!-- CUSTOMIZE -->` markers
- Skill and agent frontmatter use only documented keys, hyphenated (`argument-hint`, `disable-model-invocation`, `user-invocable`) — unknown keys are silently ignored. Hooks use the nested `hooks` array and read the event from stdin
- No symlinks anywhere in the repository — the Claude Directory's checks reject them. A link a project needs (Antigravity's `.agents/skills`) is created by `/adopt`
- Relative links inside `skeleton/` must resolve inside an adopting repo — never link to framework-only docs from the skeleton
- Every change to `skeleton/`, `modules/`, or the plugins' machinery carries a `CHANGELOG.md` entry with its **Upgrade impact** (overwrite / merge / additive, plus migration steps when needed); significant design changes get a record in `docs/decisions/`
- **Edit the machinery in its plugin form** (decision 0028): name a skill `/adf:triage` and an agent `@adf:code-reviewer`, a reference doc `${CLAUDE_PLUGIN_ROOT}/docs/SPEC-MODEL.md` (with the docs note), a module command `adf-worktree-new`; a new skill or agent opens with its Step 0, unless it runs only from the plugin. `python3 scripts/build-committed.py --check` shows what a file should read when it won't round-trip; the static checks run it
- After changing a module's script or `module.json`, `plugins/adf/docs/SPEC-MODEL.md`, an agent's checklist or a skill's steps a workflow carries, or `adf`'s version, run `scripts/build-plugins.sh` and commit `plugins/` with it — the static checks fail on drift. `adf`'s `"version"` changes only in a release (decision 0017), and the build carries it into every other plugin's manifest (decision 0023). A new plugin needs its folder with a hand-written manifest and README, and an entry in `.claude-plugin/marketplace.json`
- Run `./evals/run-evals.sh` before committing — structural checks plus functional tests of the hooks and module scripts; CI runs the same on every pull request
- Everything in the repository is in English — files, comments, examples, commit messages, PR descriptions; the static checks fail on Spanish text
- The repo is public — never include client, customer, or internal project names anywhere (files, examples, commit messages, PR descriptions); use the fictional newsletter feature from `docs/examples/` instead
