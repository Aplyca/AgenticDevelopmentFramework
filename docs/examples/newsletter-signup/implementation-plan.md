# Implementation plan — newsletter signup

> This is the AI's output during Phase 1 of `/implement`. The developer reviewed and approved this plan before any code was written.

## Scope (from git diff, spec sections, and committed docs)

- **Spec diff** (`git diff HEAD~3 HEAD~2 -- specs/`): the entire spec is net-new (this is a new feature, not a modification).
- **Test diff** (`git diff HEAD~2 HEAD~1 -- e2e/ lib/ app/`): ~22 failing tests across 3 files.
- **Docs diff** (`git diff HEAD~1 HEAD -- docs/`): 2 new files — `docs/admin/newsletter.md` (~250 lines) and `docs/copy/newsletter-defaults.md` (~80 lines). The implementation uses these as design context; any place where the chosen approach will diverge from the docs gets flagged for reconciliation in the implementation phase.
- **Existing failing tests:** ~22 — all the tests added in the previous commit. No pre-existing tests are red.

The plan must address requirements from every filled spec section (per [docs/SPEC-MODEL.md](../../skeleton/docs/SPEC-MODEL.md)):

- **Functional** — code that makes the AC + edge-case tests pass
- **Security** — server-side validation, rate-limit module, Mailchimp key kept server-side
- **Privacy** — IP stored in KV with 60s TTL, never logged in plaintext
- **Accessibility** — semantic HTML, ARIA roles, focus management in the form component
- **Technical** — Mailchimp wrapper, Vercel KV reuse, server/client component split
- **Observability** — structured logs and the metric counter
- **Deployment** — env var checks, Contentful schema coordination (preconditions, not code)

Skipped (Standard applies / Not applicable in spec): Performance, SEO, Analytics, Localization.

Plus: every claim in the committed admin guide (`docs/admin/newsletter.md`) and copy defaults (`docs/copy/newsletter-defaults.md`) must hold. Notable claims:
- "Changes appear on the site within ~1 minute" → `revalidate: 60` on the Contentful fetch
- "If a required Contentful field is empty, the section is omitted from article pages" → null check + return null in the server component
- The exact field names (`title`, `body`, `ctaLabel`, `successMessage`, `alreadySubscribedMessage`, `errorMessage`) — must match the Contentful content model

## Existing patterns observed

- `lib/contentful/` already has typed client wrappers (`getArticle`, `getAuthor`). New file `lib/contentful/newsletter.ts` should follow the same shape.
- `app/api/` uses Route Handlers (`route.ts` files) with `NextResponse`. Pattern in `app/api/contact/route.ts` is a close analogue.
- Server components in `app/articles/[slug]/page.tsx` already fetch from Contentful at render time. Component composition pattern is to put server components in `components/` and client components in `components/*.client.tsx`.
- No rate-limit utility exists yet. Vercel KV is already provisioned for the project (used by the contact form's spam check). Reuse the same instance.

## Architectural decisions

- **Rate-limit storage:** Vercel KV. Considered in-memory — rejected because Vercel functions are not single-instance. Considered Upstash directly — rejected because we already pay for KV.
- **Validation surface:** validate on the client (UX) AND on the server (security). Client validation is for the inline-error AC; server validation is the source of truth.
- **Server component vs client component split:** the `<NewsletterSignup>` wrapper is a server component (it reads Contentful at render time and can return `null` on failure). The `<NewsletterForm>` inside it is a client component (it owns submit state, error state, and the fetch).
- **Mailchimp client:** thin wrapper at `lib/newsletter/mailchimp.ts`. Returns a discriminated union (`{ status: 'subscribed' | 'already_subscribed' }` or throws on 5xx). Don't use the official SDK — we only need one endpoint and the SDK is heavy.

## Task breakdown (dependency order)

```
- [ ] 1. Create `lib/newsletter/validate-email.ts`
       Email validator. Pure function, no deps.
       [tests: validate-email.test.ts — 3 tests]

- [ ] 2. Create `lib/newsletter/rate-limit.ts`
       IP-based rate limiter on Vercel KV. 10 req / IP / 60s sliding window.
       Returns { ok: true } or { ok: false, retryAfter: number }.
       [tests: covered indirectly by route tests; no separate unit tests requested]

- [ ] 3. Create `lib/newsletter/mailchimp.ts`
       Thin POST wrapper. Maps Mailchimp's 'Member Exists' 400 to 'already_subscribed'.
       Throws on 5xx.
       [tests: covered indirectly by route tests]

- [ ] 4. Create `app/api/newsletter/route.ts`
       POST handler: rate-limit → validate → mailchimp.subscribe → respond.
       [tests: route.test.ts — 4 tests]

- [ ] 5. [P] Create `lib/contentful/newsletter.ts`
       Fetch the singleton newsletterSignup entry. Returns null on failure or
       missing required fields. Wrap with Next.js fetch caching (revalidate: 60).
       [tests: covered indirectly by E2E mock]

- [ ] 6. Create `components/NewsletterSignup.tsx` (server component)
       Reads Contentful copy. Returns null if missing. Renders <NewsletterForm>.
       [tests: e2e — 'shows form with copy', 'omits when unreachable',
        'omits when entry incomplete']

- [ ] 7. Create `components/NewsletterForm.client.tsx` (client component)
       Owns input, error, success, pending state. POSTs to /api/newsletter.
       Maps server response to UI: success | already_subscribed | error | rate_limited.
       Disables button while in flight. role="alert" for inline error / role="status"
       for success messages. Programmatic <label> association. Tab order: email → submit.
       Focus moves to email input when error appears. aria-label on submit during pending.
       [Addresses: Functional ACs 2/3/4, Accessibility (all 6 testable items), edge case
        rapid double-click. Tests: e2e — remaining ~12 tests]

- [ ] 8. Update `app/articles/[slug]/page.tsx`
       Add <NewsletterSignup /> below the article body.
       [Addresses: Functional AC1 placement. Tests: e2e — 'shows form with copy' verifies placement]

- [ ] 9. (Not code — pre-merge checklist)
       Observability section requires structured logs at INFO/ERROR + counter
       newsletter_signup_submissions_total{result}. Add to route.ts in task 4 above
       using the existing logger and metrics util.

[P] = task 5 can run in parallel with tasks 1-4 (no shared deps)
```

**Total files:** 7 new, 1 modified. Within the "5 files for one spec" red-flag threshold but justified — the split between Contentful adapter / validator / rate-limiter / Mailchimp adapter / route / server component / client component is the project's existing pattern, not new abstractions invented for this feature.

## Deployment preconditions (from Deployment section — operator-side, not code)

These ship alongside the code. Calling them out here so the developer/operator doesn't miss them:

- Set `MAILCHIMP_API_KEY` and `MAILCHIMP_LIST_ID` in Vercel env vars for **all environments** (Development, Preview, Production). Missing on Preview is the most common rollout mistake — see the [debugging scenario](../../scenarios/debugging.md).
- Confirm Vercel KV is enabled (already in place for the contact form).
- Coordinate with the Contentful editor: schema `newsletterSignup` must be promoted to all Contentful environments before code deploy. Marketing creates the entry. Verify in Preview before promoting code to Production.

## Risks and trade-offs

- **Rate-limit accuracy across edge regions.** Vercel KV is eventually consistent across regions. A determined client could hit two regions simultaneously and get ~20 req/min. Acceptable for MVP; document the assumption with a comment.
- **`x-forwarded-for` trust.** On Vercel this header is platform-set and trustworthy. If the project ever moves to a custom proxy, this becomes a spoofing vector. Document the assumption near the rate-limit call.
- **Contentful caching.** `revalidate: 60` means marketing edits take up to 60 seconds to appear. They were OK with this in clarification.
- **No analytics yet.** Out of scope per the spec. Will need a follow-up to instrument once the analytics platform is selected.

## Out of scope (preserved from spec)

- Double opt-in flow.
- Unsubscribe / preferences page.
- Backfill of existing subscribers.
- Analytics instrumentation.
- Localization.
- High-contrast theme.

## Verification plan

After implementation:

- `pnpm test:unit` — validate-email + route tests pass.
- `pnpm test:e2e` — all ~22 E2E tests pass (Functional + edge cases + Accessibility + Security + Privacy + axe).
- `pnpm tsc --noEmit` — no type errors.
- Manual screen-reader pass with VoiceOver (Testing section explicit ask).
- Manually visit `/articles/example-article` against a local Contentful sandbox; submit with a real test email; confirm Mailchimp dashboard shows the subscriber.
- Manually break Contentful (invalid token in `.env.local`) and confirm the article page still renders without the signup section.
- Confirm structured logs and the metric counter fire (Observability section).
- Verify env vars are set in Preview AND Production (Deployment section) — the most common cross-environment failure.
