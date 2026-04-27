---
title: ""
area: ""
status: draft | review | approved | implemented
feature-type: ui | api | infra | content | mixed
personal-data: yes | no
owners:
  business: client
  functional: senior-dev
  # Add an entry per filled section. Examples below — keep only what applies.
  # design: designer
  # accessibility: a11y-lead
  # security: security-lead
  # technical: tech-lead
  # testing: qa
  # documentation: tech-writer
  # deployment: devops
references:
  figma: ""
  adrs: []
  rfcs: []
  related-specs: []
---

<!--
  This template captures input from MULTIPLE roles in one document so every
  feature has a complete picture before code starts. See docs/SPEC-MODEL.md
  for the full explanation.

  ## Section status

  - REQUIRED: must be filled before status can flip to `approved`. The skill
    refuses to approve specs with empty required sections.
  - CONDITIONAL: required when `feature-type` or `personal-data` indicates so.
  - OPTIONAL: fill only when relevant to this feature.

  For sections you've considered and intentionally skipped, write:
  `> Not applicable: [one-line reason]` — the skill counts this as filled.

  For sections where standard project rules apply with no additional requirements:
  `> Standard project [area] applies (see .claude/rules/[file].md). No additional
  requirements.` — also counts as filled.
-->

# Part 1 — Intent

## Business [REQUIRED]

> Owned by: client / PM
> What the requester wants and why. Keep it brief — one paragraph plus success criteria.

[One paragraph: what the requester wants and why this matters to the business.]

**Success criteria** (what does success look like, in business terms):

- [Measurable outcome — e.g. "10% of article readers convert to subscribers within 30 days"]

## Functional [REQUIRED]

> Owned by: senior developer / tech lead
> What the feature does. User stories + testable acceptance criteria.

### User stories

- As a **[role]**, I want **[action]**, so that **[value]**.

### Acceptance criteria

Concrete, testable behaviors. Each AC must be independently testable.

1. [AC1]
2. [AC2]
3. [AC3]

### Edge cases

Empty states, errors, missing data, boundary conditions.

- [Edge case 1]

## Out of scope [REQUIRED]

> What this spec intentionally does NOT cover. Single biggest scope-creep prevention — never skip.

- [Adjacent feature deliberately excluded]

---

# Part 2 — User experience

## Design [OPTIONAL — fill if feature has UI]

> Owned by: designer / expert developer
> Visual / layout / brand decisions. Link to mockups, list any constraints not covered by the design system.

- **Mockups:** [Figma link]
- **Brand constraints:** [Anything beyond the design system tokens]
- **UX patterns to follow:** [Existing patterns in the project this should match]
- **Variants / states:** [empty, loading, error, success, etc.]

## Accessibility [REQUIRED if feature has UI — otherwise mark Not applicable]

> Owned by: a11y lead / designer
> Accessibility requirements. Default project target is WCAG 2.1 AA — call out anything beyond.

[Default: "Standard project accessibility applies (WCAG 2.1 AA — see `.claude/rules/ui-ux.md`). No additional requirements."]

Or list specific requirements:

- [e.g. Form inputs have programmatic labels and error messages use `role="alert"`]
- [e.g. Component must work with screen readers (tested with VoiceOver + NVDA)]
- [e.g. Touch targets ≥44×44px]

---

# Part 3 — Non-functional requirements

## Security [REQUIRED]

> Owned by: security lead / architect
> Security requirements. If standard rules cover it, say so. Otherwise list concrete, testable mitigations.

[Default: "Standard project security applies (see `.claude/rules/security.md`). No additional requirements."]

Or list specific requirements (each one should be testable):

- [e.g. Form is protected by reCAPTCHA v3; submissions with score <0.5 are rejected]
- [e.g. API endpoint requires authenticated session; unauthenticated requests return 401]
- [e.g. User input is sanitized before rendering — no `dangerouslySetInnerHTML` paths]
- [e.g. Rate limit: 10 req/IP/min, 429 response with Retry-After header]

## Privacy [REQUIRED if `personal-data: yes` — otherwise mark Not applicable]

> Owned by: privacy / legal / tech lead
> How personal data is collected, stored, transmitted. Compliance requirements (GDPR, CCPA, etc.).

- **Data collected:** [What personal data — email, name, IP, device ID, etc.]
- **Lawful basis:** [Consent / contract / legitimate interest / etc.]
- **Storage:** [Where and for how long]
- **Transmission:** [Where it's sent — third parties, regions]
- **User rights:** [How users access / correct / delete their data]
- **Cookie / tracking consent:** [Whether this requires consent banner update]

## Performance [OPTIONAL — fill if non-default SLA]

> Owned by: tech lead
> Specific performance targets when defaults don't apply. Defaults live in `.claude/rules/performance.md`.

- [e.g. Page LCP <2.5s on 4G mobile]
- [e.g. API endpoint p95 <200ms]
- [e.g. Component bundle size <15kb gzipped]

## SEO [OPTIONAL — fill for public-facing content]

> Owned by: SEO / marketing
> Search-engine visibility requirements.

- [e.g. Page must render server-side with full content for crawlers]
- [e.g. Structured data: `Article` schema with author, datePublished, headline]
- [e.g. Canonical URL points to the localized version]
- [e.g. Meta title ≤60 chars, meta description ≤160 chars, both editable in CMS]

## Analytics [OPTIONAL — fill if tracking required]

> Owned by: analytics lead / marketing
> What events are tracked, what properties are sent.

- [e.g. Event `newsletter_signup_view` fires when section enters viewport]
- [e.g. Event `newsletter_signup_submit` fires on submit, properties: `topics_selected: string[]`, `article_slug: string`]

## Localization [OPTIONAL — fill if multi-language]

> Owned by: localization lead / tech lead
> Languages, regions, and locale-specific behavior.

- **Languages supported:** [e.g. en-US, es-MX]
- **Source of translations:** [e.g. Contentful per-locale, JSON files, third-party TMS]
- **Locale-specific content:** [Anything that varies beyond translation — currency, date formats, regional copy variants]

---

# Part 4 — Technical

## Technical [OPTIONAL — fill if non-default architecture, integrations, or implementation constraints]

> Owned by: architect / tech lead
> Significant technical decisions specific to this feature. Standard architectural patterns live in `.claude/rules/architecture.md`.

### Architecture & integrations

- [e.g. Form submissions go to Mailchimp via server-side Route Handler — never expose API key to browser]
- [e.g. Uses Vercel KV for rate-limit storage]
- [e.g. Depends on the existing `lib/contentful/client.ts` shared client]

### Implementation constraints (sparingly used)

> Use only when there's a real reason to constrain HOW (not WHAT). Each constraint must include reasoning.

- [e.g. Must use the framework's built-in form-builder helper — Reason: standardizes validation across the site, used by 4 other forms]

### ADRs

- [Link any ADRs created or referenced for this feature — e.g. `ADR-0007: Choosing Mailchimp over SendGrid`]

---

# Part 5 — Validation & delivery

## Testing [REQUIRED]

> Owned by: QA / tech lead
> What MUST be tested. The `/write-tests` skill derives tests from this section AND the Functional ACs AND any testable criteria in Security, Accessibility, Performance.

### Mandatory test scope

- [e.g. Every functional AC has at least one E2E test]
- [e.g. Every edge case has at least one test]
- [e.g. Form validation has unit tests for valid + invalid inputs]
- [e.g. Rate-limit behavior has a route test asserting 429 + Retry-After]

### Additional test types beyond ACs

- [e.g. Accessibility: automated axe scan in E2E + manual screen-reader pass]
- [e.g. Performance: Lighthouse CI score ≥90 on the affected page]
- [e.g. Security: penetration test for the Route Handler before production]
- [e.g. Visual regression: Chromatic snapshot for the new component]

### Out of test scope

- [What's intentionally not tested in this iteration — e.g. "load testing >10k req/sec deferred until traffic justifies it"]

## Documentation [REQUIRED]

> Owned by: tech writer / dev
> What documentation must be produced and for whom.

### Audience and artifact

| Audience | What they need | Where it lives |
|---|---|---|
| End user | [e.g. Inline help text on the form explaining what they're subscribing to] | [In-product copy, sourced from Contentful] |
| Site administrator | [e.g. How to edit the newsletter copy and topics in Contentful] | [`docs/admin/newsletter.md`] |
| Developer | [e.g. How the rate-limit module works, how to swap ESPs] | [Inline JSDoc + `docs/ARCHITECTURE.md` update] |

### Out of documentation scope

- [e.g. No public API docs needed — internal feature only]

## Observability [OPTIONAL — fill if non-default monitoring]

> Owned by: DevOps / SRE
> Logging, metrics, alerts, dashboards specific to this feature. Defaults live in `.claude/rules/observability.md`.

- **Logs:** [Structured logs at INFO for normal events, ERROR for failures, what fields to include]
- **Metrics:** [Counters / histograms — e.g. `newsletter_signup_submissions_total{result}`]
- **Alerts:** [Pageable conditions — e.g. submission failure rate >5% over 5 min]
- **Dashboards:** [Existing or new dashboard to update]

## Deployment [OPTIONAL — fill if non-default infra/env]

> Owned by: DevOps
> What ships with this feature beyond code.

- **Environment variables:** [e.g. `MAILCHIMP_API_KEY`, `RECAPTCHA_SECRET` — values stored in [vault/secrets manager]]
- **Infrastructure changes:** [e.g. Provision a Vercel KV instance, add Mailchimp webhook target]
- **Database / schema changes:** [Migrations, Contentful content type additions, etc.]
- **Rollout strategy:** [Direct deploy / feature flag / canary / staged rollout]
- **Rollback plan:** [What to do if it goes wrong — env var to flip, flag to disable, revert SHA]
- **Coordination:** [Anything that needs to ship in a specific order — e.g. Contentful schema before code]

---

# Part 6 — Meta

## Clarifications [REQUIRED — even if empty initially, this section must exist]

> Q&A from spec writing. Resolves ambiguities and preserves them as context for testing and implementation.

- **Q:** [question raised during spec writing]
  **A:** [resolution]

## References

- [Related specs, ADRs, RFCs, Figma files, external docs]
