---
name: implement
description: Implement a feature by making the committed tests pass. Use after spec AND tests have been committed.
user_invocable: true
argument-hint: "[spec name or path]"
---

# Implement from Spec (Make the Tests Pass)

Build the feature by writing code that satisfies the committed spec and makes the committed tests pass.

## Prerequisites

Before running this skill, both the spec and the tests should already be committed:
- **Spec commit** (`spec:` prefix) — defines what to build
- **Test commit** (`test:` prefix) — defines how to verify it (tests should currently be failing)

## Steps

1. **Identify the scope from git diff** — Run `git diff` against the spec and test commits to see:
   - What acceptance criteria were added or changed (from the spec diff)
   - What tests are expecting (from the test diff)
   - **New spec + tests** → implement everything from scratch
   - **Modified spec + tests** → focus on the diff: new/changed ACs and their tests. Don't re-implement unchanged criteria.

2. **Run the tests — confirm they fail** — Run the test suite to see the current "red" state. The failing tests tell you exactly what the implementation needs to satisfy.

3. **Read the full spec** — Read the complete spec in `specs/` for full context. The diff tells you what's new; the full spec tells you how it fits together.

4. **Check existing code** — Read the files you'll modify. Understand the current patterns, imports, and conventions before making changes. For modifications, understand what already works and must be preserved.

5. **Plan the implementation** — Before writing code, outline which files need changes and what each change does. For non-trivial features, present the plan to the user for alignment.

6. **Implement** — Write code that makes each failing test pass. Follow the project's rules and conventions:
   - Match existing patterns in neighboring code
   - Handle edge cases listed in the spec
   - Validate at system boundaries
   - Handle errors gracefully

7. **Run the tests — they should all pass** — This is the TDD "green" phase. If any test fails:
   - Read the failure message carefully
   - Fix the implementation to satisfy the test
   - Only modify a test if it contains a genuine bug (not to make a failing test pass by weakening it)

8. **Self-review** — Before presenting to the user:
   - Does each acceptance criterion (especially new/changed ones from the diff) have corresponding code?
   - Do all tests pass?
   - Are edge cases handled?
   - Does the code follow project rules (naming, typing, error handling)?
   - No speculative features beyond what the spec says?
   - For modifications: is existing behavior preserved where the spec didn't change?

## Principles

- Build exactly what the spec says — no more, no less.
- The tests define "done". When all tests pass, the implementation is complete.
- For modifications, the git diffs are your scope. Changed ACs = changed code. New tests = new code. Unchanged ACs = unchanged code.
- Follow existing patterns. Don't introduce new patterns unless the spec requires it.
- If something in the spec is unclear or seems wrong, ask the user before implementing a guess.
- Never weaken a test to make it pass — fix the implementation instead.
