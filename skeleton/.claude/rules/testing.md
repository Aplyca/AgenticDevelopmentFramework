---
paths:
  - "e2e/**"
  - "tests/**"
  - "test/**"
  - "**/*.test.*"
  - "**/*.spec.*"
---

# Testing Rules

## Environment isolation
- Tests run on a **dedicated port**, separate from the development server. Define the test port in your test configuration and never change it to match the dev port.
- Test environments use mock/stub configurations so tests never depend on external services being up.

## External service mocking
- Mock ALL external API responses. Use your framework's mocking approach (route interception, MSW, test doubles, dependency injection, etc.).
- Never rely on real external services (databases, APIs, email servers) during tests.
- Mock responses must return realistic data structures matching actual API contracts.

## File organization
- One test file per feature area or module.
- Name test files after the feature they verify.
- Group related tests with describe/context blocks.
- Use descriptive test names that read as behavior: `'submitting with empty email shows validation error'`.

## Test structure
- **Arrange → Act → Assert** in every test.
- Set up shared mocks in `beforeEach` / setup blocks.
- Clean up state in `afterEach` / teardown blocks when needed.

## What to test
- User flows matching spec acceptance criteria.
- Edge cases listed in specs.
- View transitions, form submissions, navigation.
- Error states and empty states.

## What NOT to test
- Implementation details or internal state.
- CSS classes or styling specifics.
- Third-party library internals.
- Anything not described in a spec or requirement.

## When to write tests
- New feature: write tests that verify each acceptance criterion.
- Bug fix: write a test that reproduces the bug first, then fix it.
- Behavior change: update affected tests to match the new spec.

## Test data
- Use fake but realistic data (example emails, names, IDs).
- Never use real credentials, PII, or production data in tests.
