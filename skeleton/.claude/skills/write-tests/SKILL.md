---
name: write-tests
description: Plan and write tests from a spec's acceptance criteria BEFORE implementation (TDD). Tests should fail until code is written.
user_invocable: true
argument-hint: "[spec name or feature area]"
---

# Write Tests (TDD — Plan Then Execute)

Write tests from a committed spec's acceptance criteria. This skill follows a plan-then-execute pattern: first present a test plan for approval, then write the tests.

## Phase 1: Plan

1. **Read the spec** — Find the relevant spec in `specs/`. List every acceptance criterion and edge case.

2. **Read the spec diff** — Run `git diff HEAD~1 -- specs/` to see what changed. For modifications, focus new tests on new/changed ACs. Don't rewrite tests for unchanged criteria.

3. **Read test conventions** — Check `.claude/rules/testing.md` for:
   - Test framework and runner
   - Port assignments (test server vs dev server)
   - Mocking strategy (route interception, test doubles, etc.)
   - File organization and naming

4. **Check existing tests** — Look in the test directory for existing tests covering this feature area. Don't duplicate — add tests for new ACs, update tests for changed ACs.

5. **Present the test plan** — Show the user a mapping from ACs to tests:
   ```
   AC1: "user sees X when Y" → test: 'shows X when Y happens'
   AC2: "clicking Z navigates to W" → test: 'clicking Z navigates to W'
   Edge: "empty list shows message" → test: 'shows empty state when no items'
   ```
   Include: which test file(s) will be created or modified, which mocks are needed, and which ACs from the diff are covered.

6. **Get approval** — Wait for the user to approve the test plan before writing any test code. Iterate if they want changes.

## Phase 2: Execute

7. **Write the tests** — Follow the approved plan and the project's test patterns:
   - One test file per feature area
   - Group with describe/context blocks
   - Descriptive names that read as behavior
   - Arrange → Act → Assert structure
   - Mock ALL external services
   - Tests describe EXPECTED behavior — the implementation doesn't exist yet

8. **Run the tests — they should all fail** — This is the TDD "red" phase. Every new test should fail because no implementation exists yet. If a test passes, it's either:
   - Testing something that already exists (OK for modification workflows)
   - Testing the wrong thing (fix the test)

9. **Report results** — Show the user: tests written, all failing as expected, ready to commit.

## After tests are committed

The implementation phase (`/implement`) will write code to make these tests pass. The tests should not be modified during implementation unless they contain a bug.

## Principles

- **Plan first, then execute** — present the test plan for approval before writing code.
- **Tests come before code** — this is TDD. Write the verification contract first, then fulfill it.
- Test behavior, not implementation. Assert on what the user sees, not internal state.
- Mock external services — tests must not depend on services being up.
- Use realistic but fake test data. Never real credentials or PII.
- If a test can't be written for an acceptance criterion, the AC may need to be rewritten.
- For modifications: only write new tests for new/changed ACs. Existing passing tests for unchanged ACs stay as-is.
