---
name: spec-workflow
description: Reference for how work flows in this project — project setup, feature development (spec folder → plan → approval gate → docs first → TDD per task → draft PR), change requests, answer-only tasks, bugs and hotfixes, process changes, and parallel work. Use to decide which workflow applies or to see how the phases fit together.
---

# Development Workflows

Every task starts with **triage** (`/triage`): read it in full, then decide the deliverable (an
answer or a change), whether an environment is needed, and whether a spec folder is created,
amended, or skipped. The triage picks one of the workflows below.

## Workflow 1: Project setup (once)

`/init-project` (or the framework's `/adopt`): fill `AGENTS.md`, the constitution, the customizable
rules, the hook configuration, and the initial docs — `docs/ARCHITECTURE.md`,
`docs/security/SECURITY.md`, `docs/infrastructure/OVERVIEW.md`, `docs/GLOSSARY.md`, and reference
pages for the most complex subsystems. Agents read these before every design review and
implementation; invest in them early.

## Workflow 2: Feature or behavior change

| # | Phase | Skill | Artifact | Commit |
|---|---|---|---|---|
| 1 | Triage | `/triage` | First message | — |
| 2 | Specify + clarify | `/write-spec` | `specs/NNN-<slug>/spec.md` | — |
| 3 | Plan + tasks + analyze | `/write-plan` (`@spec-analyzer`) | `plan.md`, `tasks.md` | — |
| 4 | **Approval gate** | `/write-plan` | `status: approved` + `approvals:` line | `spec:` |
| 5 | Docs first | `/write-docs` | Pre-implementable docs | `docs:` |
| 6 | Implement, per task | `/implement` (`/write-tests` inside) | Test + code per task | `feat:` / `fix:` per task |
| 7 | Reconcile + verify | `/implement`, `/review` | Docs updated; `tasks.md` § Gate results | `docs:` |
| 8 | Deliver (when asked) | `/open-pr` | Draft pull request | — |
| 9 | Close the loop (when asked) | `/stakeholder-update` | Requester-facing message | — |

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

1. `/triage` identifies the existing spec folder and the delivered work.
2. `/write-spec` in amend mode: delta = the request now vs what the spec records as delivered (plus
   comments since its last change); append `CR N`; new ACs tagged `(CR N)`.
3. `/write-plan` adds the CR's plan and tasks; same gate; `approvals:` gets a `CR N` line.
4. Then the rest of Workflow 2: docs first when documented behavior changes, the per-task loop, gate
   results, review, a draft pull request when asked — on a fresh branch (`<type>/<slug>-<change>`),
   with a new pull request, in the **same folder**. If the delta can't be recovered — ask.

## Workflow 4: Answer-only task (investigation, impact analysis, estimate)

No spec folder, no environment unless a step must run something. Read the code, docs, and history;
deliver the answer where the task asks for it. A recommended change gets its spec once someone
approves the change.

## Workflow 5: Bugs and hotfixes

- **Bug with a clear root cause, restoring documented behavior:** `/debug` → regression test (watch it
  fail) → fix → `/commit`. No spec.
- **Bug that changes documented behavior:** treat as a change request on the feature's spec folder.
- **Hotfix (production is broken now):** `/debug` → fix + regression test → ship through the
  project's hotfix path (`CONTRIBUTING.md`). Backfill the spec and user-facing docs afterwards if
  behavior changed. Speed justifies skipping spec-first; it never justifies skipping the backfill.

## Workflow 6: A change to how we work

Record it as a PDR in `docs/process/` (`/record-decision`) and update every instruction file that
describes the old way in the same pull request. Constitution amendments get their own pull request.

## Parallel work

When several agent sessions run at once, each works in its own git worktree on its own branch —
never two sessions in one checkout. With the parallel-agents module installed, the main checkout is a
**dispatcher** only (`/dispatch`): it names the task, creates the worktree, and hands off; the
**worker** in the worktree does everything from triage onward.

## Lightweight changes

Nothing to decide — typo, copy edit, version bump, formatting, dev-only tooling: edit → verify →
`/commit`. The test is "is there anything to decide?", not "is it big?".
