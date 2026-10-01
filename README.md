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
- **Three lanes — ceremony follows risk, not size** — fast (a precise change, proved by a test), careful (a risk area: plus its checklist and the developer's yes), and full (something to decide: the spec-driven flow). The developer can always raise the lane; sensitive areas are configuration, enforced by a hook. ([Lanes](skeleton/specs/README.md#lanes--how-much-process-a-change-gets) · [cost](skeleton/docs/COST-MODEL.md))
- **One approval gate on the change surface** (full lane) — after the plan, before any code: scope, the files and layers the change touches, and every assumption, signed off by a human.
- **20 workflow skills** — triage, spec, plan, tests, docs, implement, review, commit, draft PR, the stakeholder update, decision records, context and drift audits, and more (`/dispatch` comes with a module). ([Catalog](docs/SKILLS-REFERENCE.md))
- **8 specialized agents** — including `@spec-analyzer`, which adversarially checks a spec folder before the gate. ([Catalog](docs/AGENTS-REFERENCE.md))
- **4 dynamic workflows** — `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep`: deterministic multi-agent fan-outs where every finding is independently verified.
- **Guardrail hooks and permissions** — the rules that must hold every time are configuration, not prose. The hooks block `--no-verify`, block commits and pushes on protected branches, block hand-edits to lockfiles and existing migrations, and report undeclared env vars. Each push and pull-request action needs a human to confirm it, and `.env` files are never read.
- **9 engineering standards** — code quality (including "write almost no comments"), testing, security, git workflow, plus customizable architecture, UI/UX, deployment, performance, observability.
- **Process records** — a constitution that gates every spec and review, Process Decision Records for how the team works, ADRs for the application, and on-demand code-level reference pages.
- **Optional modules** — `github` (PR template with traceability and constitution gates, issue forms, secret scan, base-branch policy), `git-hooks` (tool-agnostic `pre-push`), `clickup` (ClickUp's MCP server with a read-only allowlist), `parallel-agents` (one worktree per task with its own env file and port; the main checkout only dispatches). ([Modules](modules/README.md))
- **Installer plugin** — `/adopt` and `/upgrade` for Claude Code, plus `/cost-report` to see what agent sessions cost. ([Plugin](plugins/aplyca-framework/README.md))
- **Evals** — structural checks plus functional tests of the hooks and module scripts, run in CI on every pull request at zero token cost; dynamic fixtures for AI behavior. ([Evals](evals/README.md))
- **Onboarding, worked examples, scenario playbooks** — see [Team onboarding](#team-onboarding).

## Install in a project

### With Claude Code — the installer plugin (recommended)

1. **Install the plugin** — once per machine:

   ```bash
   claude plugin marketplace add aplyca/AgenticDevelopmentFramework
   claude plugin install aplyca-framework@aplyca
   ```

2. **Run `/adopt`** in the project. It inspects the repository (stack, commands, branching model,
   tracker, Git host) and asks which [optional modules](modules/README.md) you want. Then it copies the
   skeleton, fills the placeholders from verified repository facts only, and configures the guardrail
   hooks (`.claude/hooks/config.sh`). It records the adoption as a process decision (PDR-0001), stamps
   the baseline version at the top of `CLAUDE.md`, verifies the hooks and the `@AGENTS.md` import, and
   prepares a **draft pull request** on its own branch. It never commits to your default branch.
3. **Finish what only the team knows** in that pull request: the remaining `[PLACEHOLDER]`s, the
   constitution's principles, the sensitive areas (`AGENTS.md` and `CAREFUL_GLOBS`), and the
   stakeholder-update settings in `docs/TRACKER-INTEGRATION.md`
   (live site, previews, CMS entry links, task statuses). Then review and merge it like any change.
4. **Optional — the whole team:** let `/adopt` register the marketplace in the project's
   `.claude/settings.json`, so every teammate is offered the plugin (and `/upgrade`) when they trust
   the folder.
5. **Add a module later:** run `/adopt` again in the adopted repository. It detects the adoption and
   offers the modules you don't have yet.

The plugin contains **no framework content** — adopted repositories get plain committed files that
every AI tool can read, with or without the plugin.

### By hand

```bash
git clone https://github.com/aplyca/AgenticDevelopmentFramework.git
cp -Rn AgenticDevelopmentFramework/skeleton/. your-project/                 # never overwrites your files
cp -Rn AgenticDevelopmentFramework/modules/github/files/. your-project/     # each optional module you want
AgenticDevelopmentFramework/modules/clickup/install.sh your-project          # clickup merges instead of copying
```

Then follow [docs/SETUP.md](docs/SETUP.md): fill `AGENTS.md` and the constitution, configure the
hooks, stamp the baseline, and verify.

## Update a project

The framework is copied in, not installed as a dependency, so updates are deliberate and keep your
customizations. Read the **Upgrade impact** of each release in [CHANGELOG.md](CHANGELOG.md) first —
the field-practices release fixes defects that affect every adopted repository and lists three
migration steps.

1. **Update the plugin** — then restart Claude Code:

   ```bash
   claude plugin marketplace update aplyca
   claude plugin update aplyca-framework@aplyca
   ```

2. **Run `/upgrade`** in the adopted project. It reads the baseline stamp
   (`<!-- Skeleton source: <SHA> (<date>) · modules: … -->`) and diffs the framework from that
   version to the latest. It sorts every changed file into overwrite, merge, or additive, applies the
   CHANGELOG migration steps, and shows you the plan before changing anything. Then it updates the
   files — your project-specific content stays — re-stamps, and prepares a draft pull request.
3. **Review the pull request** and run the verification in [docs/UPGRADING.md](docs/UPGRADING.md):
   valid settings, hooks that fire, both instruction files loading, a smoke test of a changed skill.

By hand, or to cherry-pick one improvement: [docs/UPGRADING.md](docs/UPGRADING.md).

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

## The workflows

Every task starts with `/triage`. It states what the task is and picks the **lane** — how much
process the change gets. The lane follows risk and uncertainty, not size: the steps that find
defects (a test that proves the change, the hooks, CI, a reviewed draft pull request, the human QC)
run in every lane; what changes is how much is written down and approved before the code exists.

```
task ─▶ /triage ─┬─▶ answer ─────────▶ deliver the answer (no lane, no spec, no environment)
                 ├─▶ FAST lane ──────▶ restate + "done when" → edit → targeted test → /commit
                 │   (precise request, few files, no risk trigger; light CR N on delivered work)
                 ├─▶ CAREFUL lane ───▶ fast + the risk area's checklist + the developer's yes
                 │   (migration, authorization, personal data, shared contract, sensitive area)
                 └─▶ FULL lane — something to decide, a new feature, cross-layer work
                        │
   /write-spec ──▶ /write-plan (+ @spec-analyzer) ──▶ APPROVAL GATE ──▶ spec: commit
   (spec.md)       (plan.md, tasks.md)                 scope · change surface · assumptions
                        │
   /write-docs ──▶ /implement: per task  test ✗ → code → test ✓ → commit ──▶ reconcile docs
   (docs:)                                                                     gate results
                        │
   every lane: /review ──▶ /open-pr (draft, when asked) ──▶ human QC ──▶ ready ──▶ merge
                        │
   /stakeholder-update ("update the client") — drafted, shown, posted on the PR for the team to relay
```

| Situation | Lane and workflow | Playbook |
|---|---|---|
| Typo, copy, version bump, dev tooling; a precise adjustment the requester already decided | **Fast** — one-line triage → edit → targeted test → `/commit`; a light `CR N` on delivered work | [Change request § Light or full?](docs/scenarios/change-request.md#light-or-full) |
| The same, in a risk area or a sensitive area | **Careful** — fast + the area's checklist, `@security-reviewer` for authorization, data, or payments, and the developer's yes | [Lanes](skeleton/specs/README.md#lanes--how-much-process-a-change-gets) |
| New feature, unclear requirement, a design choice, cross-layer work | **Full** — `/write-spec` → `/write-plan` → **approval gate** → `/write-docs` → `/implement` (one red → green commit per task) → `/review` → `/open-pr` | [newsletter-signup example](docs/examples/newsletter-signup/README.md) |
| Change request with something to decide | **Full** — `/write-spec` amends the folder as `CR N` → the same gate and loop, for the delta only, on a fresh branch | [Change request](docs/scenarios/change-request.md) · [example](docs/examples/newsletter-topics/README.md) |
| Bug | `/debug` → then the lane the fix needs: regression test (red) → fix (green) → `/commit` | [Debugging](docs/scenarios/debugging.md) |
| Production is broken | **Careful**, without delay — root cause → regression test → fix → draft PR → ship; then backfill the spec folder | [Hotfix](docs/scenarios/hotfix.md) |
| Refactor | `/refactor`: characterization tests first, one green `refactor:` commit per step; full lane or an ADR for a structure others must follow | [Refactor](docs/scenarios/refactor.md) |
| Investigation, impact analysis, estimate | No lane — `/triage` → the answer, where the task asks for it | [Answer-only task](docs/scenarios/answer-only-task.md) |
| A change to how the team works | `/record-decision` → a PDR in `docs/process/` | — |
| Several tasks at once | `/dispatch` from the main checkout; each task in its own worktree (`parallel-agents` module) | [Parallel agents](docs/scenarios/parallel-agents.md) |
| High stakes or a broad sweep | `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep` | [Skills catalog](docs/SKILLS-REFERENCE.md) |

**The developer's intuition counts.** Say "full lane on this", "be careful here", or "just a quick
fix": raising the lane is always honored; lowering it keeps a risk area's checklist unless the
developer explicitly accepts the risk. More effort has other dials too — questions before any code,
`/evaluate` to compare designs, a higher effort level or model, `/deep-review` — each with its cost in
[`COST-MODEL.md` § Effort](skeleton/docs/COST-MODEL.md#effort--what-to-raise-and-what-it-costs).
Teams list their **sensitive areas** once (`AGENTS.md`, mirrored in `CAREFUL_GLOBS`), and a hook stops
a fast-lane edit there.

**Cost.** A session costs roughly *calls × context*. The lanes, one task per session, short tool
output, and the right model are the big levers — `sonnet` for work with a clear spec and a way to
check it, `opus` for the full lane's spec and plan and other judgment work, switched where the cache
is cold (version-less aliases throughout); [`COST-MODEL.md`](skeleton/docs/COST-MODEL.md) has the measured numbers,
and the plugin's `/cost-report` shows what your own sessions cost.

What holds in every workflow: nothing leaves the machine unless a human asks — no push, pull
request, tracker comment, or message — and the hooks and permissions enforce the rules that must
hold every time. The full reference is the `/spec-workflow` skill and
[`skeleton/specs/README.md`](skeleton/specs/README.md).

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

modules/                  Optional additions: github/, git-hooks/, clickup/, parallel-agents/
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
