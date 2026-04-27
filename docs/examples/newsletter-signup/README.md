# Worked example: Newsletter signup

This walkthrough shows the full spec-driven, test-driven, AI-assisted cycle for a small but realistic feature on a **Next.js + Contentful + Vercel** site.

**Goal:** add a newsletter signup form to article pages. Copy comes from Contentful so marketing can edit it. Submissions go through a Next.js Route Handler that rate-limits and forwards to the email service provider.

**Why this feature:** small enough to read in 15 minutes, but realistic — it touches a CMS read, a server-side route, client-side validation, accessibility, and a third-party integration. Most of the patterns you'll use day-to-day appear here.

---

## The starting requirement

What the developer received from marketing:

> *"We need a newsletter signup form on every article page so we can grow our list. Copy needs to be editable in Contentful since we'll A/B test it. Submissions go to Mailchimp."*

That's the whole brief. There are roughly a dozen unanswered questions hidden in it — and the spec phase is where they get pulled out.

---

## Phase 1 — Spec

### What the developer typed

```
/write-spec newsletter signup form on article pages, copy from Contentful, submits to Mailchimp
```

### What the AI did

The `/write-spec` skill (see `.claude/skills/write-spec/SKILL.md`) doesn't jump to a draft. It uses the **multi-perspective spec model** (see [docs/SPEC-MODEL.md](../../skeleton/docs/SPEC-MODEL.md)), which means it first classifies the feature, then asks clarifying questions across all relevant role perspectives.

In this session the AI's first move was classification:

> **AI:** Quick classification before clarifications:
>
> - **`feature-type`**: this is `ui` (form on article pages) — Accessibility section will be required.
> - **`personal-data`**: yes (collects email and IP for rate limiting) — Privacy section will be required.
>
> Required sections for this spec: Business, Functional, Out of scope, Accessibility, Security, Privacy, Testing, Documentation, Clarifications. Optional sections that look likely from your description: Design (UI feature), Technical (Mailchimp integration), Observability (you'll want to know if signups fail), Deployment (env vars and Contentful schema).
>
> Now the role-perspective clarifications:
>
> 1. **Business** — who's the success metric for this? What conversion rate makes this a success?
> 2. **Functional/Form placement** — every article page, or only certain types?
> 3. **Functional/Validation** — what counts as a valid email?
> 4. **Functional/Already-subscribed** — show specific message or generic success?
> 5. **Functional/Failure modes** — Contentful down at render → omit or fallback? Mailchimp down at submit → what does the user see?
> 6. **Design** — do you have mockups, or should we use the existing inline-callout pattern?
> 7. **Accessibility** — anything beyond WCAG 2.1 AA default?
> 8. **Security** — Mailchimp will accept any call; do we throttle? At what rate?
> 9. **Privacy** — IP for rate limiting OK to store transiently? Mailchimp data residency clear?
> 10. **Observability** — what's the alert threshold for "newsletter is broken"?
> 11. **Deployment** — confirm the Mailchimp env var should be set on ALL environments (this matters for Preview deploys).
> 12. **Documentation** — who needs admin docs for editing the Contentful entry?

The developer answered each one (most by checking with marketing first). Those answers are preserved in the spec under **Clarifications** — they're the audit trail for *why* the spec says what it says.

### The artifact

The final, approved spec: **[spec.md](spec.md)**.

Notice four things about it:

- **It captures input from many roles in one document.** Business, Functional, Design, Accessibility, Security, Privacy, Technical, Testing, Documentation, Observability, Deployment — each with a named owner. Optional sections that don't apply (Performance, SEO, Analytics, Localization) are explicitly marked `Not applicable: [reason]` so the next reader knows the team considered them, not skipped them.
- **No code, no file paths, no implementation details in Functional/Business.** It says *"copy comes from Contentful"*, not *"fetch from `/api/contentful?type=newsletterSignup`"*. Implementation specifics (Vercel KV, the Mailchimp wrapper at `lib/newsletter/`) are confined to the **Technical** section, which exists precisely for them.
- **Each AC is independently testable.** "User sees a success message after submitting a valid email" maps to one test. It doesn't bundle "and the email is forwarded to Mailchimp" — that's a separate AC, separate test.
- **Edge cases and out-of-scope are explicit.** Without them, scope creep is inevitable. The spec says "no double opt-in" once, so the implementer can't drift into building it.

### What the spec model bought us

Three things in the Security, Privacy, and Deployment sections that would be easy to miss without the role-perspective discipline:

- **Security**: explicit rate limit, explicit "Mailchimp key never in browser", explicit `x-forwarded-for` trust assumption. None of these are hinted at in the business ask.
- **Privacy**: IP retention is explicit (60-second TTL, rate-limit only). Mailchimp data residency is called out (US region, existing DPA). User rights are documented. A reviewer six months from now can answer compliance questions from this section without code-archaeology.
- **Deployment**: the env var must be set on ALL environments — including Preview. This single line prevents the Preview-deploy 500 incident shown in the [debugging scenario](../../scenarios/debugging.md). The "deployment specs" idea earns its keep here.

### Approval and commit

The developer reviewed, made two edits (added one edge case, tightened the rate-limit AC), and asked the AI to flip the status to `approved`. The skill ran its mandatory-section check first:

> **AI:** Verifying required sections before approval...
> - Business ✓ (1 paragraph + success criteria)
> - Functional ✓ (5 ACs, 6 edge cases)
> - Out of scope ✓ (4 items)
> - Accessibility ✓ (UI feature — required, 7 explicit a11y requirements listed)
> - Security ✓ (5 specific mitigations)
> - Privacy ✓ (personal-data: yes — required, all 6 sub-items filled)
> - Testing ✓ (mandatory scope + axe + manual screen-reader pass)
> - Documentation ✓ (3 audiences identified)
> - Clarifications ✓ (9 Q&As)
>
> All required sections filled. Flipping status to `approved`.

> **What if a required section had been empty?** The skill refuses to approve, lists the missing sections, and offers to walk through them. A spec can't pass this gate by skipping a perspective.

```bash
git add specs/newsletter-signup.md
git commit -m "spec: add newsletter signup form for article pages"
```

> **Why commit before tests?** The spec commit captures **intent** as a single point in history. When `/write-tests` runs next, it diffs the spec commit to know exactly which ACs are in scope — critical when you later modify this feature and only some ACs change.

---

## Phase 2 — Tests (TDD red)

### What the developer typed

```
/write-tests newsletter-signup
```

### Phase 2a — Plan

`/write-tests` doesn't write tests immediately. It first reads the spec, reads `.claude/rules/testing.md`, then **presents a plan for approval**.

The plan output: **[test-plan.md](test-plan.md)**.

Things to notice in the plan:

- Every AC has at least one test. Every edge case has a test.
- The plan names the test file (`e2e/newsletter-signup.spec.ts`) and the unit test file (`lib/newsletter/__tests__/validate-email.test.ts`). It does *not* yet write code.
- It lists the mocks needed: Contentful client, Mailchimp HTTP call, the rate-limit store. No real Contentful or Mailchimp calls in tests.

The developer reviewed the plan, asked one question ("can we add a test for the rate-limit `Retry-After` header?"), the AI updated the plan, and the developer approved.

### Phase 2b — Execute

After approval, the AI wrote the tests. Snippet from the E2E test:

```ts
// e2e/newsletter-signup.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Newsletter signup on article page', () => {
  test('shows form with copy from Contentful', async ({ page }) => {
    await page.goto('/articles/example-article');
    const region = page.getByRole('region', { name: /newsletter/i });
    await expect(region).toBeVisible();
    await expect(region.getByRole('heading')).toHaveText('Get the weekly digest');
    await expect(region.getByLabel(/email/i)).toBeVisible();
  });

  test('shows success message after valid submission', async ({ page }) => {
    await page.goto('/articles/example-article');
    await page.getByLabel(/email/i).fill('reader@example.com');
    await page.getByRole('button', { name: /subscribe/i }).click();
    await expect(page.getByRole('status')).toHaveText(/thanks/i);
  });

  test('shows inline error for invalid email', async ({ page }) => {
    await page.goto('/articles/example-article');
    await page.getByLabel(/email/i).fill('not-an-email');
    await page.getByRole('button', { name: /subscribe/i }).click();
    await expect(page.getByRole('alert')).toHaveText(/valid email/i);
  });

  // ...one test per AC and edge case
});
```

The developer ran them:

```bash
$ pnpm test:e2e
  ✘ shows form with copy from Contentful (component does not exist)
  ✘ shows success message after valid submission
  ✘ shows inline error for invalid email
  ✘ inline error uses role=alert
  ✘ form is keyboard navigable in correct tab order
  ✘ passes axe-core scan with form rendered
  ✘ returns 429 with Retry-After when rate-limited
  ...
  ~22 failed, 0 passed
```

> **All red — exactly right.** No code exists yet. If a test had passed at this stage, it would mean the test was wrong (testing nothing, or testing pre-existing behavior).

### Commit

```bash
git add e2e/newsletter-signup.spec.ts lib/newsletter/__tests__/
git commit -m "test: add newsletter signup tests (red — pending implementation)"
```

> **Why commit failing tests?** They're the verification contract. The implementer's job is now well-defined: make these specific tests pass. Anything beyond that is scope creep.

---

## Phase 3 — Implement (TDD green)

### What the developer typed

```
/implement newsletter-signup
```

### Phase 3a — Plan

Same plan-then-execute pattern. The AI:

1. Ran `git diff HEAD~2 HEAD~1 -- specs/` to see what was added in the spec commit.
2. Ran `git diff HEAD~1 HEAD -- e2e/ lib/` to see what tests are expecting.
3. Ran `pnpm test` to confirm the current red state.
4. Read existing patterns in `app/articles/`, `lib/contentful/`, `app/api/`.
5. Presented an implementation plan.

The plan output: **[implementation-plan.md](implementation-plan.md)**.

Things to notice:

- File-by-file breakdown in dependency order. Validation helper first (no deps), then the API route (uses validator), then the React component (uses both via fetch).
- Each task lists which tests it makes pass. This is the linkage between AC, test, and code.
- Two tasks marked `[P]` — they're independent and could be done in parallel.
- One architectural decision called out: rate-limit storage. The plan proposes Vercel KV; the developer agreed.

### Phase 3b — Execute

The AI worked through the tasks. Excerpts:

```ts
// lib/newsletter/validate-email.ts
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateEmail(input: unknown): { ok: true; email: string } | { ok: false; reason: 'empty' | 'invalid' } {
  if (typeof input !== 'string' || input.trim() === '') return { ok: false, reason: 'empty' };
  const email = input.trim().toLowerCase();
  if (!EMAIL_RE.test(email)) return { ok: false, reason: 'invalid' };
  return { ok: true, email };
}
```

```ts
// app/api/newsletter/route.ts
import { NextResponse } from 'next/server';
import { validateEmail } from '@/lib/newsletter/validate-email';
import { rateLimit } from '@/lib/newsletter/rate-limit';
import { subscribe } from '@/lib/newsletter/mailchimp';

export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'unknown';
  const limit = await rateLimit(ip);
  if (!limit.ok) {
    return NextResponse.json(
      { error: 'rate_limited' },
      { status: 429, headers: { 'Retry-After': String(limit.retryAfter) } },
    );
  }

  const body = await req.json().catch(() => ({}));
  const result = validateEmail(body.email);
  if (!result.ok) {
    return NextResponse.json({ error: result.reason }, { status: 400 });
  }

  const outcome = await subscribe(result.email);
  return NextResponse.json({ status: outcome });  // 'subscribed' | 'already_subscribed'
}
```

```tsx
// components/NewsletterSignup.tsx — server component fetches copy, hands to client form
import { getNewsletterCopy } from '@/lib/contentful/newsletter';
import { NewsletterForm } from './NewsletterForm.client';

export async function NewsletterSignup() {
  const copy = await getNewsletterCopy().catch(() => null);
  if (!copy) return null;  // AC: omit silently if Contentful is unreachable
  return (
    <section aria-label={copy.title}>
      <h2>{copy.title}</h2>
      <p>{copy.body}</p>
      <NewsletterForm cta={copy.cta} />
    </section>
  );
}
```

After each significant change the AI re-ran the tests. Final state:

```bash
$ pnpm test:e2e
  ✓ shows form with copy from Contentful (1.2s)
  ✓ shows success message after valid submission (0.8s)
  ✓ shows inline error for invalid email (0.4s)
  ✓ shows already-subscribed message for existing email (0.7s)
  ✓ inline error uses role=alert (0.3s)
  ✓ success and already-subscribed messages use role=status (0.4s)
  ✓ form is keyboard navigable in correct tab order (0.5s)
  ✓ focus moves to email input when error appears (0.3s)
  ✓ passes axe-core scan with form rendered (0.6s)
  ✓ returns 429 with Retry-After when rate-limited (0.3s)
  ✓ omits section when Contentful is unreachable (0.6s)
  ...
  ~22 passed
```

> **All green — and only the tests that were committed.** The AI didn't add features the spec didn't ask for. No analytics, no double opt-in, no admin dashboard.

---

## Phase 4 — Review

### What the developer typed

```
/review
```

The skill ran a multi-perspective review. Sample findings:

> **`@code-reviewer`:** the rate-limit window resets per minute but uses `Date.now()` — clock skew across Vercel edge regions could let a determined client get ~20 req/min. Acceptable trade-off, but worth a comment.
>
> **`@security-reviewer`:** `x-forwarded-for` is trusted as-is. On Vercel this header is set by the platform, but if the project ever moves to a custom proxy, this becomes a spoofing vector. Recommend documenting the assumption.
>
> **`@ux-reviewer`:** the success message uses `role="status"` — good. The error message uses `role="alert"` — good. The submit button doesn't show a pending state during the network request. AC #5 says "form is accessible" but doesn't explicitly require a loading indicator. Flag for spec follow-up, not a blocker.

The developer added an inline comment about the IP-trust assumption, opened a follow-up ticket for the loading state, and moved on.

---

## Phase 5 — Commit

```
/commit
```

The skill staged the changes, drafted a message focused on *why*, and committed:

```bash
git commit -m "feat: add newsletter signup on article pages

Marketing-editable form via Contentful, posts to Mailchimp through a
rate-limited Route Handler. Section is omitted gracefully when Contentful
is unreachable so article pages never error on a CMS outage."
```

---

## What the git history looks like at the end

```
* feat: add newsletter signup on article pages
* test: add newsletter signup tests (red — pending implementation)
* spec: add newsletter signup form for article pages
```

Three clean layers — intent, contract, execution. Six months from now when marketing wants to A/B test the rate-limit window, the next developer reads the spec to understand the constraint, the test commit to understand what's verified, and the implementation commit only if they need to touch the code.

---

## What this example deliberately leaves out

- **The Contentful model definition.** In a real project that's an ADR or a content-modeling doc, not part of this spec.
- **Mailchimp API details.** Treated as a black box behind `subscribe(email)`. Easy to swap for another ESP.
- **Production observability.** Logging, metrics, and error tracking belong in `.claude/rules/observability.md`, not in this spec.
- **Backfill of existing subscribers.** Out of scope — explicitly called out in the spec.

---

## Try it yourself

The fastest way to internalize this workflow is to do it once on a small feature in your project. Suggested first features (each is ~newsletter-signup-sized):

- A site-wide promo banner driven by a Contentful entry, dismissible per visitor.
- A "share this article" cluster (copy link, X, LinkedIn) with click tracking to a Route Handler.
- A `/health` Route Handler that pings Contentful and returns `{ status, deps: { contentful: 'ok' | 'down' } }`.

Pair with a teammate the first time. The workflow takes 30-60 minutes for a feature this size — most of it reading and approving plans, not waiting for AI to type.

---

## What this feature looks like when it gets modified

Three months later marketing wants subscribers to optionally pick topics they're interested in. The same workflow applies, but the patterns differ — the spec is *updated* (not rewritten), most existing tests stay green, and backwards compatibility becomes a first-class concern.

See **[newsletter-topics](../newsletter-topics/)** for the full modification cycle on this same feature.
