# Skills and workflows reference

The Agentic Development Framework ships **twenty-one skills**, four more for modules, and **four dynamic
workflows**. Their source is the plugins — `plugins/adf/skills/`, `plugins/adf/workflows/`, and
`plugins/adf-dev/skills/` ([decision 0028](decisions/0028-plugins-are-the-source.md)). A packaged
project loads them from there, as `/adf:skill-name`; a committed one keeps copies in `.claude/`, which
`scripts/build-committed.py` writes, and invokes them with `/skill-name` — other tools read the
`SKILL.md` and follow it. Skills run in the main conversation; workflows fan out to many
agents.

For routing (skill vs agent vs workflow), see `skeleton/.claude/rules/claude-code.md` § Skills, agents, and workflows.
For model tiers, see `plugins/adf/docs/COST-MODEL.md`. For why the workflow is shaped this way, see
[`decisions/`](decisions/README.md).

## Workflow phase skills

In order, for a change with something to decide. Commits: `spec:` → `docs:` → one per task → `docs:`.

| Skill | Purpose |
|---|---|
| `/triage` | First step on every task: read it in full, look for prior work in proportion to the task (for new behavior: is it already built, or was it declined before?), and state the deliverable (answer or change), kind, **lane** (fast, careful, or full — from the escalation triggers, the sensitive areas, and the developer's call), environment need, and open questions (one round, each with a recommended answer) — before setting anything up. One line for a small, precise change. Accepts a lane: `/triage <task> careful`. |
| `/write-spec` | Write `specs/NNN-<slug>/spec.md` with the multi-perspective model, clarify per role, ask in rounds with recommended answers, use the glossary's terms, enforce required sections — or amend a delivered feature with a change request (`CR N`, Delivered → Change table, `(CR N)` acceptance criteria). |
| `/write-plan` | Write `plan.md` (constitution check, change surface built from the code, test strategy, documentation plan, assumptions) and `tasks.md` (one task per commit, each naming its test), check consistency (`@spec-analyzer` for non-trivial work), then **stop at the approval gate**. On sign-off: `status: approved`, an `approvals:` line, and the `spec:` commit. |
| `/write-docs` | Docs first: write the pre-implementable docs the plan lists for the repository, before implementation; update mode for later revisions. Skips cleanly when there are none. With the `end-user-docs` module, end-user pages in the doc tool are `/end-user-docs`'. |
| `/write-tests` | Write tests that fail first. Task mode (inside `/implement`), acceptance mode (contract-first tests committed red), or standalone (coverage, bug reproduction). |
| `/implement` | Work through `tasks.md`: per task, test red for the right reason → code → green → one commit → tick. Stops if the change surface grows into risk; reconciles docs; records gate results. Refuses without an approved spec. |
| `/review` | Review in proportion to the lane — first checking the diff fits it (a fast-lane diff that touched a migration is a critical finding) — then against the spec folder or the request: acceptance criteria and every filled section, change-surface compliance, constitution, conventions (including the comments rule), security, UX, test evidence, doc accuracy, PR description vs diff. |
| `/commit` | One clean commit: the spec folder, a doc, one task (test and code together), or a fast- or careful-lane change with its test (and its light `CR N` entry on delivered work). Stages by name, never bypasses hooks, never pushes. |
| `/open-pr` | **Once the agent's own local check passes** (or, with nothing to run, once the gate and review pass), or when asked — in every lane, without asking first. Push and open a **draft** pull request naming the spec folder and tracker task, with what was and wasn't verified and its merge danger (does a revert undo it, what it affects if wrong). Never marks it ready. |
| `/stakeholder-update` | **Starts from a plain request** ("update the client", "reply on the task") or by name. Draft the client-facing update for a tracker task (why, what, status in the project's words, verified findings, direct questions), show it, and post it on the pull request for the team to relay; the tracker only when the developer asks. Project settings — links, CMS entries, task statuses — live in `docs/TRACKER-INTEGRATION.md`. |
| `/wrap-up` | After the pull request merges: check that nothing is left — uncommitted or unpushed work, a stash, an open task, a promised follow-up — and list it if there is. Otherwise ask once to close up: stop what the task started, remove its worktree and branch, update the base branch, and archive the session. |
| `/handoff` | Hand work in progress to someone who wasn't here — a teammate, another machine, a fresh session — as a short message of pointers: task, branch and commit, spec folder, pull request, what's done, what's next, open questions. Puts the state in the record first; never copies the spec or the process; shown to the developer, posted nowhere unasked. |

## Reference and setup skills

| Skill | Purpose |
|---|---|
| `/spec-workflow` | The workflow reference: the three lanes, setup, feature (full lane), fast and careful lanes, change requests (light and full), answer-only task, bugs and hotfixes, process changes, parallel work, effort beyond the lane. |
| `/init-project` | First-time setup from verified facts: `AGENTS.md`, constitution, hooks configuration, rules, core docs, nested `AGENTS.md` template. (The plugin's `/adopt` does this end to end.) |
| `/record-decision` | Record an ADR (the application) — only when a decision is hard to reverse, surprising without its context, and a real trade-off — or a PDR (how the team works); supersede or correct earlier records without rewriting them; update the docs that describe the decision in the same change; constitution amendments in their own pull request. |

## Quality and analysis skills

| Skill | Purpose |
|---|---|
| `/debug` | Root-cause analysis that starts with a command that fails on the bug, then ranks three to five hypotheses and tests them one at a time; after the diagnosis, routes to the lane the fix needs — a regression-test fix (fast, or careful in a risk area), a change request (light or full), or the hotfix path. |
| `/refactor` | Restructure code with tests green throughout. |
| `/evaluate` | Deep analysis of a decision: options, trade-offs, risks, a recommendation. |
| `/spec-drift` | Read-only audit of one spec folder against today's code, tests, and docs. Reports; doesn't fix. |
| `/context-audit` | Read-only audit of the instruction and process files against the repository and against each other — stale commands and paths, false enforcement claims, contradictions where precedence would produce wrong actions, and instructions that change nothing or belong in a doc read on demand. Complements Claude Code's `/doctor prompt-audit`. |
| `/orchestrate` | Model-driven parallel dispatch of specialized agents (`review`, `investigate`, `pre-commit`, `pre-gate`, `custom`) with a plan you approve first. Never auto-progresses phases. |

## Module skills

A module's skill is copied with the module in a committed install. In a packaged install it comes
from the plugin the module's `module.json` names: `/dispatch`, `/track-time`, and `/end-user-docs` from `adf`, the process, and
`/dev-env` and `/e2e` from `adf-dev`, development ([decision 0023](decisions/0023-plugins-by-concern.md)).

| Skill | Module | Purpose |
|---|---|---|
| `/dispatch` | `parallel-agents` | After triage, a change — or an answer that runs the app — gets its own worktree: it creates the task's worktree beside the main checkout (`worktree-new.sh <type>/<slug> --no-start`) and moves this session into it. A session that already has a task offers another a new session — a task chip in the desktop app, a `claude "<prompt>"` command in a terminal. A packaged install gets it from the plugin, as `/adf:dispatch`, and it runs the plugin's `adf-worktree-new` (decision 0027). |
| `/track-time` | `time-tracking` | At a milestone, after significant partial work, or after the merge: draft the task's time entries since the last one logged, one per day worked, in whole units rounded up — the AI-assisted time (the sessions, measured from the local transcripts, plus the work outside them, estimated from its evidence: understanding the task, research, debugging, manual testing, code review, task management, reporting, meetings) next to a senior developer's estimate without AI. The developer picks one number per entry; only the approved entries are written, to the tracker's time entries and nowhere else ([decision 0043](decisions/0043-track-time-in-the-tracker.md)). Settings in `docs/TIME-TRACKING.md`. A packaged install gets it from the plugin, as `/adf:track-time`. |
| `/end-user-docs` | `end-user-docs` | Write a feature's end-user page — how the people who use the product do what it lets them do — in the doc tool they read (ClickUp Docs, Confluence, Notion), never in the repository: **draft** it after the approval gate, docs first, where end users can't see it; **update** it when the build changes what it says; **publish** it to the end-user doc once the feature ships, reading the live page first and retiring the draft. Only for features whose spec lists an end-user page; each page is shown in full and written only on the developer's yes ([decision 0048](decisions/0048-end-user-docs-in-the-doc-tool.md)). Settings in `docs/END-USER-DOCS.md`. A packaged install gets it from the plugin, as `/adf:end-user-docs`. |
| `/dev-env` | `docker` | Set up, migrate, run natively, diagnose, or safely reset the project's Docker Compose local environment by the conventions of [decision 0032](decisions/0032-local-environment-layout.md): `compose.yaml` and a `Makefile` at the root, operational code in `ops/`, variables from `.env` and each service's `environment:`, ports Docker picks. It writes a missing stack from its templates and proposes moving an existing one; verified commands go to `DEV-SETUP.md` and the Quick reference, one stack per worktree with `parallel-agents`, a failing signal before any fix, and nothing deleted beyond this project's own containers and volumes without a yes. A packaged install gets it from `adf-dev`, as `/adf-dev:dev-env`. |
| `/e2e` | `e2e` | Set up, audit, or extend the project's end-to-end tests to the specification it carries ([decision 0037](decisions/0037-end-to-end-tests.md)): Playwright in its own `e2e/` folder, run with `make e2e` and `make smoke` against the checkout's own stack — in Docker, in Playwright's image, or on the host — one `@smoke` test per critical flow the developer names, each seen failing before it's committed; tests that find elements by role, wait with assertions, own their data, and never reach a real third party. Diagnoses a failing or flaky test from what it kept (`error-context.md`, the trace). A change's own tests are written test first with `/write-tests`, following `testing.md` § End-to-end. A packaged install gets it from `adf-dev`, as `/adf-dev:e2e`. |

## Dynamic workflows

Deterministic multi-agent scripts (`.claude/workflows/*.js`, Claude Code). Several times the cost of
the skill they extend; use them where coverage and confidence are worth it. `/deep-drift-sweep`'s
auditors follow `/spec-drift`'s steps: a committed project's workflow points at
`.claude/skills/spec-drift/SKILL.md`, and the plugin's carries the steps' text, because a packaged
project has no `.claude/skills/` and a workflow can't reach the plugin's skills
([decision 0030](decisions/0030-workflows-carry-skill-steps.md)).

| Workflow | What it runs | Use when |
|---|---|---|
| `/deep-review` | Scopes the branch diff, runs one reviewer per dimension (spec & scope compliance, correctness, security, conventions, tests & evidence, plus UX and docs when relevant), then an independent skeptic tries to refute every critical and warning finding | High-stakes or large changes before delivery |
| `/deep-spec-analysis` | Five lenses on a spec folder (coverage, change surface against the code, constitution and decisions, consistency and assumptions, multi-perspective completeness), each finding verified; returns a readiness verdict | Before the approval gate on risky specs |
| `/deep-context-audit` | One agent per instruction or process file checks its claims against the repository; a cross-check finds contradictions between files and names the winner by precedence | Monthly, after process changes or upgrades |
| `/deep-drift-sweep` | One drift audit per spec folder (or per spec in an area), with contradictions and missing behavior re-verified | Quarterly, or before a large change to an old area |

## Plugin skills

The `adf` plugin adds installer and measurement skills on the machine, not in the
repository: `/adf:adopt`, `/adf:upgrade`, and `/adf:cost-report` — what agent
sessions on a project cost, from Claude Code's local transcripts, with the expensive patterns
flagged. In a packaged project, every skill above also comes from the plugin, typed
`/adf:<name>` — except a development module's, typed by `adf-dev`'s name
(`/adf-dev:dev-env`, `/adf-dev:e2e`). See the [plugin README](../plugins/adf/README.md).

The `adf-connect` plugin adds `/adf-connect:connect`: connect the project to its tracker or a stack
service — Supabase, Vercel, Contentful, GitLab, Linear, Jira — through the service's official MCP
server. It writes the project's `.mcp.json` entry with safe defaults (read-only, never production, no
credentials committed), pre-approves only the tools that read, and writes it down in `DEV-SETUP.md`.
Any project can turn it on, committed or packaged. See the [plugin README](../plugins/adf-connect/README.md).

## Adding custom skills

Projects can add their own skills in `.claude/skills/` (project-owned; never touched by upgrades).
Use hyphenated frontmatter keys — `argument-hint`, `disable-model-invocation`, `user-invocable` —
because unknown keys are silently ignored. Give a skill that acts outside the machine as soon as it
runs `disable-model-invocation: true`; one that only drafts until a person approves can start from
a plain request, if it posts only after the person's yes in chat — or with the posting command behind `permissions.ask`. Document custom skills in the project's own docs.
