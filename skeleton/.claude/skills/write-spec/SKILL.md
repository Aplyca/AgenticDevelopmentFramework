---
name: write-spec
description: Write or update a feature specification using the multi-perspective spec model. Use when starting a new feature or changing existing behavior.
user_invocable: true
argument-hint: "[feature description]"
---

# Write Spec

Write a feature specification using the multi-perspective spec model (see `docs/SPEC-MODEL.md`). Specs capture input from all relevant roles in one document, with required sections enforced before approval.

## Steps

1. **Check existing specs** — Read `specs/` to find any specs that already cover this area. Don't duplicate — update the existing spec if one exists. For modifications, jump to step 8.

2. **Understand the request and classify the feature** — Ask clarifying questions if the description is ambiguous. Establish:
   - Who is the user? (which role or persona)
   - What problem does this solve?
   - What does success look like?
   - **`feature-type`**: is this `ui`, `api`, `infra`, `content`, or `mixed`?
   - **`personal-data`**: does the feature collect, store, or transmit personal data (email, name, IP, device ID, etc.)? Default to `yes` if unsure.

3. **Determine which sections apply** — Based on the classification, compute the required and optional sections:

   | Always required | Conditionally required | Common optional (ask) |
   |---|---|---|
   | Business, Functional, Out of scope, Security, Testing, Documentation, Clarifications | Accessibility (if `feature-type: ui` or `mixed`), Privacy (if `personal-data: yes`) | Design, Performance, SEO, Analytics, Localization, Technical, Observability, Deployment |

   For optional sections, ask the user which apply. Don't fill speculative sections — empty optional sections are a feature.

4. **Clarify ambiguities per section** — Before drafting, identify gaps. For each section that will be filled, ask the role-perspective questions that matter:
   - **Business**: who's the requester, what business outcome, what's the success metric?
   - **Functional**: what are the boundary conditions, error scenarios, user permissions, interactions with existing features?
   - **Design**: where are the mockups, what variants/states exist, brand constraints beyond the design system?
   - **Accessibility**: any requirements beyond WCAG 2.1 AA, screen-reader testing expected, keyboard-only flows?
   - **Security**: any auth, validation, rate-limiting, third-party trust, secret-handling beyond defaults?
   - **Privacy**: what data is collected, lawful basis, storage location/duration, third-party transmission, consent requirements?
   - **Performance**: SLAs that differ from project defaults?
   - **SEO**: server-render requirements, structured data, canonical URLs, meta?
   - **Analytics**: what events, what properties, what destination?
   - **Localization**: which languages/regions, where translations live?
   - **Technical**: significant architecture decisions, integrations, implementation constraints (sparingly)?
   - **Testing**: anything beyond "every AC has a test" — perf, security, visual regression, manual?
   - **Documentation**: split into pre-implementable (admin guides, API contracts, end-user copy defaults, SDK READMEs — written before code via `/write-docs`) and post-implementable (JSDoc, runbooks, troubleshooting — backfilled after code). Each subsection must be filled or marked Not applicable.
   - **Observability**: logs/metrics/alerts beyond defaults?
   - **Deployment**: env vars, infra changes, schema migrations, rollout strategy, rollback plan?

   Record all questions and answers in the spec's **Clarifications** section.

5. **Draft the spec** — Use the template at `specs/_template.md`. Fill the sections you determined apply. For each section:
   - **Required + content applies**: write the concrete requirements.
   - **Required + standard rules cover it**: write `> Standard project [area] applies (see .claude/rules/[file].md). No additional requirements.`
   - **Conditional + does not apply**: write `> Not applicable: [one-line reason]`.
   - **Optional + not relevant**: leave the section out entirely. Don't add the heading with empty content.

6. **Update frontmatter** — Set `feature-type`, `personal-data`, fill `owners:` for each filled section, populate `references:` with any Figma links, ADRs, related specs.

7. **Set status to `draft`** — Never auto-approve. Present to the user for review.

8. **For modifications** — When updating an existing spec:
   - Read the current spec to understand what's filled and what's not.
   - Identify which sections need updates based on the change. Most modifications touch only 1-3 sections.
   - Update only the affected sections. Do NOT rewrite unchanged sections.
   - Add new clarifications to the **Clarifications** section (don't replace existing Q&A).
   - Add any new ADRs/RFCs to **References**.
   - Update `owners:` if a different role now owns a section.
   - The git diff of this update will drive the test and implementation scope.

9. **Mandatory section enforcement (BEFORE approval)** — Before flipping status to `approved`, verify every required section is filled (concrete content, "Standard applies", or "Not applicable" — empty doesn't count):
   - [ ] Business has at least a paragraph and one success criterion
   - [ ] Functional has at least one acceptance criterion
   - [ ] Out of scope has at least one item OR explicitly says "nothing intentionally excluded for this iteration"
   - [ ] Security is filled
   - [ ] Testing is filled
   - [ ] Documentation is filled — BOTH the Pre-implementable and Post-implementable subsections must have content or `Not applicable: [reason]`. An empty Pre-implementable section is the most common gap and blocks `/write-docs`.
   - [ ] Clarifications section exists (may be empty list)
   - [ ] If `feature-type: ui` or `mixed` → Accessibility is filled
   - [ ] If `personal-data: yes` → Privacy is filled

   **If any required section is empty, refuse to mark approved.** Tell the user exactly which sections need filling and offer to walk through them.

10. **After approval** — Once all required sections are filled and the user approves, update the status to `approved`. Remind the user of the next steps:
    - Commit the spec (`spec:` prefix)
    - Run `/write-tests` (TDD) → commit (`test:` prefix)
    - Run `/write-docs` (docs-first) → commit (`docs:` prefix). Skips cleanly if no pre-implementable docs.
    - Run `/implement` → commit (`feat:` prefix)

    The spec's git diff scopes the tests, docs, and implementation that follow.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The requirements are clear enough, I'll skip clarification" | Ambiguities always exist. Uncovered gaps leak into tests and code as bugs. 5 minutes of questions saves hours of rework. |
| "I'll combine these into one acceptance criterion" | Each AC must be independently testable. Combined ACs hide untested behavior. |
| "Edge cases aren't needed for this simple feature" | Simple features break at edges. Empty states, missing data, and error scenarios are where real users encounter bugs. |
| "I'll add implementation details to help the developer" | Specs describe WHAT, not HOW. Implementation details belong in the Technical section under "Implementation constraints" — and only when there's a real reason to constrain HOW. |
| "Out of scope isn't needed" | Without explicit boundaries, implementation drifts. Out of scope prevents scope creep. |
| "I'll skip the Security section, it's a simple form" | Every spec gets a Security section. "Standard applies" is a valid answer; absent isn't. |
| "I'll mark Accessibility as Not applicable to skip it for this UI feature" | Not applicable requires a real reason. UI features always have a11y requirements (even if just "WCAG 2.1 AA default applies"). |
| "I'll fill Performance and Deployment optimistically in case we need them" | Speculative filling is worse than empty. Empty optional sections tell the next reader "this didn't apply" — better than "we guessed". |
| "I'll approve the spec myself since it looks complete" | Never auto-approve. The user approves. The skill verifies required sections are filled. |
| "The user said 'just write it', I'll fill in reasonable defaults" | "Reasonable defaults" without confirmation become bugs. Ask, don't assume. |

## Verification

Run this checklist before flipping status to `approved`:

- [ ] Every acceptance criterion is testable by an automated test
- [ ] Clarifications section records all ambiguity resolutions
- [ ] Edge cases cover: empty states, error states, boundary conditions
- [ ] Out of scope section explicitly excludes adjacent features
- [ ] All **always-required** sections are filled (not empty, not just placeholder text)
- [ ] **Conditionally required** sections (Accessibility for UI, Privacy for personal data) are filled or explicitly marked Not applicable with a reason
- [ ] Frontmatter `feature-type`, `personal-data`, and `owners` are set
- [ ] Status is `draft` (never auto-approve)

## Principles

- Business requirements only in the Business and Functional sections — no code, no file paths, no implementation details.
- Every acceptance criterion must be testable by an automated test.
- User-facing text must match the application's language (check `docs/GLOSSARY.md`).
- When in doubt, ask the user rather than assume.
- Empty optional sections are valid. Speculative filling is not.
- "Standard applies" and "Not applicable: [reason]" are first-class ways to fill a section.
- The required-section list is non-negotiable. Refuse to approve specs with empty required sections.
