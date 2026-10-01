# 0003: TDD at task granularity — one task, one red → green cycle, one commit

- **Status:** accepted
- **Date:** 2026-10-01

## Context

The previous workflow wrote **all** tests for a feature up front, committed them failing (`test:`),
and then implemented everything in one `feat:` commit. It captured the verification contract before
any code, but in practice:

- Unit tests written against an API that doesn't exist yet are guesses; many were rewritten during
  implementation, which blurred the "never change a test to make it pass" rule.
- One large `feat:` commit is hard to review and impossible to partially revert.
- "The tests failed before implementation" was asserted once for the whole suite, not observed per
  behavior.

Teams that broke plans into commit-sized tasks — each naming the test that proves it — got a
history where every commit is one behavior, backed by a test that was seen failing first, and a
place (`tasks.md`) to record that evidence.

## Decision

- Each task in `tasks.md` names its test and the acceptance criteria it serves.
- `/implement` runs the loop per task: write the test → run it and **watch it fail for the right
  reason** (the missing behavior, not an import error) → write the smallest code → run it to green →
  commit the test and the code together → tick the task. **One task = one commit.**
- The red-then-green evidence, the commands run with their counts, and what could **not** be run
  (and why) are recorded in `tasks.md` § Gate results — evidence, not claims.
- **Contract-first acceptance tests remain an option:** when the plan asks for it, end-to-end tests
  encoding the acceptance criteria are written and committed red (`test:`) before the task loop.
- The commit prefix order becomes `spec:` → `docs:` → one `feat:`/`fix:`/`refactor:` per task →
  `docs:` (reconciliation, gate results, backfill).

## Consequences

- **Positive:** each commit is reviewable and revertible on its own; every behavior is backed by a
  test that was observed failing; reviewers read evidence instead of trusting "tests pass".
- **Negative / cost:** there's no single commit that captures the whole verification contract unless
  the team opts into contract-first acceptance tests. More commits per feature. Recording gate
  results takes a few minutes per feature.

## Alternatives considered

- **Keep batch red tests.** Preserves an up-front contract but produces speculative unit tests and a
  monolithic implementation commit. Kept as the optional contract-first mode for acceptance tests,
  where the contract value is highest.
- **Tests after code.** Confirms what was built rather than what was asked; rejected outright.
