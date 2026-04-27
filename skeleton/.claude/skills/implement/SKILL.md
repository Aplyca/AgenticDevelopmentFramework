---
name: implement
description: Plan and implement a feature by making the committed tests pass. Use after spec AND tests have been committed.
user_invocable: true
argument-hint: "[spec name or path]"
---

# Implement from Spec (Plan Then Make Tests Pass)

Build the feature by writing code that satisfies the committed spec and makes the committed tests pass. This skill follows a plan-then-execute pattern: first present an implementation plan for approval, then write the code.

## Prerequisites

Before running this skill, both the spec and the tests should already be committed:
- **Spec commit** (`spec:` prefix) — defines what to build
- **Test commit** (`test:` prefix) — defines how to verify it (tests should currently be failing)

## Phase 1: Plan

1. **Identify the scope from git diff** — Run `git diff` against the spec and test commits to see:
   - What acceptance criteria were added or changed (from the spec diff)
   - What tests are expecting (from the test diff)
   - **New spec + tests** → implement everything from scratch
   - **Modified spec + tests** → focus on the diff: new/changed ACs and their tests. Don't re-implement unchanged criteria.

2. **Run the tests — confirm they fail** — Run the test suite to see the current "red" state. The failing tests tell you exactly what the implementation needs to satisfy.

3. **Read the full spec** — Read the complete spec in `specs/` for full context. The diff tells you what's new; the full spec tells you how it fits together.

4. **Check existing code** — Read the files you'll modify. Understand the current patterns, imports, and conventions before making changes. For modifications, understand what already works and must be preserved.

5. **Present the implementation plan** — Show the user:
   - **Task breakdown** (in dependency order):
     ```
     - [ ] Create `lib/validate.ts` — input validation helpers [tests: 'validates email', 'rejects empty input']
     - [ ] Update `app/api/users/route.ts` — add POST handler [tests: 'creates user', 'returns 400 on bad input']
     - [ ] [P] Update `app/users/page.tsx` — add registration form [tests: 'shows form', 'submits data']
     - [ ] [P] Add `styles/users.css` — form styling [tests: 'form renders correctly']

     [P] = can run in parallel with the previous task
     ```
   - Any architectural decisions or trade-offs
   - For non-trivial features (3+ files): dependency order and which tasks can be parallelized

6. **Get approval** — Wait for the user to approve the implementation plan before writing any code. Iterate if they want changes.

## Phase 2: Execute

7. **Implement** — Follow the approved plan. Write code that makes each failing test pass. Follow the project's rules and conventions:
   - Match existing patterns in neighboring code
   - Handle edge cases listed in the spec
   - Validate at system boundaries
   - Handle errors gracefully

8. **Run the tests — they should all pass** — This is the TDD "green" phase. If any test fails:
   - Read the failure message carefully
   - Fix the implementation to satisfy the test
   - Only modify a test if it contains a genuine bug (not to make a failing test pass by weakening it)

9. **Self-review** — Before presenting to the user:
   - Does each acceptance criterion (especially new/changed ones from the diff) have corresponding code?
   - Do all tests pass?
   - Are edge cases handled?
   - Does the code follow project rules (naming, typing, error handling)?
   - No speculative features beyond what the spec says?
   - For modifications: is existing behavior preserved where the spec didn't change?

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "This is a simple change, I'll skip the plan" | Simple changes have the highest rate of unintended side effects. Plan anyway — it takes 30 seconds. |
| "The tests are too restrictive, I'll adjust them" | Tests define the contract. Fix the implementation, not the test. Only modify a test if it has a genuine bug. |
| "I'll add error handling later" | Error handling is part of the spec. If the spec lists edge cases, implement them now. "Later" means "never." |
| "This refactor will make things cleaner" | If it's not in the spec, don't do it. Cleaner ≠ correct. Refactoring is a separate workflow. |
| "I need to add this dependency to make it easier" | Does the spec require this capability? If not, solve it with what's already available. New dependencies need justification. |
| "I'll implement this differently than the plan" | The plan was approved. If you see a better approach, update the plan and get re-approval. Don't silently deviate. |

## Red flags (stop and reassess)

- More than 5 files changing for a single spec — is scope creeping beyond what the spec says?
- Need to modify a test to make it pass — is the implementation wrong, or does the test have a genuine bug?
- Adding a new dependency — does the spec actually require this capability?
- Existing tests breaking — are you accidentally changing behavior the spec didn't touch?
- Implementation feels complex — re-read the spec. Are you building more than what's asked?

## Verification

- [ ] All tests pass — show the test runner output
- [ ] No type errors — show `tsc --noEmit` output (or equivalent)
- [ ] Every AC from the spec diff has corresponding code
- [ ] No speculative features beyond the spec
- [ ] For UI changes — confirm visual result matches spec (screenshot or manual check)
- [ ] For API changes — show a sample request/response
- [ ] Existing tests still pass (no regressions)

## Principles

- **Plan first, then execute** — present the implementation plan for approval before writing code.
- Build exactly what the spec says — no more, no less.
- The tests define "done". When all tests pass, the implementation is complete.
- For modifications, the git diffs are your scope. Changed ACs = changed code. New tests = new code. Unchanged ACs = unchanged code.
- Follow existing patterns. Don't introduce new patterns unless the spec requires it.
- If something in the spec is unclear or seems wrong, ask the user before implementing a guess.
- Never weaken a test to make it pass — fix the implementation instead.
