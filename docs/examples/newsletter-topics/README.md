# Worked example: Add topic selection to newsletter signup

This walkthrough shows the **modification** workflow on a feature that already exists. It's a direct sequel to the [newsletter-signup](../newsletter-signup/) example — same Next.js + Contentful + Vercel stack, same feature, but now we're changing it instead of building it.

**Goal:** subscribers should be able to optionally pick which topics they want to hear about. Marketing edits the topic list in Contentful; selections forward to Mailchimp interest groups so they can segment campaigns.

**Why this example:** the patterns for *modifying* a feature are different from the patterns for building one. The spec is already there. Most of the code is already there. Most of the tests are already there. The job is to change the *delta* surgically — and the workflow's job is to make that delta the only thing you touch.

Three things this example highlights that the original didn't:

1. **The spec is updated, not rewritten.** The git diff *is* the scope.
2. **Existing tests stay green.** Only new tests are added, only for new/changed behavior.
3. **Backwards compatibility is a first-class concern**, both at the data layer (existing entries that don't have the new field) and at the rollout layer (Contentful schema vs code deploy ordering).

---

## Starting state

Assume the [newsletter-signup](../newsletter-signup/) feature is shipped and has been in production for three months. The spec, tests, and implementation are committed:

```
* feat: add newsletter signup on article pages         (3 months ago)
* test: add newsletter signup tests
* spec: add newsletter signup form for article pages
```

7 ACs covered, 7 edge cases tested, 7 E2E + 4 unit tests all green.

## The change request

> *"Subscribers should be able to choose which topics they're interested in (Tech, Business, Culture, etc.). The topic list lives in Contentful — marketing manages it. Selections need to flow into Mailchimp so we can target campaigns by interest."*

Three implicit asks: a new Contentful content type for topics, a new field on the existing `newsletterSignup` entry to point to available topics, and a new mapping in our API route to Mailchimp's interest groups.

---

## Phase 1 — Update the spec

### What the developer typed

```
/write-spec update specs/newsletter-signup.md to add topic selection — multi-select pulled from Contentful, forwarded to Mailchimp interest groups
```

### What the AI did

The skill detects this is an update (not a new spec) and reads `specs/newsletter-signup.md` first. It then asked clarifications scoped to the change:

> **AI:** Reading the current spec. A few clarifications for the modification:
>
> 1. **Topic source** — a new Contentful content type `newsletterTopic`, with multiple entries, referenced from the `newsletterSignup` entry as a multi-reference field? Or a single multi-line text field on `newsletterSignup`?
> 2. **Selector behavior** — required (must pick at least one) or optional (can submit with none selected)?
> 3. **Default** — any topics pre-selected, or all unchecked by default?
> 4. **Backwards compat (data)** — what happens if the Contentful entry doesn't reference any topics yet? The form should keep working — does it omit the selector entirely?
> 5. **Backwards compat (subscribers)** — existing subscribers in Mailchimp don't have any interest groups set. Do nothing, or backfill them to a default group?
> 6. **Mailchimp mapping** — each `newsletterTopic` needs a Mailchimp `interestGroupId`. Where does that mapping live — on the Contentful entry, or in env vars?
> 7. **Selection in the success message** — does the success message vary by selected topics, or stay generic?

The developer answered (after a quick chat with marketing). Notable answers:

- Topics are a new content type with `mailchimpGroupId` as a field — no env var sprawl.
- Selection is **optional**. No default selections.
- If the Contentful entry has no `availableTopics` reference (or the reference is empty), the form renders without the selector. **Existing subscribers are not backfilled** — out of scope for this change.

These all become new entries under **Clarifications** — preserved as the audit trail of *why* the modified spec says what it says.

### The artifact

The diff applied to the original spec: **[spec-diff.md](spec-diff.md)** — and notice how *small* it is. Three ACs touched, three edge cases added, three Q&As added, two items added to out-of-scope. The vast majority of the original spec is unchanged.

> **The diff matters more than the final spec.** When `/write-tests` runs next, it will diff this commit to know exactly what's new.

### Approval and commit

```bash
git diff specs/newsletter-signup.md   # review carefully — verify nothing unrelated changed
git add specs/newsletter-signup.md
git commit -m "spec: add topic selection to newsletter signup

New: optional Contentful-managed topic multi-select on the form,
forwarded to Mailchimp interest groups. Existing subscribers are
intentionally not backfilled (out of scope)."
```

---

## Phase 2 — Tests (TDD red)

### What the developer typed

```
/write-tests newsletter-signup
```

### Phase 2a — Plan

The skill ran `git diff HEAD~1 -- specs/` to see what changed since the last spec commit, then presented a plan **scoped to the diff**.

Plan output: **[test-plan.md](test-plan.md)**.

Things to notice:

- Only **5 new tests** are proposed — covering 3 new/changed ACs and 3 new edge cases.
- The existing 11 tests for unchanged behavior stay as-is — no rewrites, no "while we're in there" cleanups.
- The plan explicitly lists which existing tests should *still pass* after the change (sanity check that we're not accidentally regressing).
- One test is a **negative test** for backwards compatibility: "form renders without topic selector when Contentful entry has no topics" — proves the modification is non-breaking for content that hasn't been updated yet.

The developer reviewed, asked one thing ("can we add an explicit test that the topic mapping survives a Contentful entry that's missing `mailchimpGroupId` on one topic?"), the AI added it, the developer approved.

### Phase 2b — Execute

After approval, the AI added the new tests to the existing files (didn't create new ones — the existing organization is fine):

```ts
// e2e/newsletter-signup.spec.ts (additions)
test.describe('Topic selection', () => {
  test('shows topic selector when topics are configured in Contentful', async ({ page }) => {
    // Contentful mock returns 3 topics
    await page.goto('/articles/example-article');
    const region = page.getByRole('region', { name: /newsletter/i });
    const topics = region.getByRole('group', { name: /interests|topics/i });
    await expect(topics).toBeVisible();
    await expect(topics.getByRole('checkbox')).toHaveCount(3);
  });

  test('omits topic selector when no topics are configured (backwards compat)', async ({ page }) => {
    // Contentful mock returns entry with empty availableTopics
    await page.goto('/articles/example-article');
    const region = page.getByRole('region', { name: /newsletter/i });
    await expect(region.getByRole('group', { name: /interests|topics/i })).toHaveCount(0);
    // form still works
    await region.getByLabel(/email/i).fill('reader@example.com');
    await region.getByRole('button', { name: /subscribe/i }).click();
    await expect(page.getByRole('status')).toHaveText(/thanks/i);
  });

  test('forwards selected topic IDs as Mailchimp interest groups', async ({ page, request }) => {
    // ...assert the request payload to Mailchimp includes the selected interest IDs
  });

  test('skips a topic with missing mailchimpGroupId and warns server-side', async ({ page }) => {
    // Contentful mock returns 3 topics, one missing mailchimpGroupId
    // assert the form still renders all 3, but submission only forwards the 2 valid ones
    // (Server logs a warning — checked separately)
  });

  test('submits successfully with no topics selected', async ({ page }) => {
    // covers AC: selection is optional
  });
});
```

The developer ran the suite:

```bash
$ pnpm test:e2e
  ✓ shows form with copy from Contentful           ← unchanged, still passes
  ✓ shows success message after valid submission   ← unchanged, still passes
  ✓ shows inline error for invalid email           ← unchanged, still passes
  ...
  ✘ shows topic selector when topics are configured           ← NEW, fails
  ✘ omits topic selector when no topics are configured        ← NEW, fails
  ✘ forwards selected topic IDs as Mailchimp interest groups  ← NEW, fails
  ✘ skips a topic with missing mailchimpGroupId               ← NEW, fails
  ✘ submits successfully with no topics selected              ← NEW, fails
  11 passed, 5 failed
```

> **Old tests still pass, new tests fail — exactly the right shape.** If an old test had failed here, the spec update would have accidentally changed unchanged behavior — and we'd go back to Phase 1.

### Commit

```bash
git add e2e/newsletter-signup.spec.ts
git commit -m "test: add topic selection tests (red — pending implementation)"
```

---

## Phase 3 — Docs (docs-first, modification)

### What the developer typed

```
/write-docs newsletter-signup
```

### Phase 3a — Plan

The skill checks the spec diff for new pre-implementable doc entries. The spec update added one entry (admin guide gains a "Managing topics" section), so the skill proceeds.

The AI:
1. Read the spec diff to see the Documentation section change.
2. Read the existing `docs/admin/newsletter.md` (the original feature's admin guide).
3. Read the new tests to understand exact behavior.
4. Presented a doc plan.

Plan output: **[doc-plan.md](doc-plan.md)**.

Things to notice (modification-specific):

- **One file modified, ~80 lines added.** Modest delta — only what the modification requires.
- **The plan extends the existing admin guide rather than creating a new file.** Admin's mental model of the feature stays in one place.
- **`docs/copy/newsletter-defaults.md` is NOT touched.** Topic names are entered directly per topic in Contentful, not as defaults — the existing copy doc still applies as-is.
- **Post-impl runbook update is called out but deferred.** Verifying topic-to-Mailchimp-group mappings needs the real implementation to write accurately.

The developer reviewed and approved.

### Phase 3b — Execute

The AI added the "Managing topics" section to `docs/admin/newsletter.md`. Excerpt:

```markdown
## Managing topics

Topics let subscribers indicate which subjects they want to hear about
when signing up. Selections forward to Mailchimp interest groups so
campaigns can be targeted by interest.

### Adding a topic in Contentful

1. Open Contentful → Content → Newsletter Topic → Add entry
2. Fill in:
   - **Name** — what readers see in the form (e.g. "Tech", "Business")
   - **Mailchimp Group ID** — see "Setting the Mailchimp interest group ID" below
3. Save and publish
4. Open the Newsletter Signup entry → add the new Newsletter Topic to the
   `availableTopics` field → save and publish

### What users see when

- **No topics configured** (the `availableTopics` field is empty): the
  topic selector is omitted from the form. Email-only signup works as
  before — this is the backwards-compatible path.

- **A topic is missing its Mailchimp Group ID**: the topic still appears
  in the form (so you notice the omission), but is silently dropped at
  submission. Users who selected only that topic will be subscribed
  without any interest group.

[...]
```

The developer committed:

```bash
git add docs/admin/newsletter.md
git commit -m "docs: add 'Managing topics' section to newsletter admin guide"
```

> **Why update docs as part of the modification?** The admin guide is the marketing team's source of truth. If the modification ships without updating it, marketing won't know how to use the new functionality. Docs-first guarantees the admin path is documented before the feature exists in production.

---

## Phase 4 — Implement

### What the developer typed

```
/implement newsletter-signup
```

### Phase 4a — Plan

The AI ran:

```bash
git diff HEAD~3 HEAD~2 -- specs/   # what changed in the spec
git diff HEAD~2 HEAD~1 -- e2e/      # what tests were added
git diff HEAD~1 HEAD -- docs/       # what doc updates landed
pnpm test:e2e                       # confirm 5 red, 11 green
```

Then read the updated admin guide and the existing implementation files to understand the current patterns and the new documented behaviors. Then presented a plan.

Plan output: **[implementation-plan.md](implementation-plan.md)**.

Things to notice:

- **2 new files, 3 modified files, 2 files explicitly NOT touched.** The plan calls out unmodified files by name — that's the agent's commitment that it's not going to drift into them.
- File modifications are described as *deltas*, not full file content. ("Add `topics?: TopicId[]` to the request body schema and forward to Mailchimp via `interests` field.")
- The Contentful schema change is treated as a separate prerequisite — the plan calls out "this code assumes the `newsletterTopic` content type and `availableTopics` field exist in Contentful" and recommends doing the schema change in Contentful first.
- A specific risk is flagged: **rollout ordering**. If the code ships before the Contentful schema change, the form renders without topics (graceful — backwards-compat AC covers it). If the schema ships before code, marketing can configure topics that nothing reads yet (also fine). Both orderings are safe — but the plan documents this explicitly so the developer doesn't have to think it through under pressure.
- Plan also commits to honoring the new admin-guide section: e.g., the doc claims "topics with missing `mailchimpGroupId` still appear in the form but are silently dropped at submit" — the implementation must match this exactly.

### Phase 4b — Execute

The AI worked through the plan. Excerpts:

```ts
// lib/contentful/topics.ts (NEW)
export type Topic = { id: string; name: string; mailchimpGroupId: string };

export async function getTopics(topicRefs: ContentfulRef[]): Promise<Topic[]> {
  if (!topicRefs?.length) return [];
  const entries = await getClient().getEntries<TopicFields>({
    'sys.id[in]': topicRefs.map(r => r.sys.id).join(','),
    content_type: 'newsletterTopic',
  });
  return entries.items
    .filter(t => t.fields.mailchimpGroupId)  // skip topics with missing mapping
    .map(t => ({
      id: t.sys.id,
      name: t.fields.name,
      mailchimpGroupId: t.fields.mailchimpGroupId,
    }));
}
```

```ts
// lib/contentful/newsletter.ts (MODIFIED — additive)
export type NewsletterCopy = {
  title: string;
  body: string;
  ctaLabel: string;
  successMessage: string;
  alreadySubscribedMessage: string;
  errorMessage: string;
  topics: Topic[];   // ← new field, defaults to [] when absent
};

export async function getNewsletterCopy(): Promise<NewsletterCopy | null> {
  // ... existing fetch logic unchanged
  return {
    title: entry.fields.title,
    // ... existing fields unchanged
    topics: await getTopics(entry.fields.availableTopics ?? []),  // ← only addition
  };
}
```

```tsx
// components/NewsletterForm.client.tsx (MODIFIED)
// Adds an optional <fieldset role="group"> when copy.topics is non-empty.
// Submit handler includes selectedTopics in the POST body.
// Existing email-only flow unchanged when topics is empty.
```

```ts
// app/api/newsletter/route.ts (MODIFIED)
// Body schema now accepts optional `topics: string[]` (Mailchimp interest IDs).
// Forwarded to Mailchimp as the `interests` map.
// All other behavior (validation, rate limit, error handling) unchanged.
```

After each task the AI reran tests. Final state:

```bash
$ pnpm test:e2e
  ✓ shows form with copy from Contentful
  ✓ shows success message after valid submission
  ✓ shows inline error for invalid email
  ...
  ✓ shows topic selector when topics are configured
  ✓ omits topic selector when no topics are configured
  ✓ forwards selected topic IDs as Mailchimp interest groups
  ✓ skips a topic with missing mailchimpGroupId
  ✓ submits successfully with no topics selected
  16 passed
```

> All 16 green — the original 11 plus the 5 new ones. No regressions, no scope creep, no drift into untouched files.

---

## Phase 5 — Review

### What the developer typed

```
/review
```

Sample findings:

> **`@code-reviewer`:** the `getTopics` filter that skips topics with missing `mailchimpGroupId` is silent — the user sees the topic in the form (because it's loaded via the entry references), but it's silently dropped server-side at submit. That's the *opposite* of the test's expectation. Look again — actually no, the test asserts the topic is rendered but only valid IDs are forwarded. Confirmed correct, but worth a code comment explaining the asymmetry so the next reader doesn't "fix" it.
>
> **`@security-reviewer`:** topic IDs from the form go straight into the Mailchimp `interests` map. Currently no validation that the IDs come from the configured topics — a determined client could submit arbitrary group IDs. Mailchimp will reject unknown ones, but it's worth validating server-side to keep the contract tight. Suggest fix: API route fetches the configured topics and intersects with submitted IDs.
>
> **`@ux-reviewer`:** the `<fieldset>` group has a `role="group"` and an `aria-labelledby` — good. The optional nature is conveyed in the label text ("Topics (optional)"). Looks fine.

The developer accepted the security finding, added a 5-line server-side intersection, added one more test for it, and re-ran the suite. Ignored the cosmetic comment suggestion (the asymmetry is captured in the test name; a comment would be redundant).

---

## Phase 6 — Commit

```
/commit
```

```bash
git commit -m "feat: add optional topic selection to newsletter signup

Subscribers can now pick topics from a Contentful-managed list; selections
forward to Mailchimp interest groups for campaign segmentation. Form is
backwards-compatible: when the Contentful entry has no availableTopics,
the selector is omitted and the form behaves as before. Existing
subscribers are unaffected (no backfill — out of scope per spec)."
```

---

## What the git history looks like at the end

```
* feat: add optional topic selection to newsletter signup           ← THIS CHANGE
* docs: add 'Managing topics' section to newsletter admin guide
* test: add topic selection tests (red — pending implementation)
* spec: add topic selection to newsletter signup
* feat: add newsletter signup on article pages                      ← original feature
* docs: add admin guide and end-user copy defaults
* test: add newsletter signup tests
* spec: add newsletter signup form for article pages
```

Two clean three-commit groups. Six months from now when marketing wants to *remove* topics or change how they're rendered, the next developer reads the second spec diff to understand exactly what was added and why — separate from the original design.

---

## What this example deliberately leaves out

- **The Contentful schema change itself.** That's editor work, not engineering work. The spec assumes it's done. In practice the developer would (a) make the schema change in a Contentful environment first, (b) verify locally against that environment, (c) ship the code, (d) promote the schema to production.
- **A backfill script for existing subscribers.** Explicitly out of scope. If marketing wants existing subscribers in default groups, that's a separate one-off task with its own spec.
- **Migration of the `successMessage` field to be topic-aware.** Explicitly out of scope. Generic message stays.

---

## Compare to the original

| | Original (newsletter-signup) | This (newsletter-topics) |
|---|---|---|
| Workflow | New feature | Modification |
| Spec | Net-new, all sections filled | Diff against existing, 3 ACs touched + Documentation section gains 1 entry |
| Tests | ~22 net-new | 7 added, ~22 unchanged |
| Docs | 2 net-new doc files | 1 doc file modified (admin guide gains a section) |
| Files | 7 new, 1 modified | 2 new, 3 modified, 2 explicitly untouched |
| Backwards compat | Not applicable | Central concern (data + rollout) |
| Rollout coordination | Not relevant | Called out in plan (Contentful schema vs code) |

The point: the same skills (`/write-spec`, `/write-tests`, `/write-docs`, `/implement`, `/review`, `/commit`), the same plan-then-execute discipline, but the *scope-finding* mechanism — the spec diff, test diff, and doc diff — is what keeps a modification from accidentally becoming a rewrite.
