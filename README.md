# AI-Assisted Development Framework

A production-grade framework for professional **multi-perspective spec-driven, test-driven, docs-first AI-assisted development.** Ships as a portable project skeleton (drop into any codebase), an enforced multi-perspective spec model, a docs-first delivery workflow, specialized AI agents, workflow skills, engineering standards, and a complete team onboarding path.

The framework is built on three reinforcing disciplines:
- **Multi-perspective spec-driven design** — every feature spec captures input from all relevant roles (business, functional, security, accessibility, privacy, design, performance, and more) in one document, with required sections enforced before approval.
- **Test-driven development** — tests are written from the spec and committed before implementation; they define "done".
- **Docs-first delivery** — user-facing docs (admin guides, API contracts, end-user copy) are written from the spec and tests and committed before implementation. Docs drive implementation thinking and are deliberately updated when reality shifts during implementation — they're living artifacts, never frozen contracts.

Works with Claude Code natively; supports Cursor, Antigravity, GitHub Copilot, Aider, and Windsurf via the [AGENTS.md](https://agents.md) standard.

## What's included

- **Multi-perspective spec model** — every feature spec captures input from all relevant roles (business, functional, security, accessibility, privacy, design, performance, testing, documentation, deployment) in one document. Required sections are enforced by the AI before a spec can be approved. ([What and why](skeleton/docs/SPEC-MODEL.md))
- **Docs-first delivery** — user-facing docs are written and committed BEFORE implementation, where they drive implementation thinking by forcing the team to articulate how the feature will be used. Docs are then updated deliberately during implementation when reality moves. The new `/write-docs` skill plans the docs from the spec + tests, writes them, and supports an update mode for substantial mid-implementation revisions.
- **Eval framework** — the framework's own skills, agents, rules, and spec template are covered by an eval suite at `evals/`. Static structural checks run in CI on every PR (zero token cost), plus dynamic fixture-based AI-invocation evals that catch behavior regressions. The framework eats its own dogfood; adopting projects don't get evals copied in but can adopt the pattern for their own custom artifacts. ([How and why](evals/README.md))
- **7 specialized AI agents** — spec-writer, code-reviewer, security-reviewer, test-runner, architect, debugger, ux-reviewer
- **11 workflow skills** — reusable prompt playbooks for common tasks (init, spec, implement, test, docs, review, debug, refactor, commit, evaluate)
- **9 engineering standards** — code quality, testing, security, git workflow, architecture, UI/UX, deployment, performance, observability
- **Documentation templates** — architecture, security, infrastructure, glossary, ADRs, dev setup
- **Enforcement hooks** — automated quality gates that prevent common mistakes
- **Team onboarding guide** — step-by-step training for adopting the workflow

### Why the spec model matters

Most spec templates capture only what the business wants. Real features need input from multiple roles — security, accessibility, design, deployment, documentation — and skipping any of them creates the "we forgot about X" problem after launch:

- The form that shipped without reCAPTCHA because security wasn't asked.
- The page invisible to screen readers because accessibility wasn't asked.
- The deploy that broke because nobody documented the new env var.
- The feature nobody knows how to use because the docs were "later".

This kit's spec model forces the conversation across all role perspectives **before code is written**. Mandatory sections (Business, Functional, Security, Testing, Documentation — plus Accessibility for UI features and Privacy for personal data) are enforced by the `/write-spec` skill: the spec literally cannot be marked approved if a required section is empty. Optional sections (Design, Performance, SEO, Analytics, Localization, Technical, Observability, Deployment) are filled in only when relevant to the feature. The result: every feature has the full picture before code starts, every AI agent sees the full picture when planning. See [docs/SPEC-MODEL.md](skeleton/docs/SPEC-MODEL.md).

## Get started

```bash
# Copy the skeleton into your project
cp -r skeleton/. your-project/

# Then customize:
# 1. AGENTS.md — project identity, stack, workflows, conventions (read by ALL AI tools)
# 2. CLAUDE.md — Claude Code features (agents, skills, rules) — remove if not using Claude Code
# 3. GEMINI.md — Antigravity features — remove if not using Antigravity
# 4. README.md — project name, setup, structure
# 5. .claude/rules/ — files marked with <!-- CUSTOMIZE -->
# 6. .claude/settings.json — enforcement hooks
```

### Or install via the Claude Code plugin

Instead of copying and customizing by hand, Claude Code users can install the framework's
installer plugin and let it do the adoption:

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework
claude plugin install aplyca-framework@aplyca
```

Then run `/adopt` in any repo — it inspects the project, copies the skeleton, fills the
placeholders from verified repo facts, and stamps the baseline SHA. Later, `/upgrade`
syncs an adopted repo to a newer skeleton version following the three-bucket taxonomy.
Both deliver a reviewable PR; neither commits to your default branch. See
[plugins/aplyca-framework](plugins/aplyca-framework/README.md).

The plugin contains **no framework content** — adopted repos get plain committed files
readable by every AI tool, exactly as with the manual copy.

See [docs/SETUP.md](docs/SETUP.md) for detailed instructions. Already adopted an earlier skeleton version? See [docs/UPGRADING.md](docs/UPGRADING.md) to pull newer changes without losing your customizations, and [CHANGELOG.md](CHANGELOG.md) for per-entry upgrade impact.

## How it works

After copying the skeleton, your project gets a layered AI configuration:

```
AGENTS.md          → Universal project context (read by ALL AI tools)
CLAUDE.md          → Claude Code-specific features (agents, skills, path-scoped rules)
GEMINI.md          → Antigravity / Gemini-specific features
.claude/rules/     → Engineering standards, auto-loaded when touching matching files
.claude/agents/    → Specialized AI agents (generic, learn your project from AGENTS.md)
.claude/skills/    → Reusable workflow playbooks (spec-driven development cycle)
.agents/skills     → Symlink to .claude/skills (for Antigravity compatibility)
.cursor/rules/     → Cursor rule files (.mdc format, mirroring .claude/rules)
specs/             → Feature specifications (business requirements + acceptance criteria)
docs/              → Architecture, security, infrastructure documentation
```

### Tool compatibility

| File | Read by |
|---|---|
| **AGENTS.md** | Claude Code, Cursor, GitHub Copilot, Antigravity, Windsurf, Aider, and [others](https://agents.md) |
| **CLAUDE.md** | Claude Code |
| **GEMINI.md** | Antigravity, Gemini CLI |
| **.cursor/rules/** | Cursor (auto-loaded by glob patterns) |
| **.agents/skills/** | Antigravity (symlink to .claude/skills) |

**AGENTS.md** is the [open standard](https://agents.md) for AI coding tools. It contains your project identity, workflows, conventions, and documentation pointers — everything any AI tool needs to understand your project.

**CLAUDE.md** and **GEMINI.md** layer tool-specific features on top. Remove whichever your team doesn't use.

## The workflow

```
Requirement → /write-spec → @architect → Approve → /commit spec
  → /write-tests (plan → approve → write) → /commit tests
  → /write-docs (plan → approve → write)  → /commit docs    [skips if no pre-impl docs]
  → /implement (plan → approve → code) → /review → /commit code
  → backfill post-impl docs (JSDoc, runbooks)
```

Every phase follows a **plan-then-execute** pattern: the AI presents a plan for your approval before writing tests, docs, or code. Three workflows: **Project Setup** (one-time docs + config), **Feature Development** (spec → tests → docs → implement → review → ship), **Hotfix** (fix → test → ship → backfill spec + docs). See `/spec-workflow` for details.

## Skills (prompt playbooks)

Skills standardize how your team interacts with AI. In Claude Code, invoke with `/skill-name`. In other AI tools, read the skill file and adapt the prompts.

| Skill | When to use |
|---|---|
| `/init-project` | First-time project setup — customize CLAUDE.md, rules, README |
| `/write-spec` | Starting a new feature — draft a spec from requirements |
| `/write-tests` | After spec is committed — plan tests from ACs (TDD red phase) |
| `/write-docs` | After tests are committed — write pre-implementable user-facing docs (skips cleanly if none in the spec) |
| `/implement` | After spec, tests, and docs are committed — build the feature |
| `/spec-drift` | Periodic audit — detect drift between a committed spec and current code/tests/docs (read-only) |
| `/orchestrate` | Dispatch multiple specialized agents in parallel for thorough reviews or investigations |
| `/review` | Before committing — multi-perspective code review |
| `/debug` | When something breaks — systematic root cause analysis |
| `/refactor` | Cleaning up code — safe restructuring with test coverage |
| `/commit` | Ready to commit — review changes and create a clean commit |
| `/evaluate` | Facing a decision — deep analysis with options, pros/cons, risks |

## Team onboarding

- **[docs/ONBOARDING.md](docs/ONBOARDING.md)** — week-by-week guide to adopting the workflow.
- **[docs/examples/](docs/examples/)** — full end-to-end worked examples on a Next.js + Contentful + Vercel stack. Start with [newsletter-signup](docs/examples/newsletter-signup/) to see spec → tests → docs → implement → review → commit on a real feature.
- **[docs/scenarios/](docs/scenarios/)** — one-page playbooks for common situations: [modifying an existing feature](docs/scenarios/modifying-existing-feature.md), [hotfix](docs/scenarios/hotfix.md), [refactor](docs/scenarios/refactor.md), [debugging](docs/scenarios/debugging.md).

## Structure

```
skeleton/                          Portable project skeleton (copy to your project)
|-- .claude/
|   |-- agents/                    7 specialized AI agents
|   |   |-- spec-writer/           Drafts feature specifications
|   |   |-- code-reviewer/         Reviews code quality and conventions
|   |   |-- security-reviewer/     Audits for security vulnerabilities
|   |   |-- test-runner/           Writes and runs tests
|   |   |-- architect/             Reviews architecture and design
|   |   |-- debugger/              Investigates errors and failures
|   |   +-- ux-reviewer/           Reviews UI against specs and standards
|   |-- rules/                     9 engineering standards (4 universal + 5 customizable)
|   |   |-- code-quality.md        Universal: naming, typing, error handling, principles
|   |   |-- testing.md             Universal: test structure, mocking
|   |   |-- security.md            Universal: injection, credentials, validation
|   |   |-- git-workflow.md        Universal: commits, branches, PRs
|   |   |-- architecture.md        Customize: layers, data flow, paths
|   |   |-- ui-ux.md               Customize: colors, typography, patterns
|   |   |-- deployment.md          Customize: environments, ports, infra
|   |   |-- performance.md         Customize: bundle targets, optimization
|   |   +-- observability.md       Customize: logging, monitoring, alerting
|   |-- skills/                    10 workflow playbooks (invoke with /name)
|   |   |-- init-project/          First-time project setup
|   |   |-- write-spec/            Draft a feature specification
|   |   |-- spec-workflow/         Full spec-driven development cycle
|   |   |-- implement/             Build from an approved spec
|   |   |-- write-tests/           Write tests from spec ACs
|   |   |-- review/                Multi-perspective code review
|   |   |-- debug/                 Systematic root cause analysis
|   |   |-- refactor/              Safe code restructuring
|   |   |-- commit/                Review and commit changes
|   |   +-- evaluate/              Deep analysis with options and trade-offs
|   +-- settings.json              Enforcement hooks (customize)
|-- .agents/
|   +-- skills -> ../.claude/skills  Symlink (Antigravity compatibility)
|-- .cursor/
|   +-- rules/                     6 Cursor rule files (.mdc format)
|       |-- architecture-review.mdc
|       |-- code-review.mdc
|       |-- implementation.mdc
|       |-- security-review.mdc
|       |-- spec-writing.mdc
|       +-- testing.mdc
|-- .claudeignore                  Ignore patterns for AI tools
|-- AGENTS.md                      Universal AI instructions (all tools)
|-- CLAUDE.md                      Claude Code-specific features
|-- GEMINI.md                      Antigravity / Gemini-specific features
|-- README.md                      Project README (customize)
|-- CONTRIBUTING.md                Contributing guide (customize)
|-- specs/
|   +-- _template.md              Spec template
+-- docs/
    |-- ARCHITECTURE.md            System overview, components, tech stack
    |-- GLOSSARY.md                Domain terminology
    |-- architecture/
    |   +-- decisions/             ADR template and guide
    |-- getting-started/
    |   +-- DEV-SETUP.md           Environment setup guide
    |-- infrastructure/
    |   +-- OVERVIEW.md            Platform, environments, CI/CD, monitoring
    +-- security/
        +-- SECURITY.md            Threat model, auth, data protection

plugins/
+-- aplyca-framework/              Claude Code installer plugin (/adopt, /upgrade)

docs/                              Framework documentation
|-- SETUP.md                       How to adopt the framework
+-- ONBOARDING.md                  Team training guide
```

## Contributing

Contributions are welcome — bug reports, skeleton improvements, new scenarios, and fixes to the `/adopt` and `/upgrade` skills. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request: every change to the skeleton ships into other teams' repositories, so it has to stay generic and carry a CHANGELOG entry with its upgrade impact.

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately as described in [SECURITY.md](SECURITY.md), not in public issues.

## License

[MIT](LICENSE) © Aplyca
