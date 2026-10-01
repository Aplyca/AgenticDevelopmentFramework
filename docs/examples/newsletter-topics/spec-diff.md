# Spec diff — CR 1 on `specs/007-newsletter-signup/spec.md`

This is how CR 1 changed the delivered spec — the [spec.md](../newsletter-signup/spec.md) in the
first example — as committed at the CR 1 approval gate (`spec: approve newsletter-signup CR 1`).
Two smaller changes came later in the branch; they are at the end.

The spec was **amended, not rewritten**. Every change is either an addition tagged `(CR 1)` or a
retirement struck through in place, and the request itself is summarized in a `CR 1` section
appended to the end of the file. Nothing delivered was deleted: AC4's text is still there, struck
through, because tests, commits, and the first pull request refer to it by number.

## Status along the way

| Date | `status` | Set by |
| --- | --- | --- |
| 2026-06-11 | `implemented` | `/implement`, in the first delivery's gate-results commit |
| 2026-09-16 | `in-review` | `/write-spec`, when it appended CR 1 — in the working tree only, never committed |
| 2026-09-17 | `approved` | `/write-plan`, at the CR 1 gate — the diff below |
| 2026-09-18 | `implemented` | `/implement`, in the CR 1 gate-results commit — see the end of this page |

Each sign-off is its own line in `approvals:`; the first one stays.

## The diff

```diff
diff --git a/specs/007-newsletter-signup/spec.md b/specs/007-newsletter-signup/spec.md
index 5d1c0e2..8b3f7a9 100644
--- a/specs/007-newsletter-signup/spec.md
+++ b/specs/007-newsletter-signup/spec.md
@@ -2,5 +2,5 @@
 title: "Newsletter signup on article pages"
 area: "marketing"
-status: implemented
+status: approved
 feature-type: ui
 personal-data: yes
@@ -8,4 +8,5 @@ tracker: "https://tracker.example.com/t/MKT-412"
 approvals:
   - "2026-06-09 · Sam (tech lead) · initial scope"
+  - "2026-09-17 · Sam (tech lead) · CR 1"
 pull-requests:
   - "https://github.com/<org>/marketing-site/pull/142 · initial delivery"
@@ -47,4 +48,6 @@ go to Mailchimp, the team's email provider.
 - Marketing changes the form's copy in Contentful and sees it on the site within 5 minutes, with
   no deploy.
+- (CR 1) Within 60 days of adding topics, at least 40% of new subscribers pick one, and the share
+  of readers who subscribe stays at 2% or more.
 
 ## Functional [REQUIRED]
@@ -59,4 +62,8 @@ go to Mailchimp, the team's email provider.
 - As an **operator**, I want the form to fail safely when Contentful or Mailchimp is down, so that
   an outage never breaks an article page.
+- (CR 1) As a **reader**, I want to choose the topics I hear about, so that the newsletter stays
+  relevant to me.
+- (CR 1) As a **marketer**, I want to manage the topic list in Contentful, so that I can add,
+  rename, or retire topics without a deploy.
 
 ### Acceptance criteria
@@ -72,6 +79,7 @@ reference these IDs. Change requests add new numbers and tag them `(CR N)`.
 - **AC3** — Submitting an empty or malformed email address shows an inline error next to the field,
   sends nothing, and moves focus to the field.
-- **AC4** — Submitting an address that is already on the list replaces the form with the "already
-  subscribed" message from the Contentful entry, not the success message.
+- ~~**AC4** — Submitting an address that is already on the list replaces the form with the "already
+  subscribed" message from the Contentful entry, not the success message.~~ _Retired by CR 1 —
+  replaced by AC10._
 - **AC5** — When the newsletter entry can't be loaded — Contentful unreachable, the entry
   unpublished, or a required field empty — article pages render without the newsletter section and
@@ -79,4 +87,15 @@ reference these IDs. Change requests add new numbers and tag them `(CR N)`.
 - **AC6** — When Mailchimp fails or can't be reached, the form shows the error message from the
   Contentful entry, keeps the typed address, and lets the reader submit again.
+- **AC7** (CR 1) — When the newsletter entry lists topics, the form shows each one as an unchecked
+  checkbox, in the entry's order, inside a group labeled "Topics (optional)", between the email
+  field and the button.
+- **AC8** (CR 1) — When the entry lists no topics, the form shows no topic group and works exactly
+  as delivered.
+- **AC9** (CR 1) — Submitting a valid address with topics selected records each selected topic as
+  an interest of the subscriber in Mailchimp; submitting with none selected subscribes the address
+  with no interests.
+- **AC10** (CR 1) — Submitting an address that is already on the list shows the same success
+  message as a new signup; any selected topics are added to that subscriber's interests, and none
+  are removed.
 
 ### Edge cases
@@ -90,4 +109,11 @@ reference these IDs. Change requests add new numbers and tag them `(CR N)`.
 - A reader over the rate limit → the error message from the entry, with the address kept (see
   Clarifications).
+- (CR 1) A topic entry that is unpublished or deleted → it doesn't appear in the form.
+- (CR 1) A submission naming a topic that isn't in the entry — a stale page or a crafted request →
+  that topic is ignored; the signup goes ahead.
+- (CR 1) Contentful can't be reached when the form is submitted → the reader is subscribed without
+  topics, and the failure is logged.
+- (CR 1) An address that unsubscribed earlier → the success message; Mailchimp keeps it
+  unsubscribed.
 
 ## Out of scope [REQUIRED]
@@ -95,8 +121,15 @@ reference these IDs. Change requests add new numbers and tag them `(CR N)`.
 - Double opt-in confirmation emails — the audience is single opt-in.
 - A preferences or unsubscribe page — Mailchimp's links in every email cover it.
-- Topic or interest preferences — email only this round.
+- ~~Topic or interest preferences — email only this round.~~ _Brought into scope by CR 1._
 - Backfilling subscribers from any earlier list.
 - Per-article copy — an A/B test changes the copy on every article at once.
 - Analytics events — the analytics platform is being chosen in a separate spec.
+- (CR 1) Removing topics from a subscriber — readers change topics through Mailchimp's preference
+  link.
+- (CR 1) Backfilling topics for existing subscribers.
+- (CR 1) Resubscribing an address that unsubscribed earlier — it needs Mailchimp's confirmation
+  email, which is double opt-in.
+- (CR 1) Pre-selecting topics from the article's category.
+- (CR 1) Per-topic success messages — the success message is the same whatever topics are chosen.
 
 ---
@@ -108,16 +141,18 @@ reference these IDs. Change requests add new numbers and tag them `(CR N)`.
 > Owned by: designer
 
-- **Mockups:** the Figma file in `references.figma`.
+- **Mockups:** the Figma file in `references.figma`. (CR 1) The topic group: its "Topics" frame.
 - **UX patterns to follow:** the inline-callout pattern of the related-articles section — one
   column, full width on mobile, contained on desktop; the existing primary button; no new color
   tokens.
 - **Variants / states:** default · pending (the button reads "Subscribing…" and is disabled) ·
-  success (the message replaces the form) · already subscribed (the message replaces the form) ·
-  error (the message appears under the form; the address is kept) · invalid (an inline error under
-  the field).
+  success (the message replaces the form) · ~~already subscribed (the message replaces the form)~~
+  _(retired by CR 1)_ · error (the message appears under the form; the address is kept) · invalid
+  (an inline error under the field) · (CR 1) with topics (one to six checkboxes between the field
+  and the button).
 - **Fixed text:** the field label ("Email address") and the inline error ("Enter a valid email
-  address.") are not editable in Contentful.
+  address.") are not editable in Contentful. (CR 1) Neither is the topic group's label, "Topics
+  (optional)".
 - **Copy lengths:** heading ≤ 80 characters, body ≤ 200, button ≤ 30, each message ≤ 200 — what the
-  mockup fits at 320 px.
+  mockup fits at 320 px. (CR 1) Topic names ≤ 40.
 
 ## Accessibility [REQUIRED if feature-type is ui or mixed — otherwise mark Not applicable]
@@ -133,4 +168,8 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - Keyboard order is email field → button, with no traps.
 - The field and the button are at least 44×44 px on a 375 px wide screen.
+- (CR 1) The topics are a group (`fieldset`) with the visible legend "Topics (optional)"; each
+  checkbox is labeled with its topic's name.
+- (CR 1) With topics on screen, keyboard order is email field → topics → button.
+- (CR 1) Each topic checkbox, with its label, is at least 44×44 px on a 375 px wide screen.
 
 ---
@@ -150,4 +189,9 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - Copy from Contentful is rendered as text, never as HTML.
 - The endpoint is public by design — signing up needs no account.
+- (CR 1) The endpoint doesn't trust topic IDs from the browser: it keeps only topics that are in
+  the entry and ignores the rest.
+- (CR 1) Anyone can add topics to an address that is already on the list without proving they own
+  it. Accepted: topics are only ever added, requests are rate-limited, and nothing is revealed.
+  _(security lead, 2026-09-16)_
 
 ## Privacy [REQUIRED if personal-data is yes — otherwise mark Not applicable]
@@ -155,8 +199,9 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 > Owned by: privacy
 
-- **Data collected:** email address; IP address, for rate limiting only.
+- **Data collected:** email address; IP address, for rate limiting only; (CR 1) the topics a reader
+  picks.
 - **Lawful basis:** consent — the reader submits the form.
-- **Storage:** email addresses in Mailchimp (US region, covered by the existing data processing
-  agreement); IP addresses in the rate-limit store for at most 60 seconds.
+- **Storage:** email addresses and (CR 1) topic choices in Mailchimp (US region, covered by the
+  existing data processing agreement); IP addresses in the rate-limit store for at most 60 seconds.
 - **Transmission:** the address goes to Mailchimp over HTTPS; nothing else leaves our systems.
 - **User rights:** the unsubscribe link in every newsletter (Mailchimp); access and deletion
@@ -164,4 +209,6 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - **Consent:** no cookies or tracking are added, so the consent banner and the privacy policy don't
   change.
+- (CR 1) The form no longer reveals whether an address is on the list: everyone who submits a
+  valid address sees the same success message.
 
 ---
@@ -190,6 +237,8 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - Address validation has unit tests for a valid address and for each invalid form in the edge
   cases.
-- The endpoint has a test for each outcome: subscribed, already subscribed, invalid input,
-  rate-limited (429 with `Retry-After`), and Mailchimp failure (502).
+- The endpoint has a test for each outcome: subscribed, ~~already subscribed,~~ _(retired by
+  CR 1)_ invalid input, rate-limited (429 with `Retry-After`), and Mailchimp failure (502).
+- (CR 1) The delivered tests for AC1–AC3, AC5, and AC6 keep passing against the unchanged,
+  topic-free fixture — that is AC8's proof. AC4's tests are removed with AC4.
 
 ### Additional test types beyond ACs
@@ -199,4 +248,6 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - Security: crafted requests — no body, a non-string address, an oversized address — against the
   endpoint.
+- (CR 1) Accessibility: the axe scan and the VoiceOver pass also cover the form with topics on
+  screen.
 
 ### Out of test scope
@@ -215,4 +266,6 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 | Site administrator (marketing) | How to edit the newsletter entry in Contentful: each field, its limit, and where it appears; how fast edits go live; how to turn the form on and off; what readers see when something fails | `docs/admin/newsletter.md` |
 | Marketing (copy) | Suggested text for the six fields — the starting values marketing edits in Contentful | `docs/copy/newsletter-defaults.md` |
+| (CR 1) Site administrator (marketing) | Managing topics; the "Already subscribed message" field is no longer shown and must stay until it's removed | `docs/admin/newsletter.md` |
+| (CR 1) Marketing (copy) | A success message that reads right for new and existing subscribers alike | `docs/copy/newsletter-defaults.md` |
 
 ### Post-implementable docs (backfilled after code)
@@ -221,4 +274,5 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 | --- | --- | --- |
 | Operator / on-call | Runbook: the signup log events, telling a Mailchimp outage from a rate-limit spike, checking Mailchimp connectivity, what readers see when Contentful is down | `docs/runbooks/newsletter.md` |
+| (CR 1) Operator / on-call | Looking up a Mailchimp group ID; checking a subscriber's topics; what a wrong group ID looks like | `docs/runbooks/newsletter.md` |
 
 ## Deployment [OPTIONAL — fill if non-default infra or configuration]
@@ -230,7 +284,14 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - **Schema / content-model changes:** a new Contentful content type, `newsletterSignup`, with six
   required text fields. It must exist in Contentful before the code deploys.
+- **Schema / content-model changes (CR 1):** a new content type, `newsletterTopic` (a name and a
+  Mailchimp group ID), and an optional `topics` field on `newsletterSignup` — both before the code
+  deploys. `alreadySubscribedMessage` stays until CR 1 is live and is removed afterwards: the
+  delivered code treats an entry without it as incomplete, so removing it first would hide the form
+  on every article page (AC5).
 - **Rollout:** direct. The section appears when marketing publishes the newsletter entry, planned
   for campaign day, 2026-06-22; until then AC5 keeps it hidden. · **Rollback:** unpublish the entry
   (no deploy needed), or revert the deploy.
+- **Rollout (CR 1):** direct; topics appear when marketing adds them to the entry. · **Rollback:**
+  revert the deploy — the delivered code ignores topics.
 
 ---
@@ -269,4 +330,22 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - **Q:** Anything beyond WCAG 2.1 AA? — **A:** The six requirements under Accessibility; nothing
   else. _(2026-06-08, a11y lead)_
+- **Q:** (CR 1) A reader already on the list picks topics — add them? — **A:** Yes: add them, and
+  never remove any. _(2026-09-16, Dana)_ Adding interests to an address without proof of ownership
+  is accepted — see Security. _(2026-09-16, security lead)_
+- **Q:** (CR 1) Who maps each topic to its Mailchimp group? — **A:** Each topic entry has a
+  "Mailchimp group ID" field. Mailchimp doesn't show these IDs on screen, so the web team looks them
+  up and marketing pastes them in. _(2026-09-16, Dana and Sam)_
+- **Q:** (CR 1) In what order do topics appear, and how many can there be? — **A:** In the entry's
+  order; at most six, which is what the design fits. _(2026-09-16, Dana)_
+- **Q:** (CR 1) Should the topic group's label be editable? — **A:** No — "Topics (optional)" is
+  fine. _(2026-09-16, Dana)_
+- **Q:** (CR 1) Does the success message vary by selected topics? — **A:** No — one message,
+  whatever the reader picks, for this iteration. _(2026-09-16, Dana)_
+- **Q:** (CR 1) Contentful can't be reached when the form is submitted, so the topics can't be
+  checked — what happens? — **A:** Subscribe the reader without topics and log it; a lost signup is
+  worse than missing topics. _(2026-09-16, Dana)_
+- **Q:** (CR 1) An address that unsubscribed earlier signs up again — resubscribe it? — **A:** No.
+  It sees the success message and stays unsubscribed: resubscribing needs Mailchimp's confirmation
+  email, and double opt-in stays out of scope. _(2026-09-16, Dana — raised by @spec-analyzer)_
 
 ## References
@@ -276,2 +355,18 @@ WCAG 2.1 AA (`.claude/rules/ui-ux.md`), plus:
 - Figma: newsletter signup (`references.figma`)
 - Mailchimp Marketing API reference — list members (vendor documentation)
+
+# CR 1 — Topic preferences; one message for everyone (2026-09-16)
+
+- **Requested:** [MKT-412](https://tracker.example.com/t/MKT-412) — the description, rewritten on
+  2026-09-14, and the comments of 2026-09-14 and 2026-09-15 · by Dana (marketing) and Lee (privacy)
+- **Intent:** Let readers choose the topics they hear about, so marketing can segment the Thursday
+  digest by interest without losing signups — and stop the form from telling anyone whether an
+  address is on the list.
+
+| Aspect | Delivered (PR #142) | Change |
+| --- | --- | --- |
+| Topic choice | None — email only (Out of scope) | Optional checkboxes for the topics listed in the Contentful entry (AC7, AC8) |
+| What Mailchimp records | A subscriber, with no interests | A subscriber, plus an interest for each selected topic (AC9) |
+| An address already on the list | Its own "already subscribed" message (AC4) | The same success message as a new signup; selected topics are added (AC10 — AC4 retired) |
+| Copy fields in Contentful | Six, all required | `alreadySubscribedMessage` is no longer shown; the field is removed after CR 1 is live |
+| Placement, validation, rate limit, failure behavior | AC1–AC3, AC5, AC6 | None |
```

## Later in the branch

The CR 1 gate-results commit (`docs: record newsletter-signup CR 1 gate results`) sets the status
back to `implemented`, so it merges with the pull request:

```diff
-status: approved
+status: implemented
```

`/open-pr` records the new pull request (`spec: link newsletter-signup CR 1 pull request`):

```diff
 pull-requests:
   - "https://github.com/<org>/marketing-site/pull/142 · initial delivery"
+  - "https://github.com/<org>/marketing-site/pull/187 · CR 1"
```

## What didn't change

- **The intent and the constraints.** The Business paragraph, the Constraints & prior decisions
  section, and the frontmatter's `tracker:`, `owners:`, and `references:`.
- **AC1, AC2, AC3, AC5, and AC6** — not a word. Their tests keep passing — 43 of them without an
  edit, and the plan names the two whose details change — which is how the change proves it didn't
  break them.
- **The five delivered edge cases**, the six delivered Security requirements, the six delivered
  Accessibility requirements, and the Privacy section's lawful basis, transmission, user rights,
  and consent.
- **The twelve delivered clarifications.** CR 1 adds seven. The old answer about the "already
  subscribed" message stays as it was: it records why AC4 existed, and CR 1's section records why
  it went.

## Why the diff matters

The diff is the scope of the change request, in a form every later step can use:

- **`/write-plan`** plans only what the diff adds: four new ACs, one retired AC, four edge cases,
  two security requirements. It doesn't re-plan AC1–AC6.
- **The gate** approves the delta, not the whole feature again.
- **The tests** follow the AC numbers: AC4's tests are removed in the commits that retire it,
  AC7–AC10 get new ones, and the tests for AC1–AC3, AC5, and AC6 keep passing.
- **`/write-docs`** updates only the docs whose behavior changed — the admin guide gains a topics
  section and a note on the retired field, the copy doc changes one default, and the rest of both
  stays as it was.

Rewriting the spec from scratch would lose that signal — and would invite every later step to redo
the whole feature.
