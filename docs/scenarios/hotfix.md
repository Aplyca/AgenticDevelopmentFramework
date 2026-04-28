# Scenario: Hotfix

## When to use this

A bug is **actively affecting users in production right now** and the normal Feature Development workflow is too slow. Examples:
- Article pages are returning 500 because a Contentful field rename broke the renderer.
- Newsletter signups are silently dropping because a Mailchimp API change broke the integration.
- A deploy went out 20 minutes ago and the homepage is blank.

**Not this scenario:**
- A bug that's annoying but not breaking → use the full [Feature Development workflow](../ONBOARDING.md). Write a spec update, write a regression test, fix.
- A bug discovered during development → just fix it; you're already in a workflow.
- A "we should improve this" request from a stakeholder → that's a feature, not a hotfix.

The hotfix workflow trades the spec-first discipline for **speed**. The trade-off is only worth it when the cost of waiting (lost revenue, lost users, broken trust) exceeds the cost of working out of order. Use it sparingly — most "urgent" bugs aren't.

## Steps

### 1. Confirm it's actually a hotfix

Before bypassing the normal flow, sanity-check:

- Is the issue affecting users *right now*? (Not "could affect" — *is*.)
- Is rolling back to the previous deploy faster and safer than fixing forward? If yes, **roll back first**, then debug at leisure.
- Is the cost of waiting 1-2 hours for a normal spec → tests → docs → implement cycle worse than the cost of a less rigorous fix?

If you answered no to all three, you're not in a hotfix. Use the [Feature Development workflow](../ONBOARDING.md) instead.

### 2. Branch from main

```bash
git checkout main
git pull
git checkout -b hotfix/article-500-contentful-field-rename
```

> Always branch even for hotfixes. You want the fix reviewable and reversible, not a direct push to main.

### 3. Diagnose the root cause

```
/debug article pages returning 500. error in Vercel logs: "TypeError: Cannot read properties of undefined (reading 'fields')". started after deploy <sha>.
```

The `/debug` skill walks you through systematic root cause analysis — don't skip it even when you think you know the cause. The five extra minutes catches the case where the obvious fix is wrong.

In this example the AI traces it: a Contentful editor renamed the `body` field to `articleBody` in the model. The renderer at `app/articles/[slug]/page.tsx` still reads `entry.fields.body`, which is now undefined.

### 4. Write a regression test FIRST

Even under time pressure, the regression test comes before the fix. It's the cheapest way to ensure the same bug doesn't reappear in three weeks.

```
/write-tests add a regression test for the article renderer: when Contentful entry is missing the expected body field, the page should render an error state, not throw.
```

Snippet of what gets written:

```ts
// e2e/articles.spec.ts (addition)
test('renders an error state when Contentful entry is missing body', async ({ page }) => {
  // mock Contentful to return an entry without 'articleBody' / 'body' field
  await page.route('**/contentful/**', route =>
    route.fulfill({ json: { fields: { title: 'Test' /* no body */ } } }),
  );
  const response = await page.goto('/articles/test');
  expect(response?.status()).toBe(200);  // not 500
  await expect(page.getByText(/article unavailable/i)).toBeVisible();
});
```

Run it. It should fail (the bug still exists):

```bash
$ pnpm test:e2e -g 'missing body'
  ✘ renders an error state when Contentful entry is missing body
```

### 5. Fix the root cause

Now write the smallest possible change that makes the test pass. For this example:

```diff
 // app/articles/[slug]/page.tsx
 export default async function ArticlePage({ params }) {
   const entry = await getArticle(params.slug);
-  return <ArticleRenderer body={entry.fields.body} />;
+  const body = entry.fields.articleBody ?? entry.fields.body;
+  if (!body) return <ArticleUnavailable />;
+  return <ArticleRenderer body={body} />;
 }
```

Run the test:

```bash
$ pnpm test:e2e -g 'missing body'
  ✓ renders an error state when Contentful entry is missing body
```

Run the full suite to make sure you didn't break anything:

```bash
$ pnpm test:e2e
  ✓ ... (all pass)
```

### 6. Quick review

```
/review
```

The review may surface concerns ("you're masking the underlying field-rename problem instead of fixing the Contentful model"). For a hotfix that's often acceptable — note the concern, ship the fix, and address the deeper issue in the backfill spec (step 8).

### 7. Commit, push, deploy

```bash
git add -A
git commit -m "fix: handle Contentful body field rename gracefully

Article pages were 500ing because editors renamed the 'body' field to
'articleBody' in the Contentful model. Renderer now accepts either name
and shows an unavailable state when both are missing. Backfill spec to
follow."

git push -u origin hotfix/article-500-contentful-field-rename
gh pr create --title "Hotfix: article 500 from Contentful field rename" --body "..."
```

Get an expedited review (one teammate, look-once, ship). Merge and confirm Vercel auto-deploys.

### 8. Verify in production

Don't trust that the deploy worked — open the affected page, watch the logs for one minute, confirm the error rate drops. If you have a synthetic monitor for this, watch it recover.

### 9. Backfill the spec AND any user-facing docs

This is the step everyone skips. Don't.

```
/write-spec update specs/article-rendering.md to document the field-rename tolerance and unavailable state
```

If the fix changed any user-facing behavior that's documented (admin guides, API contracts, troubleshooting), update those docs too:

```
/write-docs article-rendering
```

Open a follow-up PR with the spec update and doc updates together. Mention the hotfix commit in the PR body. The point: future readers see the design intent and the current user-facing behavior, not just the patch.

If the underlying problem (editors renaming fields without coordinating with engineering) is recurring, this is also the time to open a separate issue or ADR for the systemic fix.

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Skipping the regression test "to save time" | Same bug returns in a month. Costs more total time. | Write the test first. It takes 5 minutes. |
| Pushing directly to main | No review, no rollback path beyond `git revert` | Always branch and PR, even for hotfixes |
| Committing the fix without explaining *why* in the message | Six months later nobody knows why the renderer reads two field names | Always explain the *why*; future-you depends on it |
| Skipping the backfill spec | Spec drifts from reality; next change to this area is built on a wrong mental model | Always backfill within the same week |
| Treating non-urgent bugs as hotfixes | Spec discipline erodes; "everything is urgent" becomes the norm | Be honest with yourself in step 1. Most bugs aren't hotfixes. |
| Hotfixing forward when rollback would work | Adds risk in a moment of stress | Always consider rollback first. Roll back, then fix forward calmly. |

## Example

**The page:** article pages started returning 500 around 14:30. Vercel logs show `TypeError: Cannot read properties of undefined (reading 'fields')` from `app/articles/[slug]/page.tsx:14`.

**Timeline:**

| Time | Action |
|---|---|
| 14:35 | On-call sees the alert, opens Vercel logs |
| 14:37 | Confirmed: started exactly at 14:28, every article page affected. Considered rollback — last deploy was at 13:50, no urgent commits since. Rollback would work but cost 30 minutes of legitimate content updates. |
| 14:40 | Branched `hotfix/article-500-contentful-field-rename`, ran `/debug`, traced to Contentful field rename |
| 14:45 | Wrote regression test, confirmed it fails on current code |
| 14:50 | Wrote the 3-line fix, regression test passes, full suite green |
| 14:55 | `/review`, opened PR, got teammate approval |
| 14:58 | Merged, Vercel deploy started |
| 15:02 | Deploy live, error rate dropping |
| 15:05 | Synthetic monitor green, incident closed |
| Next morning | Backfill spec PR opened: documents the field-rename tolerance, links to the hotfix commit, opens a separate ADR for "Contentful model change coordination process" |

Total: 30 minutes from alert to recovery, ~1 hour the next morning to backfill. The git history shows all of it.
