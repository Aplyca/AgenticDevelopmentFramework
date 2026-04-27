# Scenario: Debugging

## When to use this

Something is broken or behaves unexpectedly, and you need to understand **why** before deciding what to do about it. Examples:
- A test passes locally but fails in CI.
- The article page renders the right data on first visit but stale data on a refresh.
- Newsletter submissions succeed in dev but return 500 on Vercel.
- A user reports something that "shouldn't be possible" given the code.

**Not this scenario:**
- You already know the cause and just need to fix it → just fix it. Debugging is for the unknown.
- It's actively breaking production → use [Hotfix](hotfix.md) (which has a `/debug` step inside it).
- The bug is "the feature doesn't do what I want" — that's a spec mismatch, not a bug → use [Modifying an existing feature](modifying-existing-feature.md).

## The core principle

**Don't guess. Diagnose.** It's tempting (especially with AI) to type "fix this" and accept the first plausible patch. That works ~30% of the time and creates the "fixed it but it came back" pattern that erodes trust in the code.

The `/debug` skill enforces a discipline: gather evidence, form a hypothesis, test it, then act. It's slower for the trivial cases. It's massively faster for the ones where the obvious cause is wrong.

## Steps

### 1. Gather evidence before opening AI

Before invoking `/debug`, collect:

- The **exact error message and stack trace** (copy/paste, don't paraphrase).
- **What you did to trigger it** — the URL, the input, the click sequence.
- **What you expected vs what happened.**
- **When it started** — was it always broken? Started after a specific deploy? After a Contentful edit?
- **Where it happens** — local? CI? preview deploy? production? all?
- **Reproduction reliability** — every time, sometimes, once?

5 minutes here saves 30 minutes of back-and-forth later.

### 2. Run /debug with the evidence

```
/debug

Newsletter submission returns 500 on Vercel preview deploys but works locally.

Error from Vercel logs:
  TypeError: Cannot read properties of undefined (reading 'subscribe')
  at POST (app/api/newsletter/route.ts:18)

Steps to reproduce:
  1. Go to <preview URL>/articles/example-article
  2. Submit any email
  3. 500 returned, error above in logs

Started: today's deploy (commit abc123). Local dev (`pnpm dev`) works fine.
Reproduces 100% on preview, 0% locally.
```

### 3. Let the skill diagnose, not patch

`/debug` walks through:

1. **Reproduce** — confirms it can replicate the failure (or asks how to).
2. **Read the code** at the failure point.
3. **Form hypotheses** — usually 2-3 plausible causes.
4. **Discriminate** — what evidence would confirm or rule out each one?
5. **Test the leading hypothesis** — by reading more code, running a probe, or asking you to.
6. **Identify the root cause** — not the symptom.
7. **Propose a fix** — but does NOT apply it until you ask.

Sample interaction continuing the example above:

> **AI:** Three hypotheses for "works locally, fails on Vercel preview":
>
> 1. **Env var missing on preview.** `MAILCHIMP_API_KEY` may be set for production but not for preview deploys in Vercel project settings. Local has it via `.env.local`.
> 2. **Build-time vs runtime resolution.** If `mailchimp.ts` reads `process.env.MAILCHIMP_API_KEY` at module load, it's captured at build time. Preview build may have run with a different env scope.
> 3. **Bundling difference.** The Mailchimp client may be tree-shaken differently in production builds than in dev.
>
> Reading `lib/newsletter/mailchimp.ts`...
>
> ```ts
> const client = MailchimpFactory(process.env.MAILCHIMP_API_KEY!);
> export const subscribe = client.subscribe;
> ```
>
> The `!` non-null assertion silently passes `undefined` if the env var isn't set, which then makes `client` an empty object — `client.subscribe` is undefined.
>
> **Most likely root cause:** hypothesis 1. `MAILCHIMP_API_KEY` is set in Vercel only for the Production environment, not Preview.
>
> **To confirm**, can you check Vercel project settings → Environment Variables → see if `MAILCHIMP_API_KEY` is enabled for "Preview"? Or run `vercel env ls`.

### 4. Confirm the hypothesis before fixing

Don't accept the diagnosis on faith — test it.

```bash
$ vercel env ls
# Output shows MAILCHIMP_API_KEY is set for Production only, not Preview. Confirmed.
```

If the test rules out the hypothesis, go back to the AI with the new evidence — don't just try the next guess.

### 5. Write a regression test

The fix isn't done until there's a test that would have caught the bug.

For this example, two layers of test help:

```ts
// Unit: the wrapper should fail loudly when the API key is missing
test('throws on missing MAILCHIMP_API_KEY', () => {
  delete process.env.MAILCHIMP_API_KEY;
  expect(() => createMailchimpClient()).toThrow(/MAILCHIMP_API_KEY required/);
});
```

```ts
// E2E: smoke test that runs against the preview deploy
test('newsletter signup returns 200 on preview deploy', async ({ page }) => {
  // configured to point at the preview URL during PR check
  ...
});
```

Run them. They should fail against the current code.

### 6. Fix the root cause, not the symptom

Two layers of fix here:

**Symptom fix (immediate):** add `MAILCHIMP_API_KEY` to Preview env vars in Vercel.

**Root cause fix (the *real* fix):** the wrapper silently swallowed the missing key with `!`. That's the underlying bug — the symptom (this 500) is just one of many symptoms it could produce. Replace the assertion with an explicit check that fails loudly:

```diff
- const client = MailchimpFactory(process.env.MAILCHIMP_API_KEY!);
- export const subscribe = client.subscribe;
+ export function createMailchimpClient() {
+   const apiKey = process.env.MAILCHIMP_API_KEY;
+   if (!apiKey) throw new Error('MAILCHIMP_API_KEY required');
+   return MailchimpFactory(apiKey);
+ }
+ export const subscribe = (email: string) => createMailchimpClient().subscribe(email);
```

Now if the env var goes missing again on any environment, the failure mode is "loud error at first use" rather than "mysterious 500 on `client.subscribe`".

### 7. Verify and commit

```bash
$ pnpm test
  ✓ ... all pass

git commit -m "fix: fail loudly when MAILCHIMP_API_KEY is missing

Root cause of preview-deploy 500s: the env var was set for production
only, and our wrapper used a non-null assertion that silently produced
an empty client object. Now throws explicitly so misconfiguration is
caught at the first request, with a clear message."
```

## Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Asking AI to "fix" without diagnosing | First plausible-looking patch lands; bug returns or moves elsewhere | Use `/debug` and let it diagnose. Only fix once the root cause is confirmed. |
| Treating the symptom, not the cause | Bug "comes back" in a different form weeks later | Always ask: "what's the underlying mechanism that produced this symptom?" Fix that. |
| Fixing without a regression test | Same bug reappears in 3 months when nobody remembers | A diagnosed bug always gets a test. Always. |
| Accepting the first hypothesis | If the hypothesis is wrong, the fix makes things worse | Demand evidence. "How would we know if this hypothesis is wrong?" |
| Vague evidence to AI | AI guesses; you waste time on irrelevant patches | Spend 5 minutes gathering evidence before opening AI. Stack traces, repro steps, environment. |
| Continuing to debug for hours instead of asking for help | Tunnel vision; obvious things missed | If you've been on it for an hour with no progress, pull in a teammate. Fresh eyes catch what tunnel vision misses. |

## Heuristics for spotting a "you're symptom-fixing" moment

- The fix is "add a check for `undefined`" without understanding *why* it's undefined.
- The fix is "add a try/catch and log it" without knowing what error to expect.
- The fix is "increase the timeout" without measuring why it was timing out.
- The fix is "add a retry" without identifying the failure mode.
- The fix is "swap the order of these two lines" and you don't know why that helps.

When you spot one of these, go back to step 2 and re-diagnose. The fix may be unavoidable in the short term — but you should also understand the underlying cause and know whether you've actually addressed it or just moved the symptom.

## Example

**The symptom:** test `e2e/newsletter-signup.spec.ts > shows success message after valid submission` fails in CI but passes locally. Started 3 days ago.

**Initial reaction:** "flaky test, retry it." Ran 5 times. Failed 3 of 5 in CI. Passed 5 of 5 locally. Not just flake.

**`/debug` session findings:**

> Hypotheses:
> 1. Race condition between fetch and assertion that local CPU is fast enough to mask
> 2. CI runner has different timezone affecting a date-formatting code path
> 3. Test pollution from a previous test
>
> Reading the test order:
>
> ```ts
> test.describe('Newsletter signup', () => {
>   test('shows form ...', async () => { ... });
>   test('shows success message ...', async () => {
>     // this test mutates the rate-limit store via real submission
>   });
>   test('shows already-subscribed message ...', async () => {
>     // also submits, hits rate limit if previous test ran first
>   });
> });
> ```
>
> Hypothesis 3 is the leading candidate: tests share state through the rate-limit store. Locally tests run fast enough that... actually no, that doesn't explain local pass / CI fail.
>
> Looking deeper: CI runs tests with `--workers=4`, locally defaults to 1. Parallel workers share the same in-memory rate-limit mock if it's a module-level singleton.
>
> Reading `lib/newsletter/__mocks__/rate-limit.ts`:
>
> ```ts
> let counter = 0;        // ← module-level, shared across workers in CI
> export const rateLimit = (ip: string) => { counter++; return { ok: counter < 10 }; };
> ```
>
> **Root cause:** the mock uses module-level state. With parallel workers, all four workers' submissions accumulate, and the suite hits the 10-request limit partway through.

**Why local missed it:** workers=1 means each test gets a fresh module load between files (Vitest behavior), so the counter resets. CI with workers=4 shares the counter across all four workers' test files.

**Symptom fix:** lower workers to 1 in CI (slow, doesn't address the bug).

**Root cause fix:** make the mock per-test by resetting in `beforeEach`, OR replace the singleton with an injectable instance. The latter is better because it also surfaces the same bug if it exists in real code.

**Regression test:** add a test that asserts the mock state is fresh between tests (would fail under the old singleton).

**Commit:**

```
fix(test): reset rate-limit mock between tests

CI parallelism (workers=4) was sharing the in-memory rate-limit counter
across worker processes, causing the 4th test in the file to hit the
limit and fail nondeterministically. Local runs with workers=1 hid the
bug. Mock now resets in beforeEach; added a sentinel test that fails
if the reset is removed.
```

Total time: 45 minutes. Without `/debug`-style discipline, the team would have likely landed "rerun on failure" or "lower workers in CI" and called it done — until the same bug reappeared in production code two months later.
