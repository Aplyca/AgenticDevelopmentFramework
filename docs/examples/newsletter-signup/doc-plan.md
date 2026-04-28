# Doc plan — newsletter signup

> This is the AI's output during Phase 1 of `/write-docs`. The developer reviewed and approved this plan before any docs were written.

## Sources read

- Spec: `specs/newsletter-signup.md` (commit `a1b2c3d`) — Documentation section (Pre-implementable subsection has 2 entries)
- Tests: `e2e/newsletter-signup.spec.ts`, `app/api/newsletter/__tests__/route.test.ts`, `lib/newsletter/__tests__/validate-email.test.ts` (commit `d4e5f6g`) — committed, currently red
- Existing docs: `docs/admin/` has 3 prior admin guides (`articles.md`, `authors.md`, `seo.md`) — match their tone, structure, and length

The Pre-implementable subsection has 2 entries; the Post-implementable subsection has 2 entries (backfilled later, not this skill's job).

## Files to create

### `docs/admin/newsletter.md` (~250 lines)

Audience: marketing team / site administrator (non-technical, may be the same person editing Contentful daily).

Sections:
1. **Overview** — what the newsletter signup is, where it appears, who it's for
2. **Editing the form copy** — step-by-step Contentful instructions for the `newsletterSignup` entry, screenshot placeholders for each field
3. **Field reference** — table of fields, what each does, character limits, where it appears in the UI (sourced from spec ACs)
4. **A/B testing copy** — workflow for changing copy, how soon changes go live (~60 seconds per Technical section), how to revert
5. **What happens when** — graceful failures: what users see when Contentful is unreachable, what marketing sees in the Contentful UI when fields are missing
6. **Common tasks** — "I want to update the success message", "I want to test changes before they go live", etc.
7. **Troubleshooting** — symptoms, likely causes, who to escalate to. Kept short — the runbook covers operational issues (post-impl)
8. **Related** — link to spec, link to runbook (placeholder until runbook exists)

Sourced from:
- Spec ACs 1, 2, 4, 5 (form rendering, success path, already-subscribed, graceful CMS failure)
- Spec edge cases (Contentful entry missing required fields)
- Spec Technical section (revalidate: 60 — copy update latency)
- Tests: every claim about UI behavior is backed by the corresponding E2E test

### `docs/copy/newsletter-defaults.md` (~80 lines)

Audience: marketing (will copy these into Contentful as seed values for the `newsletterSignup` entry).

Sections:
1. **Purpose** — these are seed values, not fixed text. Marketing customizes in Contentful.
2. **Default copy** — exact text for title, body, ctaLabel, successMessage, alreadySubscribedMessage, errorMessage, with character counts and tone guidance (drafted in collaboration with the marketing copywriter)
3. **Tone notes** — match the existing site voice (friendly, concise, second-person)

Sourced from:
- Spec Functional ACs (which copy fields exist)
- Spec Privacy section (success message must not leak whether someone is on the list — wait, AC4 explicitly says we DO show "already subscribed", so the copy reflects that)
- Project glossary (`docs/GLOSSARY.md`) for consistent terminology

## Mocks / placeholders the docs will use

- Screenshot placeholders for the Contentful editor UI (e.g. `[Screenshot: Contentful entry editor for newsletterSignup]`) — the post-impl backfill will replace these with real screenshots once the schema is set up.
- No fabricated examples of UI behavior — every behavior reference points back to a test name.

## What's deliberately NOT in these docs

- **Code-level details** (where the `validateEmail` function lives, how the rate limiter works internally) → post-impl JSDoc + ARCHITECTURE.md paragraph.
- **Runbook content** (how to investigate a 429 spike, what Mailchimp dashboard to check) → post-impl runbook.
- **End-user troubleshooting** ("I signed up but didn't get an email") → out of scope per spec.
- **Public API documentation** → out of scope per spec.

## Coverage check

- Pre-implementable doc entries from spec: 2 / 2 covered
- Each claim sourced from a spec AC, edge case, or test: yes
- Existing doc patterns matched: yes (admin/ folder convention, tone, length range)

## Expected initial state after writing

- 2 new doc files committed.
- Tests still red (docs are written from the spec + tests, not from running code).
- Implementation has not yet started.
- `/implement` will read these docs as design context. Any divergence the implementation surfaces (renamed field, edge case discovered, UX adjustment) is reconciled deliberately during the implement phase — small fixes folded into the `feat:` commit, meaningful revisions in a separate `docs:` commit.
