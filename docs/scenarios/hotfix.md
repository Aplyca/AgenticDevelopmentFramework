# Scenario: Hotfix

## When to use this

Production is broken **now** — users are affected at this moment — and the fix can't wait for the
normal path:

- Every newsletter signup fails since this morning.
- Article pages return 500 after a CMS model change.
- A deploy went out twenty minutes ago and the homepage is blank.

**Not this scenario:**

- A bug that's annoying but not breaking → [Debugging](debugging.md): diagnose, regression test, fix, a normal pull request.
- A bug you found while building something → fix it in the task you're on.
- "This should work differently" → [Change request](change-request.md).

A hotfix skips spec-first for speed. It never skips the diagnosis, the regression test, the human
review, or the backfill. Most "urgent" bugs aren't hotfixes — be honest about which this is.

## Steps

1. **Mitigate if you can.** Rolling back to the previous deployment or release, reverting a content
   or configuration change, turning off a flag: if one restores service faster and more safely than
   a fix, do it first. Once service is back you're no longer in a hotfix — the fix takes the normal
   path in [Debugging](debugging.md).

2. **Triage, fast** (`/triage`): deliverable change; kind hotfix; environment needed (the regression
   test runs); spec folder none for now — backfilled afterwards.

3. **Branch on the project's hotfix path** (`CONTRIBUTING.md` § Branching and release — both models
   are in the [skeleton's CONTRIBUTING.md](../../skeleton/CONTRIBUTING.md)):

   | Branching model | Hotfix path |
   |---|---|
   | **A** — feature branches into `main` | `fix/<slug>` from `main`; pull request into `main`; merging deploys |
   | **B** — integration branch, tagged releases | `hotfix/<slug>` from the **released tag**; pull request into `main`; tag a patch release; back-merge `main` into the integration branch immediately. Hotfixes are code-only — migrations go through the integration branch |

   Never commit to `main` directly: the git guard refuses, and branch protection on the Git host is
   the real boundary.

4. **Diagnose** (`/debug`, or the read-only `@debugger` agent) — even when the cause looks obvious.
   Five minutes here catches the fix that would only hide the symptom.

5. **Regression test first.** Reproduce the failure as a test, run it, and watch it fail for the
   right reason — the reported symptom, not a broken fixture.

6. **Smallest fix, then green** — the new test, then the fast gate (lint, typecheck, unit tests). If
   the fix needs a decision nothing documents ("what should happen when X is down?"), stop and ask:
   the developer or the area's owner decides, and the backfill records it.

7. **One commit, test and fix together** — `fix: …`, with a body that says why and records the
   red-then-green evidence (a hotfix has no `tasks.md`). Hooks run; under pressure is exactly when
   `--no-verify` is tempting, and the guard blocks it anyway.

8. **Quick `/review`, then deliver when asked.** `/open-pr` pushes and opens a **draft** pull
   request; each push and pull request action is confirmed. A human QCs it — the preview, the
   reproduction — and only then is it marked ready, reviewed, and merged. In model B someone also tags
   the patch release and opens the back-merge. The agent does any of these only when asked, never on
   its own initiative.

9. **Watch production recover** — the affected page, the error rate, the logs.

10. **Backfill — the step everyone skips.** If the hotfix changed behavior or settled a question the
    spec didn't answer, amend the feature's spec folder in a follow-up pull request
    (`specs/README.md` § Hotfix backfill): a `CR N — hotfix: <title> (date)` section with what changed,
    why, and the Delivered → Change table; the acceptance criteria it changed; a Clarification
    recording the decision (who, when); and the hotfix pull request in `pull-requests:`
    (`<url> · hotfix`). Update the user-facing docs and runbooks it affects. There's no approval gate
    for recording what already shipped — the backfill pull request is reviewed like any change. If
    the fix only restored documented behavior, the regression test is the record — there's nothing to
    backfill.

With the parallel-agents module, a model-B hotfix branches from the release tag:
`scripts/agent/worktree-new.sh hotfix/<slug> --from v1.6.0`.

## Example

The newsletter site uses model A: `main` is production.

**09:40** — the error-rate alert fires: since 09:12 every signup shows "Something went wrong, please
try again". Article pages are fine.

**09:44 — mitigate?** There has been no deploy since Tuesday, so a rollback won't help. The logs
show the rate limiter's store rejecting every call: a campaign mention overnight used up the store
plan's monthly request quota, and raising it needs the account owner, who is out until tomorrow.
Fix forward.

**Triage**

```
Triage — Every newsletter signup fails since 09:12 (on-call alert)
- Deliverable: change
- Kind: hotfix — production broken now; no deploy since Tuesday, so a rollback won't help
- Environment: needed now — the regression test runs against the signup route
- Spec folder: none now; backfill specs/007-newsletter-signup/ afterwards
- Open questions: 1) While the limiter's store is unavailable, accept signups without rate limiting
  (fail open) or reject them (fail closed)? The spec doesn't say.
- Next: fix/newsletter-rate-limit-outage from main, then /debug
```

**Diagnosis** (`/debug`): the route calls the rate limiter before anything else; the limiter throws
when its store rejects a request; nothing catches it, so the route returns 500 and the form shows its
generic error. The spec's Security section sets the limit — 10 requests per IP per minute — but not
what happens when the limiter itself is down. That's a decision, so it goes to the developer, who
asks the security owner: **fail open** — accept the signup, log an error event, alert on it — because
losing every signup costs more than a short window without the limit.

**Regression test**, red for the right reason:

```
✘ accepts a valid signup when the rate-limit store is unavailable
    expected status 200, received 500
```

**Fix**: the route catches the store failure, logs `newsletter.rate_limit.store_unavailable`, and
carries on. The test passes; the unit suite and lint pass.

**Delivery**: the developer asked for the pull request; `/open-pr` opened a draft into `main`. The
on-call lead checked the preview, marked it ready, reviewed, and merged; the merge deployed. By 10:25
the error rate was back to normal.

**Backfill**, the next morning, on a fresh branch, `docs/newsletter-signup-rate-limit-outage`:
`spec.md` gains a `CR N — hotfix: Accept signups when the rate-limit store is unavailable` section
(the next free number) whose Delivered → Change row reads *rate-limit store unavailable: every signup
fails with a 500 → the signup is accepted, and an error is logged and alerted*; a new criterion
tagged `(CR N)` states the rule; a Clarification records the decision, the security owner, and the
date; and the hotfix pull request goes into `pull-requests:` as `<url> · hotfix`. The runbook gets a
section on the store's quota.

**The same hotfix in model B** (integration branch `staging`, releases tagged on `main`, last release
`v1.6.0`):

```
git switch -c hotfix/newsletter-rate-limit-outage v1.6.0   # from the released tag, not from staging
# … the same diagnosis, test, fix, commit, and draft pull request into main …
# after the merge, by a human (or by the agent, when asked):
git tag -a v1.6.1 -m "Accept signups when the rate-limit store is unavailable"
git push origin v1.6.1                                       # the tag ships
# then, immediately: a pull request from main into staging — the back-merge
```

Branching from `staging` instead would ship unreleased work with the fix; skipping the back-merge
would let the next release from `staging` bring the bug back.

## Commits it produces

```
$ git log --oneline main..fix/newsletter-rate-limit-outage
4c2e8f1 fix: accept signups when the rate-limit store is unavailable
```

The commit body carries what a hotfix has no `tasks.md` for:

```
fix: accept signups when the rate-limit store is unavailable

Since 09:12 the rate limiter's store has rejected every call (monthly
request quota used up), and the uncaught error turned every signup into
a 500. Per the security owner's decision during the incident, the route
now fails open: it accepts the signup and logs
newsletter.rate_limit.store_unavailable, which is alerted.

Red: "accepts a valid signup when the rate-limit store is unavailable"
failed with 500. Green after the fix; unit suite and lint pass.
Spec backfill to follow on specs/007-newsletter-signup/.
```

And the backfill, a day later:

```
$ git log --oneline main..docs/newsletter-signup-rate-limit-outage
b7d0e3a docs: add the rate-limit store quota check to the newsletter runbook
2a9f6c4 spec: record the rate-limiter outage rule from the hotfix
```

## Common mistakes

| Mistake | What happens | Instead |
|---|---|---|
| Skipping the diagnosis because the cause "is obvious" | The fix hides the symptom — raise the rate limit, add a retry — and the cause stays | `/debug` first; it takes minutes |
| Skipping the regression test | The same failure is back in a month | Test first, watch it fail, then fix |
| Pushing straight to `main` | No review and no clean revert — and the guard refuses | Branch and draft pull request, expedited review |
| Letting the agent settle an open question | A security trade-off made by a tool, unrecorded | Ask; the backfill records who decided |
| Fixing forward when a rollback would do | More risk at the worst moment | Mitigate first, then fix calmly on the normal path |
| Model B: branching from the integration branch | Unreleased work ships with the hotfix | Branch from the released tag |
| Model B: forgetting the back-merge | The next release brings the bug back | Back-merge `main` into the integration branch right away |
| Skipping the backfill | The spec describes a system that no longer exists | Backfill within days — it's part of the hotfix |

**Reference:** [`/debug`](../../skeleton/.claude/skills/debug/SKILL.md) ·
[`CONTRIBUTING.md` § Branching and release](../../skeleton/CONTRIBUTING.md#branching-and-release) ·
[`/open-pr`](../../skeleton/.claude/skills/open-pr/SKILL.md) ·
[testing rules — red, then green](../../skeleton/.claude/rules/testing.md)
