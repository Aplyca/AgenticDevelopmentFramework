# Scenario: Modifying an existing feature

## When to use this

You're changing the behavior of something that already has a spec. Examples:
- Marketing wants the newsletter signup to also accept a name field.
- Article page should show the publish date in the reader's timezone, not UTC.
- The rate limit on `/api/contact` needs to drop from 10/min to 3/min.

**Not this scenario:**
- Adding something net-new with no existing spec → use the full Feature Development workflow ([ONBOARDING.md](../ONBOARDING.md)).
- Fixing a production-breaking bug right now → use [Hotfix](hotfix.md).
- Restructuring code with no behavior change → use [Refactor](refactor.md).

## Why this scenario has its own playbook

The defining feature is that **you should not start from a blank spec**. The existing spec is the source of truth — you update it, and the **git diff of that update** becomes the precise scope for tests and implementation. Unchanged ACs stay unchanged. Unchanged code stays unchanged. The AI agents read those diffs to know exactly what to touch.

## Steps

### 1. Find the existing spec

```
ls specs/
# or
grep -l "newsletter" specs/
```

If no spec exists for this area, you're either in the wrong scenario, or the project predates spec discipline. In the latter case: backfill a spec describing the *current* behavior first, commit it, then come back here.

### 2. Update the spec

```
/write-spec update specs/newsletter-signup.md to add an optional first-name field
```

The skill detects you're modifying an existing spec and:
- Reads the current spec
- Asks clarifying questions about the change
- Updates only the affected ACs (and adds new ones if needed)
- Adds new edge cases if the change introduces them
- Adds a new Q&A under **Clarifications** for any ambiguities resolved during the update

Review the diff carefully — make sure unchanged ACs are *actually* unchanged (no accidental rewording).

### 3. Commit the spec update

```bash
git diff specs/newsletter-signup.md       # review the diff
git add specs/newsletter-signup.md
git commit -m "spec: add optional first-name field to newsletter signup"
```

> The diff itself is the most important artifact. It's what the next two steps will read.

### 4. Plan and write tests for the changed/new ACs only

```
/write-tests newsletter-signup
```

In the planning phase, the AI runs `git diff HEAD~1 -- specs/` to see what changed. The plan it presents will only cover **new and changed ACs** — existing tests for unchanged ACs stay as they are.

Approve the plan, let the AI write the new tests, then run the suite:

```bash
$ pnpm test:e2e
  ✓ shows form with copy from Contentful           ← unchanged, still passes
  ✓ shows success message after valid submission   ← unchanged, still passes
  ...
  ✘ accepts optional first-name field              ← new, fails (red)
  ✘ stores first name when provided                ← new, fails (red)
```

The expected pattern: **old tests still pass, new tests fail**. If an old test now fails, your spec update accidentally changed behavior the spec didn't intend to change — go back to step 2.

### 5. Commit the new tests

```bash
git add e2e/newsletter-signup.spec.ts
git commit -m "test: add first-name field tests (red — pending implementation)"
```

### 6. Update user-facing docs (docs-first)

```
/write-docs newsletter-signup
```

If the spec update added entries to **Pre-implementable docs** (e.g., the admin guide gains a section explaining the new field), the skill plans the doc updates, you approve, the AI writes them, and you commit:

```bash
git commit -m "docs: update admin guide for first-name field"
```

If the spec update didn't touch user-facing docs, the skill skips cleanly. Proceed.

### 7. Plan and implement the change

```
/implement newsletter-signup
```

The AI reads both diffs (spec and tests) to know the exact scope. The implementation plan should:
- Touch only the files needed for the new/changed behavior
- Explicitly note which existing code stays as-is
- List which tests each file change makes pass

Approve, let it execute, verify all tests pass (old + new):

```bash
$ pnpm test:e2e
  ✓ shows form with copy from Contentful
  ✓ shows success message after valid submission
  ✓ accepts optional first-name field
  ✓ stores first name when provided
  ...
  9 passed
```

### 8. Review and commit

```
/review
/commit
```

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Writing a new spec instead of updating | Two specs cover the same area, contradict over time | Always update the existing spec; the spec history shows how the feature evolved |
| Rewriting unchanged ACs while updating | Test diff is huge, scope is unclear, regressions | Touch only what's actually changing; review the spec diff before committing |
| Skipping the spec commit before tests | `/write-tests` can't tell what changed; writes tests for everything | Always commit the spec first |
| Updating tests for unchanged behavior "while you're in there" | Test commit mixes scope changes with refactor; reviewers can't tell intent | Keep the test commit limited to the changed scope. If you want to refactor existing tests, do it in a separate commit afterward |
| Implementing more than the diff says | Scope creep; review surfaces unrelated changes | If you find yourself touching files not in the implementation plan, stop and re-read the spec diff |

## Example

**Starting point:** the newsletter signup spec from the [worked example](../examples/newsletter-signup/spec.md) is committed, tests are committed, code is shipped.

**Change request:** marketing wants to A/B test adding an optional first-name field.

**Spec diff** (after running `/write-spec`):

```diff
 ## Acceptance criteria

 1. Every article page renders a newsletter signup section beneath the article body,
-   containing a heading, body copy, an email input with a visible label, and a submit button.
+   containing a heading, body copy, an email input with a visible label, an OPTIONAL
+   first-name input with a visible label, and a submit button. The first-name input
+   is shown only when the Contentful entry's `showFirstName` boolean is true.
    Heading, body copy, and submit button label are sourced from the singleton
    Contentful entry of type `newsletterSignup`.

 2. When the user submits a valid email address, the form replaces itself with a success
-   message sourced from the same Contentful entry, and the email is recorded as a Mailchimp subscriber.
+   message sourced from the same Contentful entry, and the email is recorded as a Mailchimp
+   subscriber. If the first-name field is shown and filled, the name is recorded as the
+   `FNAME` merge field on the Mailchimp subscriber.

 ## Edge cases

 ...
+- First-name field shown but left empty → email submits successfully, no FNAME recorded.
+- First-name field filled with whitespace only → treated as empty.
+- First-name longer than 50 characters → trimmed to 50 (Mailchimp's FNAME limit).
```

**Test plan** (subset, from `/write-tests`):

> AC1 (modified) — only the new clause needs a test:
>   - `shows first-name input when Contentful flag is true` (NEW)
>   - `omits first-name input when Contentful flag is false` (NEW)
>   - existing `shows form with copy from Contentful` test still covers the rest of AC1
>
> AC2 (modified) — only the new clause needs a test:
>   - `records first name as FNAME when provided` (NEW)
>   - existing `shows success message after valid submission` still covers the base success path
>
> Edge cases — 3 new tests for the 3 new edge cases.

**Implementation diff:** ~30 lines across 3 files (Contentful adapter, server component, client form). The Route Handler changes by ~5 lines (forward optional `firstName` to Mailchimp). No other files touched.

**Git history at the end:**

```
* feat: add optional first-name field to newsletter signup
* docs: update admin guide for first-name field
* test: add first-name field tests (red — pending implementation)
* spec: add optional first-name field to newsletter signup
* feat: add newsletter signup on article pages       ← original feature
* docs: add admin guide and end-user copy defaults
* test: add newsletter signup tests
* spec: add newsletter signup form for article pages
```

A reader six months from now sees both the original feature and the modification as clean three-commit groups.
