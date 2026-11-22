---
name: spec-workflow
description: Reference for how work flows here — the fast, careful, and full lanes, project setup, feature development, change requests, answers, bugs and hotfixes, process changes, and parallel work. Use to decide which workflow applies or to see how the phases fit together.
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/spec-workflow/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

> **The reference docs this file names are the plugin's copies,** in `${CLAUDE_PLUGIN_ROOT}/docs/` — outside this project, which keeps none in its own `docs/`. Read them at the full paths given.

# Development Workflows

Which workflow applies, and where its steps live. The rules are in `AGENTS.md` § How work flows and
`specs/README.md`, and each skill carries its own steps: this page only routes, so it never holds a
second copy that can drift.

Every task starts with **triage** (`/adf:triage`): the deliverable — an answer or a change — the
**lane** for a change, which follows risk and uncertainty, not size (`specs/README.md` § Lanes), and
whether an environment is needed.

## Workflow by situation

| Situation | Route | Where the steps live |
|---|---|---|
| Project setup, once | `/adf:init-project`, or `/adf:adopt` end to end | Those skills |
| A precise change in one layer, no trigger — **fast** | The test first, seen failing → edit → `/adf:commit` → local check → `/adf:open-pr` | `AGENTS.md` § 2; `/adf:triage` § Routing |
| The same in a risk or sensitive area — **careful** | Fast, plus the area's checklist; `@adf:security-reviewer` for authorization, personal data, or payments | `specs/README.md` § Careful-lane checklists; `/adf:review` step 3 |
| Something to decide, a new feature or dependency, or work across layers — **full** | `/adf:write-spec` → `/adf:write-plan` → approval gate → `/adf:write-docs` → `/adf:implement` → local check → `/adf:open-pr` | `AGENTS.md` § 3; `specs/README.md` § Flow |
| A change request on delivered work | A light `CR N` with a fast or careful change; a full one (`/adf:write-spec`, change-request mode) when something is left to decide — after the merge, on a fresh branch | `AGENTS.md` § 4; `specs/README.md` § Change requests |
| **Feedback on an open pull request** | A change request on the same branch and the same draft | `specs/README.md` § Before the merge |
| An answer — investigation, impact analysis, estimate | Read-only; delivered where the task asks; a change it recommends gets a lane once someone approves it | `AGENTS.md` § 5 |
| A bug whose cause is unclear | `/adf:debug`, then the lane the fix needs | `/adf:debug` |
| A hotfix — production is broken | The careful lane, without delay: regression test, seen failing → fix → the draft pull request; backfill the spec | `AGENTS.md` § 5; `CONTRIBUTING.md` |
| A refactor | `/adf:refactor`; the full lane when it sets a structure others must follow | `/adf:refactor` |
| A change to how we work | A PDR (`/adf:record-decision`) | `/adf:record-decision` |
| Several sessions at once | One worktree per session; with the parallel-agents module, `/adf:dispatch` | `AGENTS.md` § Delivery rules; `${CLAUDE_PLUGIN_ROOT}/docs/PARALLEL-AGENTS.md` |
| Passing work in progress to someone else | Pointers to the record, never a copy | `/adf:handoff` |
| A bug or improvement found along the way | Reported with `file:line` and routed, never dropped or fixed in passing | `specs/README.md` § Found along the way |
| The base branch moved under an open draft | Only for a reason; a merge commit, never a rebase | `/adf:open-pr sync` |
| After the merge, or an answer delivered | Close up the task | `/adf:wrap-up` |

**More care without a new lane:** questions before any code, `/adf:evaluate` to compare designs, a
higher effort level or `/model opus`, extra tests, `@adf:security-reviewer`, `/adf:deep-review`.
Each costs differently (`${CLAUDE_PLUGIN_ROOT}/docs/COST-MODEL.md` § Effort).
