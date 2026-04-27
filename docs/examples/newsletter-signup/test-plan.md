# Test plan — newsletter signup

> This is the AI's output during Phase 1 of `/write-tests`. The developer reviewed and approved this plan before any test code was written.

## Sources read

The multi-perspective spec model (see [docs/SPEC-MODEL.md](../../skeleton/docs/SPEC-MODEL.md)) means test scope is derived from MORE than just the Functional ACs. For this spec the AI sourced tests from:

- **Functional** — 5 ACs, 6 edge cases (always)
- **Testing** — explicit asks: axe scan, manual screen-reader pass, security crafted-payload tests
- **Security** — testable mitigations (rate limit + Retry-After, server-side validation)
- **Accessibility** — explicit a11y requirements (label association, role=alert, role=status, focus management, keyboard nav)
- **Privacy** — IP not stored beyond rate-limit window (asserted by checking KV TTL behavior)

Skipped: Performance (marked Standard applies), SEO/Analytics/Localization (marked Not applicable).

Conventions: `.claude/rules/testing.md` (Playwright for E2E on port 3001, Vitest for unit tests, MSW for HTTP mocking).

## Files to create

- `e2e/newsletter-signup.spec.ts` — Playwright E2E covering user-visible behavior, accessibility, and end-to-end flows
- `lib/newsletter/__tests__/validate-email.test.ts` — Vitest unit tests for the validator
- `app/api/newsletter/__tests__/route.test.ts` — Vitest tests for the Route Handler (validation, rate limit, Privacy/IP behavior, Mailchimp errors)

No existing tests cover this area.

## Mocks needed

- **Contentful client** — `lib/contentful/__mocks__/newsletter.ts`. Returns a fixed entry by default; individual tests override to simulate missing fields or unreachable.
- **Mailchimp HTTP** — MSW handler at `https://*.api.mailchimp.com/3.0/lists/*/members`. Default returns `{ status: 'subscribed' }`. Tests override to simulate already-subscribed (400 with `title: 'Member Exists'`) and 5xx.
- **Rate-limit store** — in-memory implementation behind the same interface as the Vercel KV one. Reset between tests.

## Tests by source section

### From Functional (ACs)

| AC | Test file | Test name |
|---|---|---|
| AC1: form renders with Contentful copy on every article page | `e2e/newsletter-signup.spec.ts` | `shows form with copy from Contentful` |
| AC2 (UI): valid email → success message | `e2e/newsletter-signup.spec.ts` | `shows success message after valid submission` |
| AC2 (server): API forwards to Mailchimp | `app/api/newsletter/__tests__/route.test.ts` | `forwards valid email to Mailchimp` |
| AC3: invalid/empty email → inline error, no submission | `e2e/newsletter-signup.spec.ts` | `shows inline error for invalid email` |
| AC3 (server): 400 on bad input | `app/api/newsletter/__tests__/route.test.ts` | `returns 400 when email is missing or invalid` |
| AC4: already-subscribed → specific message | `e2e/newsletter-signup.spec.ts` | `shows already-subscribed message for existing email` |
| AC5a: Contentful unreachable → section omitted | `e2e/newsletter-signup.spec.ts` | `omits section when Contentful is unreachable` |
| AC5b: Mailchimp unreachable → retry-able error, input preserved | `e2e/newsletter-signup.spec.ts` | `shows retry-able error and preserves input on Mailchimp failure` |

### From Functional (edge cases)

| Edge case | Test file | Test name |
|---|---|---|
| Empty email | `lib/newsletter/__tests__/validate-email.test.ts` | `rejects empty input as 'empty'` |
| Malformed email (parameterized: `not-an-email`, `a@`, `@b.com`, `a b@c.com`) | `lib/newsletter/__tests__/validate-email.test.ts` | `rejects malformed input as 'invalid'` |
| Trims whitespace + lowercases | `lib/newsletter/__tests__/validate-email.test.ts` | `normalizes valid input` |
| Contentful entry missing required fields | `e2e/newsletter-signup.spec.ts` | `omits section when Contentful entry is incomplete` |
| Mailchimp 5xx | `app/api/newsletter/__tests__/route.test.ts` | `returns 502 when Mailchimp is unreachable` |
| Rapid double-click | `e2e/newsletter-signup.spec.ts` | `disables submit while request is in flight` |

### From Security

| Requirement | Test file | Test name |
|---|---|---|
| Rate limit 10 req/IP/min, 429 + Retry-After | `app/api/newsletter/__tests__/route.test.ts` | `returns 429 with Retry-After header when rate-limited` |
| Server-side validation rejects crafted payloads | `app/api/newsletter/__tests__/route.test.ts` | `returns 400 for non-string email payload` (parameterized: empty body, non-string, oversize) |
| Mailchimp API key never sent to client | covered by architecture (no client-side import path); spot-checked manually before merge | — |

### From Accessibility

| Requirement | Test file | Test name |
|---|---|---|
| Email input has programmatically associated label | `e2e/newsletter-signup.spec.ts` | `email input has accessible label` |
| Inline error uses role=alert | `e2e/newsletter-signup.spec.ts` | `inline error uses role=alert` |
| Success/already-subscribed messages use role=status | `e2e/newsletter-signup.spec.ts` | `success and already-subscribed messages use role=status` |
| Form is keyboard navigable in tab order | `e2e/newsletter-signup.spec.ts` | `form is keyboard navigable in correct tab order` |
| Focus moves to email input when error shown | `e2e/newsletter-signup.spec.ts` | `focus moves to email input when error appears` |
| Submit button has accessible name during pending state | `e2e/newsletter-signup.spec.ts` | `submit button keeps accessible name during pending state` |
| Touch targets ≥44×44px | covered by axe-core scan — see Testing section | — |

### From Privacy

| Requirement | Test file | Test name |
|---|---|---|
| IP not stored beyond 60s TTL | `app/api/newsletter/__tests__/route.test.ts` | `rate-limit entry is set with 60s TTL` |

### From Testing (explicit asks beyond ACs)

| Requirement | Test file | Test name |
|---|---|---|
| Automated axe scan on article page with form rendered | `e2e/newsletter-signup.spec.ts` | `passes axe-core scan with form rendered` |
| Manual screen-reader pass (VoiceOver) before merge | manual; PR checklist item | — |

## Coverage check

- **Functional ACs covered:** 5 / 5
- **Edge cases covered:** 6 / 6
- **Security requirements covered:** 2 / 3 (Mailchimp-key-never-on-client is architectural, not test-able)
- **Accessibility requirements covered:** 6 / 7 (touch-target size deferred to axe scan)
- **Privacy requirements covered:** 1 / 1
- **Testing explicit asks covered:** 1 / 2 (manual screen-reader is a PR checklist item)

**Total automated tests:** ~22 (8 Functional + 6 edge cases + 3 Security + 6 Accessibility + 1 Privacy + 1 axe). Across 3 new test files.

## Expected initial state after writing

All ~22 tests fail. The component, Route Handler, validator, and rate-limit module don't exist yet.
