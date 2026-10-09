# Agents reference

The Agentic Development Framework ships eight specialized agents, whose source is the `adf` plugin's `plugins/adf/agents/` ([decision 0028](decisions/0028-plugins-are-the-source.md)). A packaged project loads them from the plugin, as `@adf:agent-name`; a committed one keeps copies in `.claude/agents/`, which `scripts/build-committed.py` writes, and invokes them with `@agent-name`. All agents are generic — they learn project specifics from the project's `AGENTS.md` and `.claude/rules/` at runtime.

For the routing decision (skill vs agent vs workflow), see **Skills, agents, and workflows** in `skeleton/.claude/rules/claude-code.md`. For model-tier rationale, see `plugins/adf/docs/COST-MODEL.md`.

## Catalog

| Agent | Purpose | Tool access | Model tier |
|---|---|---|---|
| `@spec-writer` | Drafts or amends a spec folder's `spec.md` from business requirements using the multi-perspective spec model, including change-request (`CR N`) amendments | Read + Write | Sonnet |
| `@spec-analyzer` | Adversarial pre-gate analysis of a spec folder: ACs without tasks or tests, change-surface gaps found in the code, constitution conflicts, contradictions, unstated assumptions, invented requirements. Returns a readiness verdict | Read-only | Opus |
| `@code-reviewer` | Reviews code for quality, conventions (including the comments rule), change-surface compliance, and test evidence against the spec folder | Read-only | Sonnet |
| `@security-reviewer` | Audits for injection, credential exposure, loosened authorization, unsafe data handling, and OWASP-style issues | Read-only | Sonnet |
| `@test-runner` | Writes the tests a spec folder's tasks name, runs them red for the right reason before the code exists and green after, and reports the evidence for the gate results | Full edit + Bash | Sonnet |
| `@architect` | Reviews a plan's architecture, change surface, data flow, component boundaries, and system design | Read-only | Opus |
| `@debugger` | Root cause analysis for errors, failures, and unexpected behavior — a failing signal first, then ranked hypotheses | Read + Bash (no edit) | Sonnet |
| `@ux-reviewer` | Reviews UI against specs and UX standards — layout, flow, consistency, accessibility basics, user-facing text | Read-only | Sonnet |

## Why agents vs skills

Agents run in their own subprocess with their own tool restrictions. Use them when you need:

- **Parallel execution** — e.g., run `@security-reviewer` while you continue implementation in the main context.
- **Isolation** — second opinions where main-context bias would skew the review.
- **Tool restrictions** — read-only reviewers physically can't edit code, which is a stronger guarantee than "please don't edit."

Skills are step-by-step playbooks that run in the main conversation. Use them for sequential work (review, then implement, then commit) where you want the AI to keep all the context.

## Customizing model tiers

Each agent's `model:` frontmatter uses a version-less alias (`haiku`, `sonnet`, `opus`) set per `plugins/adf/docs/COST-MODEL.md` § Choosing between Sonnet and Opus — reviews and well-specified work on Sonnet, judgment (`@spec-analyzer`, `@architect`) on Opus — so it follows new model releases without changes. An agent runs in its own context, so its model costs the main session no cache switch. To change a tier in your project, record the agent, its model, and the reason in your `.claude/rules/claude-code.md`. The session passes that model when it spawns the agent, which outranks the agent's frontmatter. This works in both installs: a packaged project has no agent file to edit (an update replaces the plugin's copy), and an upgrade overwrites a committed project's. The format, and the settings that don't do this, are in `plugins/adf/docs/COST-MODEL.md` § Per-agent recommendations ([decision 0031](decisions/0031-agent-model-overrides-in-the-project-rule.md)).

## Agents inside workflows

The `/deep-*` workflows (`plugins/adf/workflows/`) don't call these agents directly — their reviewers need to run read-only `git` commands, which the read-only agents can't. Instead a lens follows the matching agent's checklist, so the standards stay in one place. A committed project's workflow points at the project's copy (for example `.claude/agents/security-reviewer/agent.md`). The plugin's workflow carries the checklist's text, because a packaged project has no `.claude/agents/` and a workflow can't reach the plugin's agents ([decision 0029](decisions/0029-workflows-carry-agent-checklists.md)).

## Adding custom agents

Adopting projects can add their own agents in `.claude/agents/`. Custom agents are project-owned, won't be touched on framework upgrade, and should be documented in the project's own docs (not here).
