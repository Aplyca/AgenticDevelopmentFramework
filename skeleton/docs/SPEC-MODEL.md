# Spec model

This project uses a **multi-perspective spec model**: every feature spec captures input from all relevant roles in one document, with required sections enforced by the AI before the spec can be approved.

## Why this model

Most "spec templates" capture only what the business wants. Real features need input from multiple roles — security, accessibility, design, deployment, documentation — and skipping any of them creates the "we forgot about X" problem after launch:

- The form that shipped without reCAPTCHA because security wasn't asked.
- The page that's invisible to screen readers because accessibility wasn't asked.
- The deploy that broke because nobody documented the new env var.
- The feature nobody knows how to use because the docs were "later".

This model forces the conversation across all role perspectives **before code is written**, while keeping the spec readable and the diff useful.

## Structure

A spec has six parts. Sections within each part are either **required**, **conditional** (required when a flag in the frontmatter says so), or **optional** (fill only when relevant).

### Part 1 — Intent (required)

| Section | Status | Owned by |
|---|---|---|
| Business | Required | Client / PM |
| Functional | Required | Senior dev / tech lead |
| Out of scope | Required | Senior dev / tech lead |

### Part 2 — User experience (required for UI features)

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

### Part 4 — Technical

| Section | Status | Owned by |
|---|---|---|
| Technical (architecture, integrations, implementation constraints) | Optional | Architect / tech lead |

### Part 5 — Validation & delivery (mostly required)

| Section | Status | Owned by |
|---|---|---|
| Testing | Required | QA / tech lead |
| Documentation | Required | Tech writer / dev |
| Observability | Optional | DevOps / SRE |
| Deployment | Optional | DevOps |

### Part 6 — Meta (required)

| Section | Status | Owned by |
|---|---|---|
| Clarifications | Required | Whoever wrote the spec |
| References | Required | Whoever wrote the spec |

## Mandatory enforcement

The `/write-spec` skill **refuses to mark a spec as approved** if any required section is empty. Specifically:

**Always required (every spec):**
- Business
- Functional (with at least one acceptance criterion)
- Out of scope
- Security
- Testing
- Documentation
- Clarifications (can be empty list, but section must exist)

**Conditionally required:**
- **Accessibility** — required when `feature-type` is `ui` or `mixed`. For `api`, `infra`, or `content`, mark `> Not applicable: [reason]`.
- **Privacy** — required when `personal-data: yes`. Note: collecting an email address counts as personal data.

**Optional sections:** filled only when relevant. Empty optional sections don't block approval.

## How to "fill" a section

Three valid ways:

1. **Concrete content.** List requirements, mockup links, env vars, etc.
2. **Standard rules apply.** Write `> Standard project [area] applies (see .claude/rules/[file].md). No additional requirements.` This is the right choice when defaults cover the feature — common for Security and Accessibility on routine features.
3. **Not applicable.** Write `> Not applicable: [one-line reason]`. Use only when the section truly doesn't apply (e.g., Accessibility for an API endpoint with no UI).

The skill counts all three as "filled". An empty section or a section with only the placeholder text is "empty" and blocks approval.

## How the AI uses each section

| Skill | Sections it reads |
|---|---|
| `/write-spec` | All sections — orchestrates filling them in, enforces mandatory |
| `/write-tests` | **Functional** ACs, **Edge cases**, **Testing** requirements, plus testable criteria from **Security**, **Accessibility**, **Performance** |
| `/write-docs` | **Documentation → Pre-implementable** subsection drives what gets written; **Functional** ACs and the committed tests are the source of truth for the docs' claims. Skips cleanly when Pre-implementable is empty / Not applicable. Has an update mode for substantial revisions surfaced during implementation. |
| `/implement` | All sections — plan must cover functional code, security mitigations, a11y implementation, observability hooks, deployment changes. Reads committed docs to drive thinking; when the chosen approach diverges from doc claims, reconciles docs deliberately (separate `docs:` commit or folded into `feat:`). Doc reconciliation is a normal sub-step, not an exception. |
| `/review` | All sections — multi-perspective review checks each section's requirements were actually met |

## Diagrams in specs

The Technical section supports an optional **Diagrams (Mermaid)** subsection. Use it when prose alone won't convey a non-trivial data flow, interaction sequence, or data model. Common diagram types: sequence diagrams (request/response flows), flowcharts (decision logic, state machines), ER diagrams (data model relationships), C4 component diagrams (high-level boundaries).

The spec template includes worked examples. Skip diagrams for simple CRUD or pure UI tweaks — they earn their place when the feature is genuinely complex.

## The Documentation section: pre-implementable vs post-implementable

The Documentation section splits into two subsections to support docs-first development:

**Pre-implementable docs** (written via `/write-docs` BEFORE code, become a contract):
- Admin / operator guides
- API contracts (OpenAPI, GraphQL schemas, type signatures of public surfaces)
- End-user help / microcopy defaults (often seeded into a CMS)
- Public-facing READMEs / SDK documentation
- Architecture sketches for non-trivial features

**Post-implementable docs** (backfilled after code, often need real running output):
- Code-level JSDoc / inline comments (come with the code)
- Runbooks with real metrics, dashboards, log examples
- Tutorials with screenshots / exact UI text
- Troubleshooting guides built from real failure modes

Both subsections must be filled or marked `Not applicable: [reason]`. An empty Pre-implementable subsection is the most common gap and blocks `/write-docs`.

## Example: which sections get filled for common feature types

### Newsletter signup form (UI + form + third-party integration)

Filled: Business, Functional, Out of scope, Design, Accessibility, Security, Privacy, Testing, Documentation, Deployment, Clarifications, References. Not filled: Performance (default applies), SEO (form not SEO-relevant), Analytics (separate ticket), Localization (English only this iteration), Observability (default applies).

### `/health` API endpoint (no UI, no personal data, simple infra)

Filled: Business, Functional, Out of scope, Security ("Standard applies"), Accessibility ("Not applicable: no UI"), Testing, Documentation, Observability, Clarifications. Not filled: Design, Privacy (no personal data), most others.

### CMS content model change (Contentful field rename, no UI change)

Filled: Business, Functional, Out of scope, Accessibility ("Not applicable: no UI change"), Security ("Standard applies"), Testing, Documentation, Deployment (coordinate schema change with code deploy), Clarifications. Not filled: Design, Privacy, etc.

### Adding analytics tracking to existing pages (no new UI, integration only)

Filled: Business, Functional, Out of scope, Security ("Standard applies"), Accessibility ("Not applicable: no new UI"), Privacy (tracking implications), Analytics, Testing, Documentation, Deployment (env vars), Clarifications. Not filled: Design, Performance, SEO, Localization, Observability.

## Owners and handoffs

The `owners:` map in the frontmatter records who's responsible for each filled section. This matters because:

- **Reviewers know who to ping** when a section needs changes.
- **Spec updates** can be partial — when only the Security section changes, only the security lead reviews the diff.
- **Clarification questions** route to the right person automatically.

Owner names are role labels by default (`client`, `senior-dev`, `designer`, `tech-lead`, `qa`, `tech-writer`, `devops`, `security-lead`, `a11y-lead`, `privacy`). Replace with team-member names if your team prefers.

## Frontmatter reference

```yaml
---
title: ""                      # short, descriptive
area: ""                       # e.g. "marketing", "auth", "checkout"
status: draft | review | approved | implemented
feature-type: ui | api | infra | content | mixed
personal-data: yes | no        # collecting email/name/IP/etc. counts as yes
owners:
  business: client
  functional: senior-dev
  # ...one entry per filled section
references:
  figma: ""
  adrs: []
  rfcs: []
  related-specs: []
---
```

## When the model gets in the way

Two failure modes to watch for:

1. **Bureaucracy on tiny features.** A 5-line copy change probably doesn't need 10 sections. For trivial changes, skip the spec entirely and use the [hotfix](./scenarios/hotfix.md) workflow with backfill — or use a single-AC spec with most optional sections empty.
2. **Speculative filling.** Tempting to write Performance and Deployment sections "just in case" — don't. Empty optional sections are a feature, not a bug. They tell the next reader "this didn't apply" rather than "we forgot to think about it" (the difference between empty and "Not applicable: [reason]" matters here).

The model is designed for routine engineering work where forgetting a perspective has real cost. For everything else, smaller is better.

## Related

- [Spec template](../specs/_template.md) — the actual file to copy
- [ADR template](./architecture/decisions/0000-template.md) — for technical decisions that span features
- [Worked example: newsletter-signup](../../docs/examples/newsletter-signup/) — full spec using this model
- Skill files: `.claude/skills/write-spec/SKILL.md`, `write-tests/SKILL.md`, `implement/SKILL.md`
