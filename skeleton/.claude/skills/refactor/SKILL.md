---
name: refactor
description: Refactor code safely while keeping tests passing. Use when cleaning up code without changing behavior.
user_invocable: true
argument-hint: "[file or area to refactor]"
---

# Refactor Safely

Improve code structure without changing external behavior.

## Steps

1. **Verify tests exist** — Before refactoring anything, confirm there are tests covering the code you'll change. If not, write tests first. Refactoring without tests is gambling.

2. **Run tests** — Run the full test suite. All tests must pass BEFORE you start. This is your safety net.

3. **Define the goal** — What specifically are you improving?
   - Extracting a shared component/function (used in 2+ places)
   - Simplifying complex logic (too many nesting levels, unclear flow)
   - Renaming for clarity (names don't match what the code does)
   - Removing dead code (unused imports, unreachable branches)
   - Reducing duplication (copy-pasted blocks)

4. **Make one change at a time** — Each refactoring step should be:
   - Small enough to understand at a glance
   - Independently correct (tests pass after each step)
   - Reversible if something goes wrong

5. **Run tests after each change** — If tests fail, the last change broke something. Fix or revert it before continuing.

6. **Review the result** — After all changes:
   - Is the code genuinely simpler, or did you just move complexity?
   - Did you introduce any new patterns the project doesn't use?
   - Is the public API unchanged? (same inputs, same outputs, same behavior)

## What is NOT refactoring

- Adding features (that's implementation — needs a spec)
- Changing behavior (that's a bug fix or feature change — needs a spec)
- Adding abstractions "for the future" (that's speculative design)
- Reformatting code you didn't change (that's noise in the diff)

## Principles

- Tests are the safety net. No tests = no refactoring.
- One thing at a time. Don't mix refactoring with feature work.
- Leave the code better than you found it, but don't gold-plate it.
