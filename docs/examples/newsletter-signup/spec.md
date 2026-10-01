---
title: "Newsletter signup on article pages"
area: "marketing"
status: implemented
feature-type: ui
personal-data: yes
tracker: "https://tracker.example.com/t/MKT-412"
approvals:
  - "2026-06-09 · Sam (tech lead) · initial scope"
pull-requests:
  - "https://github.com/<org>/marketing-site/pull/142 · initial delivery"
owners:
  business: client
  functional: tech-lead
  design: designer
  accessibility: a11y-lead
  security: security-lead
  privacy: privacy
  constraints: tech-lead
  testing: qa
  documentation: tech-writer
  deployment: devops
references:
  figma: "https://figma.com/file/[example]/newsletter-signup"
  adrs:
    - "ADR-0007 — Mailchimp is the email provider for the marketing list"
  pdrs: []
  related-specs: []
---

# Newsletter signup on article pages

# Part 1 — Intent

## Business [REQUIRED]

> Owned by: client (marketing)

Marketing wants readers to subscribe to the newsletter from the article they are reading, to grow
the list the Thursday digest goes to. They want to change the form's wording in Contentful
themselves — to A/B test headlines and calls to action without waiting for a deploy. Subscribers
go to Mailchimp, the team's email provider.

**Success criteria** (business terms):

- Within a quarter of launch, at least 2% of readers who reach the form subscribe.
- Marketing changes the form's copy in Contentful and sees it on the site within 5 minutes, with
  no deploy.

## Functional [REQUIRED]

> Owned by: tech lead

### User stories

- As a **reader**, I want to subscribe from the article I'm reading, so that I get more like it.
- As a **marketer**, I want to edit the form's copy in Contentful, so that I can test headlines and
  calls to action without a deploy.
- As an **operator**, I want the form to fail safely when Contentful or Mailchimp is down, so that
  an outage never breaks an article page.

### Acceptance criteria

Each AC is independently testable and keeps its number for life — `tasks.md` and the tests
reference these IDs. Change requests add new numbers and tag them `(CR N)`.

- **AC1** — Every article page shows a newsletter section below the article body, with a heading,
  body text, an email field with a visible label, and a submit button. The heading, body text, and
  button label come from the newsletter signup entry in Contentful.
- **AC2** — Submitting a valid email address adds it to the Mailchimp audience as a subscriber and
  replaces the form with the success message from the Contentful entry.
- **AC3** — Submitting an empty or malformed email address shows an inline error next to the field,
  sends nothing, and moves focus to the field.
- **AC4** — Submitting an address that is already on the list replaces the form with the "already
  subscribed" message from the Contentful entry, not the success message.
- **AC5** — When the newsletter entry can't be loaded — Contentful unreachable, the entry
  unpublished, or a required field empty — article pages render without the newsletter section and
  without an error.
- **AC6** — When Mailchimp fails or can't be reached, the form shows the error message from the
  Contentful entry, keeps the typed address, and lets the reader submit again.

### Edge cases

- Empty or whitespace-only address → inline error, nothing sent (AC3).
- Malformed address — no `@`, no domain, a space, more than 254 characters → inline error, nothing
  sent (AC3).
- Surrounding spaces or capital letters → trimmed and lowercased before the address is sent.
- Repeated clicks on the button → the button is disabled while a request is in flight; one request
  is sent.
- A reader over the rate limit → the error message from the entry, with the address kept (see
  Clarifications).

## Out of scope [REQUIRED]

- Double opt-in confirmation emails — the audience is single opt-in.
- A preferences or unsubscribe page — Mailchimp's links in every email cover it.
- Topic or interest preferences — email only this round.
- Backfilling subscribers from any earlier list.
- Per-article copy — an A/B test changes the copy on every article at once.
- Analytics events — the analytics platform is being chosen in a separate spec.

---

# Part 2 — User experience

## Design [OPTIONAL — fill if the feature has UI]

> Owned by: designer

- **Mockups:** the Figma file in `references.figma`.
- **UX patterns to follow:** the inline-callout pattern of the related-articles section — one
  column, full width on mobile, contained on desktop; the existing primary button; no new color
  tokens.
- **Variants / states:** default · pending (the button reads "Subscribing…" and is disabled) ·
  success (the message replaces the form) · already subscribed (the message replaces the form) ·
  error (the message appears under the form; the address is kept) · invalid (an inline error under
  the field).
- **Fixed text:** the field label ("Email address") and the inline error ("Enter a valid email
  address.") are not editable in Contentful.
- **Copy lengths:** heading ≤ 80 characters, body ≤ 200, button ≤ 30, each message ≤ 200 — what the
  mockup fits at 320 px.

## Accessibility [REQUIRED if feature-type is ui or mixed — otherwise mark Not applicable]

> Owned by: a11y lead

WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:

- The email field has a visible label associated with it in code — not a placeholder.
- The inline error is announced (`role="alert"`) and focus moves to the field.
- The messages that replace the form are announced (`role="status"`).
- While a request is in flight, the button keeps an accessible name ("Subscribing").
- Keyboard order is email field → button, with no traps.
- The field and the button are at least 44×44 px on a 375 px wide screen.

---

# Part 3 — Non-functional requirements

## Security [REQUIRED]

> Owned by: security lead

- The Mailchimp API key never reaches the browser; every call to Mailchimp is made on the server.
- The signup endpoint accepts at most 10 requests per IP address per minute; beyond that it answers
  429 with `Retry-After` set to the seconds left in the window.
- The endpoint validates the address itself; validation in the browser is feedback only.
- A request with no body, a non-string address, or an address over 254 characters gets a 400 and
  never reaches Mailchimp.
- Copy from Contentful is rendered as text, never as HTML.
- The endpoint is public by design — signing up needs no account.

## Privacy [REQUIRED if personal-data is yes — otherwise mark Not applicable]

> Owned by: privacy

- **Data collected:** email address; IP address, for rate limiting only.
- **Lawful basis:** consent — the reader submits the form.
- **Storage:** email addresses in Mailchimp (US region, covered by the existing data processing
  agreement); IP addresses in the rate-limit store for at most 60 seconds.
- **Transmission:** the address goes to Mailchimp over HTTPS; nothing else leaves our systems.
- **User rights:** the unsubscribe link in every newsletter (Mailchimp); access and deletion
  requests through the existing privacy process.
- **Consent:** no cookies or tracking are added, so the consent banner and the privacy policy don't
  change.

---

# Part 4 — Constraints

## Constraints & prior decisions [OPTIONAL — fill when the feature must respect something non-obvious]

> Owned by: tech lead

- Subscriber data lives only in Mailchimp — we keep no list of addresses of our own. Reason:
  Mailchimp is the system of record for the marketing list (ADR-0007), and the privacy review
  covers Mailchimp alone.

---

# Part 5 — Validation & delivery

## Testing [REQUIRED]

> Owned by: QA

### Mandatory test scope

- Every acceptance criterion and edge case has at least one automated test.
- Address validation has unit tests for a valid address and for each invalid form in the edge
  cases.
- The endpoint has a test for each outcome: subscribed, already subscribed, invalid input,
  rate-limited (429 with `Retry-After`), and Mailchimp failure (502).

### Additional test types beyond ACs

- Accessibility: an automated axe scan of an article page with the form rendered, and a manual
  VoiceOver pass on the preview before the pull request is marked ready.
- Security: crafted requests — no body, a non-string address, an oversized address — against the
  endpoint.

### Out of test scope

- Load testing — revisit if signups pass 1,000 a day.
- Mailchimp's own address checks and Contentful's field validation — vendor behavior.

## Documentation [REQUIRED]

> Owned by: tech writer

### Pre-implementable docs (written before code, via `/write-docs`)

| Audience | What they need | Where it lives |
| --- | --- | --- |
| Site administrator (marketing) | How to edit the newsletter entry in Contentful: each field, its limit, and where it appears; how fast edits go live; how to turn the form on and off; what readers see when something fails | `docs/admin/newsletter.md` |
| Marketing (copy) | Suggested text for the six fields — the starting values marketing edits in Contentful | `docs/copy/newsletter-defaults.md` |

### Post-implementable docs (backfilled after code)

| Audience | What they need | Where it lives |
| --- | --- | --- |
| Operator / on-call | Runbook: the signup log events, telling a Mailchimp outage from a rate-limit spike, checking Mailchimp connectivity, what readers see when Contentful is down | `docs/runbooks/newsletter.md` |

## Deployment [OPTIONAL — fill if non-default infra or configuration]

> Owned by: devops

- **Environment variables:** `MAILCHIMP_API_KEY`, `MAILCHIMP_LIST_ID` — declared in the env
  template, and set in every Vercel environment, Preview included.
- **Schema / content-model changes:** a new Contentful content type, `newsletterSignup`, with six
  required text fields. It must exist in Contentful before the code deploys.
- **Rollout:** direct. The section appears when marketing publishes the newsletter entry, planned
  for campaign day, 2026-06-22; until then AC5 keeps it hidden. · **Rollback:** unpublish the entry
  (no deploy needed), or revert the deploy.

---

# Part 6 — Meta

## Clarifications [REQUIRED — the section must exist even while empty]

- **Q:** Every article page, or only some — and where on the page? — **A:** Every article page,
  below the article body and above related articles. _(2026-06-08, Dana)_
- **Q:** What counts as a valid address? — **A:** After trimming: not empty, one `@`, a dot in the
  domain, no spaces, at most 254 characters. Mailchimp does the strict check. _(2026-06-08, Dana and
  Sam)_
- **Q:** An address already on the list — its own message, or the normal success message? — **A:**
  Its own message: marketing prefers to tell people they're already subscribed. _(2026-06-08,
  Dana)_ The message reveals whether an address is on the list; the security lead accepted that,
  since the rate limit bounds lookups and nothing else is revealed. _(2026-06-09, security lead —
  raised by @spec-analyzer)_
- **Q:** What rate limit? — **A:** 10 requests per IP per minute, about ten times a fast human; 429
  with `Retry-After`. _(2026-06-08, security lead)_
- **Q:** Contentful down when a page renders — hide the form, or fall back to built-in copy? —
  **A:** Hide it. An article page must never fail because of the CMS, and there is no copy outside
  Contentful to fall back to. _(2026-06-08, Dana)_
- **Q:** Mailchimp down on submit — what does the reader see? — **A:** The error message from the
  entry, with the address kept; no automatic retry. _(2026-06-08, Dana)_
- **Q:** What does a reader over the rate limit see? — **A:** The same error message; no separate
  field. _(2026-06-09, Dana — raised by @spec-analyzer)_
- **Q:** Single or double opt-in? — **A:** Single opt-in; the audience is set up that way, and
  double opt-in is out of scope. _(2026-06-08, Dana)_
- **Q:** How fast must copy edits show up? — **A:** Within 5 minutes is fine. _(2026-06-08, Dana)_
- **Q:** Should the field label and the inline error be editable? — **A:** No — fixed text is fine.
  _(2026-06-08, Dana)_
- **Q:** When should readers first see the form? — **A:** On campaign day, 2026-06-22. The code can
  ship earlier; marketing publishes the entry that day. _(2026-06-09, Dana — relayed by Sam at the
  approval gate)_
- **Q:** Anything beyond WCAG 2.1 AA? — **A:** The six requirements under Accessibility; nothing
  else. _(2026-06-08, a11y lead)_

## References

- Tracker task: [MKT-412](https://tracker.example.com/t/MKT-412)
- ADR-0007 — Mailchimp is the email provider for the marketing list
- Figma: newsletter signup (`references.figma`)
- Mailchimp Marketing API reference — list members (vendor documentation)
