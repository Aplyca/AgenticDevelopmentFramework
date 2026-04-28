# Scenario: Refactor

## When to use this

You're restructuring code **without changing observable behavior**. Examples:
- Extracting a duplicated bit of Contentful-fetching logic into a shared helper.
- Splitting a 600-line server component into smaller composable pieces.
- Renaming `lib/utils.ts` (the dumping-ground module) into focused files.
- Replacing a hand-rolled rate-limit utility with a library now that the project has standardized on one.

**Not this scenario:**
- Adding a feature, even a tiny one → [Feature Development](../ONBOARDING.md) or [Modifying an existing feature](modifying-existing-feature.md). If the user can tell anything changed, it's not a refactor.
- Fixing a bug → if the behavior changes (even to "correct"), write a spec update and a test first.
- "While I'm refactoring let me also add this small feature" → **stop**. Two commits, two PRs, never combined.

## The defining rule

A refactor that requires changing tests is not a refactor — it's a behavior change. The test suite is the contract; if the contract has to change, the spec has to change first.

Exception: tests that asserted on internal structure (private function names, file paths) instead of behavior. Those tests are arguably broken — but treat updating them carefully and call it out in the commit message.

## Prerequisites

Before you start a refactor, **the area must have test coverage** for the behaviors you care about preserving. If it doesn't:

1. Stop the refactor.
2. Write characterization tests that describe the current behavior. Run them — they should pass.
3. Commit those tests with a `test:` prefix.
4. *Then* start the refactor.

This is annoying but non-negotiable. Refactoring untested code is just rewriting and hoping.

## Steps

### 1. Verify test coverage

```bash
pnpm test e2e/articles.spec.ts e2e/newsletter-signup.spec.ts
```

If the area you're refactoring isn't well covered, write tests first. See [Prerequisites](#prerequisites).

### 2. Run the refactor skill

```
/refactor extract Contentful client setup duplicated across lib/contentful/article.ts and lib/contentful/newsletter.ts into a shared lib/contentful/client.ts
```

The skill follows a plan-then-execute pattern:

1. Reads the affected files.
2. Identifies what's being extracted/moved/renamed.
3. Presents a plan: "I'll create `client.ts` with `getClient()`, replace 4 duplicate definitions across 4 files, no callers change."
4. Waits for approval.
5. Makes the changes.
6. Runs the tests.

### 3. Tests must stay green at every step

The refactor skill should run tests after each significant change. If they ever go red, **stop and revert that step** — something about the change altered behavior.

```bash
$ pnpm test
  ✓ ...all pass
```

If you have to run a smaller subset for speed during the refactor, that's fine — but run the full suite at the end before committing.

### 4. Skip the docs phase

A refactor that doesn't change observable behavior also doesn't change docs. `/write-docs` is **not** part of the refactor workflow. If you find yourself wanting to update an admin guide or API contract, that's a signal the refactor is actually changing behavior — go back to step 1, write a spec, and use the [Modifying an existing feature](modifying-existing-feature.md) workflow instead.

(Code-level docs like JSDoc may need updates if you renamed an exported symbol — those go in the same commit as the refactor.)

### 5. Run review

```
/review
```

Review on a refactor focuses on different things than a feature review:
- **Did we actually reduce duplication / clarify structure?** (the *point* of the refactor)
- **Are the new abstractions used in the way they were extracted to support?** (or are we one-shot abstracting?)
- **Did public APIs change?** (they shouldn't, in a pure refactor)

### 6. Commit

```bash
git add -A
git commit -m "refactor: extract shared Contentful client setup

Same getClient() pattern was repeated in article.ts and newsletter.ts;
each had subtly different timeout configs. Centralizing in client.ts so
the next adapter (likely an authors module) doesn't add a third variant.
No behavior change."
```

The `refactor:` prefix is important. It tells reviewers (and future-you) that the diff is structural, no behavior change, no spec update needed.

### 7. Open a small, single-purpose PR

A refactor PR should be **boring** to review. If your reviewer is asking "wait, did this change behavior?", the PR is doing too much. Split it.

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Refactor + feature in the same commit | Reviewers can't tell what's behavior change vs structure change; bugs hide in the diff | Always two separate commits. Refactor first, feature second. |
| Refactoring untested code | "I think this still works" → it doesn't | Write characterization tests first; commit them; then refactor. |
| Adding "small improvements" mid-refactor | Scope creeps, PR balloons, review takes forever | If you spot something, note it in a follow-up TODO. Don't fix it now. |
| Modifying tests "to clean them up" during a refactor | The contract you're supposedly preserving is now also changing | Tests stay as-is during a refactor. Test cleanup is a separate refactor. |
| Refactoring "for the sake of it" | Time spent, no payoff, sometimes regressions | Refactor for a specific reason: removing duplication, enabling an upcoming feature, fixing a real pain point. Not "this could be cleaner." |
| Speculative abstraction | "What if we need this to be configurable?" → premature flexibility, harder to read | Only extract abstractions when you have at least 2-3 concrete use cases (the "rule of three"). |

## Example

**Starting point:** `lib/contentful/article.ts` and `lib/contentful/newsletter.ts` each define their own `getClient()` with slightly different timeout configs:

```ts
// lib/contentful/article.ts
import { createClient } from 'contentful';
const client = createClient({
  space: process.env.CONTENTFUL_SPACE_ID!,
  accessToken: process.env.CONTENTFUL_TOKEN!,
  timeout: 5000,
});

export async function getArticle(slug: string) { /* ... */ }
```

```ts
// lib/contentful/newsletter.ts
import { createClient } from 'contentful';
const client = createClient({
  space: process.env.CONTENTFUL_SPACE_ID!,
  accessToken: process.env.CONTENTFUL_TOKEN!,
  timeout: 3000,   // ← subtly different
});

export async function getNewsletterCopy() { /* ... */ }
```

**Why refactor:** about to add `lib/contentful/authors.ts`. Three files × the same boilerplate is the moment to extract. Also, the timeout difference is unintentional drift from when one was copied from the other.

**Plan from `/refactor`:**

```
- [ ] 1. Create lib/contentful/client.ts with getClient(timeout?: number).
       Default timeout 5000ms (the more conservative of the two).
- [ ] 2. Update lib/contentful/article.ts: import from client.ts, remove local createClient.
- [ ] 3. Update lib/contentful/newsletter.ts: import from client.ts.
       Pass timeout: 3000 explicitly to preserve current behavior.
       (Optional follow-up: spec discussion of whether 3000ms is right.)
- [ ] 4. Run full test suite, confirm green.

No public API changes. No test changes. Behavior preserved exactly
(including the deliberately-different newsletter timeout).
```

**Diff size:** ~25 lines across 3 files. **Tests:** untouched, all green. **Commit:**

```
refactor: extract shared Contentful client factory

Same createClient() boilerplate was duplicated in article.ts and
newsletter.ts with slightly different timeouts. Extracted getClient(timeout)
so the upcoming authors adapter doesn't add a third copy. Newsletter's
3000ms timeout is preserved explicitly — flagging for spec discussion
in a follow-up.
```

A reviewer can scan the diff in 30 seconds and confirm "yep, just structure". The commit explains the *why* — including the deliberate preservation of the timeout drift, so future-them knows it wasn't an accident.
