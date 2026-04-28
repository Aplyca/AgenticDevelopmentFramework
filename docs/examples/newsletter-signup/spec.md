---
title: "Newsletter signup on article pages"
area: "marketing"
status: approved
feature-type: ui
personal-data: yes
owners:
  business: client
  functional: senior-dev
  design: designer
  accessibility: a11y-lead
  security: security-lead
  privacy: tech-lead
  technical: tech-lead
  testing: qa
  documentation: tech-writer
  deployment: devops
references:
  figma: "https://figma.com/file/[example]/newsletter-signup"
  adrs:
    - "ADR-0007: Mailchimp as ESP for marketing list"
    - "ADR-0009: Vercel KV for in-route rate limiting"
  rfcs: []
  related-specs: []
---

# Part 1 — Intent

## Business [REQUIRED]

> Owned by: client (marketing team)

Marketing wants a newsletter signup form on every article page so they can grow the subscriber list and run weekly campaigns. Copy must be editable in Contentful so they can A/B test headlines and CTAs without a code deploy. Subscribers go to Mailchimp because that's the existing ESP.

**Success criteria:**

- 5%+ conversion rate from article-page visit to confirmed signup within the first quarter post-launch.
- Marketing can edit form copy in Contentful and see changes in production within 5 minutes.

## Functional [REQUIRED]

> Owned by: senior developer

### User stories

- As a **reader**, I want to subscribe to the newsletter from any article page, so that I get more content like what I just read.
- As a **marketer**, I want to edit the signup copy in Contentful, so that I can A/B test headlines and CTAs without a code deploy.
- As an **operator**, I want the form to fail safely when Contentful or Mailchimp is unavailable, so that a CMS or ESP outage doesn't break article pages.

### Acceptance criteria

1. Every article page renders a newsletter signup section beneath the article body, containing a heading, body copy, an email input with a visible label, and a submit button. Heading, body copy, and submit button label are sourced from the singleton Contentful entry of type `newsletterSignup`.
2. When the user submits a valid email address, the form replaces itself with a success message sourced from the same Contentful entry, and the email is recorded as a Mailchimp subscriber.
3. When the user submits an empty or malformed email, an inline error message appears next to the input, the form is not submitted, and focus moves to the input.
4. When the user submits an email that is already subscribed to Mailchimp, the form replaces itself with an "already subscribed" message (separate from the success message) sourced from the Contentful entry.
5. When Contentful is unreachable at render time, the newsletter section is omitted from the article page entirely (the page still renders without error). When Mailchimp is unreachable at submit time, the form shows a generic, retry-able error message and does not lose the user's input.

### Edge cases

- Empty email on submit → inline error, no submission.
- Malformed email (no `@`, no domain, contains spaces) → inline error, no submission.
- Email already subscribed → "already subscribed" message, treated as successful UX outcome.
- Contentful entry missing required fields → section omitted entirely, warning logged server-side.
- Mailchimp returns 5xx → user sees retry-able error, input preserved, server logs the failure.
- User clicks submit multiple times rapidly → button disabled while request is in flight, no duplicate submissions.

## Out of scope [REQUIRED]

- Double opt-in confirmation email (Mailchimp can be configured to send one independently).
- A user preferences / unsubscribe page.
- Backfilling subscribers from any prior list.
- Per-article variants of the copy (A/B test is global, not per-article).

---

# Part 2 — User experience

## Design [filled — UI feature]

> Owned by: designer

- **Mockups:** [Figma link in references]
- **UX patterns to follow:** matches the existing inline-callout pattern used by the related-articles section (single-column, full-width on mobile, contained on desktop).
- **Variants / states:**
  - Default: heading + body + email input + submit button
  - Pending: button shows spinner + label "Subscribing..."
  - Success: form replaced by success message
  - Already subscribed: form replaced by alt message
  - Error: inline error message beside input
- **Brand constraints:** uses the existing primary button style. No new color tokens.

## Accessibility [REQUIRED — UI feature]

> Owned by: a11y lead

Project default is WCAG 2.1 AA. Specific testable requirements for this feature:

- Email input has a programmatically associated `<label>` (visible, not placeholder-only).
- Inline error message uses `role="alert"` so screen readers announce it on appearance.
- Success and already-subscribed messages use `role="status"`.
- Submit button has an accessible name even when displaying a spinner (`aria-label="Subscribing"` during pending).
- Form is fully keyboard navigable in tab order: email → submit. No keyboard traps.
- Focus moves to the email input when an inline error is shown.
- Touch targets ≥44×44px on mobile.

---

# Part 3 — Non-functional requirements

## Security [REQUIRED]

> Owned by: security lead

- The Mailchimp API key is never exposed to the browser. All Mailchimp calls happen in the server-side Route Handler.
- The Route Handler rate-limits to 10 requests per IP per minute. Requests beyond the limit return HTTP 429 with `Retry-After` header set to seconds until window resets.
- The Route Handler trusts the `x-forwarded-for` header for IP identification (Vercel platform sets this; trustworthy on Vercel deploys).
- Email input is validated server-side (source of truth) AND client-side (UX); never trust client validation alone.
- No `dangerouslySetInnerHTML` paths — Contentful copy is rendered as text only.

## Privacy [REQUIRED — collects personal data (email)]

> Owned by: tech lead

- **Data collected:** email address, IP address (for rate limiting; not stored beyond the rate-limit window).
- **Lawful basis:** explicit user action (entering email and clicking subscribe = consent).
- **Storage:** email stored in Mailchimp (US region — covered by existing data processing agreement). IP stored in Vercel KV with 60-second TTL for rate-limit purposes only, not retained.
- **Transmission:** email transmitted to Mailchimp HTTPS API.
- **User rights:** users can unsubscribe via the link in any newsletter email (Mailchimp default). Right-to-be-forgotten is handled by the existing privacy ops process.
- **Cookie / tracking consent:** no cookies set by this feature. No consent banner update needed.

## Performance

> Not applicable: standard project performance targets (see `.claude/rules/performance.md`) cover this feature. The form is below the fold and does not affect LCP. Submit-to-feedback target is the project default of <500ms p95.

## SEO

> Not applicable: form is interactive UI, not search-indexed content.

## Analytics

> Not applicable for this iteration: analytics platform selection is in flight (separate spec). Will be backfilled when the analytics tooling lands.

## Localization

> Not applicable: site is currently English-only. When localization rolls out site-wide, this form's Contentful copy will follow the project's standard localization pattern with no code changes needed.

---

# Part 4 — Technical

## Technical [filled — non-default integration]

> Owned by: tech lead

### Architecture & integrations

- Submissions go to Mailchimp via a Next.js Route Handler at `app/api/newsletter/route.ts`. Mailchimp API key is server-side only (env var).
- Rate limit storage uses Vercel KV (already provisioned for the contact form's spam check; reuse the same instance).
- Server component fetches Contentful copy via the existing shared client at `lib/contentful/client.ts` with `revalidate: 60` so marketing edits appear within ~1 minute.
- A thin Mailchimp wrapper at `lib/newsletter/mailchimp.ts` handles the single endpoint we need; no SDK (lightweight, single-purpose).

### ADRs

- **ADR-0007** — Mailchimp as ESP for marketing list (existing decision, no change).
- **ADR-0009** — Vercel KV for in-route rate limiting (created during this spec's planning, applies to all rate-limited routes).

---

# Part 5 — Validation & delivery

## Testing [REQUIRED]

> Owned by: QA / tech lead

### Mandatory test scope

- Every functional AC has at least one E2E test (Playwright, port 3001).
- Every edge case has at least one test.
- Email validator has unit tests covering valid + each invalid form (empty, no `@`, no domain, whitespace, mixed case normalization).
- Route Handler has tests for: valid submission, invalid input, rate-limited (429 + Retry-After), Mailchimp 5xx (502).

### Additional test types beyond ACs

- **Accessibility**: automated axe scan in the E2E suite for the article page with the form rendered. Manual screen-reader pass with VoiceOver before merge.
- **Security**: server-side validation tested with crafted payloads (empty body, non-string email, oversize input).

### Out of test scope

- Load testing — current traffic doesn't justify it. Revisit if newsletter traffic exceeds 1000 submissions/day.

## Documentation [REQUIRED]

> Owned by: tech writer / dev

### Pre-implementable docs (written before code via `/write-docs`)

| Audience | What they need | Where it lives |
|---|---|---|
| Site administrator (marketing) | How to edit the `newsletterSignup` Contentful entry — which fields are required, where copy appears, how soon edits go live, how to verify the form on the site | `docs/admin/newsletter.md` |
| End user (via CMS) | Default copy for title, body, CTA, success message, already-subscribed message, error message — seed values that marketing customizes in Contentful | `docs/copy/newsletter-defaults.md` |

### Post-implementable docs (backfilled after code)

| Audience | What they need | Where it lives |
|---|---|---|
| Developer | How rate limiting works, how to swap ESPs, where the Mailchimp wrapper lives | Inline JSDoc on `lib/newsletter/*` + a one-paragraph addition to `docs/ARCHITECTURE.md` |
| Operator | Runbook entry: how to investigate a spike in 429s, how to verify Mailchimp connectivity, what to do when Contentful is unreachable | `docs/runbooks/newsletter.md` |

### Out of documentation scope

- No public API docs needed — internal feature only.
- No support troubleshooting guide for end users — handled by the marketing team's existing FAQ.

## Observability [filled — non-default monitoring needed]

> Owned by: DevOps / SRE

- **Logs:** structured logs at INFO for normal events (`newsletter.subscribe.ok`, `newsletter.subscribe.already_subscribed`), ERROR for failures (`newsletter.subscribe.mailchimp_5xx`, `newsletter.subscribe.contentful_unreachable`). Include request IP (hashed) and Mailchimp response status.
- **Metrics:** counter `newsletter_signup_submissions_total{result}` where `result` is one of `ok | already_subscribed | invalid_email | rate_limited | mailchimp_error | server_error`.
- **Alerts:** page on-call if `mailchimp_error` rate exceeds 5% of submissions over a 5-minute window.
- **Dashboards:** add a panel to the existing "Marketing site" dashboard showing submissions per hour by result.

## Deployment [filled — new env vars and KV setup]

> Owned by: DevOps

- **Environment variables:**
  - `MAILCHIMP_API_KEY` — Mailchimp API key. Stored in Vercel project secrets. Set for **all** environments (Development, Preview, Production) — must not be missing on Preview deploys.
  - `MAILCHIMP_LIST_ID` — target list ID. Same scope.
- **Infrastructure changes:** confirm Vercel KV instance is enabled and accessible from Production (already in place for the contact form). No new provisioning.
- **Database / schema changes:**
  - Contentful: add new singleton content type `newsletterSignup` with fields: `title`, `body`, `ctaLabel`, `successMessage`, `alreadySubscribedMessage`, `errorMessage`. Schema must be promoted to all Contentful environments before code deploy.
- **Rollout strategy:** standard Vercel deploy. No feature flag — feature is intrinsically gated by the presence of the Contentful entry (no entry → form omits gracefully).
- **Rollback plan:** revert the deploy. Contentful schema can stay (no harm if unused).
- **Coordination:** Contentful schema → Contentful entry created by marketing → code deploy. In that order. Verify in Preview before promoting to Production.

---

# Part 6 — Meta

## Clarifications [REQUIRED]

- **Q:** Form placement — every article page, or only certain types? **A:** Every article page, beneath the article body. Sidebar placement is out of scope for this iteration.
- **Q:** Contentful model — new entry type or reuse existing? **A:** New singleton entry type `newsletterSignup` (fields enumerated in Deployment).
- **Q:** What counts as a valid email? **A:** Non-empty after trim, matches `^[^\s@]+@[^\s@]+\.[^\s@]+$`. Marketing accepts that this allows some technically-invalid addresses; Mailchimp does the strict check.
- **Q:** Already-subscribed email — show specific message or generic success? **A:** Specific message ("you're already subscribed"). Marketing prefers transparency over the privacy gain of a generic message.
- **Q:** Rate limit value? **A:** 10 requests per IP per minute. ~10× a reasonable human submission rate.
- **Q:** Contentful unreachable at render time — omit or fallback? **A:** Omit silently. Article pages must never fail because of a CMS outage.
- **Q:** Mailchimp unreachable at submit — what does the user see? **A:** "Something went wrong, please try again" with input preserved. No automatic retry on the client.
- **Q:** Accessibility target? **A:** Project default (WCAG 2.1 AA) with the explicit ARIA roles listed in the Accessibility section.
- **Q:** Where does the Mailchimp API key live? **A:** Vercel env vars, set for ALL environments (this is the key context for the preview-deploy bug class — see ADR-0009 follow-up).

## References

- ADR-0007: Mailchimp as ESP for marketing list
- ADR-0009: Vercel KV for in-route rate limiting
- Figma: [link in frontmatter]
