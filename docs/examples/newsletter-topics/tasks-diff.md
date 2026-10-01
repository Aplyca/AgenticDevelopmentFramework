# Tasks diff — CR 1 on `specs/007-newsletter-signup/tasks.md`

CR 1 changes the delivered [tasks.md](../newsletter-signup/tasks.md) in two places: the header's
date, and a `CR 1` section appended at the end. T000–T042 stay as they are, ticked, with their gate
results — the June evidence for AC1–AC6. The CR's evidence sits beside it, not on top of it.

CR 1's task IDs start at T100, so the first delivery's IDs stay stable — the same rule as AC
numbers.

## The header

```diff
 - **Spec:** ./spec.md · **Plan:** ./plan.md
 - **Branch:** `feat/newsletter-signup`
-- **Last updated:** 2026-06-11
+- **Last updated:** 2026-09-18
```

## Appended to the end of `tasks.md`

Everything below this line is the appended text.

---

# CR 1 — Topic preferences; one message for everyone

- **Spec:** ./spec.md § CR 1 · **Plan:** ./plan.md § CR 1
- **Branch:** `feat/newsletter-signup-topics` — a fresh branch that starts with the folder's slug and
  names the change

## Phase 0 — Approval

- [x] T100 — CR 1 approved at the gate (scope, change surface, assumptions) and committed (`spec:`)

## Phase 1 — Docs first

- [x] T101 — Admin guide: "Managing topics", and the "Already subscribed message" field marked as no
      longer shown (→ AC7, AC8, AC9, AC10)
- [x] T102 — Copy defaults: a success message for new and existing subscribers alike (→ AC10)

## Phase 2 — Foundation

- [x] T110 — Mailchimp client: one upsert, with interests, for new and existing addresses (test:
      `lib/newsletter/__tests__/mailchimp.test.ts` · "sends the selected interests with
      status_if_new subscribed", "returns subscribed for an address already on the list without
      changing its status") (→ AC9, AC10; removes AC4's two tests)
- [x] T111 [P] — The loader reads topics; `alreadySubscribedMessage` is no longer required (test:
      `lib/contentful/__tests__/newsletter.test.ts` · "returns topics in the entry's order, skipping
      unpublished ones", "returns an empty topic list when the entry has none", "returns the copy
      when alreadySubscribedMessage is empty") (→ AC7, AC8, AC10)

## Phase 3 — Stories (TDD, one commit per task)

- [x] T120 — The endpoint accepts topics and keeps only the entry's (test:
      `app/api/newsletter/__tests__/route.test.ts` · "forwards the selected topics' group IDs as
      interests", "ignores topic IDs that aren't in the entry", "subscribes without interests and
      logs newsletter.topics.unavailable when the entry can't be loaded") (→ AC9, Security)
- [x] T121 — The form shows the topic group and sends the selection (test:
      `components/__tests__/NewsletterForm.test.tsx` · "shows the configured topics as unchecked
      checkboxes in a group labeled Topics (optional)", "shows no topic group when the entry has no
      topics", "sends the selected topic IDs with the email") (→ AC7, AC8, AC9, Accessibility)
- [x] T122 — Remove the retired already-subscribed state from the form (refactor:
      `components/__tests__/NewsletterForm.test.tsx` stays green; AC4's test is removed) (→ AC10)

## Phase 4 — Acceptance

- [x] T130 — End-to-end tests for topics, the single success message, keyboard order, target size,
      and axe; AC4's test replaced (test: `e2e/newsletter-signup.spec.ts` — six tests) (→ AC7, AC8,
      AC9, AC10, Accessibility)

## Phase 5 — Reconcile & polish

- [x] T140 — Reconcile committed docs with what was built (→ Documentation)
- [x] T141 — Post-implementable docs: the runbook — looking up a group ID, checking a subscriber's
      topics, a wrong group ID (→ Documentation)
- [x] T142 — Record gate results below

## Verification checklist (each checkpoint)

- [x] Lint clean — `pnpm lint`
- [x] Typecheck clean — `pnpm typecheck`
- [x] Unit / integration tests passing — `pnpm test`
- [x] End-to-end tests passing — `pnpm test:e2e` (Chromium; WebKit and Firefox run in CI only, see
      below)
- [x] Every acceptance criterion met; every filled spec section addressed
- [x] Security and accessibility reviewed — `/review`, 2026-09-18; the VoiceOver pass is listed
      below as not run

## Gate results (2026-09-18)

**Baseline** — `main` on 2026-09-16, before T110: `pnpm test` — 52 files, 279 tests passing.
`pnpm test:e2e` — 5 files, 27 tests passing. Lint and typecheck clean. No pre-existing failures.

**Red, then green, per task.**

| Task | Red | Green |
| --- | --- | --- |
| T110 | `mailchimp.test.ts` — 2 failed, 4 passed. `expected undefined to deeply equal { '9f3ab1c2d4': true, 'b72e0d5a19': true }` (the request carried no interests); `expected 'already_subscribed' to be 'subscribed'` | 5 passed. Removed with AC4: "maps Mailchimp's Member Exists response to already_subscribed" and, in `route.test.ts`, "returns 200 already_subscribed for an address already on the list". "subscribes a new address" now checks the `PUT` request; its outcome assertion is unchanged |
| T111 | `newsletter.test.ts` — 3 failed. First: `expected undefined to deeply equal [ { id: 'topic-tech', name: 'Tech', … }, … ]`; also `expected null not to be null` | 8 passed |
| T120 | `route.test.ts` — 3 failed. First: `expected "subscribe" to be called with arguments: [ 'reader@example.com', { interests: [ '9f3ab1c2d4', 'b72e0d5a19' ] } ]` | 10 passed |
| T121 | `NewsletterForm.test.tsx` — 2 failed, 1 passed. First: `Unable to find an accessible element with the role "group" and name "Topics (optional)"`. "shows no topic group when the entry has no topics" passed before any T121 code: the delivered form never renders one. That is AC8 holding, not a wrong test; it stays as AC8's guard | 11 passed |
| T122 | Refactor — no red. `NewsletterForm.test.tsx` green before and after; AC4's test removed, and "announces success and already-subscribed messages with role=status" narrowed to "announces the success message with role=status" | 10 passed |
| T130 | E2E — the 6 new tests passed on their first run: the behavior was built in T110–T122. Against `main`'s build, 5 of the 6 failed, as they should; AC8's passed there, because the delivered form has no topic group — which is exactly AC8 | 15 passed |

**Docs.** T140: the 9 claims in the new admin-guide section and the copy change were checked
against the build. All hold, so there was nothing to commit; T140 is ticked in the gate-results
commit. T141: the runbook section was written from the built endpoint and Mailchimp client.

**Full gate** (`pnpm verify`):

- `pnpm lint` and `pnpm typecheck` — clean
- `pnpm test` — 52 files, 287 tests passed (279 before; 11 new; 3 removed with AC4)
- `pnpm build` — succeeded
- `pnpm test:e2e` — 5 files, 32 tests passed on Chromium (27 before; 6 new; 1 removed with AC4),
  including the axe scan with topics on screen
- 43 of the 49 delivered newsletter tests — those for AC1–AC3, AC5, AC6, and their security,
  privacy, and accessibility requirements — passed without an edit. Of the other six, four went
  with AC4 and two were adjusted in T110 and T122, as the plan says.

**Not run here, and why:**

- The end-to-end suite between T110 and T130 — it needs the app running and isn't part of the
  per-task loop. In those commits AC4's delivered end-to-end test no longer matched the code — as
  expected, since T110 retired AC4's behavior; T130 replaced it.
- A real Mailchimp upsert with real group IDs — tests mock Mailchimp. Checked on the preview, which
  needs the three topics in Contentful `sandbox`.
- The VoiceOver pass over the topic group — needs a person; before the pull request is marked
  ready.
- End-to-end runs on WebKit and Firefox — the project runs them in CI only.

**Pre-existing failures:** none.
