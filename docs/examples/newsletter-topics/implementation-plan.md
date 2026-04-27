# Implementation plan — newsletter topics modification

> This is the AI's output during Phase 1 of `/implement` for the topic-selection modification. Scope is bounded by both diffs (spec + tests).

## Scope (from git diffs)

- **Spec diff** (`git diff HEAD~2 HEAD~1 -- specs/`): AC1a is new, AC2 has a new clause, 4 new edge cases.
- **Test diff** (`git diff HEAD~1 HEAD -- e2e/ app/api/`): 7 failing tests across 2 files.
- **Existing failing tests:** 7 (all the new ones). 18 existing tests are green and must stay green.

## Existing patterns observed

- `lib/contentful/article.ts` and `lib/contentful/newsletter.ts` use the same shared client (added in a prior refactor at `lib/contentful/client.ts`).
- The Mailchimp wrapper at `lib/newsletter/mailchimp.ts` exposes `subscribe(email, options?)`. The optional second argument is currently unused — this modification can extend it without breaking callers.
- The form component `components/NewsletterForm.client.tsx` uses controlled state for the email field; the same pattern works for checkbox state.
- Server-side validation lives in the Route Handler, not in the wrapper. New topic-ID validation belongs there.

## Architectural decisions

- **Topic-ID validation surface:** server-side, in the Route Handler. The form uses configured topic IDs (from the rendered options), so client-side validation would be cosmetic — but a crafted POST could submit arbitrary IDs. Intersect submitted IDs with the configured set and forward only the valid ones. (This intersection was added in response to the security review; tests cover it.)
- **Mailchimp interests payload shape:** `{ interests: { [groupId]: true } }` — Mailchimp's REST contract. Encapsulated inside `mailchimp.ts`; callers pass topic IDs as a flat array.
- **Contentful query for topics:** single batched query with `sys.id[in]=...` rather than N round trips. Same pattern used by the article-related-articles fetcher.
- **Type for `Topic`:** narrow type at the boundary (`{ id, name, mailchimpGroupId }`); skip topics with missing `mailchimpGroupId` at the boundary so downstream code never sees the partial shape.

## Task breakdown (dependency order)

```
- [ ] 1. Create `lib/contentful/topics.ts`
       New module. getTopics(refs) — batched query, filters out topics missing
       mailchimpGroupId, returns Topic[].
       [tests: indirectly covered by E2E + route tests]

- [ ] 2. Update `lib/contentful/newsletter.ts`
       Extend NewsletterCopy type with `topics: Topic[]`.
       In getNewsletterCopy(): call getTopics() with entry.fields.availableTopics ?? [].
       Default to [] when field is absent.
       [tests: e2e — 'shows topic selector', 'omits topic selector']

- [ ] 3. Update `lib/newsletter/mailchimp.ts`
       Extend subscribe(email, options?) — options now includes
       `interestGroupIds?: string[]`. Forward as `{ interests: { [id]: true } }` in
       the Mailchimp payload. No interest IDs → no interests field (preserves existing
       call sites' behavior exactly).
       [tests: route tests — 'forwards topic IDs', existing 'forwards valid email']

- [ ] 4. Update `app/api/newsletter/route.ts`
       Body schema: optional `topics?: string[]`.
       After email validation: load configured topic IDs (from Contentful, cached for
       the request via React's cache()), intersect with submitted IDs, pass valid IDs
       to mailchimp.subscribe().
       [tests: route tests — 'forwards topic IDs', 'drops submitted IDs not in configured set'
        + e2e 'forwards selected topic IDs', 'skips a topic with missing mailchimpGroupId']

- [ ] 5. Update `components/NewsletterForm.client.tsx`
       When `copy.topics?.length > 0`: render <fieldset role="group"> with a checkbox per
       topic. Owned local state `selectedTopicIds: Set<string>`. On submit, include
       Array.from(selectedTopicIds) in the POST body.
       When `copy.topics` is empty: render exactly as before (no fieldset).
       [tests: e2e — 'shows topic selector', 'omits topic selector', 'submits successfully
        with no topics selected']

- [ ] 6. (No change needed) `components/NewsletterSignup.tsx`
       Already passes the full copy object to NewsletterForm. Topics flow through
       automatically once getNewsletterCopy returns them.
       [tests: existing e2e tests still cover the wrapper behavior]
```

## Files NOT touched (explicit commitment)

- `lib/newsletter/validate-email.ts` — email validation unchanged.
- `lib/newsletter/rate-limit.ts` — rate-limiting unchanged.
- `app/articles/[slug]/page.tsx` — article page integration unchanged.
- `lib/contentful/client.ts` — shared Contentful client unchanged.
- `e2e/articles.spec.ts` — article tests unrelated, no change.
- All test files for unchanged ACs — no edits.

If anything in this list ends up modified, the implementation has drifted past the spec — stop and re-plan.

## Risks and trade-offs

- **Rollout ordering with Contentful schema.** Two cases:
  - Code ships first: form sees no `availableTopics` (backwards-compat AC kicks in), works as before. Safe.
  - Schema ships first: marketing can configure topics that the deployed code doesn't yet read. Visible only in Contentful, no user-facing change. Safe.
  - **Recommendation:** ship the Contentful schema in the editor environment first, verify locally against it, then ship the code, then promote the schema to production. Documented in the PR description.
- **Eventual consistency of topics fetch.** `getTopics` is called per-render of the article page. Cached at Next.js fetch level (revalidate: 60). Acceptable per the original spec's clarification on cache freshness.
- **Mailchimp interest groups must exist.** This implementation assumes the `mailchimpGroupId` on each `newsletterTopic` corresponds to a real Mailchimp interest group. If the ID is wrong, Mailchimp will reject the subscription. The graceful-degradation test (missing mailchimpGroupId) covers the *missing* case but not the *wrong* case. Documented as a follow-up in the spec's out-of-scope section if it becomes an issue.
- **No client-side validation of topic IDs.** Intentional — server is source of truth. Form options come from the same configured set, so a normal user can't submit an unknown ID. Only a crafted request can, and that's covered by the server-side intersection.

## Out of scope (preserved from spec diff)

- Backfilling existing Mailchimp subscribers.
- Per-topic success messages.
- "Select all" / "select none" convenience controls.
- Topic name localization.
- Auto-inferring topics from article context.

## Verification plan

After implementation:

- `pnpm test:unit` — validate-email tests still pass; route tests (existing 4 + new 2) all pass.
- `pnpm test:e2e` — original 7 + new 5 = 12 all pass.
- `pnpm tsc --noEmit` — no type errors. The `topics?` optional field cascades through; check no callers break.
- Manually: against a local Contentful environment with `newsletterTopic` schema added and 2 sample topics configured, visit an article page, see the topic selector, select one, submit a real test email, verify Mailchimp dashboard shows the subscriber in the correct interest group.
- Manually: against a local Contentful environment WITHOUT `newsletterTopic` schema (or with the field empty), visit an article page, confirm the selector is absent and the email-only flow still works.
