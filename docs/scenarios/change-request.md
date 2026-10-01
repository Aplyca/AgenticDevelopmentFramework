# Scenario: Change request on delivered work

## When to use this

Something was delivered — it has a spec folder and shipped through a pull request — and someone
wants it to behave differently:

- The requester's feedback after acceptance testing ("round two").
- A tracker task that refers to delivered work ("the topic checkboxes we shipped last month…").
- A bug report that turns out to be a request: the code does what the spec says, and the requester
  now wants something else.

**Not this scenario:**

- Nothing delivered yet → a new feature: the flow in [`specs/README.md`](../../skeleton/specs/README.md), worked end to end in the [newsletter-signup example](../examples/newsletter-signup/).
- The code doesn't do what the spec says → a bug: [Debugging](debugging.md) — regression test and fix, no spec change.
- Production is broken now → [Hotfix](hotfix.md).
- A typo or a change the spec doesn't record → the fast lane, no change request: edit, test, `/commit`. Copy that lives in the CMS isn't a code change at all.

## Why it has its own playbook

Re-reading the task from scratch is how delivered scope gets silently dropped or redone. Trackers
rarely keep a revision history of a task's description; the spec folder is the snapshot of what was
agreed and built, and the comments since it last changed are usually where the change was argued.
So the work starts from the **delta** — the request now against what the spec records as delivered
— and everything after it (plan, tests, docs, code) covers only that delta.

## Light or full?

Decide by whether anything is left to decide — not by size:

| The request | Change request | Lane |
|---|---|---|
| Precise: the requester said exactly what changes ("the label reads *Your email*", "show 20 per page") | **Light** — a short `CR N … · light` entry in `spec.md`, committed with the change; no plan, no gate | Fast, or careful in a risk area |
| Leaves something to us: behavior, scope, or design to choose ("make it less intrusive"), or it conflicts with an agreed criterion | **Full** — the steps below | Full |

A light change request still starts from the delta (steps 1–2 below) and still records the change
in the folder — the next request is computed against it. If it turns out to need a decision, it
becomes a full one.

**A light example.** Marketing asks, in the original task, for the email field's label to read
"Your email". The spec records the label as fixed text, so the change shows against the record —
but the wording is given, it touches one component and its test, and no trigger applies:

```
Fast lane — the email field's label reads "Your email" instead of "Email address"; done when the form
shows it and the label test asserts it; files: NewsletterForm.client.tsx, NewsletterForm.test.tsx,
specs/007-newsletter-signup/spec.md (light CR 3).
```

`spec.md` gains, in the same commit as the change (`feat: label the newsletter email field "Your
email"`):

```markdown
# CR 3 — Email field label (2026-10-08) · light

- **Requested:** https://tracker.example.com/t/MKT-412 (comment of 2026-10-06) · Dana (marketing lead)

| Aspect | Delivered (CR 2, PR …) | Change |
| --- | --- | --- |
| Email field label | Fixed text "Email address" | Fixed text "Your email" |
```

— and the Design section's fixed-text line now reads "Your email" (CR 3). No plan, no gate: the
pull request's review approves the diff, and its URL joins `pull-requests:` as `· CR 3`.

## Steps — a full change request

1. **Triage** (`/triage`). Search `specs/` by tracker link, slug, and keywords;
   `git log -- specs/NNN-<slug>/` shows when each part landed. State the kind as a change request on
   that folder and the spec action as "amend as `CR N`".

2. **Find the delta.** Compare the request now with what the spec records as delivered —
   acceptance criteria, Out of scope, Clarifications, earlier `CR` sections — plus the tracker
   comments since the folder last changed (`git log -1 --format=%cs -- specs/NNN-<slug>/`). If the
   delta can't be recovered — no folder, or a description rewritten without a trace — say so and
   ask. Never reconstruct the old requirement from the code and present it as fact.

3. **Branch** — a fresh one that starts with the feature's slug and names the change
   (`feat/newsletter-signup-success-topics`), so branch, folder, and pull request still join — the
   session hook finds the folder by that prefix. Never reuse the feature's earlier branch: git keeps
   one after a squash merge, with pre-merge history, and work on it starts from old code.

4. **Amend the spec** (`/write-spec`, amend mode). Append a `CR N — <title> (date)` section to
   `spec.md`: where it was requested and by whom (a link, never a copy), the intent, and a
   **Delivered → Change** table. New acceptance criteria get new numbers tagged `(CR N)`; criteria
   the request retires are struck through, not deleted; Clarifications are appended, not replaced.
   Status goes to `in-review`.

5. **Plan the delta** (`/write-plan`). Extend `plan.md` and `tasks.md` with the CR's own part —
   change surface (read from the code, with shared code's other consumers), test strategy, docs
   plan, assumptions, tasks. The earlier parts stay as the record of what was built. Run
   `@spec-analyzer` on anything non-trivial.

6. **Approval gate — the same as for a new feature.** Scope (the CR's criteria and what stays out),
   change surface, assumptions. On sign-off: `status: approved`, an `approvals:` line ending
   `· CR N`, and one commit: `spec: approve <slug> CR N`.

7. **Docs first** (`/write-docs`) when the CR's plan lists pre-implementable docs — usually an
   existing doc gains a section. `docs:` commit.

8. **Implement task by task** (`/implement`): write the test, watch it fail, write the code, watch
   it pass, commit, tick. Tests for unchanged behavior stay as they are, and stay green. A test that
   pins behavior the CR must not break passes on its first run — expected for a test-only task
   (`test:`): break that behavior on purpose to see it fail, restore it, and say so in the gate
   results.

9. **Reconcile, verify, review** — docs checked against what was built; the full gate run and
   recorded under the CR's part of `tasks.md`, with `status: implemented` once every task is ticked;
   then `/review`.

10. **Deliver when asked.** `/open-pr` pushes and opens a **draft** naming `specs/NNN-<slug>/ (CR N)`
    — Claude Code asks you to confirm the push and the pull request — and records its URL in
    `pull-requests:` with `· CR N`. A human QCs the preview before it's marked ready; the agent runs
    `gh pr ready` only if that person asks. For a tracker task, `/stakeholder-update` drafts the reply
    when the developer asks.

### A legacy single-file spec

Repositories that adopted an older framework version have specs like `specs/newsletter-signup.md`.
They stay valid until the feature changes; the first change request moves the file into a folder
**in the same pull request**:

1. On the work branch, `git mv specs/newsletter-signup.md specs/007-newsletter-signup/spec.md` —
   `007` is the next free number; keep the slug.
2. Amend as above: add the frontmatter keys the current template has (`tracker:`, `approvals:`,
   `pull-requests:`), the `CR N` section, and a `plan.md` and `tasks.md` for the change. The move
   lands with everything else in the gate's `spec:` commit.
3. Don't rewrite the old sections into the new template. The move is a move: the delivered record
   stays as it was approved, and a file that stays mostly the same is still recognized as a rename,
   so `git log --follow` shows its whole history.

## Example

`specs/007-newsletter-signup/` holds the original delivery and CR 1, the optional topic checkboxes —
the [newsletter-topics example](../examples/newsletter-topics/) walks through that CR in full
([spec diff](../examples/newsletter-topics/spec-diff.md), [plan diff](../examples/newsletter-topics/plan-diff.md),
[tasks diff](../examples/newsletter-topics/tasks-diff.md)).

A week after CR 1 shipped, marketing edits the original tracker task — the description now says the
success message "lists the topics the reader chose" — and comments: *"This was in the brief; it seems to have
been missed."*

**Triage**

```
Triage — Newsletter signup: show the chosen topics after signing up (https://tracker.example.com/t/MKT-412)
- Deliverable: change
- Kind: change request on specs/007-newsletter-signup/ — CR 1 recorded a generic success message as the requester's decision
- Environment: needed later, for the TDD loop — not for planning
- Spec folder: amend specs/007-newsletter-signup/ as CR 2
- Open questions: 1) Is the lead-in ("You'll hear about:") editable in Contentful like the rest of the copy?
  2) With no topics chosen, does the message stay as it is?
- Next: /write-spec (CR 2), then /write-plan
```

**The delta.** The description was edited in place, so the tracker can't show what it said when
CR 1 was agreed. The spec can: CR 1's Clarifications record the question "Does the success message
vary by selected topics?" with the requester's answer — generic for this iteration — and Out of
scope lists per-topic success messages. So this is a new request, not a missed one, and the agent
can say so politely by pointing at the record, without arguing from what the code happens to do.

**The `CR 2` section** (excerpt):

```markdown
# CR 2 — Show the chosen topics after signing up (2026-10-01)

- **Requested:** https://tracker.example.com/t/MKT-412 (comment of 2026-09-29) · Dana (marketing lead)
- **Intent:** readers see what they signed up for, which marketing expects to reduce early unsubscribes.

| Aspect | Delivered (CR 1, PR #187) | Change |
| --- | --- | --- |
| Success message, topics chosen | Generic message from Contentful | Followed by an editable lead-in and the chosen topics' names |
| Success message, no topics chosen | Generic message | None |
| Copy model | No lead-in field | New optional lead-in field; when empty, topics are not listed |
```

New criteria go into Functional with the next free numbers:

```markdown
- **AC11 (CR 2)** — After a successful signup with topics chosen, the success message is followed by
  the lead-in from Contentful and the chosen topics' names, in form order, in the same status announcement.
- **AC12 (CR 2)** — After a successful signup with no topics chosen, the success message is unchanged.
```

**The gate** showed the change surface — the Contentful copy adapter, the client form component, the
admin guide and copy defaults, plus one change outside the repository: a new optional field on the
`newsletterSignup` content type, which marketing ops adds in the Contentful web app — and what stays
untouched: the signup route, the Mailchimp wrapper, rate limiting. One assumption was
written down for the developer to confirm: the lead-in is optional, so the code can ship before
marketing fills it in. The existing "no topics" test asserted only that the signup succeeds, so a
test-only task pins AC12's message before any code changes.

## Commits it produces

```
$ git log --oneline main..feat/newsletter-signup-success-topics
6b1d9e0 spec: link newsletter-signup CR 2 pull request
a47f3c2 docs: record newsletter-signup CR 2 gate results
51c08aa feat: list the chosen topics after a successful signup
c3f6e19 feat: add the topics lead-in to the signup copy model
9e2b7d4 test: pin the plain success message when no topics are chosen
0d8a2b7 docs: describe the topics lead-in in the admin guide
e19c4f5 spec: approve newsletter-signup CR 2
```

With a legacy single-file spec the history looks the same: the move is part of
`spec: approve newsletter-signup CR 2`.

## Common mistakes

| Mistake | What happens | Instead |
|---|---|---|
| Re-analyzing the task from scratch | Delivered scope is dropped or redone; the new analysis contradicts the record | Start from the spec folder and compute the delta |
| A precise adjustment through the full change request | Spec, plan, gate, and analyzer for a decision nobody had to make — several times the cost, no more defects found | A light `CR N` in the fast or careful lane |
| A decision passed off as a precise adjustment | The agent picks the behavior, and the light entry records a requirement nobody agreed | If you'd have to choose how it behaves, it's a full change request |
| Opening a new spec folder for the change | The feature's record splits; the next request has no single "delivered" to compare against | Amend the same folder with `CR N` |
| Reconstructing what was agreed from the code | An accident of implementation becomes a "requirement" | If the spec and the thread don't say, ask |
| Copying the tracker text into the CR section | Two versions of the requirement drift; client text lands in git | Link the comment; state the intent in a sentence |
| Renumbering or rewording delivered criteria | Tasks and tests that cite AC numbers point at the wrong thing | New numbers tagged `(CR N)`; strike through retired ones |
| Reusing the previous plan | The gate approves nothing new; the change surface goes unchecked | The CR gets its own plan, tasks, and `approvals:` line |
| Editing tests of unchanged behavior "while you're there" | Scope blurs; a regression hides in the noise | Add tests for the delta; old tests stay and stay green |
| Rewriting a legacy spec into the new template while moving it | The record of what was delivered changes, and git stops recognizing the move as a rename | Move it as it is; the CR section, plan, and tasks carry the change |

**Reference:** [`specs/README.md` § Change requests](../../skeleton/specs/README.md#change-requests) ·
[`/write-spec`](../../skeleton/.claude/skills/write-spec/SKILL.md) (amend mode) ·
[`/write-plan`](../../skeleton/.claude/skills/write-plan/SKILL.md) ·
the `CR N` template at the end of [`spec.md`](../../skeleton/specs/_templates/spec.md)
