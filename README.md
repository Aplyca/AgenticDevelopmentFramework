# AI-Assisted Development Starter Kit

A production-ready configuration for professional AI-assisted, spec-driven, test-driven development using Claude Code.

## What's included

- **7 specialized AI agents** — spec-writer, code-reviewer, security-reviewer, test-runner, architect, debugger, ux-reviewer
- **10 workflow skills** — reusable prompt playbooks for common tasks (init, spec, implement, test, review, debug, refactor, commit, evaluate)
- **9 engineering standards** — code quality, testing, security, git workflow, architecture, UI/UX, deployment, performance, observability
- **Documentation templates** — architecture, security, infrastructure, glossary, ADRs, dev setup
- **Enforcement hooks** — automated quality gates that prevent common mistakes
- **Team onboarding guide** — step-by-step training for adopting the workflow

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

See [docs/SETUP.md](docs/SETUP.md) for detailed instructions.

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
Requirement → /write-spec → @architect → Approve → /commit spec → /implement → /write-tests → /review → /commit code
                                                        ↑
                                              Spec commit creates a git diff
                                              that scopes the implementation
```

Three workflows: **Project Setup** (one-time docs + config), **Feature Development** (spec → commit → implement → test → review → ship), **Hotfix** (fix → test → ship → backfill spec). See `/spec-workflow` for details.

## Skills (prompt playbooks)

Skills standardize how your team interacts with AI. In Claude Code, invoke with `/skill-name`. In other AI tools, read the skill file and adapt the prompts.

| Skill | When to use |
|---|---|
| `/init-project` | First-time project setup — customize CLAUDE.md, rules, README |
| `/write-spec` | Starting a new feature — draft a spec from requirements |
| `/implement` | After spec is approved — build the feature |
| `/write-tests` | After implementation — write tests from spec ACs |
| `/review` | Before committing — multi-perspective code review |
| `/debug` | When something breaks — systematic root cause analysis |
| `/refactor` | Cleaning up code — safe restructuring with test coverage |
| `/commit` | Ready to commit — review changes and create a clean commit |
| `/evaluate` | Facing a decision — deep analysis with options, pros/cons, risks |

## Team onboarding

See [docs/ONBOARDING.md](docs/ONBOARDING.md) for a week-by-week guide to adopting this workflow.

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

docs/                              Starter kit documentation
|-- SETUP.md                       How to adopt the starter kit
+-- ONBOARDING.md                  Team training guide
```

## License

MIT
