# Tasks: [feature name]

<!--
  One task = one commit, landed through the TDD loop:
    write the test → run it and watch it fail → write the code → run it to green → commit.
  A test that never failed proves nothing. Every task names the test that proves it and the
  acceptance criteria it serves; the tests themselves live in the test directories — this file
  is the map. Tick a task in the same commit that completes it.
  [P] = independent of the previous task (can run in parallel).
  The docs-first tasks (Phase 1) share one `docs:` commit; test-only tasks are `test:` commits.
  Each delivery is one branch and one pull request; size the work so that holds.
  Change request: leave the delivered tasks as they are and append a "# CR N — <title>" part with
  these phases, its tasks numbered from T<N>00 (T100 for CR 1) and its own gate results.
-->

- **Spec:** ./spec.md · **Plan:** ./plan.md
- **Branch:** `<type>/<slug>`
- **Last updated:** YYYY-MM-DD

## Phase 0 — Approval

- [ ] T000 — Spec folder approved at the gate (scope, change surface, assumptions) and committed (`spec:`)

## Phase 1 — Docs first

<!-- Pre-implementable docs from plan.md § Documentation plan, committed together (`docs:`)
     before the implementation tasks. Delete this phase when the plan lists none. -->

- [ ] T001 — [Doc] for [audience] (→ AC1, AC2)

## Phase 2 — Foundation

<!-- Shared groundwork the stories depend on: schema/migrations, shared types, configuration.
     Foundation that several features need is its own spec and its own PR, landed first. -->

- [ ] T010 — [Task] (test: `[path]` · "[name]") (→ AC…)

## Phase 3 — Stories (TDD, one commit per task)

- [ ] T020 — [Task] (test: `[path]` · "[name]") (→ AC1)
- [ ] T021 [P] — [Task] (test: `[path]` · "[name]") (→ AC2)

## Phase 4 — Acceptance

<!-- End-to-end tests that encode the acceptance criteria. Written after the stories, they pass
     on their first run: prove each can fail by breaking the behavior it covers, restore it, and
     commit (`test:`). When plan.md asks for contract-first acceptance tests, these move to the
     front and are committed red. -->

- [ ] T030 — [End-to-end test encoding AC1–AC3] (→ AC1, AC2, AC3)

## Phase 5 — Reconcile & polish

- [ ] T040 — Reconcile committed docs with what was built (→ Documentation)
- [ ] T041 — Post-implementable docs (→ Documentation)
- [ ] T042 — Record gate results below

## Verification checklist (each checkpoint)

<!-- CUSTOMIZE: the project's real commands, from AGENTS.md § Quick reference -->

- [ ] Lint clean
- [ ] Typecheck clean
- [ ] Unit / integration tests passing
- [ ] End-to-end tests passing (or listed below as not run, with the reason)
- [ ] Every acceptance criterion met; every filled spec section addressed
- [ ] Security and accessibility reviewed

## Gate results (YYYY-MM-DD)

<!-- Evidence, not claims. For each task: the red failure you saw and the green that followed.
     Commands run and their counts (e.g. "unit: 19 files, 350 tests"). What was NOT run, and
     why (no environment, shared database, needs a preview). The PR body links here. -->
