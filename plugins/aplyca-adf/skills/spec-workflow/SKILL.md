---
name: spec-workflow
description: Reference for how work flows in this project — the fast, careful, and full lanes, project setup, feature development (spec folder → plan → approval gate → docs first → TDD per task → draft PR), change requests, answer-only tasks, bugs and hotfixes, process changes, and parallel work. Use to decide which workflow applies or to see how the phases fit together.
---

# Development Workflows

Every task starts with **triage** (`/aplyca-adf:triage`): read it in full, then decide the deliverable (an
answer or a change), the **lane** for a change, and whether an environment is needed. The lane
follows risk and uncertainty, not size (`specs/README.md` § Lanes):

| Lane | When | Workflow |
|---|---|---|
| **Fast** | A precise request (or a bug with a clear cause), about 3 files or fewer, no escalation trigger | Workflow 2a |
| **Careful** | The same, touching a risk area or a sensitive area | Workflow 2a plus the area's checklist |
| **Full** | Something to decide, a new feature, or work across layers | Workflow 2 |

The developer can raise the lane at any time; lowering it never silently drops a risk checklist.

## Workflow 1: Project setup (once)

`/aplyca-adf:init-project` (or the framework's `/adopt`): fill `AGENTS.md`, the constitution, the customizable
rules, the hook configuration, and the initial docs — `docs/ARCHITECTURE.md`,
`docs/security/SECURITY.md`, `docs/infrastructure/OVERVIEW.md`, `docs/GLOSSARY.md`, and reference
pages for the most complex subsystems. Agents read these before every design review and
implementation; invest in them early.

## Workflow 2a: Fast and careful lanes

1. **Triage in one line** — the request in your words, "done when…", and the files you expect to
   touch. Ask now only what blocks you, as one round with your recommended answers.
2. **Search every use** of what you change — shared code and other callers are a trigger.
3. **Test first, then edit** — write or update the test that asserts the new behavior and watch it
   fail (for a bug, the regression test); then edit until it passes. Quiet output; the full gate once, before delivery.
4. **Careful lane** — apply the area's checklist (migration, authorization, personal data, shared
   code, contract, infrastructure), run `@aplyca-adf:security-reviewer` for authorization, data, or payments,
   and get the developer's yes on the risky part.
5. **Commit** (`/aplyca-adf:commit`) — with a light `CR N` entry in `spec.md` when the change alters recorded
   behavior (a fix that restores documented behavior needs none).
6. **Stop and move up a lane** when the diff grows past the stated files, a test outside the area
   fails, or no test can prove the change.
7. **Deliver when asked** — a draft pull request stating the lane (`/aplyca-adf:open-pr`); the human review and
   QC are the gate.

## Workflow 2: Feature or behavior change (full lane)

| # | Phase | Skill | Artifact | Commit |
|---|---|---|---|---|
| 1 | Triage | `/aplyca-adf:triage` | First message | — |
| 2 | Specify + clarify | `/aplyca-adf:write-spec` | `specs/NNN-<slug>/spec.md` | — |
| 3 | Plan + tasks + analyze | `/aplyca-adf:write-plan` (`@aplyca-adf:spec-analyzer`) | `plan.md`, `tasks.md` | — |
| 4 | **Approval gate** | `/aplyca-adf:write-plan` | `status: approved` + `approvals:` line | `spec:` |
| 5 | Docs first | `/aplyca-adf:write-docs` | Pre-implementable docs | `docs:` |
| 6 | Implement, per task | `/aplyca-adf:implement` (`/aplyca-adf:write-tests` inside) | Test + code per task | `feat:` / `fix:` per task |
| 7 | Reconcile + verify | `/aplyca-adf:implement`, `/aplyca-adf:review` | Docs updated; `tasks.md` § Gate results | `docs:` |
| 8 | Deliver (when asked) | `/aplyca-adf:open-pr` | Draft pull request | — |
| 9 | Close the loop (when asked) | `/aplyca-adf:stakeholder-update` | Requester-facing message | — |

**Why one approval gate, after the plan.** Approving the spec alone is cheap but checks the wrong
thing: an agent's convincing analysis is most often wrong about *which files and layers the change
touches*, and that is only known once the plan exists. The gate shows the scope, the change surface,
and every assumption together — before the first commit, when correcting them is a sentence.

**Why commit the spec folder, then docs, then one commit per task.**
- The `spec:` commit records intent *and* the approved change surface; later diffs are reviewed
  against it.
- The `docs:` commit captures how the feature will be used before code constrains the conversation.
- One commit per task, each made after its test went red then green, gives a history where every
  step is reviewable, revertible, and backed by a test that once failed.
- If implementation goes wrong, the spec and docs commits survive and the work restarts cleanly.

**Contract-first acceptance tests (optional).** When the team wants the verification contract up
front, the plan lists end-to-end tests that encode the ACs; they're written and committed red
(`test:`) right after the docs, and the task loop turns them green.

## Workflow 3: Change request on delivered work

A precise adjustment the requester already decided takes Workflow 2a with a **light** `CR N` entry
committed with the change. When the request leaves something to decide, it's a **full** change
request:

1. `/aplyca-adf:triage` identifies the existing spec folder and the delivered work.
2. `/aplyca-adf:write-spec` in amend mode: delta = the request now vs what the spec records as delivered (plus
   comments since its last change); append `CR N`; new ACs tagged `(CR N)`.
3. `/aplyca-adf:write-plan` adds the CR's plan and tasks; same gate; `approvals:` gets a `CR N` line.
4. Then the rest of Workflow 2: docs first when documented behavior changes, the per-task loop, gate
   results, review, a draft pull request when asked — on a fresh branch (`<type>/<slug>-<change>`),
   with a new pull request, in the **same folder**. If the delta can't be recovered — ask.

## Workflow 4: Answer-only task (investigation, impact analysis, estimate)

No spec folder, no environment unless a step must run something. Read the code, docs, and history;
deliver the answer where the task asks for it. A recommended change gets its spec once someone
approves the change.

## Workflow 5: Bugs and hotfixes

- **Bug with a clear root cause, restoring documented behavior:** the fast lane (careful in a risk
  area) — `/aplyca-adf:debug` → regression test (watch it fail) → fix → `/aplyca-adf:commit`. No spec folder.
- **Bug that changes documented behavior:** a change request on the feature's spec folder — light or
  full, by whether there's something to decide.
- **Hotfix (production is broken now):** the careful lane — `/aplyca-adf:debug` → fix + regression test → ship through the
  project's hotfix path (`CONTRIBUTING.md`). Backfill the spec and user-facing docs afterwards if
  behavior changed. Speed justifies skipping spec-first; it never justifies skipping the backfill.

## Workflow 6: A change to how we work

Record it as a PDR in `docs/process/` (`/aplyca-adf:record-decision`) and update every instruction file that
describes the old way in the same pull request. Constitution amendments get their own pull request.

## Parallel work

When several agent sessions run at once, each works in its own git worktree on its own branch —
never two sessions in one checkout. With the parallel-agents module installed, the main checkout is a
**dispatcher** only (`/dispatch`): it names the task, creates the worktree, and hands off; the
**worker** in the worktree does everything from triage onward. Passing work in progress to a
teammate, another machine, or a fresh session is `/aplyca-adf:handoff`: pointers to the record, never a copy.

## Effort beyond the lane

The developer can ask for more care without changing the lane — questions before any code,
`/aplyca-adf:evaluate` to compare designs, a higher effort level or `/model opus`, extra tests,
`@aplyca-adf:security-reviewer`, `/aplyca-adf:deep-review`. Each costs differently (`docs/COST-MODEL.md` § Effort).
