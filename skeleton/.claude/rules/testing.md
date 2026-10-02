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
- **Mock only at the system boundary** — external services, the clock, randomness. Your own modules run for real: a test that mocks internal collaborators breaks on every refactor and proves only the wiring.

## Tests that can fail
- **Expected values come from outside the code** — a literal, a worked example, the spec. A test that recomputes the expected value the way the code does (`expect(total(items)).toBe(items.reduce(sum))`) passes by construction and can never disagree with the code.
- **Verify through the public interface** — call the module and check what it returns or does. Querying its database directly or asserting which internal function was called couples the test to the implementation: it breaks when behavior hasn't changed.
- **Assert the behavior the spec names**, not that the code ran: "the 11th signup in a minute is rejected", not "no error was thrown".

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
- New feature: every acceptance criterion and testable requirement gets a test, mapped in the spec folder's `plan.md` and named on its task in `tasks.md`.
- Bug fix: write a test that reproduces the bug first, then fix it.
- Behavior change: update the affected tests to the amended spec first — they fail until the code changes.
- Fast or careful lane: write or update the test that asserts the new behavior first, and watch it
  fail before changing the code. A copy-only change needs no new test that merely restates the text;
  when an existing test asserts the old text, update it first — it fails until the copy changes.

## Red, then green — every change, in every lane
The unit is a task from `tasks.md` in the full lane, and the change itself in the fast and careful
lanes.
- **Write the test, run it, and watch it fail** before writing the code that satisfies it. A test that never failed proves nothing: it may be testing something that already exists, or nothing at all.
- **Make it pass with the smallest change**, run it to green, then commit the test and the code together.
- If a new test passes before any code exists, stop: either the behavior already exists (say so) or the test is wrong.
- Never weaken an assertion to get to green. Fix the implementation — or, if the test itself is wrong, say why in the commit body.

## Verification budget
- **While iterating, run the targeted tests** — the test you're writing and its neighbors — not the
  whole suite on every step. **Run the full gate once**, before delivery.
- **Keep output short:** a quiet or dot reporter, failures only, `| tail -n 40`. Everything a command
  prints stays in the conversation and is paid for on every later call.
- **End-to-end and browser checks** run when the change touches that flow or the developer asks; the
  human QC on the preview remains the real check of how it looks and feels.

## Evidence, not claims
- Green tests are necessary, not sufficient — verify the behavior, not just the pass.
- Record what you ran in the spec folder's `tasks.md` § Gate results: the red failure you saw, the green that followed, the commands and their counts, and anything you could **not** run (no environment, shared database, needs a preview) and why.
- Layers that need services (integration, end-to-end, visual) may live outside the per-commit loop; say which layers ran before delivery.

## Test data
- Use fake but realistic data (example emails, names, IDs).
- Never use real credentials, PII, or production data in tests.
