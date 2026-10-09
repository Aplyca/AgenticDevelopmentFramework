# Scenario: Debugging

## When to use this

Something is broken or behaves unexpectedly, and nobody knows why yet:

- Newsletter signups return 500 on preview deployments but work locally.
- A test passes locally and fails in CI.
- A reader reports something the code "can't do".

**Not this scenario:**

- Production is broken now → [Hotfix](hotfix.md), which has a diagnosis step inside.
- You already know the cause → write the regression test and fix it ([After the diagnosis](#after-the-diagnosis)).
- The task asks only *why* — no change requested → [Answer-only task](answer-only-task.md): the diagnosis is the deliverable.

## Diagnose, then decide

Typing "fix this" and accepting the first plausible patch works some of the time and produces the
"fixed it, it came back" pattern the rest of the time. `/debug` enforces the order: evidence,
hypotheses, the root cause that explains every symptom — and only then a decision about what to do.
That decision matters as much as the diagnosis: the same symptom can end as a one-commit fix, a
change request, or a hotfix.

## Steps

1. **Triage** (`/triage`): kind bug, cause unknown; environment only if reproducing needs something
   running; spec folder decided after the diagnosis, not before.

2. **Gather evidence** before asking for a diagnosis: the exact error and stack trace, pasted, not
   paraphrased; steps to reproduce; expected versus actual; when it started (which deploy, which
   content edit); where (local, CI, preview, production); how reliably.

3. **Diagnose** — `/debug` in this conversation, or the [`@debugger`](../../plugins/adf/agents/debugger.md)
   agent for an isolated, read-only investigation (it can't edit, so it can't "just fix it"). Either
   way it starts with a **signal** — one command that fails on this bug, every time, in seconds —
   then ranks three to five hypotheses, shows them to you, and tests them one at a time. You often
   know which one to rule out: say so. When several layers are suspects, `/orchestrate investigate`
   runs different perspectives in parallel.

4. **Confirm the hypothesis** before acting on it. It must explain every symptom, and something must
   be able to prove it wrong — the signal passing once the cause is removed, a log line, a setting.
   If the evidence rules it out, go back with the new evidence instead of trying the next guess.

5. **Decide what happens next** — the table below — and say which row you're in.

## After the diagnosis

| The diagnosis says | Next | Spec folder | Commits |
|---|---|---|---|
| A defect: the fix restores documented behavior (a spec criterion, a committed doc) or changes nothing documented | Fast lane (careful in a risk area): regression test → watch it fail → fix the root cause → green | None — the regression test is the record | One `fix:`, test and fix together |
| The code does what the spec says; someone wants different behavior | [Change request](change-request.md) | A light `CR N` when the requester decided the new behavior; a full one when there's something to decide | Light: one commit with the change. Full: `spec:` first, then the CR's tasks |
| Nothing documents what should happen | It's a decision: ask, then record the answer as a `CR N` on the feature's folder | Amend | `spec:` first |
| Production is broken now | [Hotfix](hotfix.md) — the careful lane, without delay | Backfilled afterwards | `fix:` |
| The cause is outside the repository — configuration, a platform setting, a third party | Report it; the fix is a human action. Change code only where it made the failure worse | None | `fix:` only if code changed |
| The task asked only why | Deliver the diagnosis as the answer — [Answer-only task](answer-only-task.md) | None | None |

A fix without a spec folder still goes through the TDD loop: the test reproduces the bug and fails
for the right reason before the fix exists. With no `tasks.md`, the red-then-green evidence goes in
the commit body and in the pull request's "verified / not verified".

## Example

**Symptom.** Signups return 500 on preview deployments; locally they work. It started with today's
first preview build.

```
/debug Newsletter signup returns 500 on preview deployments, works locally.
Log: TypeError: Cannot read properties of undefined (reading 'split')
     at mailchimpHost (lib/newsletter/mailchimp.ts:9)
     at POST (app/api/newsletter/route.ts:18)
Repro: any article on the preview URL, submit any email. 100% on preview, 0% locally.
Started: today's first preview build.
```

**Signal.** A request against the preview deployment, which prints `500` on every run (and `200`
against `localhost:3000`):

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$PREVIEW_URL/api/newsletter" \
  -H 'content-type: application/json' -d '{"email":"reader@example.com"}'
```

**Diagnosis.** Three hypotheses, ranked and shown to the developer before testing: the provider key
is missing on preview (then setting it makes the signal pass); the key is read at build time rather
than at runtime (then a rebuild changes the result); a bundling difference (then a local production
build fails too). Reading the provider wrapper settles it: it
picks Mailchimp's host from the data-center suffix of `MAILCHIMP_API_KEY`, read with a non-null
assertion, so a missing key surfaces as a `TypeError` on `undefined` instead of a configuration
error. The hosting platform's settings confirm it: the key is set for Production only. The spec's Deployment section already says every environment
needs it.

**Decision — two causes, two rows of the table:**

- **Outside the repository.** The developer enables the key for preview deployments in the hosting
  platform. The `check-env-declared` hook checks that every variable the code reads is *declared*
  in `.env.example`; it can't know whether each deploy target has a *value* — that's what the spec's
  Deployment section is for.
- **A defect.** The non-null assertion turned a configuration mistake into an opaque crash far from
  its cause. Failing with a clear configuration error changes nothing documented — readers still see
  the retry-able error — so: no spec change, a regression test, a fix.

```
✘ throws MailchimpUnavailableError naming MAILCHIMP_API_KEY when the key is missing
    expected error matching /MAILCHIMP_API_KEY/, got "Cannot read properties of undefined (reading 'split')"
```

The wrapper now checks the key first and throws `MailchimpUnavailableError` with a message naming
the variable; the route already maps that error to the 502 the form answers with its error message
(AC6). Green, and the route's existing tests stay green.

**Same feature, a different row.** Readers at a university report the form's error message on their
first try. `/debug` finds the whole campus behind one network address — and the route allows 10
signups per IP per minute, exactly what the spec's Security section says, answered with the error
message, as its Clarifications decided. Nothing is broken, so nothing gets
"fixed": raising the limit or keying on something other than the address is a security decision. It
becomes a [change request](change-request.md) on `specs/007-newsletter-signup/`.

## Commits it produces

```
$ git log --oneline main..fix/newsletter-provider-key
8d3a1f7 fix: fail clearly when the email provider key is missing
```

The university case produces no fix commit. Its first commit is the change request's
`spec: approve newsletter-signup CR N`, after the gate.

## Common mistakes

| Mistake | What happens | Instead |
|---|---|---|
| "Fix this" without a diagnosis | A plausible patch lands; the bug moves elsewhere | `/debug`; fix only a confirmed root cause |
| Treating the symptom | A `try/catch` and a log line, a bigger timeout, a retry — the cause stays | Ask what mechanism produced the symptom, and fix that |
| No regression test | The bug is back in three months | Every diagnosed bug gets a test that failed first |
| Fixing working-as-specified behavior | A requirement changes in a `fix:` commit nobody approved | Check the spec first; behavior changes are change requests |
| Theorizing before reproducing | Code reading builds a theory nothing can confirm; a coincidental fix looks like a real one | A command that fails on the bug first; when the cause is plain, the regression test is that command |
| Accepting the first hypothesis | A wrong fix on top of the original bug | Rank three to five, name what would prove each wrong, then check |
| Vague evidence | The agent guesses | Exact errors, reproduction steps, environment |
| Hours of tunnel vision | Obvious things get missed | After an hour without narrowing it down, step back or pull in a teammate |

Signs you're fixing a symptom: the fix adds an `undefined` check without knowing why the value is
undefined; catches an error without knowing which one to expect; raises a timeout without measuring
why it times out; adds a retry without naming the failure; or reorders two lines and you can't say why
that helps.

**Reference:** [`/debug`](../../plugins/adf/skills/debug/SKILL.md) ·
[testing rules — red, then green](../../skeleton/.claude/rules/testing.md) ·
[`specs/README.md` § Lanes](../../skeleton/specs/README.md#lanes--how-much-process-a-change-gets)
