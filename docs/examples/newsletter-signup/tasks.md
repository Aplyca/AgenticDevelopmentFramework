# Tasks: Newsletter signup on article pages

- **Spec:** ./spec.md · **Plan:** ./plan.md
- **Branch:** `feat/newsletter-signup`
- **Last updated:** 2026-06-11

## Phase 0 — Approval

- [x] T000 — Spec folder approved at the gate (scope, change surface, assumptions) and committed (`spec:`)

## Phase 1 — Docs first

- [x] T001 — Admin guide `docs/admin/newsletter.md` for marketing: editing the entry, the field
      reference, turning the form on and off, what readers see when something fails (→ AC1, AC2,
      AC4, AC5, AC6)
- [x] T002 — Copy defaults `docs/copy/newsletter-defaults.md`: suggested text for the six fields
      (→ AC1, AC2, AC4, AC6)

## Phase 2 — Foundation

- [x] T010 — Email validation, `lib/newsletter/validate-email.ts` (test:
      `lib/newsletter/__tests__/validate-email.test.ts` · "rejects %s as invalid") (→ AC3)
- [x] T011 [P] — Per-IP rate limiter, `lib/newsletter/rate-limit.ts` (test:
      `lib/newsletter/__tests__/rate-limit.test.ts` · "allows 10 requests from one IP and blocks
      the 11th with retryAfter", "stores the per-IP counter with a 60-second expiry") (→ Security,
      Privacy)
- [x] T012 [P] — Mailchimp client, `lib/newsletter/mailchimp.ts`, with its two variables declared
      in `.env.example` (test: `lib/newsletter/__tests__/mailchimp.test.ts` · "maps Mailchimp's
      Member Exists response to already_subscribed", "throws MailchimpUnavailableError on a 5xx
      response") (→ AC2, AC4, AC6)

## Phase 3 — Stories (TDD, one commit per task)

- [x] T020 [P] — Load the copy from Contentful, `lib/contentful/newsletter.ts` (test:
      `lib/contentful/__tests__/newsletter.test.ts` · "returns null when a required field is
      empty", "requests the entry with the article route's 300-second revalidation") (→ AC1, AC5)
- [x] T021 — Subscribe endpoint, `app/api/newsletter/route.ts` (test:
      `app/api/newsletter/__tests__/route.test.ts` · "subscribes a valid email and returns 200
      subscribed", "returns 400 invalid_email for %s") (→ AC2, AC3, AC4, Security)
- [x] T022 — Rate limit and provider failure in the endpoint (test:
      `app/api/newsletter/__tests__/route.test.ts` · "returns 429 with Retry-After on the 11th
      request from one IP", "returns 502 provider_unavailable and logs
      newsletter.subscribe.mailchimp_error when Mailchimp fails") (→ AC6, Security)
- [x] T023 — The section on article pages: `components/NewsletterSignup.tsx`, the form's markup,
      and `app/articles/[slug]/page.tsx` (test: `components/__tests__/NewsletterSignup.test.tsx` ·
      "renders nothing when the copy can't be loaded"; `e2e/newsletter-signup.spec.ts` · "shows the
      signup section with Contentful copy below the article body") (→ AC1, AC5)
- [x] T024 — The form's behavior: submit, inline validation, outcome messages, pending state (test:
      `components/__tests__/NewsletterForm.test.tsx` · "shows an inline error, sends nothing, and
      moves focus to the field for an invalid email", and seven more) (→ AC2, AC3, AC4, AC6,
      Accessibility)

## Phase 4 — Acceptance

- [x] T030 — End-to-end tests for AC2–AC6, keyboard order, axe, target size, and cookies (test:
      `e2e/newsletter-signup.spec.ts` — nine tests) (→ AC2, AC3, AC4, AC5, AC6, Accessibility,
      Privacy)

## Phase 5 — Reconcile & polish

- [x] T040 — Reconcile committed docs with what was built (→ Documentation)
- [x] T041 — Post-implementable docs: operator runbook `docs/runbooks/newsletter.md` (→ Documentation)
- [x] T042 — Record gate results below

## Verification checklist (each checkpoint)

- [x] Lint clean — `pnpm lint`
- [x] Typecheck clean — `pnpm typecheck`
- [x] Unit / integration tests passing — `pnpm test`
- [x] End-to-end tests passing — `pnpm test:e2e` (Chromium; WebKit and Firefox run in CI only, see
      below)
- [x] Every acceptance criterion met; every filled spec section addressed
- [x] Security and accessibility reviewed — `/review`, 2026-06-11; the VoiceOver pass is listed
      below as not run

## Gate results (2026-06-11)

**Baseline**, before T010: `pnpm test` — 41 files, 212 tests passing. `pnpm test:e2e` — 3 files,
14 tests passing. Lint and typecheck clean. No pre-existing failures.

**Red, then green, per task.** Each new module's first run failed on the missing import — that is
not a red. The red recorded here is the first run that reached an assertion, after the module's
exported signature existed with no behavior behind it.

| Task | Red | Green |
| --- | --- | --- |
| T010 | `validate-email.test.ts` — 9 failed. First: `expected { ok: true, email: '  Reader@Example.com ' } to deeply equal { ok: true, email: 'reader@example.com' }` | 9 passed |
| T011 | `rate-limit.test.ts` — 3 failed. First: `expected { ok: true } to deeply equal { ok: false, retryAfter: 60 }` | 3 passed |
| T012 | `mailchimp.test.ts` — 4 failed. First: `expected 'subscribed' to be 'already_subscribed'` | 4 passed |
| T020 | `newsletter.test.ts` — 5 failed. First: `expected { title: '', body: '', …(4) } to be null` | 5 passed |
| T021 | `route.test.ts` — 6 failed. First: `expected 501 to be 200` | 6 passed |
| T022 | `route.test.ts` — 2 failed, 6 passed: `expected 200 to be 429`; `promise rejected "MailchimpUnavailableError: Mailchimp responded 503" instead of resolving` | 8 passed |
| T023 | `NewsletterSignup.test.tsx` — 2 failed: `Unable to find an accessible element with the role "heading"`. E2E: `expect(locator).toBeVisible()` — `Received: <element(s) not found>` | 2 passed; E2E 1 passed |
| T024 | `NewsletterForm.test.tsx` — 7 failed, 1 passed. First: `Unable to find an accessible element with the role "alert"`. "labels the email field" passed before any T024 code: T023 had already built the label for AC1. The behavior exists, so the test isn't wrong; it stays as the guard for the accessibility requirement | 8 passed |
| T030 | E2E — the 9 new tests passed on the first run: the behavior was built red-then-green in T010–T024. Each was seen failing once: against `main`'s build, 8 of the 9 failed; AC5's passed there (`main` has no section at all) and failed once its Contentful failure was switched off | 10 passed |

**Docs.** T040: the 14 claims in the admin guide and the copy defaults were checked against the
build; 13 held and 1 was rewritten (Contentful won't publish an entry with an empty required field —
see the `docs:` commit). T041: the runbook was written from the built log events and error mapping.

**Full gate** (`pnpm verify`):

- `pnpm lint` — clean, including the `jsx-a11y` and `react/no-danger` rules
- `pnpm typecheck` — clean
- `pnpm test` — 48 files, 251 tests passed (212 before, 39 new)
- `pnpm build` — succeeded; it would fail if a client component imported the Mailchimp client
- `pnpm test:e2e` — 4 files, 24 tests passed on Chromium (14 before, 10 new), including the axe scan

**Not run here, and why:**

- The VoiceOver pass — needs a person. It happens on the preview deployment, before the pull
  request is marked ready.
- A real Mailchimp signup and a real Contentful read — tests mock both, by rule. Both are checked on
  the preview, which needs `MAILCHIMP_API_KEY` and `MAILCHIMP_LIST_ID` set for Preview in Vercel —
  not visible from here.
- End-to-end runs on WebKit and Firefox — the project runs them in CI only.

**Pre-existing failures:** none.
