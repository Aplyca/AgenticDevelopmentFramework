# Test plan — newsletter topics modification

> This is the AI's output during Phase 1 of `/write-tests` for the topic-selection modification. The plan is scoped to the **spec diff**, not the full spec.

## Source

- Spec diff: `git diff HEAD~1 -- specs/newsletter-signup.md` (commit `e7f8g9h`)
- Conventions: `.claude/rules/testing.md`
- Existing tests in scope: `e2e/newsletter-signup.spec.ts` (7 tests), `app/api/newsletter/__tests__/route.test.ts` (4 tests), `lib/newsletter/__tests__/validate-email.test.ts` (3 tests)

## Files to modify

- `e2e/newsletter-signup.spec.ts` — add a new `describe` block for "Topic selection". 5 new tests.
- `app/api/newsletter/__tests__/route.test.ts` — add 2 new tests for the topic-forwarding and ID-validation behavior.

## Files NOT to create or change

- `lib/newsletter/__tests__/validate-email.test.ts` — validator is unchanged. No new tests, no edits.
- No new test files. The existing organization fits.

## Mocks needed

- **Contentful client mock** — extend the existing default fixture to include an `availableTopics` reference and 3 `newsletterTopic` entries with `mailchimpGroupId`s. Individual tests override:
  - Override 1: empty `availableTopics` (backwards-compat scenario).
  - Override 2: one topic with missing `mailchimpGroupId` (graceful-degradation scenario).
- **Mailchimp HTTP mock (MSW)** — extend the existing handler to capture and assert the `interests` field in the request body. Default behavior unchanged.

## AC → test mapping (modification scope only)

| AC (changed/new) | Test file | Test name | Status |
|---|---|---|---|
| AC1 (unchanged base) | `e2e/newsletter-signup.spec.ts` | `shows form with copy from Contentful` | EXISTING — must stay green |
| AC1a (new) | `e2e/newsletter-signup.spec.ts` | `shows topic selector when topics are configured in Contentful` | NEW |
| AC1a (backwards compat) | `e2e/newsletter-signup.spec.ts` | `omits topic selector when no topics are configured (backwards compat)` | NEW |
| AC2 (unchanged base) | `e2e/newsletter-signup.spec.ts` | `shows success message after valid submission` | EXISTING — must stay green |
| AC2 (new clause) | `e2e/newsletter-signup.spec.ts` | `forwards selected topic IDs as Mailchimp interest groups` | NEW |
| AC2 server-side | `app/api/newsletter/__tests__/route.test.ts` | `forwards topic IDs as interests in Mailchimp request` | NEW |

## Edge case → test mapping (new edge cases only)

| Edge case (new) | Test file | Test name |
|---|---|---|
| `availableTopics` empty/absent → selector omitted | covered by AC1a backwards-compat test | (same test) |
| Topic missing `mailchimpGroupId` → rendered in form, dropped at submit | `e2e/newsletter-signup.spec.ts` | `skips a topic with missing mailchimpGroupId at submission` |
| Submit with no topics selected → succeeds, no interests recorded | `e2e/newsletter-signup.spec.ts` | `submits successfully with no topics selected` |
| Submitted topic IDs not in configured set → silently dropped server-side | `app/api/newsletter/__tests__/route.test.ts` | `drops submitted topic IDs that are not in configured availableTopics` |

## Existing tests that must still pass (sanity check)

These should NOT change and should NOT regress:

- `shows form with copy from Contentful`
- `shows success message after valid submission`
- `shows inline error for invalid email`
- `shows already-subscribed message for existing email`
- `form is keyboard accessible and announces state changes`
- `returns 429 with Retry-After header when rate-limited` (route test)
- `omits section when Contentful is unreachable`
- `shows retry-able error and preserves input on Mailchimp failure`
- ...and all 3 validator unit tests, all 4 route tests.

If any of these go red after the change, the modification is doing more than the spec says it should.

## Coverage check

- New ACs covered: 2 / 2 (AC1a, AC2-new-clause)
- Changed ACs covered: 1 / 1 (AC2 — both old and new clause)
- New edge cases covered: 4 / 4
- Existing tests touched: 0
- New tests: 5 E2E + 2 route = 7 total

## Expected initial state after writing

- 11 existing tests still pass (sanity).
- 5 new E2E tests fail.
- 2 new route tests fail.

If the existing tests don't all pass before adding the new tests, the test environment is in a bad state — investigate before proceeding.
