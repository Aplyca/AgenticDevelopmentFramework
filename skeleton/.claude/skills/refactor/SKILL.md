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

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll refactor this and add the new feature at the same time" | Refactoring and features are separate workflows with separate commits. Mixing them makes both harder to review and revert. |
| "Tests aren't needed for this refactor, I'm just renaming" | Renames can break imports, references, and string-based lookups. Run tests. |
| "I'll add this abstraction now since we'll need it later" | YAGNI. Abstractions for hypothetical futures add complexity today. Refactor for what exists, not what might exist. |
| "Let me clean up the surrounding code while I'm here" | Scope creep. Only change what was asked. Unrelated cleanup belongs in a separate commit. |

## Verification

- [ ] All tests pass after refactoring — show test runner output
- [ ] No type errors — show `tsc --noEmit` output (or equivalent)
- [ ] Public API unchanged (same inputs, outputs, behavior)
- [ ] No new patterns introduced that don't exist elsewhere in the project
- [ ] Git diff shows only the intended refactoring, no unrelated changes

## Principles

- Tests are the safety net. No tests = no refactoring.
- One thing at a time. Don't mix refactoring with feature work.
- Leave the code better than you found it, but don't gold-plate it.
