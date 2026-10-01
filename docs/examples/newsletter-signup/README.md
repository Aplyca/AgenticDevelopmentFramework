# Worked example: newsletter signup (a new feature)

This walkthrough follows one feature through the whole workflow, from the tracker task to the
draft pull request and the message back to the requester: **triage → spec folder → plan with its
change surface → an independent check → one approval gate → docs first → one TDD commit per task →
reconciled docs → gate results → review → draft PR → client update.**

The project is a marketing site built with **Next.js (App Router) + Contentful + Vercel**;
subscribers go to **Mailchimp**. The feature is small enough to read in one sitting, yet it touches a
CMS read, a server endpoint, a third-party API, personal data, accessibility, and a shared page
template — most of what everyday work involves.

## The files in this folder

`spec.md`, `plan.md`, and `tasks.md` are the spec folder exactly as it sits in the project at
`specs/007-newsletter-signup/` after delivery. This README is the walkthrough — it is not part of
the spec folder.

| File | What it is |
| --- | --- |
| [spec.md](spec.md) | WHAT and WHY — the multi-perspective spec, `status: implemented` |
| [plan.md](plan.md) | HOW — constitution check, approach, change surface, contracts, test strategy, docs, rollout, risks, assumptions |
| [tasks.md](tasks.md) | Fifteen tasks, one commit each, all ticked, with the gate results |

The templates they were copied from: [`skeleton/specs/_templates/`](../../../skeleton/specs/_templates/spec.md).
The process they follow: [`skeleton/specs/README.md`](../../../skeleton/specs/README.md).

**People** (all fictional): **Dana**, marketing lead — the requester. **Sam**, tech lead — the
developer working with the agent. A security lead, an accessibility lead, and marketing ops appear
by role.

---

## The request

The tracker task — [MKT-412](https://tracker.example.com/t/MKT-412), "Newsletter signup on article
pages" — says, in full:

> We need a newsletter signup form on every article page so we can grow our list. Copy needs to be
> editable in Contentful since we'll A/B test it. Submissions go to Mailchimp.

Three sentences, and a dozen decisions nobody has made yet.

---

## Step 0 — Triage

```
/triage https://tracker.example.com/t/MKT-412
```

The agent reads the task through the tracker's MCP server (reads need no confirmation), checks
`specs/`, `git log`, and open pull requests for prior work, and states its triage before creating
anything:

```
Triage — Newsletter signup on article pages (https://tracker.example.com/t/MKT-412)
- Deliverable: change — a signup form on article pages; copy from Contentful; subscribers to Mailchimp
- Kind: new feature — no spec folder mentions newsletters or MKT-412; no branch or open PR touches it
- Environment: not yet — the spec and the plan only read code; tests start with /implement
- Spec folder: new — specs/007-newsletter-signup/ (001–006 are taken). There is plenty to decide:
  failure behavior, rate limiting, personal data
- Open questions (for /write-spec's clarification round): 1) An address already on the list — its
  own message? 2) Mailchimp down — what does the reader see? 3) Contentful down — hide the form?
  4) A rate limit, and how strict?
- Next: /write-spec, then /write-plan
```

Triage is stated, not approved: the agent carries on, and Sam can redirect it. The session-start
hook had already reported that the checkout was on `main`, a protected branch, so `/write-spec`
starts by creating `feat/newsletter-signup` — the branch slug matches the folder slug, which is how
branch, folder, and pull request find each other.

---

## Step 1 — Spec

```
/write-spec newsletter signup on article pages — MKT-412
```

`/write-spec` classifies the feature, then asks questions from each role's perspective before it
drafts anything:

> **AI:** Classification first:
> - `feature-type: ui` — a form on article pages, so Accessibility is required.
> - `personal-data: yes` — it collects email addresses (and IP addresses, if we rate-limit), so
>   Privacy is required.
>
> Required: Business, Functional, Out of scope, Accessibility, Security, Privacy, Testing,
> Documentation, Clarifications. Optional sections that look relevant: Design, Deployment (new
> environment variables and a Contentful content type), and Constraints & prior decisions
> (ADR-0007 makes Mailchimp the system of record). I see no reason for Performance, SEO, Analytics,
> Localization, or Observability beyond the project defaults — tell me if you disagree.
>
> Questions, by perspective:
> 1. **Business** — what result would make this a success?
> 2. **Functional** — every article page, or some? Where on the page?
> 3. **Functional** — what counts as a valid address?
> 4. **Functional** — an address already on the list: its own message, or the normal one?
> 5. **Functional** — Contentful down when a page renders: hide the form, or fall back to built-in copy?
> 6. **Functional** — Mailchimp down on submit: what does the reader see?
> 7. **Design** — is there a mockup? Which existing pattern should it match?
> 8. **Accessibility** — anything beyond WCAG 2.1 AA?
> 9. **Security** — a rate limit on the endpoint? What value?
> 10. **Privacy** — single or double opt-in? Where does Mailchimp keep the data?
> 11. **Documentation** — who edits the Contentful entry, and do they need a guide?
> 12. **Deployment** — how fast must copy edits show up on the site?

Sam answered most of these directly, took four to Dana in a short call, and got the rate limit from
the security lead. Every answer went into **Clarifications** with its date and who gave it — the
record of *why* the spec says what it says.

Before handing the spec to planning, the skill checks the required sections:

> **AI:** Business ✓ · Functional ✓ (6 ACs, 5 edge cases) · Out of scope ✓ (6 items) ·
> Accessibility ✓ · Security ✓ · Privacy ✓ · Testing ✓ · Documentation ✓ (pre and post) ·
> Clarifications ✓ (10). Optional sections filled: Design, Constraints & prior decisions,
> Deployment. Constitution: no conflicts. Status stays `draft` — approval happens at the gate, once
> the plan exists.

The result is **[spec.md](spec.md)**. Things to notice:

- **WHAT and WHY only.** No file paths, components, or libraries. It says "the copy comes from the
  newsletter signup entry in Contentful", not how the entry is queried. The design lives in
  `plan.md`.
- **Each acceptance criterion is independently testable and numbered for life.** Contentful failing
  (AC5) and Mailchimp failing (AC6) are separate criteria because they are separate behaviors with
  separate tests. Tests and tasks cite these numbers; a later change request adds new numbers
  instead of renumbering.
- **Optional sections that don't apply are absent**, not filled with "Not applicable". An absent
  Performance section says "the project default applies"; a speculative one would claim thought
  that never happened.
- **Constraints & prior decisions holds one line**, because it is non-obvious and has a reason: no
  copy of subscribers on our side (ADR-0007).
- **The frontmatter links the tracker task instead of copying it**, and `approvals:` and
  `pull-requests:` start empty — they fill in at the gate and at delivery.

---

## Step 2 — Plan and tasks

```
/write-plan specs/007-newsletter-signup
```

`/write-plan` reads the constitution, `AGENTS.md`, the rules, and ADR-0007 and ADR-0009 — and then
**the code**, because the change surface comes from the code, not from the spec: the article route,
the shared Contentful and Redis clients, the contact form's endpoint (the closest existing pattern),
and the test setup in `tests/`. It writes two files:

- **[plan.md](plan.md)** — the design. The section that matters most is the **change surface**:
  every file the change creates or modifies, by layer, with the reason; the shared files and their
  other consumers (the article template renders about 1,300 pages); and what is deliberately **not**
  touched (the shared Contentful client, the contact form, `middleware.ts`). The **test strategy**
  maps every AC, edge case, and testable requirement to a named test. **Assumptions** are written
  down one by one, because an unstated assumption is how an invented requirement slips in.
- **[tasks.md](tasks.md)** — fifteen tasks in dependency order. Each implementation task names its
  test and the ACs it serves; each will be one red → green cycle and one commit.

---

## Step 3 — An independent check

For anything non-trivial, the plan gets a second, adversarial read before anyone is asked to
approve it. `@spec-analyzer` runs in its own context with read-only tools and assumes the plan is
convincing and incomplete:

```
@spec-analyzer specs/007-newsletter-signup

[critical] plan.md § Approach, § Change surface — The copy is fetched with `revalidate: 60`, but
  app/articles/[slug]/page.tsx:9 sets `export const revalidate = 300`. Next.js regenerates a static
  route at the shortest interval among its fetches, so all ~1,300 article pages would regenerate
  every minute instead of every five — five times the regenerations and the Contentful requests.
  The change surface lists the page only as "renders the section".
  Fix: fetch the copy with the route's 300 s window (the spec asks for "within 5 minutes") and list
  the page's revalidation under shared code.

[gap] plan.md § Change surface — lib/newsletter/mailchimp.ts will read MAILCHIMP_API_KEY and
  MAILCHIMP_LIST_ID, but .env.example is not in the table and no task declares them. spec.md
  § Deployment needs them on Preview too.
  Fix: add .env.example to the change surface and to T012.

[gap] spec.md § Privacy — "IP addresses in the rate-limit store for at most 60 seconds" has no
  test in plan.md § Test strategy.
  Fix: a rate-limit.test.ts test that asserts the expiry, on T011.

[question] plan.md § Test strategy maps a 429 to the error message in the form, but no AC, edge
  case, or clarification says what a rate-limited reader sees. Who decided?

[question] spec.md AC4 — the "already subscribed" message tells anyone whether an address is on
  the list. Clarifications record marketing's preference; is the security owner's acceptance
  recorded?

ACs: 6/6 mapped · testable requirements: 15/16 (Privacy expiry unmapped) · docs: 3/3
Verdict: NOT READY — 1 critical. Could not check: Vercel's environment settings; the Mailchimp
audience's opt-in mode.
```

The critical finding is the kind this check exists for. The draft plan was reasonable — a
60-second refresh so marketing sees edits quickly — and wrong about its blast radius: a one-line
choice in a new file would have changed the caching of every article on the site. Nothing in the
spec pointed at it; only reading the article route did.

The agent applied the critical fix and both gaps, and took the two questions to Sam. Dana decided
that rate-limited readers see the same error message; the security lead accepted the
enumeration trade-off, since the rate limit bounds lookups. Both answers went into Clarifications.
A second run of `@spec-analyzer` returned **READY FOR THE GATE**.

---

## Step 4 — The approval gate

This is the one approval in the workflow, and it comes after the plan on purpose: the part of a
convincing analysis that is most often wrong — which files and layers the change really touches —
is only known once the plan exists. The agent stops and shows:

> **AI:** Approval gate — `specs/007-newsletter-signup/`
>
> **Scope.** In: AC1–AC6 — the section on every article page with copy from Contentful, signup to
> Mailchimp, inline validation, the already-subscribed message, a hidden section when Contentful
> fails, a retry-able error when Mailchimp fails — plus the Security, Privacy, and Accessibility
> requirements. Out: double opt-in, a preferences page, topic preferences, backfills, per-article
> copy, analytics.
>
> **Change surface.** 7 new source files (three in `lib/newsletter/`, the Contentful loader, the
> endpoint, two components) and 2 changed shared files: `app/articles/[slug]/page.tsx`, which
> renders every article — its 300-second regeneration window stays as it is — and `.env.example`.
> Plus 8 test files, 3 fixture files, and 4 docs. Not touched: the shared Contentful client, the
> contact form and its spam check (same Redis, separate keys), `middleware.ts`.
>
> **Assumptions.** A1 — Vercel's `x-forwarded-for` is the reader's IP. A2 — the audience is single
> opt-in. A3 — marketing ops creates the content type in Contentful. A4 — marketing publishes the
> entry before we deploy. A5 — the article route keeps its 300-second window.
>
> **Risks.** The already-subscribed message reveals list membership (accepted by the security
> lead). A fixed window allows bursts of 20 across a boundary. Trusting `x-forwarded-for` holds
> only on Vercel.
>
> **Verification.** Every AC and requirement maps to a named test — unit, component, and end to
> end, including an axe scan. The VoiceOver pass is manual, on the preview.
>
> **Docs first.** The admin guide and the copy defaults for marketing. After the code: the runbook
> and a paragraph in `docs/ARCHITECTURE.md`.
>
> No implementation code until you approve. Reply with changes, or approve.

Sam read the change surface and the assumptions, and corrected two things:

> **Sam:** A4 is backwards. Marketing launches on campaign day, June 22, and wants to switch it on
> themselves. We deploy whenever it's ready; they publish the entry on the 22nd, and AC5 keeps the
> section hidden until then. Put that in the admin guide, so they know publishing is the switch.
> And drop the ARCHITECTURE.md paragraph — that doc covers cross-cutting structure, not single
> features. The runbook is enough.

> **AI:** Updated. `plan.md`: A4 rewritten and Rollout reordered — deploy first, Sam seeds the
> entry as a draft, marketing publishes on 2026-06-22. `spec.md`: Deployment and a new
> clarification. T001 gains "Turning the form on and off". T041 is the runbook only, and
> `docs/ARCHITECTURE.md` moved to "Not touched". Nothing else in the change surface changed.
> Approve?
>
> **Sam:** Approved.

Two corrections, two minutes. After the first commit, the same corrections would have meant
rewriting docs and redoing a deploy plan. On approval, the agent sets the status, records the
sign-off, ticks T000, and commits the folder — locally; nothing is pushed:

```yaml
status: approved
approvals:
  - "2026-06-09 · Sam (tech lead) · initial scope"
```

```bash
git add specs/007-newsletter-signup/spec.md specs/007-newsletter-signup/plan.md specs/007-newsletter-signup/tasks.md
git commit -m "spec: approve newsletter-signup scope and plan"
```

The `spec:` commit records intent **and** the approved change surface. Every later diff is reviewed
against it.

---

## Step 5 — Docs first

```
/write-docs specs/007-newsletter-signup
```

The plan lists two pre-implementable docs, so the skill writes them before any code exists. It reads
the documentation plan, the spec, and the planned tests — the precise statement of behavior every
claim must match — plus the existing guides in `docs/admin/`, to match their tone. An excerpt from
the admin guide, including the section the gate added:

```markdown
## Turning the form on and off

The newsletter section appears on article pages only while the **Newsletter Signup** entry is
published. Publish the entry to turn the form on; unpublish it to take the form down. Either way,
article pages change within 5 minutes — no deploy needed.

## What readers see when something goes wrong

- **The entry is unpublished, deleted, or missing a required field:** article pages show no
  newsletter section. Nothing else on the page changes.
- **Contentful can't be reached:** the same — no section; the article renders normally.
- **Mailchimp can't be reached, or a reader submits too many times in a minute:** the reader sees
  your **Error message** under the form, and what they typed stays in the field so they can try
  again.
```

Every sentence traces to an AC, an edge case, or a planned test. There are no screenshots — the UI
doesn't exist yet, and a fabricated one would be wrong the moment the build differs. T001 and T002
are ticked, and both docs land in one commit, as `/write-docs` does:

```bash
git commit -m "docs: add marketing docs for newsletter-signup"
```

---

## Step 6 — Implement, one task at a time

```
/implement specs/007-newsletter-signup
```

`/implement` refuses to start without the gate, and checks before writing a line:

> **AI:** Prerequisites: `status: approved` with an approvals line (2026-06-09) ✓ · folder
> committed ✓ · Phase 1 docs committed ✓ · environment: `pnpm install` done; the tests need no
> running services (Contentful and Mailchimp are mocked, Redis is faked). Baseline: `pnpm test` —
> 41 files, 212 tests passing; `pnpm test:e2e` — 3 files, 14 tests passing. No pre-existing
> failures. Starting T010.

Every task then runs the same loop: **write the task's test → run it and watch it fail for the right
reason → write the smallest code that passes → run it to green, with its neighbors → tick the task
→ commit test, code, and tick together.** Three tasks in detail:

### T010 — email validation: what counts as "red"

The test comes first:

```ts
// lib/newsletter/__tests__/validate-email.test.ts
import { describe, expect, it } from 'vitest';
import { validateEmail } from '../validate-email';

describe('validateEmail', () => {
  it('accepts and normalizes a valid address', () => {
    expect(validateEmail('  Reader@Example.com ')).toEqual({ ok: true, email: 'reader@example.com' });
  });

  it('rejects an empty or whitespace-only value as empty', () => {
    expect(validateEmail('')).toEqual({ ok: false, reason: 'empty' });
    expect(validateEmail('   ')).toEqual({ ok: false, reason: 'empty' });
  });

  it.each(['not-an-email', 'reader@', '@example.com', 'read er@example.com', 'reader@example'])(
    'rejects %s as invalid',
    (input) => {
      expect(validateEmail(input)).toEqual({ ok: false, reason: 'invalid' });
    },
  );

  it('rejects a non-string value as invalid', () => {
    expect(validateEmail(42)).toEqual({ ok: false, reason: 'invalid' });
  });

  it('rejects an address longer than 254 characters as invalid', () => {
    expect(validateEmail(`${'a'.repeat(245)}@example.com`)).toEqual({ ok: false, reason: 'invalid' });
  });
});
```

The first run fails — but not usefully:

```
$ pnpm vitest run lib/newsletter/__tests__/validate-email.test.ts
 FAIL  lib/newsletter/__tests__/validate-email.test.ts
Error: Failed to resolve import "../validate-email" from "lib/newsletter/__tests__/validate-email.test.ts". Does the file exist?
```

> **AI:** That isn't a red — no assertion ran, so it proves nothing about the behavior. Adding the
> function's signature with no validation behind it, so the assertions can run.

```ts
export type EmailCheck = { ok: true; email: string } | { ok: false; reason: 'empty' | 'invalid' };

export function validateEmail(input: unknown): EmailCheck {
  return { ok: true, email: String(input) };
}
```

```
 FAIL  lib/newsletter/__tests__/validate-email.test.ts > validateEmail > accepts and normalizes a valid address
AssertionError: expected { ok: true, …(1) } to deeply equal { ok: true, …(1) }

- Expected
+ Received

  {
-   "email": "reader@example.com",
+   "email": "  Reader@Example.com ",
    "ok": true,
  }

 FAIL  lib/newsletter/__tests__/validate-email.test.ts > validateEmail > rejects an empty or whitespace-only value as empty
AssertionError: expected { ok: true, email: '' } to deeply equal { ok: false, reason: 'empty' }
 …
      Tests  9 failed (9)
```

That is red for the right reason: every assertion fails because validation is missing — which is
exactly what T010 adds. Then the smallest code that passes:

```ts
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_LENGTH = 254;

export function validateEmail(input: unknown): EmailCheck {
  if (typeof input !== 'string') return { ok: false, reason: 'invalid' };
  const email = input.trim().toLowerCase();
  if (email === '') return { ok: false, reason: 'empty' };
  if (email.length > MAX_LENGTH || !EMAIL.test(email)) return { ok: false, reason: 'invalid' };
  return { ok: true, email };
}
```

```
 ✓ lib/newsletter/__tests__/validate-email.test.ts (9 tests) 4ms
      Tests  9 passed (9)
```

```bash
git add lib/newsletter/validate-email.ts lib/newsletter/__tests__/validate-email.test.ts specs/007-newsletter-signup/tasks.md
git commit -m "feat: add email validation for newsletter signups"
```

One task, one commit: the test, the code, and the ticked box in `tasks.md`.

### T022 — the endpoint's guards: a clean red

T021 built the endpoint's happy path. T022 adds the rate limit and the Mailchimp failure, starting
with two tests in the existing route test file:

```ts
it('returns 429 with Retry-After on the 11th request from one IP', async () => {
  for (let i = 0; i < 10; i++) await POST(signupRequest('reader@example.com', '203.0.113.7'));

  const response = await POST(signupRequest('reader@example.com', '203.0.113.7'));

  expect(response.status).toBe(429);
  expect(response.headers.get('Retry-After')).toBe('60');
});

it('returns 502 provider_unavailable and logs newsletter.subscribe.mailchimp_error when Mailchimp fails', async () => {
  vi.mocked(subscribe).mockRejectedValueOnce(new MailchimpUnavailableError(503));

  await expect(POST(signupRequest('reader@example.com'))).resolves.toMatchObject({ status: 502 });
  expect(logger.error).toHaveBeenCalledWith('newsletter.subscribe.mailchimp_error', { status: 503 });
});
```

```
 FAIL  app/api/newsletter/__tests__/route.test.ts > POST /api/newsletter > returns 429 with Retry-After on the 11th request from one IP
AssertionError: expected 200 to be 429 // Object.is equality

 FAIL  app/api/newsletter/__tests__/route.test.ts > POST /api/newsletter > returns 502 provider_unavailable and logs newsletter.subscribe.mailchimp_error when Mailchimp fails
AssertionError: promise rejected "MailchimpUnavailableError: Mailchimp responded 503" instead of resolving

      Tests  2 failed | 6 passed (8)
```

Both fail on the missing behavior — the endpoint answers the 11th request, and lets Mailchimp's
error escape — while T021's six tests stay green. The code:

```ts
export async function POST(request: Request) {
  // Trustworthy only because Vercel overwrites this header (plan.md A1); behind another proxy it can be spoofed.
  const ip = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
  const limit = await rateLimit(ip);
  if (!limit.ok) {
    logger.info('newsletter.subscribe.rate_limited');
    return NextResponse.json(
      { error: 'rate_limited' },
      { status: 429, headers: { 'Retry-After': String(limit.retryAfter) } },
    );
  }

  const check = validateEmail(await readEmail(request));
  if (!check.ok) {
    logger.info('newsletter.subscribe.invalid');
    return NextResponse.json({ error: 'invalid_email' }, { status: 400 });
  }

  try {
    const status = await subscribe(check.email);
    logger.info(status === 'subscribed' ? 'newsletter.subscribe.ok' : 'newsletter.subscribe.already_subscribed');
    return NextResponse.json({ status });
  } catch (error) {
    if (!(error instanceof MailchimpUnavailableError)) throw error;
    logger.error('newsletter.subscribe.mailchimp_error', { status: error.status });
    return NextResponse.json({ error: 'provider_unavailable' }, { status: 502 });
  }
}
```

The file's one comment states a security invariant the code can't express — the kind of comment
the comments rule keeps. Green, then the neighbors:

```
 ✓ app/api/newsletter/__tests__/route.test.ts (8 tests) 31ms
$ pnpm vitest run lib/newsletter app/api/newsletter
      Tests  24 passed (24)
```

```bash
git commit -m "feat: rate-limit the newsletter endpoint and handle provider failures"
```

### T024 — the form: a test that passes too early

T023 put the section on article pages, with the form's markup but no behavior. T024 adds the
behavior, starting with eight component tests. The accessibility requirements are tests too:

```tsx
it('shows an inline error, sends nothing, and moves focus to the field for an invalid email', async () => {
  const user = userEvent.setup();
  render(<NewsletterForm copy={copy} />);

  await user.type(screen.getByLabelText('Email address'), 'not-an-email');
  await user.click(screen.getByRole('button', { name: copy.ctaLabel }));

  expect(screen.getByRole('alert')).toHaveTextContent('Enter a valid email address.');
  expect(screen.getByLabelText('Email address')).toHaveFocus();
  expect(fetchSpy).not.toHaveBeenCalled();
});
```

```
 FAIL  components/__tests__/NewsletterForm.test.tsx > NewsletterForm > shows an inline error, sends nothing, and moves focus to the field for an invalid email
TestingLibraryElementError: Unable to find an accessible element with the role "alert"
 …
      Tests  7 failed | 1 passed (8)
```

One test passed before any T024 code existed, and the rule is to stop and find out why:

> **AI:** "labels the email field" passes already. T023 built the visible, associated label because
> AC1 requires it, so the behavior exists and the test isn't wrong. Keeping it as the guard for the
> accessibility requirement; the other seven fail for the right reason.

After the code: `Tests 8 passed (8)`, and the `jsx-a11y` lint rules stay clean. Commit:
`feat: add submit, error, and success states to the newsletter form`.

### The other tasks

- **T011** — the rate limiter, tested against the project's in-memory Redis fake with fake timers;
  the privacy test checks the 60-second expiry the analyzer asked for.
- **T012** — the Mailchimp client. When the agent wrote `lib/newsletter/mailchimp.ts`, the
  `check-env-declared` hook fired before `.env.example` had been updated:
  `lib/newsletter/mailchimp.ts reads MAILCHIMP_API_KEY MAILCHIMP_LIST_ID but .env.example does not
  declare it.` The task already planned the declaration; the hook makes sure it can't be forgotten.
- **T020** — the Contentful loader, with a test that pins the 300-second revalidation — the
  analyzer's critical finding, now guarded.
- **T023** — the only change to a shared file. Its end-to-end red was
  `expect(locator).toBeVisible() — Received: <element(s) not found>`: the article page didn't
  render the section yet.
- **T030** — the end-to-end acceptance tests, written after the stories, passed on their first
  run. That is expected — the behavior was built red-then-green in earlier tasks — but a test that
  never failed proves nothing, so, as with characterization tests, each was proven able to fail
  before the `test:` commit: against `main`'s build, eight of the nine failed; the ninth (AC5's,
  which expects no section) failed once its Contentful outage was switched off.

Every task's red and green line is in [tasks.md § Gate results](tasks.md#gate-results-2026-06-11).

---

## Step 7 — Reconcile the docs

The docs were written before the code to drive the thinking; now they are checked against what was
built (T040). Fourteen claims in the admin guide and the copy defaults, one at a time:

> **AI:** 13 of 14 hold. One doesn't: the guide says the section disappears if the entry is
> "missing a required field". All six fields are required in the content type, and Contentful won't
> publish an entry with an empty required field — so marketing can't reach that state by editing.
> The loader still guards against it (spec AC5), but the guide shouldn't describe a path editors
> can't take. Rewriting the bullet.

```diff
-- **The entry is unpublished, deleted, or missing a required field:** article pages show no
-  newsletter section. Nothing else on the page changes.
+- **The entry is unpublished or deleted:** article pages show no newsletter section. Nothing else
+  on the page changes.
+- **You clear a required field:** Contentful won't publish the change until the field is filled
+  in, so readers keep seeing the last published version.
```

```bash
git commit -m "docs: update newsletter admin guide for Contentful's required fields"
```

Reconciliation is routine, not a failure: docs written first are living documents. Then T041, the
post-implementable runbook, written from the built code — the real log event names, the real error
mapping, how to tell a Mailchimp outage from a rate-limit spike:
`docs: add newsletter runbook for operators`.

---

## Step 8 — Gate results

With every task ticked, the agent runs the full gate and records the evidence in `tasks.md` —
evidence, not claims (excerpt):

```markdown
**Full gate** (`pnpm verify`):
- `pnpm test` — 48 files, 251 tests passed (212 before, 39 new)
- `pnpm build` — succeeded; it would fail if a client component imported the Mailchimp client
- `pnpm test:e2e` — 4 files, 24 tests passed on Chromium (14 before, 10 new), including the axe scan

**Not run here, and why:**
- The VoiceOver pass — needs a person. It happens on the preview deployment, before the pull
  request is marked ready.
- A real Mailchimp signup and a real Contentful read — tests mock both, by rule. Both are checked on
  the preview, which needs `MAILCHIMP_API_KEY` and `MAILCHIMP_LIST_ID` set for Preview in Vercel —
  not visible from here.
```

In the same commit, `/implement` sets `status: implemented` in `spec.md`: every task is done, and
the status merges with the pull request, so the folder reads "as built" the moment the code lands.

```bash
git commit -m "docs: record newsletter-signup gate results"
```

---

## Step 9 — Review

```
/review specs/007-newsletter-signup
```

> **AI:** **Scope.** 26 files changed: the 23 in `plan.md`'s change surface, plus the spec folder.
> 14 commits for 15 tasks — T001 and T002 share the docs-first commit; every other task has its
> own. Tracker task linked.
>
> **Spec compliance.** AC1–AC6 implemented. Every Security, Privacy, and Accessibility requirement
> addressed. Nothing built beyond the spec.
>
> **Constitution.** No migrations, no new dependency, no silenced types, accessibility lint on. The
> endpoint is public, as spec § Security states.
>
> **Test evidence.** Every AC and testable requirement maps to a test. Gate results show red, then
> green, per task, with counts, and list what wasn't run and why.
>
> **Docs.** The admin guide matches the build after the reconciliation commit; the runbook's event
> names match `route.ts`.
>
> **Findings.**
> - **[nit]** `lib/newsletter/rate-limit.ts:14` — a fixed window lets one IP send up to 20 requests
>   across a window boundary. `plan.md` already lists it as an accepted risk; no change suggested.
> - **[nit]** `components/NewsletterForm.client.tsx:48` — the pending label "Subscribing" is written
>   twice, once as visible text and once as `aria-label`. One constant would do.
>
> **Verdict:** approve with nits. Not reviewed: the preview deployment, and visual fidelity to the
> Figma file.

Sam left both as they are — the first is a recorded decision, the second is style.

---

## Step 10 — Draft pull request

Nothing has left the machine yet. Delivery happens only when Sam asks:

```
/open-pr
```

The skill checks the branch and the evidence, verifies that the description matches the diff, and
shows the title and body before anything is sent:

```markdown
feat: add newsletter signup to article pages

## Traceability
**Spec:** `specs/007-newsletter-signup/`
**Tracker task:** https://tracker.example.com/t/MKT-412

## What changed and why
Marketing wants readers to subscribe from article pages, and to edit the form's copy without a
deploy. Every article page now renders a signup section below the body. Its copy comes from a new
`newsletterSignup` entry in Contentful; when the entry can't be loaded or isn't published, the
section isn't rendered — which is also how marketing turns it on (they publish on 2026-06-22).
Submissions go to a new same-origin endpoint, `POST /api/newsletter`, which allows 10 requests per
IP per minute (then 429 with `Retry-After`), validates the address, and adds it to the Mailchimp
audience. The Mailchimp key never leaves the server.

Every changed file is inside the change surface approved in `plan.md` on 2026-06-09. Deploy needs:
the content type in Contentful `master`, and the two Mailchimp variables in Vercel for Preview and
Production — order and rollback in `plan.md` § Rollout & deployment.

## How to verify
1. On the preview (it reads Contentful `sandbox`, which has a published entry), open any article:
   the section sits below the body.
2. Subscribe with a `+test` address you control; it appears in the Mailchimp audience.
3. Submit the same address again: the "already subscribed" message.
4. Submit `not-an-email`: an inline error, with focus on the field.
5. With VoiceOver: the inline error and the messages are announced.

**Tests:** 7 new Vitest files (39 tests) and `e2e/newsletter-signup.spec.ts` (10 tests), mapped AC
by AC in `plan.md` § Test strategy.

## Verified / not verified
- Verified: lint, typecheck, and build; Vitest 48 files / 251 tests; Playwright on Chromium, 24
  tests including the axe scan; every task went red, then green — `tasks.md` § Gate results.
- Not verified: the VoiceOver pass; a real Mailchimp signup and a real Contentful read (tests mock
  both); whether the Mailchimp variables are set for Preview and Production in Vercel; WebKit and
  Firefox (CI only).

## Screenshots
From the local Playwright run at 375 px and 1280 px: default, inline error, success.
```

Claude Code asks Sam to confirm the push and `gh pr create --draft` — outward actions sit behind
`permissions.ask`. The pull request opens as a **draft**: #142. The agent records it in `spec.md`
and commits locally — `spec: link newsletter-signup pull request`, which goes up with the next push
Sam asks for. It offers to post the PR link on MKT-412, showing the exact text; that's a write
Dana would see, so it waits for a yes (Sam preferred to post it by hand). It ends with what to QC before
the PR is marked ready: the Vercel variables, a real signup on the preview, and the VoiceOver pass.

**The human QC paid off.** On the preview the next morning, Sam's first test signup showed the
error message: the Mailchimp variables were set for Production only. Sam added them for Preview,
redeployed, and everything passed, VoiceOver included. That is the "not verified" list doing its
job — the agent said plainly what it couldn't see. Then:

> **Sam:** QC done. Push the link commit and mark it ready.

The agent ran `git push` and `gh pr ready 142`, each confirmed again at the prompt. An agent marks a
pull request ready only when a person who has exercised it asks. A teammate reviewed it, and it was
squash-merged on 2026-06-15.

---

## Step 11 — Close the loop

The task came from the tracker, so the requester hears back in their own terms:

```
/client-update MKT-412 142
```

The skill verifies each claim — the merged PR, production's article pages (no section yet, as
planned), the draft entry in Contentful `master` — and shows the full draft in chat:

> **For the team:** suggested reply for the tracker task [Newsletter signup on article pages](https://tracker.example.com/t/MKT-412).
>
> ---
>
> Hi Dana,
>
> Here's a quick update on the newsletter signup form.
>
> Readers will be able to subscribe at the end of every article: they enter their email address and
> go straight into your Mailchimp audience. Everything they read — the heading, the text, the button,
> and the three messages (thanks, already subscribed, something went wrong) — comes from the new
> Newsletter Signup entry in Contentful, so you can change it whenever you like.
>
> The form is live but switched off: it appears within five minutes of publishing that entry, and
> disappears if you unpublish it. The [entry](https://app.contentful.com/spaces/SPACE_ID/entries/ENTRY_ID)
> is ready as a draft with our suggested text, for the 22nd.
>
> We noticed one thing along the way:
>
> - **The "already subscribed" message tells anyone who types an address whether it's on your
>   list.** That's what you asked for, and our security lead is comfortable with it — let us know if
>   your privacy team would rather everyone saw the same message.
>
> 1 question for you:
>
> 1. **Launch:** will you publish the entry yourselves on the 22nd, or would you like us to do it at
>    a time you choose?
>
> Thanks!

No code, no branch names, no pull request links — pages and the CMS entry Dana will use. Sam asked
for it as a comment on the pull request (the default, for the team to relay), confirmed the
`gh pr comment` prompt, and pasted it into the tracker by hand.

---

## The history

```
$ git log --oneline main..feat/newsletter-signup
7c1e9b4 spec: link newsletter-signup pull request
4f0a2d6 docs: record newsletter-signup gate results                      T042 · status: implemented
b93e7a1 docs: add newsletter runbook for operators                       T041
e61f3c8 docs: update newsletter admin guide for Contentful's required fields   T040
2a8d4f0 test: add newsletter-signup acceptance tests                     T030
d07b5e2 feat: add submit, error, and success states to the newsletter form   T024
91c6a3f feat: show the newsletter section on article pages              T023
5e2f8b7 feat: rate-limit the newsletter endpoint and handle provider failures   T022
c3a9d14 feat: add the newsletter subscribe endpoint                      T021
8b4e0a5 feat: load newsletter copy from Contentful                       T020
f19d6c2 feat: add the Mailchimp client for newsletter signups            T012
6ad3b70 feat: add a per-IP rate limiter for newsletter signups           T011
0e7c5a9 feat: add email validation for newsletter signups                T010
a2f84d1 docs: add marketing docs for newsletter-signup                   T001, T002
3d9b6e8 spec: approve newsletter-signup scope and plan                   T000
```

Read from the bottom: the approved intent and change surface, how marketing will use the feature,
then one reviewable, revertible step per task — each backed by a test that once failed — then the
docs brought in line with reality and the evidence. Six months from now, someone wondering why the
copy takes five minutes to appear finds the answer in `plan.md`, and the reason the "already
subscribed" message exists in `spec.md` § Clarifications.

---

## What this example leaves out

- **Most of the code.** Only the parts that show the workflow; the rest is ordinary Next.js.
- **Real credentials, URLs, and IDs.** `<org>`, `SPACE_ID`, and `ENTRY_ID` are placeholders;
  `tracker.example.com` stands in for whichever tracker you use (ClickUp, Jira, Linear, GitHub
  Issues…).
- **A perfectly smooth session.** Real sessions have more back-and-forth than shown — but the
  stops are the same: triage stated, gate presented, red seen, evidence recorded.

## Try it yourself

Pick a feature of about this size in your own project — a dismissible site-wide banner driven by a
CMS entry, a "share this article" cluster, a health-check endpoint — and run it end to end once,
ideally with a teammate. Most of the time goes into reading and correcting the plan, not waiting
for code.

## Next: the change request

Three months later, marketing wants readers to pick topics, and privacy wants the "already
subscribed" message gone. That isn't a new feature — it amends this same folder as **CR 1**. See
[newsletter-topics](../newsletter-topics/README.md).
