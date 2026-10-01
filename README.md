# AI-Assisted Development Framework

A production-grade framework for professional **multi-perspective spec-driven, test-driven, docs-first AI-assisted development.** It ships as a portable project skeleton you drop into any codebase, optional modules for your Git host and ways of working, and an installer plugin for Claude Code. It includes an enforced multi-perspective spec model, specialized agents, workflow skills, multi-agent workflows, and guardrail hooks. Engineering standards and a team onboarding path are part of it too.

The framework is built on three reinforcing disciplines:
- **Multi-perspective spec-driven design** — every feature's spec captures input from all relevant roles (business, functional, security, accessibility, privacy, design, performance, and more), with required sections enforced. The plan that follows names the exact **change surface**, and nothing is implemented until a human approves it.
- **Test-driven development** — every task names the test that proves it; the test is written and **seen failing** before the code that makes it pass, and each task lands as one commit.
- **Docs-first delivery** — user-facing docs (admin guides, API contracts, end-user copy) are written from the spec and plan before implementation, and deliberately updated when reality shifts — living artifacts, never frozen contracts.

Works with Claude Code natively; supports Cursor, Antigravity, GitHub Copilot, Codex, Aider, and Windsurf via the [AGENTS.md](https://agents.md) standard.

Most of what's here was proven in real client projects first — some built on this framework, some grown alongside it — and then generalized. The reasoning behind each decision is in [`docs/decisions/`](docs/decisions/README.md).

## What's included

- **Spec folders** — `specs/NNN-<slug>/` with `spec.md` (the multi-perspective WHAT and WHY), `plan.md` (constitution check, change surface, test strategy, documentation plan, assumptions), and `tasks.md` (one task per commit, each naming its test, plus recorded gate results). Change requests amend the same folder. ([Process](skeleton/specs/README.md) · [Spec model](skeleton/docs/SPEC-MODEL.md))
- **One approval gate on the change surface** — after the plan, before any code: scope, the files and layers the change touches, and every assumption, signed off by a human.
- **20 workflow skills** — triage, spec, plan, tests, docs, implement, review, commit, draft PR, stakeholder update, decision records, context and drift audits, and more (`/dispatch` comes with a module). ([Catalog](docs/SKILLS-REFERENCE.md))
- **8 specialized agents** — including `@spec-analyzer`, which adversarially checks a spec folder before the gate. ([Catalog](docs/AGENTS-REFERENCE.md))
- **4 dynamic workflows** — `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep`: deterministic multi-agent fan-outs where every finding is independently verified.
- **Guardrail hooks and permissions** — the rules that must hold every time are configuration, not prose. The hooks block `--no-verify`, block commits and pushes on protected branches, block hand-edits to lockfiles and existing migrations, and report undeclared env vars. Each push and pull-request action needs a human to confirm it, and `.env` files are never read.
- **9 engineering standards** — code quality (including "write almost no comments"), testing, security, git workflow, plus customizable architecture, UI/UX, deployment, performance, observability.
- **Process records** — a constitution that gates every spec and review, Process Decision Records for how the team works, ADRs for the application, and on-demand code-level reference pages.
- **Optional modules** — `github` (PR template with traceability and constitution gates, issue forms, secret scan, base-branch policy), `git-hooks` (tool-agnostic `pre-push`), `parallel-agents` (one worktree per task with its own env file and port; the main checkout only dispatches). ([Modules](modules/README.md))
- **Installer plugin** — `/adopt` and `/upgrade` for Claude Code. ([Plugin](plugins/aplyca-framework/README.md))
- **Evals** — structural checks plus functional tests of the hooks and module scripts, run in CI on every pull request at zero token cost; dynamic fixtures for AI behavior. ([Evals](evals/README.md))
- **Onboarding, worked examples, scenario playbooks** — see [Team onboarding](#team-onboarding).

## Get started

### With Claude Code — the installer plugin

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework
claude plugin install aplyca-framework@aplyca
```

Then run `/adopt` in any repository. It inspects the project and copies the skeleton plus the modules you choose. It fills the placeholders from verified repository facts and configures the guardrail hooks. It records the adoption as a process decision, stamps the baseline SHA, and prepares a draft pull request. Later, `/upgrade` brings an adopted repository to a newer version without losing its customizations. Neither ever commits to your default branch.

The plugin contains **no framework content** — adopted repositories get plain committed files that every AI tool can read.

### By hand

```bash
cp -Rn skeleton/. your-project/                         # never overwrites your files
cp -Rn modules/github/files/. your-project/             # optional modules
```

Then follow [docs/SETUP.md](docs/SETUP.md): fill `AGENTS.md` and the constitution, configure the hooks, and stamp the baseline. Already adopted an earlier version? See [docs/UPGRADING.md](docs/UPGRADING.md) and [CHANGELOG.md](CHANGELOG.md). The field-practices release fixes defects that affect every adopted repository.

## How it works

```
AGENTS.md          → Universal instructions — identity, ground rules, how work flows, boundaries (read by every AI tool)
CLAUDE.md          → Imports AGENTS.md, then adds the Claude Code layer: skills, agents, workflows, enforced guardrails
GEMINI.md          → Imports AGENTS.md, then adds Antigravity / Gemini notes
.claude/rules/     → Engineering standards, loaded when Claude reads matching files
.claude/skills/    → Workflow playbooks (/triage, /write-spec, /write-plan, /implement, …)
.claude/agents/    → Specialized agents (generic — they learn your project from AGENTS.md)
.claude/workflows/ → Dynamic multi-agent workflows (/deep-review, …)
.claude/hooks/     → Guardrails as code, configured in config.sh
.agents/skills     → Symlink to .claude/skills (Antigravity)
.cursor/rules/     → Cursor rules (.mdc)
specs/             → Spec folders — the record of intent
docs/              → Constitution, architecture, ADRs, PDRs, reference pages, security, infrastructure
```

| File | Read by |
|---|---|
| **AGENTS.md** | Codex, Cursor, GitHub Copilot, Windsurf, Aider, Gemini, and [others](https://agents.md) natively; Claude Code through the `@AGENTS.md` import in `CLAUDE.md` |
| **CLAUDE.md** | Claude Code |
| **GEMINI.md** | Antigravity, Gemini CLI |
| **.cursor/rules/** | Cursor |
| **.agents/skills/** | Antigravity |

When a repository has both a `CLAUDE.md` and an `AGENTS.md`, Claude Code reads `CLAUDE.md` **instead** — so the skeleton's `CLAUDE.md` imports `AGENTS.md` on its first line. Keep that import.

## The workflow

```
task ─▶ /triage ─┬─▶ answer only ─────────────▶ deliver the answer (no spec, no environment)
                 ├─▶ nothing to decide ────────▶ edit → verify → /commit
                 └─▶ change with something to decide
                        │
   /write-spec ──▶ /write-plan (+ @spec-analyzer) ──▶ APPROVAL GATE ──▶ spec: commit
   (spec.md)       (plan.md, tasks.md)                 scope · change surface · assumptions
                        │
   /write-docs ──▶ /implement: per task  test ✗ → code → test ✓ → commit ──▶ reconcile docs
   (docs:)                                                                     gate results
                        │
   /review (or /deep-review) ──▶ /open-pr (draft, when asked) ──▶ human QC ──▶ ready ──▶ merge
                        │
   /stakeholder-update (when asked)
```

Change requests on delivered work amend the same spec folder (`CR N`). Hotfixes fix first and backfill. Process changes become PDRs. The full reference is the `/spec-workflow` skill.

## Team onboarding

- **[docs/ONBOARDING.md](docs/ONBOARDING.md)** — week-by-week guide to adopting the workflow.
- **[docs/examples/](docs/examples/README.md)** — worked examples on a Next.js + Contentful + Vercel stack: a complete spec folder for a newsletter signup, then a change request amending it.
- **[docs/scenarios/](docs/scenarios/README.md)** — one-page playbooks: change requests, answer-only tasks, hotfixes, refactors, debugging, parallel agents.
- **[docs/decisions/](docs/decisions/README.md)** — why the framework works this way.
- **[docs/AgenticDevelopmentGuide.md](docs/AgenticDevelopmentGuide.md)** — the agentic development guide (Spanish) the framework implements.

## Repository structure

```
skeleton/                 Portable project skeleton — what an adopting repository gets
├── AGENTS.md · CLAUDE.md · GEMINI.md · README.md · CONTRIBUTING.md · .claudeignore
├── .claude/
│   ├── agents/           8 agents
│   ├── skills/           19 skills
│   ├── workflows/        4 dynamic workflows
│   ├── hooks/            guardrail hooks + config.sh
│   ├── rules/            9 engineering standards
│   └── settings.json     model alias, permissions (allow / ask / deny), hook wiring
├── .agents/skills        → .claude/skills
├── .cursor/rules/        Cursor rules
├── specs/                README.md (the process) + _templates/ (spec, plan, tasks)
└── docs/                 CONSTITUTION, SPEC-MODEL, ARCHITECTURE, TRACKER-INTEGRATION, COST-MODEL,
                          MEMORY-STRATEGY, MCP-INTEGRATION, GLOSSARY, process/ (PDRs),
                          architecture/decisions/ (ADRs), reference/, security/, infrastructure/,
                          getting-started/

modules/                  Optional additions: github/, git-hooks/, parallel-agents/
plugins/aplyca-framework/ Claude Code installer plugin (/adopt, /upgrade)
docs/                     Framework docs: SETUP, UPGRADING, ONBOARDING, references, examples,
                          scenarios, decisions
evals/                    Static checks, hook and module tests, dynamic fixtures
```

## Contributing

Contributions are welcome — bug reports, skeleton and module improvements, new scenarios, and fixes to the `/adopt` and `/upgrade` skills. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request: every change to the skeleton ships into other teams' repositories, so it has to stay generic, pass the evals, and carry a CHANGELOG entry with its upgrade impact.

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately as described in [SECURITY.md](SECURITY.md), not in public issues.

## License

[MIT](LICENSE) © Aplyca
