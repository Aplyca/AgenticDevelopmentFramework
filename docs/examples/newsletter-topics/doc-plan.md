# Doc plan — newsletter topics modification

> This is the AI's output during Phase 1 of `/write-docs` for the topic-selection modification. The plan is scoped to the **spec diff**.

## Sources read

- Spec diff: `git diff HEAD~1 -- specs/newsletter-signup.md` — Documentation section gained one Pre-implementable entry (admin guide update for topic management).
- Tests diff: 7 new tests across 2 files.
- Existing docs:
  - `docs/admin/newsletter.md` — already exists from the original feature; this modification extends it.
  - `docs/copy/newsletter-defaults.md` — exists; no changes needed (no new copy fields, just topic checkboxes).

## Files to modify

### `docs/admin/newsletter.md` (modification — adds ~80 lines)

Add a new section: **Managing topics** (positioned after "Field reference"). Subsections:

1. **Overview** — what topics are, how readers see them, what marketing controls
2. **Adding a topic in Contentful** — step-by-step
3. **Setting the Mailchimp interest group ID** — where to find the ID in Mailchimp, how to enter it on the `newsletterTopic` entry
4. **Linking topics to the form** — adding entries to `availableTopics` on the `newsletterSignup` singleton
5. **What users see when** — no topics configured (selector omitted), one topic missing `mailchimpGroupId` (still shown in form, silently dropped at submit), submission with no topics selected (succeeds normally)
6. **Removing a topic** — what happens to existing subscribers in that interest group (Mailchimp keeps them — out of scope to remove), how to clean up if needed

The rest of the existing admin guide stays unchanged.

## Files NOT to create or change

- `docs/copy/newsletter-defaults.md` — no new copy fields; topic names are entered directly per topic, not as defaults.
- New doc files — the modification fits inside the existing admin guide; a separate file would fragment the admin's mental model of the feature.

## Mocks / placeholders

- Screenshot placeholders for the Contentful editor showing the new `newsletterTopic` content type and the `availableTopics` reference field on `newsletterSignup`.

## What's deliberately NOT in this update

- **Code-level details** about how `getTopics()` filters out topics with missing `mailchimpGroupId` → post-impl JSDoc.
- **Runbook updates** about verifying the topic-to-group mapping → post-impl backfill (listed in spec).
- **Per-topic success message variants** → out of scope per spec.

## Coverage check

- New Pre-implementable doc entries from spec diff: 1 / 1 covered
- Each claim sourced from a spec AC, edge case, or test: yes
- Existing doc patterns matched: yes (extends the existing admin guide)

## Expected initial state after writing

- 1 modified doc file committed (admin guide gains a "Managing topics" section).
- Tests still red (the new ones from the test commit).
- Implementation has not yet started.
- `/implement` will read the updated admin guide as additional context for the topic-management code path.
