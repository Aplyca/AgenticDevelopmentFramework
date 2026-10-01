# Worked example: newsletter topics (a change request)

The sequel to [newsletter-signup](../newsletter-signup/README.md). Three months after the signup
form shipped, marketing wants readers to choose topics, and the privacy lead wants the form to stop
revealing who is on the list. Most day-to-day work looks like this: not a new feature, but a change
to one that is already delivered.

A change request is not a new feature, and treating it as one is how delivered scope gets silently
dropped or redone. The workflow is the same — triage, spec, plan, one gate, docs first, one TDD
commit per task, draft PR — with three differences:

1. **Triage finds the existing spec folder and computes the delta**: the request now, against what
   the spec records as delivered, plus the tracker comments since the folder last changed.
2. **The same folder is amended** with a `CR 1` section, new acceptance criteria tagged `(CR 1)`,
   and a retired criterion struck through — not deleted.
3. **The gate approves only the delta**, and the delivered tests for unchanged behavior run
   unedited — they are the proof that nothing else broke.

## The files in this folder

The three diff files show what CR 1 changed in the spec folder `specs/007-newsletter-signup/`. Read
them against the delivered files in [../newsletter-signup/](../newsletter-signup/).

| File | What it shows |
| --- | --- |
| [spec-diff.md](spec-diff.md) | The diff to `spec.md`: the `CR 1` section with its Delivered → Change table, AC7–AC10, AC4 struck through, the frontmatter's status and approvals |
| [plan-diff.md](plan-diff.md) | The `CR 1` section appended to `plan.md`: the change surface for the delta, test strategy rows, documentation plan, rollout |
| [tasks-diff.md](tasks-diff.md) | The `CR 1` tasks appended to `tasks.md` (T100–T142), ticked, with their gate results |

**People** (all fictional): **Dana**, marketing lead — the requester. **Lee**, privacy lead.
**Sam**, tech lead — the developer working with the agent.

---

## Starting state

`specs/007-newsletter-signup/` reads `status: implemented`, with one line in `approvals:` (initial
scope, 2026-06-09) and one in `pull-requests:` (#142). The form has been live since marketing
published the entry on 2026-06-22. AC1–AC6 are delivered and tested.

## The request

On 2026-09-14 Dana reopened [MKT-412](https://tracker.example.com/t/MKT-412) and rewrote its
description in place. The tracker keeps no history of descriptions — the original three sentences
are gone. The task now reads:

> Newsletter signup on every article page, copy editable in Contentful. Readers can choose which
> topics they want (Tech, Business, Culture — we'll manage the list in Contentful) so we can segment
> the Thursday digest in Mailchimp.

And there are comments:

> **2026-07-02, Dana:** The form has been live a week — 2.6% of readers who see it sign up.
>
> **2026-09-14, Dana:** Reopening for round two: topic choice. Please keep topics optional — we don't
> want fewer signups.
>
> **2026-09-15, Lee:** While you're in there: the "already subscribed" message tells anyone who
> types an address whether that person is on our list. Please show everyone the same thank-you
> message.
>
> **2026-09-15, Dana:** Agreed — go with Lee's version.

---

## Step 0 — Triage

```
/triage https://tracker.example.com/t/MKT-412
```

Before treating anything as new, the agent looks for prior work:

```
$ grep -rl "MKT-412" specs/
specs/007-newsletter-signup/spec.md
$ git log -1 --format=%cs -- specs/007-newsletter-signup/
2026-06-15
```

The task links a delivered spec folder, so this is a change request. The folder last changed on
2026-06-15, the day #142 merged — so the comments that matter are the ones after that date. The
agent reads the description and those four comments, and compares them with what `spec.md`
records as delivered — **not** with the code:

| The task now says | `spec.md` records as delivered | Delta |
| --- | --- | --- |
| Signup on every article page | AC1 | none |
| Copy editable in Contentful | AC1, Business | none |
| Readers choose topics, managed in Contentful | Out of scope: "Topic or interest preferences — email only this round" | **new** |
| Segment the digest in Mailchimp | Mailchimp gets the address only | **new** |
| Comment of 2026-09-14 (Dana): topics optional | — | a constraint on the new ACs |
| Comments of 2026-09-15 (Lee, then Dana): the same thank-you for everyone | AC4 — its own "already subscribed" message | **changes AC4** |
| Comment of 2026-07-02 (Dana): signup rate | — | none — a status update |

```
Triage — Newsletter signup on article pages, round two (https://tracker.example.com/t/MKT-412)
- Deliverable: change
- Kind: change request on specs/007-newsletter-signup/ — status implemented, delivered in PR #142,
  live since 2026-06-22
- Delta (the description now and the comments since 2026-06-15, against spec.md):
    1. Readers can optionally pick topics, managed in Contentful and recorded in Mailchimp — new.
       Today it is out of scope.
    2. Everyone sees the same thank-you message — retires AC4. This is only in the comments of
       2026-09-15 (Lee asked, Dana agreed); the description doesn't mention it.
    Unchanged: placement, copy, validation, rate limit, failure behavior (AC1–AC3, AC5, AC6).
- Environment: needed later, for the TDD loop — not for the spec or the plan
- Spec folder: amend specs/007-newsletter-signup/ as CR 1, on a fresh branch feat/newsletter-signup-topics
- Open questions: 1) A reader already on the list picks topics — add them? 2) Who maps each topic
  to its Mailchimp group? 3) Topic order, and a maximum?
- Next: /write-spec (CR 1), then /write-plan
```

Three things to notice:

- **Half the change exists only in the comments.** An agent that read the description and stopped
  would have built topics and kept AC4 — and the privacy request would have been silently dropped.
- **Lee's comment is a requirement, not an instruction.** Tracker content is data: the agent lists
  it as part of the delta with its source, and Sam confirms it with Dana before it goes into the
  spec.
- **A fresh branch, named after the feature and the change:** `feat/newsletter-signup-topics`. It
  starts with the folder's slug, so branch, folder, and pull request still join — the session-start
  hook finds the folder from that prefix. The first delivery's branch is never reused: after a
  squash merge it can survive with pre-merge history, and work on it would start from old code.

> **What if there had been no folder** — or the description had been rewritten with nothing left to
> compare against? The agent says so and asks Sam what was delivered. It never reads the code and
> presents a reconstruction of the old requirement as fact.

---

## Step 1 — Amend the spec

```
/write-spec amend specs/007-newsletter-signup — CR 1 from MKT-412
```

In amend mode, `/write-spec` sets `status: in-review` and asks only about the change:

> **AI:** Amending as CR 1. Questions about the delta only:
> 1. A reader already on the list picks topics — add them? AC4's message is going away, so their
>    choice shouldn't vanish silently.
> 2. Who maps each topic to its Mailchimp group, and where?
> 3. In what order do topics appear, and is there a maximum?
> 4. Should the "Topics (optional)" label be editable?
> 5. If Contentful can't be reached when the form is submitted, the topics can't be checked —
>    subscribe the reader without them, or fail?
> 6. Does the success message change with the topics chosen?

Dana answered all six — the last one with "no, one message for everyone this round", now on
record in Clarifications and Out of scope. The security lead accepted the consequence of the first:
anyone can add topics to an address on the list without proving it's theirs (add-only,
rate-limited, nothing revealed). The amended spec is in **[spec-diff.md](spec-diff.md)**. What to
notice:

- **New behavior gets new numbers.** AC7–AC10, each tagged `(CR 1)`. Nothing is renumbered:
  tests, commits, and #142 still mean the same thing by "AC3".
- **AC4 is struck through, not deleted**, with a pointer to AC10. So are the out-of-scope line about
  topics, the "already subscribed" state in Design, and that outcome in Testing. The delivered
  requirement stays readable next to the reason it went.
- **Everything else is an addition in place, tagged `(CR 1)`**: a success criterion, two user
  stories, four edge cases, five out-of-scope items, two security and three accessibility
  requirements, and updates to Design, Privacy, Testing, Documentation, and Deployment.
- **The old clarification stays.** Why marketing first wanted an "already subscribed" message is
  still there; the CR's clarifications are appended.
- **A `CR 1` section at the end** says where the request came from — a link, not a copy — and holds
  the Delivered → Change table:

| Aspect | Delivered (PR #142) | Change |
| --- | --- | --- |
| Topic choice | None — email only (Out of scope) | Optional checkboxes for the topics listed in the Contentful entry (AC7, AC8) |
| What Mailchimp records | A subscriber, with no interests | A subscriber, plus an interest for each selected topic (AC9) |
| An address already on the list | Its own "already subscribed" message (AC4) | The same success message as a new signup; selected topics are added (AC10 — AC4 retired) |
| Copy fields in Contentful | Six, all required | `alreadySubscribedMessage` is no longer shown; the field is removed after CR 1 is live |
| Placement, validation, rate limit, failure behavior | AC1–AC3, AC5, AC6 | None |

---

## Step 2 — Plan the delta

```
/write-plan specs/007-newsletter-signup
```

`/write-plan` reads the `CR 1` section first, then what was delivered — the folder's history and the
first plan — and then the code the delta touches. It appends a `CR 1` section to `plan.md`
([plan-diff.md](plan-diff.md)) and CR 1's tasks to `tasks.md` ([tasks-diff.md](tasks-diff.md)):

- **The change surface is small and explicit:** four source files change — the Contentful loader,
  the Mailchimp client, the endpoint, the form — and none are new. The Mailchimp client is shared
  code, so the plan names its consumers: one, the endpoint.
- **The approach changes one Mailchimp call** from "add a member" to "add or update a member", so a
  single request serves new and existing addresses, and the "already subscribed" outcome — AC4 —
  disappears by design.
- **The test strategy maps the retirement too:** each of AC4's four tests is listed with the task
  that removes or replaces it.
- **Tasks start at T100**, so the first delivery's T000–T042 keep their IDs and their June evidence.

---

## Step 3 — The independent check

```
@spec-analyzer specs/007-newsletter-signup

[critical] plan.md § CR 1 › Rollout & deployment, step 1 — "Marketing ops adds newsletterTopic and
  the topics field, and removes alreadySubscribedMessage." The delivered loader treats an entry
  without alreadySubscribedMessage as incomplete (lib/contentful/newsletter.ts:31) and returns
  null, so AC5 hides the section. Until the CR 1 code is live, every article page would lose the
  form.
  Fix: keep the field through this change and remove it in a separate cleanup once CR 1 is live;
  add a loader test showing the new code no longer needs it.

[gap] plan.md § CR 1 › Change surface — adds three topics to the default fixture,
  tests/fixtures/contentful/newsletter-signup.json. The delivered E2E test "reaches the field and
  the button in order with the keyboard" tabs from the field straight to the button; with topics on
  screen it fails. AC8 says that without topics the form "works exactly as delivered" — the
  delivered tests can only prove it if they still run against a topic-free entry.
  Fix: put the topics in a separate fixture and leave the default alone.

[question] spec.md AC10 — an address that unsubscribed earlier: the upsert keeps it unsubscribed,
  yet the reader sees the success message. Acceptable, or should it be resubscribed — which needs
  Mailchimp's confirmation email, and double opt-in is out of scope?

ACs: 4/4 new mapped; AC4's retirement traced to its tests · testable requirements: 7/7 · docs: 3/3
Verdict: NOT READY — 1 critical.
```

The critical finding is the change-request version of a classic mistake. "Content model first, then
code" is the usual safe order — and for a *removal* it is exactly backwards: the old code still
reads the field. The fix is the expand-then-contract order now in the plan: keep the field, ship
the code that no longer needs it, then remove the field in a separate change.

The agent applied the fix and the gap; Dana answered the question (no — they see the success
message and stay unsubscribed), and the answer became an edge case and a clarification. A second
run returned **READY FOR THE GATE**.

---

## Step 4 — The gate, for the delta

The gate shows only what CR 1 changes:

> **AI:** Approval gate — CR 1 on `specs/007-newsletter-signup/`
>
> **Scope.** In: AC7–AC10 — optional topics from Contentful, recorded as Mailchimp interests; one
> success message for everyone, with topics added for addresses already on the list. Retired: AC4.
> Unchanged: AC1–AC3, AC5, AC6. Out: removing topics, backfills, resubscribing addresses that
> unsubscribed, pre-selected topics.
>
> **Change surface.** Four changed source files — the loader, the Mailchimp client (one consumer:
> the endpoint), the endpoint, the form — and none new. Five test files, two fixtures (one new; the
> default untouched), three docs. In Contentful, a new type and a new optional field, by marketing
> ops. Not touched: validation, rate limiting, the section component, the article page,
> `.env.example`, and the delivered tests for AC1–AC3, AC5, and AC6.
>
> **Assumptions.** A6 — a `PUT` with `status_if_new` never changes an existing member's status.
> A7 — a group keeps its ID when renamed. A8 — the digest's segments are marketing's work.
>
> **Risks.** Removing `alreadySubscribedMessage` before this ships would hide the form everywhere —
> the rollout keeps it until a later cleanup. A wrong group ID makes signups with that topic fail.
> Anyone can add topics to an address on the list (accepted).
>
> **Verification.** Every new AC and edge case maps to a test. Of the 49 delivered tests, four go
> with AC4 and two are adjusted, each in a named task; the other 43 must pass unedited.
>
> **Docs first.** "Managing topics" in the admin guide and one new default in the copy doc. After
> the code: the runbook.
>
> No implementation code until you approve. Reply with changes, or approve.

> **Sam:** One question. During the deploy, readers will have pages from the old code open. What
> happens when they submit?
>
> **AI:** The old page posts `{ email }` with no topics — the new endpoint treats topics as
> optional — and gets `{ "status": "subscribed" }`, which the old form shows as success. The
> endpoint never sends `already_subscribed` any more, so an old page can't show the retired
> message. It's compatible both ways; `plan.md` § CR 1 › Data model & contracts says so.
>
> **Sam:** Approved.

The agent sets `status: approved`, adds the second sign-off below the first, ticks T100, and
commits:

```yaml
approvals:
  - "2026-06-09 · Sam (tech lead) · initial scope"
  - "2026-09-17 · Sam (tech lead) · CR 1"
```

```bash
git commit -m "spec: approve newsletter-signup CR 1"
```

---

## Step 5 — Docs first, for the changed behavior only

`/write-docs` updates the docs whose behavior changes and leaves the rest of each file alone. The
admin guide gains a section:

```markdown
## Managing topics

Readers can pick the topics they want when they sign up. Each topic is a **Newsletter Topic**
entry; the form shows the topics listed in the **Topics** field of the Newsletter Signup entry, in
that order — up to six. With no topics listed, the form has no topic section at all.

To add a topic:

1. Ask the web team for the topic's **Mailchimp group ID**. Mailchimp doesn't show these IDs on
   screen.
2. Create a Newsletter Topic entry with the **Name** readers will see (up to 40 characters) and the
   group ID, and publish it.
3. Add it to the **Topics** field of the Newsletter Signup entry, and publish that entry. The topic
   appears within 5 minutes.

Try a new topic on the preview site before publishing it on the live site: if its group ID is
wrong, Mailchimp rejects every signup that picks it, and those readers see your Error message.
```

…and marks the **Already subscribed message** field as no longer shown, with a warning to leave it
in place. In the copy defaults, the suggested success message changes from "You're subscribed!" —
odd for someone already on the list — to "Thanks for signing up — look out for the Thursday
digest." Both land in one commit: `docs: add marketing docs for newsletter-signup CR 1`.

---

## Step 6 — One commit per task

The loop is the same as in the first delivery: write the task's test, watch it fail for the right
reason, write the code, watch it pass, commit. One task in detail — the one that retires AC4.

### T110 — the Mailchimp client becomes an upsert

Two new tests in the existing file:

```ts
it('sends the selected interests with status_if_new subscribed', async () => {
  await subscribe('reader@example.com', { interests: ['9f3ab1c2d4', 'b72e0d5a19'] });

  const request = mailchimpRequests.last();
  expect(request.body.interests).toEqual({ '9f3ab1c2d4': true, 'b72e0d5a19': true });
  expect(request.body.status_if_new).toBe('subscribed');
});

it('returns subscribed for an address already on the list without changing its status', async () => {
  mailchimpAudience.add('existing@example.com', { status: 'subscribed' });

  await expect(subscribe('existing@example.com')).resolves.toBe('subscribed');
  expect(mailchimpRequests.last().body).not.toHaveProperty('status');
});
```

```
 FAIL  lib/newsletter/__tests__/mailchimp.test.ts > subscribe > sends the selected interests with status_if_new subscribed
AssertionError: expected undefined to deeply equal { '9f3ab1c2d4': true, 'b72e0d5a19': true }

 FAIL  lib/newsletter/__tests__/mailchimp.test.ts > subscribe > returns subscribed for an address already on the list without changing its status
AssertionError: expected 'already_subscribed' to be 'subscribed' // Object.is equality

      Tests  2 failed | 4 passed (6)
```

Red for the right reasons: the delivered client sends no interests, and reports an existing
address as `already_subscribed`. After the change to `PUT`, the two new tests pass — and two
delivered tests now assert retired behavior. Removing them is not weakening tests to get to green:
the requirement they encode, AC4, was retired at the gate, and the commit says so:

```
feat: upsert Mailchimp members with their topic interests

One PUT with status_if_new replaces the POST: a new address is
subscribed; an existing one keeps its status and gains the selected
interests, none removed (AC9, AC10).

AC4 was retired by CR 1 (approved 2026-09-17). Removes the two tests
that asserted the already_subscribed outcome, in mailchimp.test.ts and
route.test.ts. "subscribes a new address" now checks the PUT request;
its outcome assertion is unchanged.
```

### The rest

- **T111** — the loader reads topics, and no longer requires `alreadySubscribedMessage` — with the
  test the analyzer asked for, so the field can be removed later without hiding the form.
- **T120** — the endpoint keeps only topics that are in the entry; a crafted ID is ignored.
- **T121** — the form's topic group. One new test passed before any code: "shows no topic group
  when the entry has no topics". The delivered form never renders one, so the behavior already
  exists — that is AC8 holding, and the test stays as its guard.
- **T122** — `refactor:` — the form's already-subscribed state was unreachable since T110; it goes,
  with its test. Behavior doesn't change; the tests stay green throughout.
- **T130** — six end-to-end tests, including the replacement for AC4's. Run against `main`'s build,
  five failed as they should; AC8's passed there — the delivered form has no topic group, which is
  exactly AC8.

---

## Step 7 — Reconcile, record, review

**Reconcile (T140).** Nine claims in the new admin-guide section and the copy change, checked
against the build: all hold. Nothing to commit — T140 is ticked with the gate results. Not every
reconciliation finds something; it still has to be done. **Runbook (T141):** how to look up a group
ID, check a subscriber's topics, and recognize a wrong group ID in the logs.

**Gate results (T142)** — the full table is in [tasks-diff.md](tasks-diff.md#gate-results-2026-09-18).
The line that matters most for a change request:

```markdown
- 43 of the 49 delivered newsletter tests — those for AC1–AC3, AC5, AC6, and their security,
  privacy, and accessibility requirements — passed without an edit. Of the other six, four went
  with AC4 and two were adjusted in T110 and T122, as the plan says.
```

The same commit sets `status: implemented` — `docs: record newsletter-signup CR 1 gate results`.

**Review.** `/review` checks the diff against the CR 1 change surface (every file inside it), the
commits against the tasks, AC7–AC10 against the code, and AC4's retirement against the tests that
went with it. Verdict: approve with one nit — the route tests hard-code the topic IDs that the new
fixture already defines. Sam left it for a later tidy-up.

---

## Step 8 — Draft pull request

When Sam asks, `/open-pr` pushes the branch and opens draft #187:

```markdown
feat: add newsletter topic preferences (CR 1)

## Traceability
**Spec:** `specs/007-newsletter-signup/` (CR 1)
**Tracker task:** https://tracker.example.com/t/MKT-412

## What changed and why
Marketing wants to segment the Thursday digest by interest, and privacy asked that the form stop
revealing whether an address is on the list (MKT-412: the description and the comments of
2026-09-14 and 2026-09-15). When the Contentful entry lists topics, the form now shows them as
optional checkboxes and records the chosen ones as Mailchimp interests. The Mailchimp call is now a
single "add or update", so an address already on the list gets the same success message as a new
one, and its chosen topics are added (AC4 retired; AC7–AC10 added). The endpoint accepts only topics
that are in the entry.

With no topics in the entry the form is unchanged, and the delivered tests prove it, unedited. Every
changed file is inside the CR 1 change surface approved on 2026-09-17. Deploy order: the new type
and field in Contentful `master` before merging; do **not** remove `alreadySubscribedMessage` until
this is live — the current code needs it.

## How to verify
1. On the preview (Contentful `sandbox` has three topics), open an article: three unchecked topics
   under "Topics (optional)".
2. Pick two and subscribe with a `+test` address; in Mailchimp, the member has those two groups.
3. Submit the same address with a third topic: the same success message; the member now has three.
4. Remove the topics from the `sandbox` entry: within 5 minutes, the form has no topic group.

**Tests:** 17 new, 2 changed, 4 removed with AC4 — mapped in `plan.md` § CR 1 › Test strategy.

## Verified / not verified
- Verified: lint, typecheck, and build; Vitest 52 files / 287 tests; Playwright on Chromium, 32
  tests including axe with topics on screen; 43 of the 49 delivered newsletter tests pass unedited
  (four went with AC4, two were adjusted as planned) — `tasks.md` § CR 1 › Gate results.
- Not verified: a real Mailchimp update with real group IDs; the VoiceOver pass over the topic
  group; WebKit and Firefox (CI only).

## Screenshots
From the local Playwright run at 375 px and 1280 px: the form with three topics; the success message.
```

The agent records #187 in `spec.md` (`spec: link newsletter-signup CR 1 pull request`) — a second
line under `pull-requests:`, below #142. Sam QC'd the preview the next working day, VoiceOver
included, and asked the agent to push the link commit and mark the pull request ready. It merged on
2026-09-21.

---

## Step 9 — Close the loop

```
/client-update MKT-412 187
```

> **For the team:** suggested reply for the tracker task [Newsletter signup on article pages](https://tracker.example.com/t/MKT-412).
>
> ---
>
> Hi Dana and Lee,
>
> Here's a quick update on newsletter topics.
>
> Readers can now pick the topics they're interested in when they sign up, and their choices are
> saved to your Mailchimp groups, ready for segmenting the Thursday digest. Picking a topic is
> optional. As Lee asked, everyone now sees the same thank-you message, whether or not they were
> already on the list — and people already on the list who pick topics get those topics added.
>
> This is live. The form looks exactly as before until topics are added to the
> [Newsletter Signup entry](https://app.contentful.com/spaces/SPACE_ID/entries/ENTRY_ID); they
> appear within five minutes of publishing.
>
> We noticed a few things along the way:
>
> - **People who unsubscribed in the past and sign up again** see the thank-you message but stay
>   unsubscribed: resubscribing someone needs a confirmation email from Mailchimp, which we kept out
>   of scope. Tell us if you'd like that next.
> - **The "Already subscribed message" field** in the entry is no longer shown. Please leave it in
>   place for now — we'll let you know when it can go.
>
> 1 question for you:
>
> 1. **Setting up topics:** each topic needs its group ID from Mailchimp, which Mailchimp doesn't
>    show on screen. Shall we create Tech, Business, and Culture for you as drafts, ready for you to
>    publish?
>
> Thanks!

---

## What did not change — and why that matters

| Unchanged | Why it matters |
| --- | --- |
| The text of AC1–AC3, AC5, and AC6, and 43 of the 49 delivered tests — not a line edited | They are the regression check. If CR 1 had broken placement, validation, or failure handling, a test written in June would have gone red. The other six are accounted for: four went with AC4, two were adjusted in named tasks |
| `validate-email.ts`, `rate-limit.ts`, `NewsletterSignup.tsx`, the article page, `.env.example` | The reviewer reads four source files, not nine; the blast radius is the one the gate approved |
| The default test fixture, still without topics | AC8 — "works exactly as delivered" — is proved by the delivered tests, not merely asserted by new ones |
| Security's rate limit and validation; Privacy's IP handling; the Constraints section | The CR's security and privacy review covers only what is new |
| The first plan and T000–T042, with their gate results | The folder keeps both stories: June's evidence for AC1–AC6, September's for AC7–AC10 |
| The rest of the admin guide and the runbook | Docs for unchanged behavior aren't rewritten |
| `alreadySubscribedMessage` in Contentful | Expand, then contract: the field goes only after the code that needed it is gone |

## The history

```
$ git log --oneline main..feat/newsletter-signup-topics
d4a1f07 spec: link newsletter-signup CR 1 pull request
a93c2e5 docs: record newsletter-signup CR 1 gate results                 T140, T142 · status: implemented
5f17b0c docs: add topic checks to the newsletter runbook                 T141
e2c84d9 test: cover newsletter topics end to end                         T130
71b5e3a refactor: remove the retired already-subscribed state from the form   T122
c06f9a4 feat: let readers pick newsletter topics                         T121
9d2e7b1 feat: keep only the entry's topics when subscribing              T120
4b8a0f6 feat: load newsletter topics from Contentful                     T111
f3e9c25 feat: upsert Mailchimp members with their topic interests        T110
8a6d1e4 docs: add marketing docs for newsletter-signup CR 1              T101, T102
2f0c7d3 spec: approve newsletter-signup CR 1                             T100
```

Two pull requests, one folder. `spec.md` now records the first delivery and CR 1 — two approval
lines, two pull-request lines, AC4 visibly retired — so the next person to change this feature
starts from an accurate record of what it does and why.

## Compared with the first delivery

| | First delivery (#142) | CR 1 (#187) |
| --- | --- | --- |
| Triage | New feature, new folder | Change request: the delta from the spec and the comments |
| `spec.md` | Every section written | 11 sections amended in place, tagged `(CR 1)`; AC4 and three related lines struck through; a `CR 1` section appended |
| Acceptance criteria | AC1–AC6 | AC7–AC10 added; AC4 retired |
| Change surface | 7 new source files, 2 changed shared files | 4 changed source files, none new |
| Tests | 49 new | 17 new, 2 changed, 4 removed with AC4; 43 untouched |
| Tasks and commits | 15 tasks, 14 task commits | 12 tasks, 10 task commits |
| What `@spec-analyzer` caught | A cache setting that would have changed every article page | A removal ordered before the code that still needed it |
| The gate | Scope, change surface, five assumptions | The delta only: four ACs, one retirement, four files, three assumptions |

The skills and the gate are the same. What keeps a change request from turning into a rewrite is
where the scope comes from: the delta against the spec as delivered.
