---
name: write-tests
description: Write tests from a spec's acceptance criteria. Use after implementation to verify the feature works correctly.
user_invocable: true
argument-hint: "[spec name or feature area]"
---

# Write Tests

Write tests that verify a feature matches its specification.

## Steps

1. **Read the spec** — Find the relevant spec in `specs/`. List every acceptance criterion and edge case — each one becomes at least one test.

2. **Read test conventions** — Check `.claude/rules/testing.md` for:
   - Test framework and runner
   - Port assignments (test server vs dev server)
   - Mocking strategy (route interception, test doubles, etc.)
   - File organization and naming

3. **Check existing tests** — Look in the test directory for existing tests covering this feature area. Don't duplicate — update if behavior changed.

4. **Map spec to tests** — Create a list:
   ```
   AC1: "user sees X when Y" → test: 'shows X when Y happens'
   AC2: "clicking Z navigates to W" → test: 'clicking Z navigates to W'
   Edge: "empty list shows message" → test: 'shows empty state when no items'
   ```

5. **Write the tests** — Follow the project's test patterns:
   - One test file per feature area
   - Group with describe/context blocks
   - Descriptive names that read as behavior
   - Arrange → Act → Assert structure
   - Mock ALL external services

6. **Run the tests** — Execute the test suite and verify all tests pass. If any fail, diagnose: is it a test issue or an implementation bug?

## Principles

- Test behavior, not implementation. Assert on what the user sees, not internal state.
- Mock external services — tests must not depend on services being up.
- Use realistic but fake test data. Never real credentials or PII.
- If a test can't be written for an acceptance criterion, the AC may need to be rewritten.
