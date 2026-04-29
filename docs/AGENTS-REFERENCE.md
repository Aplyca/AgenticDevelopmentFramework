# Agents reference

The AI-Assisted Development Framework ships seven specialized agents in `skeleton/.claude/agents/`. Adopting projects copy them verbatim and invoke them with `@agent-name` in Claude Code. All agents are generic — they learn project specifics from the project's `AGENTS.md`, `CLAUDE.md`, and `.claude/rules/` at runtime.

For the routing decision (skill vs agent), see the **When to use skills vs agents** section in `skeleton/CLAUDE.md`. For model-tier rationale, see `skeleton/docs/COST-MODEL.md`.

## Catalog

| Agent | Purpose | Tool access | Model tier |
|---|---|---|---|
| `@spec-writer` | Drafts and updates feature specifications from business requirements using the multi-perspective spec model | Read + Write `specs/` | Sonnet |
| `@code-reviewer` | Reviews code for quality, conventions, and best practices against the project's standards | Read-only | Haiku |
| `@security-reviewer` | Audits for injection, credential exposure, unsafe data handling, and OWASP-style issues | Read-only | Haiku |
| `@test-runner` | Writes tests from a committed spec (TDD red phase — ACs, edge cases, testable requirements from Security/Accessibility/Performance/Privacy/Analytics/Localization sections), then runs them after implementation (green phase) | Full edit + Bash | Sonnet |
| `@architect` | Reviews architecture decisions, data flow, component boundaries, and system design | Read-only | Haiku |
| `@debugger` | Root cause analysis for errors, failures, and unexpected behavior | Read + Bash (no edit) | Sonnet |
| `@ux-reviewer` | Reviews UI against specs and UX standards — layout, flow, consistency, accessibility basics, user-facing text | Read-only | Haiku |

## Why agents vs skills

Agents run in their own subprocess with their own tool restrictions. Use them when you need:

- **Parallel execution** — e.g., run `@security-reviewer` while you continue implementation in the main context.
- **Isolation** — second opinions where main-context bias would skew the review.
- **Tool restrictions** — read-only reviewers physically can't edit code, which is a stronger guarantee than "please don't edit."

Skills are step-by-step playbooks that run in the main conversation. Use them for sequential work (review, then implement, then commit) where you want the AI to keep all the context.

## Customizing model tiers

Each agent's `model:` frontmatter is set per `skeleton/docs/COST-MODEL.md`. To change a tier in your project, edit the agent's `agent.md` directly — the framework doesn't enforce model choice across upgrades, so your override survives.

## Adding custom agents

Adopting projects can add their own agents in `.claude/agents/`. Custom agents are project-owned, won't be touched on framework upgrade, and should be documented in the project's own docs (not here).
