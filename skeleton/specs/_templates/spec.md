---
title: ""
area: ""
status: draft                 # draft → in-review → approved → implemented (see specs/README.md § Status)
feature-type: ui | api | infra | content | mixed
personal-data: yes | no
tracker: ""                   # link to the business requirement (task, ticket, issue) — link it, never copy it
approvals: []                 # one line per sign-off at the approval gate: "YYYY-MM-DD · <who> · initial scope" / "… · CR 1"
pull-requests: []             # one line per PR: "<url> · initial delivery" / "<url> · CR 1"
owners:
  business: client
  functional: senior-dev
  # Add an entry per filled section. Examples below — keep only what applies.
  # design: designer
  # accessibility: a11y-lead
  # security: security-lead
  # testing: qa
  # documentation: tech-writer
  # deployment: devops
references:
  figma: ""
  adrs: []
  pdrs: []
  related-specs: []
---

# [Feature name]

<!--
  spec.md is the WHAT and WHY: requirements from every relevant role, in one document.
  The HOW lives in plan.md, the commit-sized breakdown in tasks.md (same folder).
  See docs/SPEC-MODEL.md for the model and specs/README.md for the process.

  Section status:
  - REQUIRED: must be filled before the approval gate. /write-spec refuses to hand a spec to
    planning while a required section is empty.
  - CONDITIONAL: required when `feature-type` or `personal-data` says so.
  - OPTIONAL: fill only when relevant — leave the heading out otherwise.

  Two other ways to fill a section, both count as filled:
  `> Standard project [area] applies (see .claude/rules/[file].md). No additional requirements.`
  `> Not applicable: [one-line reason]`

  Requirements come from the tracker task or the requester. If neither states them, stop and
  ask — never fill a gap with a plausible assumption.
-->

# Part 1 — Intent

## Business [REQUIRED]

> Owned by: client / PM
> What the requester wants and why. One paragraph plus success criteria.

[One paragraph: what the requester wants and why this matters to the business.]

**Success criteria** (business terms):

- [Measurable outcome — e.g. "10% of article readers subscribe within 30 days"]

## Functional [REQUIRED]

> Owned by: senior developer / tech lead
> What the feature does. User stories + numbered, testable acceptance criteria.

### User stories

- As a **[role]**, I want **[action]**, so that **[value]**.

### Acceptance criteria

Each AC is independently testable and keeps its number for life — `tasks.md` and the tests
reference these IDs. Change requests add new numbers and tag them `(CR N)`.

- **AC1** — [Concrete, observable behavior]
- **AC2** — [Concrete, observable behavior]

### Edge cases

Empty states, errors, missing data, boundary conditions.

- [Edge case]

## Out of scope [REQUIRED]

> What this spec intentionally does NOT cover — the single biggest scope-creep guard.

- [Adjacent behavior deliberately excluded, and why]

---

# Part 2 — User experience

## Design [OPTIONAL — fill if the feature has UI]

> Owned by: designer
> Mockups, variants and states, constraints beyond the design system.

- **Mockups:** [link]
- **UX patterns to follow:** [existing patterns this must match]
- **Variants / states:** [empty, loading, error, success]

## Accessibility [REQUIRED if feature-type is ui or mixed — otherwise mark Not applicable]

> Owned by: a11y lead / designer
> Default target is WCAG 2.1 AA — call out anything beyond it.

> Standard project accessibility applies (WCAG 2.1 AA — see `.claude/rules/ui-ux.md`). No additional requirements.

Or list specific, testable requirements:

- [e.g. Inline errors use `role="alert"` and move focus to the first invalid field]

---

# Part 3 — Non-functional requirements

## Security [REQUIRED]

> Owned by: security lead / architect
> Testable mitigations, or "standard applies". Authorization boundaries are never loosened to
> make data appear — broadening access is a security decision stated here.

> Standard project security applies (see `.claude/rules/security.md`). No additional requirements.

Or list specific, testable requirements:

- [e.g. Endpoint requires an authenticated session; unauthenticated requests get 401]
- [e.g. Rate limit: 10 requests/IP/minute; 429 with Retry-After]

## Privacy [REQUIRED if personal-data is yes — otherwise mark Not applicable]

> Owned by: privacy / legal / tech lead

- **Data collected:** [email, name, IP, device ID…]
- **Lawful basis:** [consent / contract / legitimate interest]
- **Storage:** [where, and for how long]
- **Transmission:** [third parties, regions]
- **User rights:** [access / correction / deletion path]
- **Consent:** [does the consent banner or policy change?]

## Performance [OPTIONAL — fill if non-default targets]

- [e.g. API p95 < 200 ms]

## SEO [OPTIONAL — fill for public-facing content]

- [e.g. Server-rendered with full content; canonical URL; editable meta title ≤ 60 chars]

## Analytics [OPTIONAL — fill if tracking is required]

- [e.g. Event `newsletter_signup_submit` with `topics_selected: string[]`]

## Localization [OPTIONAL — fill if multi-language]

- **Languages:** [e.g. en-US, es-MX]
- **Source of translations:** [CMS per locale, JSON files, TMS]

---

# Part 4 — Constraints

## Constraints & prior decisions [OPTIONAL — fill when the feature must respect something non-obvious]

> Owned by: tech lead
> Business rules, compliance, and existing decisions (link ADRs / PDRs) this feature must
> respect. A constraint on HOW belongs here only with its reason; the design itself lives in
> plan.md.

- [e.g. Contact data is written only through the existing audit-logged service — Reason: compliance requires the audit trail (ADR-0007)]

---

# Part 5 — Validation & delivery

## Testing [REQUIRED]

> Owned by: QA / tech lead
> What MUST be tested. plan.md maps every AC and testable requirement to a test; tasks.md
> names that test on the task that makes it pass.

### Mandatory test scope

- [e.g. Every AC has at least one test; every edge case has a test]

### Additional test types beyond ACs

- [e.g. Accessibility: automated axe scan + manual screen-reader pass]

### Out of test scope

- [e.g. Load testing deferred until traffic justifies it]

## Documentation [REQUIRED]

> Owned by: tech writer / dev
> Both subsections must be filled or marked Not applicable. plan.md turns them into doc tasks.

### Pre-implementable docs (written before code, via `/write-docs`)

Describe behavior that the spec and plan already define — they drive implementation thinking
and are reconciled deliberately when implementation reveals reality differs.

| Audience | What they need | Where it lives |
| --- | --- | --- |
| [Site administrator] | [How to edit the copy and topics in the CMS] | [`docs/admin/<feature>.md`] |
| [API consumer] | [Contract for the new endpoint] | [`openapi/<feature>.yaml`] |

Or: `> Not applicable: [reason]`

### Post-implementable docs (backfilled after code)

Need real running code, real metrics, or real failure modes.

| Audience | What they need | Where it lives |
| --- | --- | --- |
| [Operator] | [Runbook: investigating a spike in 429s] | [`docs/runbooks/<feature>.md`] |

Or: `> Not applicable: [reason]`

## Observability [OPTIONAL — fill if non-default monitoring]

- **Logs / metrics / alerts:** [what, beyond `.claude/rules/observability.md` defaults]

## Deployment [OPTIONAL — fill if non-default infra or configuration]

- **Environment variables:** [names only — declared in the env template]
- **Schema / content-model changes:** [migrations, CMS types — and their ordering]
- **Rollout:** [direct / flag / staged] · **Rollback:** [how]

---

# Part 6 — Meta

## Clarifications [REQUIRED — the section must exist even while empty]

> Questions raised while writing the spec, and how they were resolved. Answers are folded back
> into the sections above; this list preserves why.

- **Q:** [question] — **A:** [resolution] _(YYYY-MM-DD, who)_

## References

- [Related specs, ADRs, PDRs, designs, external docs]

<!--
  ─── Change requests ────────────────────────────────────────────────────────
  When delivered work changes (client feedback, a second round, a scope change), amend THIS
  folder instead of opening a new one. Append one section per request:

  # CR N — [short title] (YYYY-MM-DD)

  - **Requested:** [link to where it was asked — tracker comment, meeting notes] · by [who]
  - **Intent:** [what the requester is trying to achieve, in one or two sentences]

  | Aspect | Delivered (PR …) | Change |
  | --- | --- | --- |
  | [behavior] | [what shipped] | [what changes / none] |

  New or changed acceptance criteria go into Functional with new numbers, tagged `(CR N)`;
  a criterion the request retires is struck through, not deleted. Record the gate sign-off
  in `approvals:` and the PR in `pull-requests:`.

  A light change request — a precise adjustment the requester already decided, made in the
  fast or careful lane — is shorter, has no gate, and is committed with the change itself:

  # CR N — [short title] (YYYY-MM-DD) · light

  - **Requested:** [link] · by [who]

  | Aspect | Delivered (PR …) | Change |
  | --- | --- | --- |
  | [behavior] | [what shipped] | [what changes] |

  Plus any acceptance criterion it adds or changes, tagged `(CR N)`, in Functional.
-->
