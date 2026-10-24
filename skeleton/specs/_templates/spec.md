---
title: ""
area: ""
status: draft                 # draft → in-review → approved → implemented (see specs/README.md § Status)
feature-type: ui | api | infra | content | mixed
personal-data: yes | no
tracker: ""                   # link to the business requirement (task, ticket, issue) — link it, never copy or quote it
approvals: []                 # one line per sign-off at the approval gate: "YYYY-MM-DD · <role> · initial scope" / "… · CR 1" — a role (developer, tech lead), never a name
pull-requests: []             # one line per PR: "<url> · initial delivery" / "<url> · CR 1" (a CR on the open PR adds to its line: "· initial delivery, CR 1")
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
  related-specs: []           # a feature split across folders: the consumer names its provider's folder, the provider its consumers
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

  Decisions are dated and attributed to a role — requester, developer, tech lead, legal — never
  to a person's name, and written in your own words: no quotes or text copied from the tracker,
  no "the requester said…". The `tracker:` link is where people's words live; git history
  holds who committed what (specs/README.md § Records name roles).
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
> plan.md. A feature split across spec folders writes its shared contract here, in both
> folders (specs/README.md § Granularity).

- [e.g. Contact data is written only through the existing audit-logged service — Reason: compliance requires the audit trail (ADR-0007)]
- [e.g. Shared contract with `specs/012-topic-catalog/` (provider): `GET /api/topics?state=active|archived` returns `{ id, label }`; a change to it is recorded in this spec and its pull request — Reason: the feature is split across both folders]

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

### End-user docs [OPTIONAL — with the end-user-docs module]

How the people who use the product do what this feature lets them do — written in the doc tool they
read (`docs/END-USER-DOCS.md`), never in the repository, via `/end-user-docs`: drafted before code,
published once the feature ships. Only for a feature that changes what end users see or do.

| End users | What they need | Page in the end-user doc |
| --- | --- | --- |
| [Site visitors] | [How to subscribe to the newsletter and confirm it] | [User guide › Newsletter › Subscribe (new page)] |

Or: `> Not applicable: [reason — e.g. nothing end users see or do changes]`

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
> into the sections above; this list preserves why. Each answer in your own words, attributed
> to the role that decided it — never a name, never a quote from the tracker.

- **Q:** [question] — **A:** [resolution] _(YYYY-MM-DD, [role — requester, tech lead, legal…])_

## References

- [Related specs, ADRs, PDRs, designs, external docs]

<!--
  ─── Change requests ────────────────────────────────────────────────────────
  When delivered work changes (client feedback, a second round, a scope change) — or feedback
  arrives while its pull request is still open — amend THIS folder instead of opening a new one.
  Append one section per request:

  # CR N — [short title] (YYYY-MM-DD)

  - **Requested:** [link to where it was asked — tracker comment, meeting notes] · by [role — requester, tech lead…]
  - **Intent:** [what the requester is trying to achieve, in one or two sentences, in your words]

  | Aspect | Delivered (PR …) | Change |
  | --- | --- | --- |
  | [behavior] | [what shipped — or, on an open PR, what the branch built] | [what changes / none] |

  New or changed acceptance criteria go into Functional with new numbers, tagged `(CR N)`;
  a criterion the request retires is struck through, not deleted. Record the gate sign-off
  in `approvals:` and the PR in `pull-requests:`.

  A light change request — a precise adjustment the requester already decided, made in the
  fast or careful lane — is shorter, has no gate, and is committed with the change itself:

  # CR N — [short title] (YYYY-MM-DD) · light

  - **Requested:** [link] · by [role]

  | Aspect | Delivered (PR …) | Change |
  | --- | --- | --- |
  | [behavior] | [what shipped] | [what changes] |

  Plus any acceptance criterion it adds or changes, tagged `(CR N)`, in Functional.

  Before the merge, a change request rides the same branch and the same draft pull request;
  after it, a new branch and a new pull request (specs/README.md § Change requests).
-->
