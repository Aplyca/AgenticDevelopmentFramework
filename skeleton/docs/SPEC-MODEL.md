# Spec model

This project uses a **multi-perspective spec model**: every feature's `spec.md` captures input from
all relevant roles in one document, with required sections enforced before the spec can go to
planning. The spec lives in a **spec folder** (`specs/NNN-<slug>/`) next to the `plan.md` that says
how it will be built and the `tasks.md` that breaks the plan into commits — see `specs/README.md` for
the process.

| File | Answers | Written by |
|---|---|---|
| `spec.md` | WHAT and WHY — every role's requirements | `/write-spec` |
| `plan.md` | HOW — architecture, change surface, test strategy, documentation plan, assumptions | `/write-plan` |
| `tasks.md` | In what order, one commit at a time — each task names its test | `/write-plan` |

## Why this model

Most spec templates capture only what the business wants. Real features need input from multiple
roles — security, accessibility, design, deployment, documentation — and skipping any of them creates
the "we forgot about X" problem after launch:

- The form that shipped without bot protection because security wasn't asked.
- The page that's invisible to screen readers because accessibility wasn't asked.
- The deploy that broke because nobody documented the new environment variable.
- The feature nobody knows how to use because the docs were "later".

This model forces the conversation across all perspectives **before code is written**, while keeping
the spec readable and its diff useful.

## Structure of spec.md

Six parts. Sections are **required**, **conditional** (required when a frontmatter flag says so), or
**optional** (filled only when relevant).

### Part 1 — Intent (required)

| Section | Status | Owned by |
|---|---|---|
| Business | Required | Client / PM |
| Functional (user stories, numbered ACs, edge cases) | Required | Senior dev / tech lead |
| Out of scope | Required | Senior dev / tech lead |

### Part 2 — User experience

| Section | Status | Owned by |
|---|---|---|
| Design | Optional | Designer |
| Accessibility | Required if UI | A11y lead / designer |

### Part 3 — Non-functional requirements

| Section | Status | Owned by |
|---|---|---|
| Security | Required | Security lead / architect |
| Privacy | Required if `personal-data: yes` | Privacy / legal / tech lead |
| Performance | Optional | Tech lead |
| SEO | Optional | SEO / marketing |
| Analytics | Optional | Analytics lead / marketing |
| Localization | Optional | Localization lead / tech lead |

### Part 4 — Constraints

| Section | Status | Owned by |
|---|---|---|
| Constraints & prior decisions (business rules, compliance, ADRs and PDRs to respect, reasoned constraints on HOW) | Optional | Tech lead |

The design itself — architecture, integrations, diagrams, the files that change — is not part of the
spec. It lives in `plan.md`, and is approved together with the spec at the approval gate.

### Part 5 — Validation & delivery

| Section | Status | Owned by |
|---|---|---|
| Testing | Required | QA / tech lead |
| Documentation (pre- and post-implementable) | Required | Tech writer / dev |
| Observability | Optional | DevOps / SRE |
| Deployment | Optional | DevOps |

### Part 6 — Meta

| Section | Status | Owned by |
|---|---|---|
| Clarifications | Required | Whoever wrote the spec |
| References | Optional | Whoever wrote the spec |

### Change requests

When delivered work changes, the same `spec.md` gets a `CR N` section — intent plus a Delivered →
Change table — and new acceptance criteria tagged `(CR N)`. Retired criteria are struck through, not
deleted. The folder stays the single record of the feature, before and after.

## Mandatory enforcement

`/write-spec` **refuses to hand a spec to planning** while a required section is empty:

**Always required:** Business · Functional (at least one numbered AC) · Out of scope · Security ·
Testing · Documentation (both subsections) · Clarifications (may be an empty list, but it exists).

**Conditionally required:**
- **Accessibility** — when `feature-type` is `ui` or `mixed`. For `api`, `infra`, or `content`, mark `> Not applicable: [reason]`.
- **Privacy** — when `personal-data: yes`. Collecting an email address counts.

**Approval** happens later, at the gate in `/write-plan`, once the change surface is known: the
developer signs off on scope, change surface, and assumptions together, and `status` becomes
`approved` with an `approvals:` line.

## How to "fill" a section

1. **Concrete content** — requirements, mockup links, environment variables.
2. **Standard rules apply** — `> Standard project [area] applies (see .claude/rules/[file].md). No additional requirements.` Common for Security and Accessibility on routine features.
3. **Not applicable** — `> Not applicable: [one-line reason]`, only when the section truly doesn't apply.

All three count as filled. An empty section, or one holding only template text, blocks planning.

## How the AI uses each section

| Skill / agent | Reads |
|---|---|
| `/write-spec` | All sections — orchestrates filling them and enforces the required ones |
| `/write-plan` | All sections — turns them into the change surface, a test for every testable requirement, and doc tasks |
| `@spec-analyzer` | The whole folder — every AC → task → test, constitution conflicts, change-surface gaps, unstated assumptions |
| `/write-tests` | **Functional** ACs and edge cases, **Testing**, and testable criteria from **Security**, **Accessibility**, **Performance**, **Privacy**, **Analytics**, **Localization** |
| `/write-docs` | **Documentation → Pre-implementable**, via the plan's documentation plan; ACs and planned tests are the source of truth for every claim |
| `/implement` | All sections, through `tasks.md` — every task's code satisfies the requirements its ACs and sections carry |
| `/review` | All sections — checks each requirement was actually met, inside the approved change surface |

## The Documentation section: pre-implementable vs post-implementable

**Pre-implementable docs** (written via `/write-docs` before code):
- Admin and operator guides
- API contracts (OpenAPI, GraphQL schemas, public type signatures)
- End-user help and copy defaults (often seeded into a CMS)
- Public READMEs and SDK documentation

**Post-implementable docs** (backfilled after code — they need real output):
- Runbooks with real metrics, dashboards, and logs
- Tutorials with real screenshots
- Troubleshooting guides built from real failure modes

Both subsections must be filled or marked `Not applicable: [reason]`.

## Which sections get filled for common feature types

### Newsletter signup form (UI + form + third-party integration)

Filled: Business, Functional, Out of scope, Design, Accessibility, Security, Privacy, Constraints &
prior decisions (subscribers live only in the email provider), Testing, Documentation, Deployment,
Clarifications, References. Not filled: Performance (default applies), SEO (form not SEO-relevant),
Analytics (separate task), Localization (English only this iteration), Observability (default
applies).

### Health-check API endpoint (no UI, no personal data)

Filled: Business, Functional, Out of scope, Security ("Standard applies"), Accessibility ("Not
applicable: no UI"), Testing, Documentation, Observability, Clarifications.

### CMS content-model change (field rename, no UI change)

Filled: Business, Functional, Out of scope, Accessibility ("Not applicable: no UI change"), Security
("Standard applies"), Testing, Documentation, Deployment (schema change ordered before the code
deploy), Clarifications.

### Analytics tracking on existing pages (integration only)

Filled: Business, Functional, Out of scope, Security ("Standard applies"), Accessibility ("Not
applicable: no new UI"), Privacy (tracking implications), Analytics, Testing, Documentation,
Deployment (env vars), Clarifications.

## Owners and handoffs

The `owners:` map in the frontmatter records who is responsible for each filled section:
reviewers know who to ask, partial updates (only Security changed) go to the right person, and
clarification questions route themselves. Role labels by default (`client`, `senior-dev`,
`designer`, `tech-lead`, `qa`, `tech-writer`, `devops`, `security-lead`, `a11y-lead`, `privacy`);
replace them with names if your team prefers.

## Frontmatter reference

```yaml
---
title: ""
area: ""                       # e.g. "marketing", "auth", "checkout"
status: draft                  # draft → in-review → approved → implemented
feature-type: ui | api | infra | content | mixed
personal-data: yes | no        # collecting email/name/IP/etc. counts as yes
tracker: ""                    # link to the requirement — never a copy of it
approvals: []                  # "YYYY-MM-DD · <who> · initial scope" / "… · CR 1"
pull-requests: []              # "<url> · initial delivery" / "<url> · CR 1"
owners:
  business: client
  functional: senior-dev
  # one entry per filled section
references:
  figma: ""
  adrs: []
  pdrs: []
  related-specs: []
---
```

## When the model gets in the way

1. **Ceremony on changes with nothing to decide.** A typo, a version bump, or a one-line copy edit
   needs no spec folder at all (`specs/README.md` § When a change needs a spec folder). The test is
   "is there anything to decide?", not "is it big?".
2. **Speculative filling.** Writing Performance and Deployment "just in case" is worse than leaving
   them out. An absent optional section says "this didn't apply"; a guessed one says "we didn't
   really think about it" while looking like we did.

## Related

- `specs/README.md` — the process: when a folder is needed, the flow, the approval gate, change requests
- `specs/_templates/` — the files to copy (`spec.md`, `plan.md`, `tasks.md`)
- `docs/CONSTITUTION.md` — the gate every spec and plan is checked against
- `.claude/skills/write-spec/`, `write-plan/`, `implement/` — the playbooks
