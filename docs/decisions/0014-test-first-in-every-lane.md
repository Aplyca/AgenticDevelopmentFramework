# 0014: Test first in every lane

- **Status:** accepted
- **Date:** 2026-10-01
- **Supersedes:** [0011](0011-lanes-ceremony-follows-risk.md) in part — the order of the fast and careful lanes' steps

## Context

The full lane runs one red → green cycle per task ([0003](0003-tdd-at-task-granularity.md)): write the
test, watch it fail, write the code, watch it pass. When decision 0011 added the fast and careful
lanes, it wrote their steps as "edit, prove it with a targeted test, commit". That required a failing
test first only for a bug, so a precise non-bug change could be edited first and tested afterwards.

That is the weaker proof the TDD rule exists to prevent. A test written after the code can pass for
the wrong reason — asserting what the code happens to do, or nothing at all — and nobody sees it fail.
In the practice this framework came from, tests come before the code: written, run, and seen
failing; then the code makes them pass. The lanes were meant to cut paperwork, not proof (0011:
"every lane proves the change with a test").

## Decision

- **Every lane is test-first.** In the fast and careful lanes, write or update the test that asserts
  the new behavior and watch it fail — for a bug, the regression test — then make the change until it
  passes. The unit is the change; in the full lane it stays the task.
- **A copy-only change** needs no new test that merely restates the text. When an existing test
  asserts the old text, update that test first: it fails until the copy changes.
- **Changes that amend a spec** update the affected tests to the amended spec first.
- **The evidence** goes where each lane records it: `tasks.md` § Gate results in the full lane; the
  commit body or the pull request's "Verified / not verified" in the fast and careful lanes, which
  `/review` checks.

## Consequences

- **Positive:** one rule for every change — a test that has been seen failing — so lane choice never
  weakens proof, and the lanes still differ only in paperwork and approval.
- **Negative / cost:** a precise change takes one more test run (the red one) before the edit.
  Seconds with targeted tests.

## Alternatives considered

- **Keep test-after for non-bug fast-lane changes.** Rejected: it is exactly where a test that never
  failed goes unnoticed.
- **Require a new test for every copy change.** Rejected: a test that restates a string proves only
  that the string was typed twice. Updating an existing assertion first keeps the proof without it.
