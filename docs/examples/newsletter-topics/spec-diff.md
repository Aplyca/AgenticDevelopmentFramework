# Spec diff — adding topic selection

> This is the diff applied to `specs/newsletter-signup.md` during Phase 1 of `/write-spec`. Notice what *didn't* change — most of the spec is untouched, which is the point.

## The diff

```diff
 ---
 title: "Newsletter signup on article pages"
 area: "marketing"
-status: approved
+status: approved   # status unchanged — still approved, modification re-approved separately
 ---

 ## Overview

 Add a newsletter signup section to every article page so the marketing team can grow the
 subscriber list. Copy is editable in Contentful for A/B testing. Submissions are forwarded
 to Mailchimp through a server-side Route Handler that validates input, rate-limits per IP,
 and never exposes the Mailchimp API key to the browser.

+An optional topic selector lets subscribers indicate which subjects they want to hear
+about; selections forward to Mailchimp interest groups for campaign segmentation.
+
 ## User stories

 - As a **reader**, I want to subscribe to the newsletter from any article page, so that I
   get more content like what I just read.
+- As a **reader**, I want to optionally pick which topics I'm interested in, so that the
+  emails I receive are relevant to me.
 - As a **marketer**, I want to edit the signup copy in Contentful, so that I can A/B
   test headlines and CTAs without a code deploy.
+- As a **marketer**, I want to manage the available topics in Contentful, so that I can
+  add, remove, or rename topics without a code deploy.
 - As an **operator**, I want the form to fail safely when Contentful or Mailchimp is
   unavailable, so that a CMS or ESP outage doesn't break article pages.

 ## Acceptance criteria

 1. Every article page renders a newsletter signup section beneath the article body,
    containing a heading, body copy, an email input with a visible label, and a submit
    button. Heading, body copy, and submit button label are sourced from the singleton
    Contentful entry of type `newsletterSignup`.

+1a. When the `newsletterSignup` entry references one or more `newsletterTopic` entries
+    via the `availableTopics` field, the form additionally renders an optional checkbox
+    group beneath the email input, listing each topic by name, with a "(optional)" label.
+    When `availableTopics` is empty or absent, the checkbox group is omitted entirely.
+
 2. When the user submits a valid email address, the form replaces itself with a success
    message sourced from the same Contentful entry, and the email is recorded as a
-   Mailchimp subscriber.
+   Mailchimp subscriber. If the user selected one or more topics, those selections are
+   recorded as Mailchimp interest group memberships using each topic's `mailchimpGroupId`.

 ... (ACs 3, 4, 5, 6, 7 unchanged) ...

 ## Edge cases

 ... (existing edge cases unchanged) ...

+- `availableTopics` field is empty / absent on the `newsletterSignup` entry → topic
+  selector is omitted, form behaves as the email-only original.
+- A referenced `newsletterTopic` entry is missing the `mailchimpGroupId` field → topic
+  is still rendered in the form (so marketing sees the omission), but is silently dropped
+  server-side at submission. A warning is logged server-side.
+- User submits with no topics selected → submission proceeds normally, no interest groups
+  are recorded for the subscriber.
+- User submits with topic IDs not in the configured `availableTopics` (e.g. crafted
+  request) → server validates submitted topic IDs against the configured set and silently
+  drops unknown IDs. No error to the user.

 ## Clarifications

 ... (existing Q&As unchanged) ...

+- **Q:** Topic source — new content type or a multi-line text field on `newsletterSignup`?
+  **A:** New singleton-style content type `newsletterTopic` with fields: `name`,
+  `description` (unused for now, future-proofing), `mailchimpGroupId`. Referenced from
+  `newsletterSignup` via a new multi-reference field `availableTopics`.
+- **Q:** Selection required or optional? **A:** Optional. Subscribers can submit with
+  none selected. No default selections.
+- **Q:** What if the Contentful entry doesn't reference any topics yet? **A:** Form
+  omits the selector entirely and behaves as the email-only original. This is the
+  backwards-compatibility path for the current deployed entry.
+- **Q:** What about existing subscribers in Mailchimp who don't have any interest groups?
+  **A:** Do nothing. Backfilling existing subscribers is out of scope for this iteration.
+- **Q:** Where does the Mailchimp `interestGroupId` mapping live — Contentful or env?
+  **A:** On the Contentful `newsletterTopic` entry as a field. Avoids env-var sprawl and
+  lets marketing manage the mapping with engineering as a one-time setup per topic.
+- **Q:** Does the success message vary by selected topics? **A:** No, generic message
+  stays for this iteration.

 ## Out of scope

 ... (existing items unchanged) ...

+- Backfill of existing Mailchimp subscribers into default interest groups.
+- Per-topic success messages or follow-up flows.
+- A "select all" / "select none" convenience control on the topic checkbox group.
+- Localization of topic names (Contentful supports it; English only this iteration).
+- Inferring topic interest from article context (e.g. auto-checking "Tech" on tech
+  articles). Reader picks explicitly.

 ## Documentation

 ### Pre-implementable docs

 ... (existing entries unchanged) ...

+| Site administrator (marketing) | Updated section in admin guide: how to add/remove topics in Contentful, how to set the `mailchimpGroupId` for each topic, what users see when no topics are configured | Update existing `docs/admin/newsletter.md` (new section: "Managing topics") |

 ### Post-implementable docs

 ... (existing entries unchanged) ...

+| Operator | Add to runbook: how to verify topic-to-Mailchimp-group mapping is correct, what to check when a subscriber is missing expected interest groups | Update existing `docs/runbooks/newsletter.md` (new section, post-impl backfill) |
```

## What didn't change

- ACs 3, 4, 5, 6, 7 — entirely unchanged.
- All existing edge cases (empty email, malformed email, already-subscribed, Contentful unreachable, Mailchimp unreachable, rapid double-click, rate-limited).
- The rate-limit value (10 req/IP/min).
- The accessibility requirement (WCAG 2.1 AA).
- The render-failure behavior (Contentful unreachable → omit section).

## Why this matters

The two diffs that come next — the test diff (Phase 2) and the implementation diff (Phase 3) — read this spec diff to understand scope. Because:

- **AC 1 didn't change**, the existing test for AC 1 stays. AC 1a is new, gets a new test.
- **AC 2 changed (added a clause)**, the existing test for AC 2 stays (covers the original clause), a new test covers the new clause.
- **ACs 3-7 didn't change**, none of their tests change, none of the code that satisfies them changes.

If we'd rewritten the spec from scratch instead of diffing it, we'd lose this scope signal — and the implementation agent might happily refactor the entire feature.
