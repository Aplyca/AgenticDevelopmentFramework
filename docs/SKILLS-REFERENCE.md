# Skills reference

The AI-Assisted Development Framework ships thirteen workflow skills in `skeleton/.claude/skills/`. Adopting projects copy them verbatim and invoke them with `/skill-name` in Claude Code. Skills are step-by-step playbooks that run in the main conversation context.

For the routing decision (skill vs agent), see the **When to use skills vs agents** section in `skeleton/CLAUDE.md`. For per-skill model recommendations, see `skeleton/docs/COST-MODEL.md`.

## Workflow phase skills

The spec-driven sequence. Each phase commits before the next begins (`spec:`, `test:`, `docs:`, `feat:`).

| Skill | Purpose |
|---|---|
| `/write-spec` | Draft a feature specification using the multi-perspective spec model. Enforces required sections (Business, Functional, Security, Accessibility, Testing, Documentation, etc.) before approval. See `skeleton/docs/SPEC-MODEL.md`. |
| `/write-tests` | Write tests from spec acceptance criteria AND testable requirements in security / accessibility / performance / privacy / analytics / localization sections. TDD red phase — tests should fail until implementation. |
| `/write-docs` | Docs-first: plan and write pre-implementable user-facing docs (admin guides, API contracts, end-user copy defaults, SDK READMEs) BEFORE implementation. Skips cleanly when the spec has no pre-implementable docs. |
| `/implement` | Build from an approved spec. Reads spec git diff for scope, addresses every filled section (functional, security, a11y, perf), reads committed docs to drive thinking, and reconciles docs deliberately when implementation diverges from initial intent. |
| `/commit` | Review changes and create a well-structured git commit. Runs on Haiku — well-bounded task. |

## Reference / setup skills

| Skill | Purpose |
|---|---|
| `/spec-workflow` | Complete workflow reference — setup, feature dev, hotfix. The playbook the phase skills implement. |
| `/init-project` | First-time project setup. Walks through customizing `AGENTS.md`, `CLAUDE.md`, rules, and project docs to fit the adopting team's stack. |

## Quality and analysis skills

| Skill | Purpose |
|---|---|
| `/review` | Multi-perspective code review against project standards. |
| `/debug` | Systematic root cause analysis. Escalate to Opus for tricky bugs (race conditions, distributed-system issues, anything you've already tried to fix once). |
| `/refactor` | Safe code restructuring while keeping tests passing. |
| `/evaluate` | Deep analysis of a question, proposal, or decision. Researches, presents options with pros/cons/risks, recommends with rationale. Use for design decisions and second opinions. |
| `/spec-drift` | Read-only audit: detect divergences between a committed spec and current code/tests/docs. Reports findings categorized by severity; does NOT fix. Run periodically (monthly per spec area) to catch silent decay after the spec has aged through many PRs. |
| `/orchestrate` | Dispatch multiple specialized agents in parallel for thorough reviews or investigations. Faster and more thorough than running them sequentially. Costs more than `/review`; use for high-stakes diffs or multi-angle exploration. Does NOT auto-progress through workflow phases (preserves plan-then-execute discipline). |

## Adding custom skills

Adopting projects can add their own skills in `.claude/skills/`. Custom skills are project-owned, won't be touched on framework upgrade, and should be documented in the project's own docs (not here).
