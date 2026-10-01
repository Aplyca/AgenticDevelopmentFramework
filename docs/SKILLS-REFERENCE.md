# Skills and workflows reference

The Agentic Development Framework ships **nineteen skills** in `skeleton/.claude/skills/`, one
more in the `parallel-agents` module, and **four dynamic workflows** in `skeleton/.claude/workflows/`.
Adopting projects copy them verbatim. In Claude Code, invoke a skill with `/skill-name`; other tools
read the `SKILL.md` and follow it. Skills run in the main conversation; workflows fan out to many
agents.

For routing (skill vs agent vs workflow), see `skeleton/CLAUDE.md` § Skills, agents, and workflows.
For model tiers, see `skeleton/docs/COST-MODEL.md`. For why the workflow is shaped this way, see
[`decisions/`](decisions/README.md).

## Workflow phase skills

In order, for a change with something to decide. Commits: `spec:` → `docs:` → one per task → `docs:`.

| Skill | Purpose |
|---|---|
| `/triage` | First step on every task: read it in full, look for prior work in proportion to the task, and state the deliverable (answer or change), kind, **lane** (fast, careful, or full — from the escalation triggers, the sensitive areas, and the developer's call), environment need, and open questions — before setting anything up. One line for a small, precise change. Accepts a lane: `/triage <task> careful`. |
| `/write-spec` | Write `specs/NNN-<slug>/spec.md` with the multi-perspective model, clarify per role, enforce required sections — or amend a delivered feature with a change request (`CR N`, Delivered → Change table, `(CR N)` acceptance criteria). |
| `/write-plan` | Write `plan.md` (constitution check, change surface built from the code, test strategy, documentation plan, assumptions) and `tasks.md` (one task per commit, each naming its test), check consistency (`@spec-analyzer` for non-trivial work), then **stop at the approval gate**. On sign-off: `status: approved`, an `approvals:` line, and the `spec:` commit. |
| `/write-docs` | Docs first: write the pre-implementable docs the plan lists, before implementation; update mode for later revisions. Skips cleanly when there are none. |
| `/write-tests` | Write tests that fail first. Task mode (inside `/implement`), acceptance mode (contract-first tests committed red), or standalone (coverage, bug reproduction). |
| `/implement` | Work through `tasks.md`: per task, test red for the right reason → code → green → one commit → tick. Stops if the change surface grows; reconciles docs; records gate results. Refuses without an approved spec. |
| `/review` | Review in proportion to the lane — first checking the diff fits it (a fast-lane diff that touched a migration is a critical finding) — then against the spec folder or the request: acceptance criteria and every filled section, change-surface compliance, constitution, conventions (including the comments rule), security, UX, test evidence, doc accuracy, PR description vs diff. |
| `/commit` | One clean commit: the spec folder, a doc, one task (test and code together), or a fast- or careful-lane change with its test (and its light `CR N` entry on delivered work). Stages by name, never bypasses hooks, never pushes. |
| `/open-pr` | **User-invoked only.** Push and open a **draft** pull request naming the spec folder and tracker task, with what was and wasn't verified. Never marks it ready. |
| `/stakeholder-update` | **Starts from a plain request** ("update the client", "reply on the task") or by name. Draft the client-facing update for a tracker task (why, what, status in the project's words, verified findings, direct questions), show it, and post it on the pull request for the team to relay; the tracker only when the developer asks. Project settings — links, CMS entries, task statuses — live in `docs/TRACKER-INTEGRATION.md`. |

## Reference and setup skills

| Skill | Purpose |
|---|---|
| `/spec-workflow` | The workflow reference: the three lanes, setup, feature (full lane), fast and careful lanes, change requests (light and full), answer-only task, bugs and hotfixes, process changes, parallel work, effort beyond the lane. |
| `/init-project` | First-time setup from verified facts: `AGENTS.md`, constitution, hooks configuration, rules, core docs, nested `AGENTS.md` template. (The plugin's `/adopt` does this end to end.) |
| `/record-decision` | Record an ADR (the application) or a PDR (how the team works); supersede or correct earlier records without rewriting them; update the docs that describe the decision in the same change; constitution amendments in their own pull request. |

## Quality and analysis skills

| Skill | Purpose |
|---|---|
| `/debug` | Systematic root-cause analysis; after the diagnosis, routes to the lane the fix needs — a regression-test fix (fast, or careful in a risk area), a change request (light or full), or the hotfix path. |
| `/refactor` | Restructure code with tests green throughout. |
| `/evaluate` | Deep analysis of a decision: options, trade-offs, risks, a recommendation. |
| `/spec-drift` | Read-only audit of one spec folder against today's code, tests, and docs. Reports; doesn't fix. |
| `/context-audit` | Read-only audit of the instruction and process files against the repository and against each other — stale commands and paths, false enforcement claims, contradictions where precedence would produce wrong actions. Complements Claude Code's `/doctor prompt-audit`. |
| `/orchestrate` | Model-driven parallel dispatch of specialized agents (`review`, `investigate`, `pre-commit`, `pre-gate`, `custom`) with a plan you approve first. Never auto-progresses phases. |

## Module skill

| Skill | Module | Purpose |
|---|---|---|
| `/dispatch` | `parallel-agents` | In the main checkout: name the task, create its worktree (`worktree-new.sh --no-start`), and hand off to a worker session with a three-line prompt. Reads only; no analysis, no edits. |

## Dynamic workflows

Deterministic multi-agent scripts (`.claude/workflows/*.js`, Claude Code). Several times the cost of
the skill they extend; use them where coverage and confidence are worth it.

| Workflow | What it runs | Use when |
|---|---|---|
| `/deep-review` | Scopes the branch diff, runs one reviewer per dimension (spec & scope compliance, correctness, security, conventions, tests & evidence, plus UX and docs when relevant), then an independent skeptic tries to refute every critical and warning finding | High-stakes or large changes before delivery |
| `/deep-spec-analysis` | Five lenses on a spec folder (coverage, change surface against the code, constitution and decisions, consistency and assumptions, multi-perspective completeness), each finding verified; returns a readiness verdict | Before the approval gate on risky specs |
| `/deep-context-audit` | One agent per instruction or process file checks its claims against the repository; a cross-check finds contradictions between files and names the winner by precedence | Monthly, after process changes or upgrades |
| `/deep-drift-sweep` | One drift audit per spec folder (or per spec in an area), with contradictions and missing behavior re-verified | Quarterly, or before a large change to an old area |

## Plugin skills

The `aplyca-framework` plugin adds installer and measurement skills on the machine, not in the
repository: `/adopt`, `/upgrade`, and `/cost-report` — what agent sessions on a project cost, from
Claude Code's local transcripts, with the expensive patterns flagged. See the
[plugin README](../plugins/aplyca-framework/README.md).

## Adding custom skills

Projects can add their own skills in `.claude/skills/` (project-owned; never touched by upgrades).
Use hyphenated frontmatter keys — `argument-hint`, `disable-model-invocation`, `user-invocable` —
because unknown keys are silently ignored. Give a skill that acts outside the machine as soon as it
runs `disable-model-invocation: true`; one that only drafts until a person approves can start from
a plain request, with the posting command behind `permissions.ask`. Document custom skills in the project's own docs.
