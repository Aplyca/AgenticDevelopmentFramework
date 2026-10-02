---
name: implement
description: Implement an approved spec folder one task at a time — for each task in tasks.md write its test, watch it fail, write the code, watch it pass, and commit — keeping plan.md and the committed docs true to what is built, then record the gate results. Use after the approval gate (spec status approved) and /aplyca-adf:write-docs.
argument-hint: "[spec folder, e.g. specs/007-newsletter-signup]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/implement/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Implement — one task, one red → green cycle, one commit

Build the feature by working through `tasks.md` in order. Each task is one TDD cycle and one
commit: the test that proves the task, then the code that satisfies it, together. The approved
plan is the contract for **where** code goes (the change surface); the tests are the contract for
**what** it does.

## Prerequisites — refuse to start without them

- `spec.md` reads `status: approved`, with an `approvals:` line covering this scope (the CR, for a
  change request). If not, stop: the approval gate in `/aplyca-adf:write-plan` hasn't happened.
- The spec folder is committed (`spec:`).
- If `plan.md` lists pre-implementable docs, they're committed (`docs:`) and their Phase 1 tasks
  are ticked. If not, run `/aplyca-adf:write-docs` first.
- The environment the tests need is up — start it now if triage deferred it — and host
  dependencies are installed so the git hooks can run on commit.

## Phase 1: Prepare

1. **Read the folder:** `spec.md` (every filled section, not only Functional), `plan.md` (change
   surface, test strategy, risks, assumptions), `tasks.md`, and the committed docs — they describe
   how the feature will be used and should drive your thinking.
2. **Mind the model.** Implementing an approved plan is well-specified work — `sonnet` handles it.
   If this session is on Opus and still carries the whole planning conversation, suggest a fresh
   Sonnet session (the spec folder is the handoff); keep Opus for a task that turns out genuinely hard.
3. **Run the existing suite** to know the baseline. Pre-existing failures are recorded in the gate
   results and reported — not silently fixed, and not mistaken for yours.

## Phase 2: The loop — for each task, in order

4. **Take the next unticked task.** Respect dependencies; `[P]` tasks can go in any order.
5. **Write the test the task names**, following `.claude/rules/testing.md` and the patterns of
   neighboring tests.
6. **Run it and watch it fail — for the right reason:** an assertion about the missing behavior,
   not a syntax error, import error, or broken fixture. Keep the failure line for the gate results.
   If it **passes** before you've written any code, stop: the behavior already exists or the test is
   wrong. Find out which and tell the developer. The exception is a **test-only task** — acceptance
   tests written after the stories, or a test that pins behavior the change must not break. It is
   expected to pass: break the behavior it covers on purpose, watch it fail, restore it, and record
   that in the gate results.
7. **Write the smallest code that makes it pass**, inside the plan's change surface, matching the
   existing patterns. Handle the edge cases the spec lists; validate at system boundaries.
8. **Run it to green**, plus the neighboring tests, to catch regressions early — targeted runs with
   quiet output, not the whole suite each time (`.claude/rules/testing.md` § Verification budget).
   Tidy the code while everything stays green.
9. **Tick the task and commit** test, code, and the tick together — one commit:
   `feat: <what the task delivers>` (or `fix:`, `refactor:`; `test:` for a test-only task). Stage
   files by name. Hooks run; never `--no-verify`.
10. **Next task.**

## When reality departs from the plan

- **Small deviation inside the change surface** (a different helper, an extra guard): update
  `plan.md` in the same commit and carry on.
- **The change surface grows** — a new layer, a file outside the table, a shared component, a
  migration, a dependency: **stop**. Explain what you found, update `plan.md`, and get the
  developer's re-confirmation (add an `approvals:` line) before continuing.
- **A requirement turns out wrong or ambiguous:** stop and ask; the answer goes into the spec's
  Clarifications. Never guess.
- **A test is genuinely wrong:** fix it in its own commit and say why. Never weaken a test to get
  to green.

## Docs evolve with reality

Docs were written first to drive implementation thinking, and they are living artifacts. When the
build reveals that reality differs from a committed doc — a renamed field, an extra edge case, a UX
adjustment — updating the doc is a normal part of this phase, not an exception:

- **Small fix** (a sentence, a field name): fold it into the task's commit and say so in the body.
- **Meaningful revision** (changed behavior, a new section): its own `docs:` commit; for a large
  rework, re-run `/aplyca-adf:write-docs` in update mode.
- **Never** ship code that contradicts a committed doc.

## Phase 3: Finish

11. **Reconcile and backfill** — the Phase 5 tasks: committed docs checked claim by claim against
    what was built; post-implementable docs (runbooks, troubleshooting) written or listed for later.
12. **Run the full gate** — the verification checklist in `tasks.md`: lint, typecheck, every test
    layer this environment can run.
13. **Record the gate results** in `tasks.md`: the red-then-green evidence per task, commands and
    counts, what you could **not** run and why, pre-existing failures. With every task ticked, set
    `status: implemented` in `spec.md` — it merges with the pull request, so the folder reads as built.
    Commit (`docs: record <slug> gate results`).
14. **Self-review**, then `/aplyca-adf:review`. Don't push. Offer `/aplyca-adf:open-pr` when the developer wants to deliver.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The spec is approved in spirit — I'll start" | No `status: approved` and no `approvals:` line means no gate happened. Run `/aplyca-adf:write-plan`'s gate first. |
| "I'll write all the code, then the tests" | Then no test ever failed — and a test that never failed proves nothing. One red → green cycle per task. |
| "The test failed with an import error — that counts as red" | Red means the assertion failed because the behavior is missing. Fix the scaffolding until it fails for the right reason. |
| "I'll batch several tasks into one commit" | One task, one commit — that's what makes the history reviewable and each step revertible. |
| "This file isn't in the change surface, but it's a tiny edit" | Change surface growth goes back to the developer. Tiny edits to shared code are how regressions ship. |
| "The tests are too strict — I'll loosen them" | Tests are the contract. Fix the implementation; fix a test only when it's genuinely wrong, and say so. |
| "I'll clean up this nearby code while I'm here" | Not in the spec, not in this branch. Refactoring is its own task or its own workflow. |
| "I'll add this dependency to make it easier" | The plan didn't approve it. New dependencies need justification and re-confirmation. |
| "All green — I'll push and open the PR" | Pushing is outward. Finish the gate results and review; push only when asked. |

## Red flags (stop and reassess)

- A task needs more than ~5 files — the task, or the plan, is too coarse.
- A new test passes before any code exists, outside a test-only task.
- You're editing a test to make it pass.
- Existing tests break in an area the spec didn't touch.
- You're about to touch a file that isn't in the change surface.

## Verification

- [ ] `status: approved` and an `approvals:` line existed before the first line of code
- [ ] Every task went red (for the right reason) then green — a test-only task by breaking the behavior on purpose — and landed as its own commit (docs-first tasks share one)
- [ ] Every task in `tasks.md` is ticked, or its absence is explained
- [ ] All changes are inside the approved change surface — or the extension was re-confirmed
- [ ] Every filled spec section (Security, Accessibility, Privacy, Performance, Analytics, Localization, Observability, Deployment) is addressed
- [ ] Committed docs match what was built; post-implementable docs written or listed
- [ ] The full gate ran; `tasks.md` § Gate results records evidence and what was not run
- [ ] Deployment needs (env vars, migrations, ordering) are listed for whoever ships it
- [ ] Nothing was pushed

## Principles

- One task, one red → green cycle, one commit.
- A test that never failed proves nothing.
- The change surface is a contract; growing it is the developer's call.
- Keep the plan and the docs true to what is built.
- Evidence, not claims — and never outward actions unasked.
