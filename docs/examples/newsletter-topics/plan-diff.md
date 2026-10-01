# Plan diff — CR 1 on `specs/007-newsletter-signup/plan.md`

CR 1 changes the delivered [plan.md](../newsletter-signup/plan.md) in two places: the header's date,
and a `CR 1` section appended at the end. Everything above it stays as approved on 2026-06-09 — it
is the record of how the first delivery was built. (Its AC4 rows describe tests that CR 1 removes;
the CR 1 test strategy below names each one and the task that removes it.)

The appended section uses the same headings as the template, so the CR is planned — and checked at
the gate — with the same rigor as the original feature, but only for the delta.

## The header

```diff
 - **Spec:** ./spec.md · **Tasks:** ./tasks.md
-- **Last updated:** 2026-06-09
+- **Last updated:** 2026-09-16
```

## Appended to the end of `plan.md`

Everything below this line is the appended text.

---

# CR 1 — Topic preferences; one message for everyone

- **Spec:** ./spec.md § CR 1 · **Tasks:** ./tasks.md § CR 1

## Constitution check

Every principle in `docs/CONSTITUTION.md` was read against this section (2026-09-16).

- [x] No conflicts — or each conflict is listed below with its resolution
- [x] Security by default — topic IDs from the browser are checked against the entry; adding
      interests to an existing address without proof of ownership is an accepted risk, stated in
      spec § Security
- [x] Secrets — no new variables
- [x] Requirements not invented — AC7–AC10 trace to the MKT-412 description (rewritten 2026-09-14)
      and the comments of 2026-09-14 and 2026-09-15; everything else to spec § Clarifications
- [x] No new dependency — the subscriber hash is an MD5 from Node's `crypto`
- [x] Approved stack — nothing new
- [x] Accessibility — a `fieldset` with a legend; the `jsx-a11y` lint rules stay on
- [x] Types not silenced
- [x] No migrations in this change

## Approach

Topics are entries of a new Contentful type, `newsletterTopic`, listed in a new optional `topics`
field on the newsletter entry. The existing loader reads them, in order, with the rest of the copy.
The form shows them as checkboxes and sends the selected topics' **entry IDs** with the address. The
endpoint loads the entry itself, keeps only IDs that are in it, and maps them to Mailchimp group
IDs — so nothing the browser sends reaches Mailchimp unchecked.

The Mailchimp call changes from "add a member" (`POST /lists/{id}/members`) to "add or update a
member" (`PUT /lists/{id}/members/{hash}` with `status_if_new: "subscribed"`). One request covers
both cases: a new address is subscribed; an existing one keeps its status and gains the selected
interests, with none removed. The "already subscribed" outcome disappears — which is what AC10 asks
for — and so does the form's separate message (AC4, retired).

Rejected:

- Keep the `POST`, and on "Member Exists" send a second request to add the interests — two requests
  and two code paths for one outcome.
- Send Mailchimp group IDs from the browser — the server would have to check them anyway.
- Topics as a list of names on the newsletter entry — each topic needs its own group ID, and
  marketing wants to reorder and unpublish topics one at a time.
- Remove `alreadySubscribedMessage` from the content type in this change — the delivered code needs
  it until this code is live (see Rollout).

## Architecture & integrations

- **Topic** — `{ id, name, mailchimpGroupId }`. `lib/contentful/newsletter.ts` owns reading topics:
  published ones only, in the entry's order, at most six. The form uses `id` and `name`; only the
  endpoint uses `mailchimpGroupId`.
- **Signup request** — `{ email, topics? }`, where `topics` holds topic entry IDs. The endpoint owns
  turning them into interests.
- **Mailchimp** — `PUT /lists/{list_id}/members/{subscriber_hash}`, where the hash is the MD5 of the
  lowercased address, with `email_address`, `status_if_new: "subscribed"`, and
  `interests: { [groupId]: true }`. Mailchimp's screens call these *groups*; its API calls them
  *interests*. Error handling is as delivered: any error response or network failure raises
  `MailchimpUnavailableError` (AC6).
- **Must not leak:** as delivered — the Mailchimp key and response shapes stay inside
  `lib/newsletter/mailchimp.ts`.

## Change surface

Verified by reading the delivered loader, endpoint, Mailchimp client, and form, every caller of the
Mailchimp client, and the tests that use the newsletter fixtures.

| Area / layer | File (new / changed) | Why |
| --- | --- | --- |
| CMS (content model) | Contentful: new type `newsletterTopic`; new optional field `topics` on `newsletterSignup` — created by marketing ops, no repository file | AC7–AC9 |
| CMS | `lib/contentful/newsletter.ts` (changed) | AC7, AC8 — topics in the entry's order; `alreadySubscribedMessage` no longer required |
| Email provider | `lib/newsletter/mailchimp.ts` (changed — shared) | AC9, AC10 — one upsert with interests; the `already_subscribed` outcome goes away |
| API | `app/api/newsletter/route.ts` (changed) | AC9, Security — accept `topics`, keep only the entry's, map them to group IDs |
| UI | `components/NewsletterForm.client.tsx` (changed) | AC7, AC8, AC9, Accessibility — the topic group; AC10 — the already-subscribed state is removed |
| Tests | `lib/contentful/__tests__/newsletter.test.ts`, `lib/newsletter/__tests__/mailchimp.test.ts`, `app/api/newsletter/__tests__/route.test.ts`, `components/__tests__/NewsletterForm.test.tsx`, `e2e/newsletter-signup.spec.ts` (changed) | CR 1 test strategy; AC4's tests removed |
| Test fixtures | `tests/fixtures/contentful/newsletter-signup.with-topics.json` (new); `tests/msw/mailchimp.ts` (changed) | An entry with three topics; Mailchimp's handler for the upsert |
| Docs | `docs/admin/newsletter.md`, `docs/copy/newsletter-defaults.md` (changed, pre); `docs/runbooks/newsletter.md` (changed, post) | Documentation plan |

**Shared code and its other consumers:**

- `lib/newsletter/mailchimp.ts` — one consumer, the endpoint
  (`grep -rn "newsletter/mailchimp" app lib components` finds only `app/api/newsletter/route.ts`).
  Changing its request has no blast radius beyond this feature.
- `tests/fixtures/contentful/newsletter-signup.json` — the default entry every delivered newsletter
  test uses — is **not** changed. Topics live in a separate fixture, so the delivered tests run
  exactly as before, and that is AC8's proof. (Found by `@spec-analyzer`.)

**Not touched (deliberately):**

- `lib/newsletter/validate-email.ts` and `lib/newsletter/rate-limit.ts` — validation and rate
  limiting don't change.
- `components/NewsletterSignup.tsx` — it already passes the whole copy object to the form.
- `app/articles/[slug]/page.tsx` — placement doesn't change.
- `.env.example` — no new variables.
- The delivered tests for AC1–AC3, AC5, and AC6 — they must pass unedited.
- `alreadySubscribedMessage` in Contentful — removed only after this change is live.

## Data model & contracts

**Contentful — new content type `newsletterTopic`:**

| Field | Type | Required | Max length | Shown as |
| --- | --- | --- | --- | --- |
| `name` | Short text | Yes | 40 | The checkbox label |
| `mailchimpGroupId` | Short text | Yes | — | Not shown — the Mailchimp interest the topic records |

**Contentful — `newsletterSignup`:** a new field, `topics` — references to `newsletterTopic`,
optional, at most six. `alreadySubscribedMessage` stays, unread, until the cleanup after this
change.

**Endpoint — `POST /api/newsletter`:**

| Request | Responses |
| --- | --- |
| `{ "email": string, "topics"?: string[] }` — topic entry IDs | `200 { "status": "subscribed" }` for new and existing addresses — `already_subscribed` is no longer returned · `400`, `429`, and `502` as delivered |

Compatible in both directions during the deploy: a page rendered by the old code posts `{ email }`
(topics are optional), and the old form shows `subscribed` as success.

**Environment variables, Redis, database:** no changes.

## Test strategy

The same tools and mock layer as the first delivery. CR 1's tests use the new topics fixture; the
default fixture stays topic-free.

| Requirement | Test (file · name) | Type |
| --- | --- | --- |
| AC7 | `lib/contentful/__tests__/newsletter.test.ts` · "returns topics in the entry's order, skipping unpublished ones" | unit |
| AC7 | `components/__tests__/NewsletterForm.test.tsx` · "shows the configured topics as unchecked checkboxes in a group labeled Topics (optional)" | component |
| AC7, AC9 | `e2e/newsletter-signup.spec.ts` · "a reader picks two topics and subscribes" | e2e |
| AC8 | `newsletter.test.ts` · "returns an empty topic list when the entry has none" | unit |
| AC8 | `NewsletterForm.test.tsx` · "shows no topic group when the entry has no topics" | component |
| AC8 | `newsletter-signup.spec.ts` · "shows no topic group when none are configured" — and every delivered E2E test, unedited | e2e |
| AC9 | `lib/newsletter/__tests__/mailchimp.test.ts` · "sends the selected interests with status_if_new subscribed" | unit |
| AC9 | `app/api/newsletter/__tests__/route.test.ts` · "forwards the selected topics' group IDs as interests" | integration |
| AC9 | `NewsletterForm.test.tsx` · "sends the selected topic IDs with the email" | component |
| AC9 (none selected) | `route.test.ts` · "subscribes a valid email and returns 200 subscribed" — delivered, unedited: with no topics, `subscribe` still receives the address alone | integration |
| AC10 | `mailchimp.test.ts` · "returns subscribed for an address already on the list without changing its status" | unit |
| AC10 | `newsletter-signup.spec.ts` · "an address already on the list sees the success message" — replaces AC4's test | e2e |
| AC10 (rollout) | `newsletter.test.ts` · "returns the copy when alreadySubscribedMessage is empty" | unit |
| Edge: an unpublished topic | covered by AC7's loader test | unit |
| Edge: a topic that isn't in the entry (Security) | `route.test.ts` · "ignores topic IDs that aren't in the entry" | integration |
| Edge: Contentful unreachable on submit | `route.test.ts` · "subscribes without interests and logs newsletter.topics.unavailable when the entry can't be loaded" | integration |
| Edge: an address that unsubscribed earlier | covered by AC10's Mailchimp test — the request never sets `status` | unit |
| Accessibility: group, legend, labels | covered by AC7's component test, which finds the group and each checkbox by role and name | component |
| Accessibility: keyboard order with topics | `newsletter-signup.spec.ts` · "reaches the topics between the field and the button with the keyboard" | e2e |
| Accessibility: 44×44 px checkboxes | `newsletter-signup.spec.ts` · "topic checkboxes are at least 44×44 px on a 375 px viewport" | e2e |
| Testing: axe with topics | `newsletter-signup.spec.ts` · "has no axe violations with topics rendered" | e2e |
| Testing: screen reader with topics | VoiceOver pass on the preview, before the pull request is marked ready — needs a person | manual |
| Retired with AC4 | Removed in T110: `mailchimp.test.ts` · "maps Mailchimp's Member Exists response to already_subscribed" and `route.test.ts` · "returns 200 already_subscribed for an address already on the list". Removed in T122: `NewsletterForm.test.tsx` · "shows the already-subscribed message, not the success message". Replaced in T130: AC4's E2E test | — |
| Delivered tests that change | T110: `mailchimp.test.ts` · "subscribes a new address" (AC2) — its request assertion moves from `POST` to `PUT`; its outcome assertion stays. T122: `NewsletterForm.test.tsx` · "announces success and already-subscribed messages with role=status" narrows to "announces the success message with role=status". Every other delivered test runs unedited | — |

**Contract-first acceptance tests:** none.

## Documentation plan

| Doc | Audience | Pre / post | Task |
| --- | --- | --- | --- |
| `docs/admin/newsletter.md` — "Managing topics"; the "Already subscribed message" field marked as no longer shown | Site administrators (marketing) | pre | T101 |
| `docs/copy/newsletter-defaults.md` — a success message for new and existing subscribers alike | Marketing (copy) | pre | T102 |
| `docs/runbooks/newsletter.md` — looking up a group ID; checking a subscriber's topics; a wrong group ID | Operators / on-call | post | T141 |

## Rollout & deployment

1. Marketing ops adds the `newsletterTopic` type and the optional `topics` field in Contentful
   `sandbox`, then in `master`. This is safe before the deploy: the delivered code ignores fields it
   doesn't read.
2. Merge and deploy. With no topics in the entry, the form is unchanged (AC8).
3. Sam looks up the group IDs; marketing creates the topics (Tech, Business, Culture), adds them to
   the entry, and publishes. The topics appear within 5 minutes.
4. Only after step 2 is live: a separate content-model cleanup removes `alreadySubscribedMessage`.
   Before then, the delivered code would see an incomplete entry and hide the form on every article
   page (AC5).

**Rollback:** revert the deploy — the delivered code ignores topics, and interests already saved in
Mailchimp do no harm. Leave `alreadySubscribedMessage` in place until the change is final.

## Risks & mitigations

- Removing `alreadySubscribedMessage` too early hides the form site-wide — the rollout order above;
  the admin guide tells marketing to leave the field alone; the removal is a separate change. (Found
  by `@spec-analyzer`.)
- A topic with a wrong group ID makes Mailchimp reject the signups that pick it, and those readers
  see the error message (AC6) — the admin guide says to try a new topic on the preview before
  publishing it; the runbook shows what the log looks like.
- Anyone can add topics to an address on the list — accepted (spec § Security).

## Assumptions

- A6 — A `PUT` with `status_if_new` never changes an existing member's status. (Mailchimp's API
  reference.) The "unsubscribed earlier" edge case rests on it.
- A7 — A Mailchimp group keeps its ID when it is renamed. (Mailchimp's API reference.)
- A8 — Setting up the digest's segments in Mailchimp is marketing's work, not part of this change.
  (Dana.)

## Open questions

None — every answer is in spec.md § Clarifications.
