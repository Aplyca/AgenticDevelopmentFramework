---
name: refactor
description: Restructure code without changing observable behavior — pin current behavior with tests first, plan the steps and the files they touch, change one thing at a time with tests green after every step, and commit each step. Use for cleanups, extractions, renames, and simplifications; a structural decision worth keeping gets an ADR, and a change users can notice is not a refactor.
argument-hint: "[file or area to refactor]"
---

# Refactor Safely

Improve code structure without changing what it does for any user or caller. The tests are the
safety net; a refactor without them is a gamble.

## Is this a refactor?

- **Users, callers, or stored data could notice the difference** → it's a change, not a refactor:
  triage it (`/triage`) — usually a spec folder or a change request.
- **There's a structural decision with lasting consequences** (a new module boundary, replacing a
  pattern used across the codebase, swapping a library) → record it as an ADR (`/record-decision`)
  before or with the refactor. If the team needs to agree on it first, it's a spec folder with
  something to decide.
- **Otherwise** — extracting a shared function, simplifying logic, renaming, removing dead code or
  duplication — this skill is the whole workflow.

## Steps

1. **Check the safety net.** Find the tests that cover the code you'll touch, and run the whole
   suite: everything must pass before you start. Where coverage is missing, write
   **characterization tests** that pin today's behavior — then prove each one can fail by breaking
   the code it covers on purpose (and putting it back). Commit them first (`test:`), green.

2. **Plan the steps.** Name the goal (what gets simpler, and how you'll know), the sequence of small
   steps, and the files each step touches. For a refactor across several files or layers, show the
   developer this plan and its file list before starting — the same change-surface check a feature
   gets at its gate.

3. **One step at a time.** Each step is small enough to understand at a glance, leaves the tests
   green, and is reversible.

4. **Run the tests after every step.** A failure means the last step changed behavior: fix it or
   revert it before going on. Never edit an assertion to get back to green — a refactor that needs
   a test changed isn't one.

5. **Commit each green step** (`refactor: <what got simpler>`). Small commits keep review easy and
   any single step revertible.

6. **Review the result.**
   - Is the code genuinely simpler, or did the complexity just move?
   - No new patterns the project doesn't already use?
   - Public interfaces unchanged — same inputs, outputs, errors, side effects?
   - Comments: delete the ones the cleaner code made redundant; don't add narration
     (`.claude/rules/code-quality.md`).

## What is NOT refactoring

- Adding features or changing behavior — even "tiny" ones (triage it)
- Adding abstractions "for the future" (speculative design)
- Reformatting code you didn't otherwise change (noise in the diff)
- Updating user-facing docs — if docs must change, behavior changed

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll refactor this and add the new feature at the same time" | Separate workflows, separate commits. Mixed, both are harder to review and to revert. |
| "Tests aren't needed for this refactor, I'm just renaming" | Renames break imports, references, and string-based lookups. Run the tests. |
| "There are no tests here, but the change is obviously safe" | Pin the behavior first with characterization tests. "Obviously safe" is what every regression looked like. |
| "This test now fails — I'll update it to the new structure" | A test that changes meaning means behavior changed. Fix the code or stop and triage. |
| "I'll add this abstraction now since we'll need it later" | YAGNI. Refactor for what exists, not what might. |
| "Let me clean up the surrounding code while I'm here" | Scope creep. Unrelated cleanup is its own refactor, its own commits. |

## Red flags (stop and reassess)

- A test assertion needs to change.
- The diff touches files outside the plan.
- The refactor needs a new dependency.
- You can't describe a step in one sentence.

## Verification

- [ ] The suite passed before the first change and after every step — show the output
- [ ] Missing coverage was pinned with characterization tests first, each seen failing once
- [ ] No test assertion was changed to get to green
- [ ] Public interfaces unchanged (inputs, outputs, errors, side effects)
- [ ] Typecheck and lint clean
- [ ] The diff contains only the planned refactoring; each step is its own `refactor:` commit
- [ ] A lasting structural decision, if any, is recorded as an ADR

## Principles

- No tests, no refactoring.
- One step at a time, green after each, committed after each.
- Behavior a user could notice means it isn't a refactor.
- Leave the code simpler than you found it — don't gold-plate it.
