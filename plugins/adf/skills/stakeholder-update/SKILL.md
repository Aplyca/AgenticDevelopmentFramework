---
name: stakeholder-update
description: Draft the requester's update on a tracker task at three moments — started (after triage, the task to in progress, with a message only when there's something worth saying), in review (once the draft pull request opens, the task to review, with a business-focused report — the preview, what to test, and the pull request), and delivered (why, what, status, verified findings, direct questions) — in the client's terms, with screenshots when they help, and show it in chat; the draft is the deliverable. Posts it and moves the task only after the developer approves the exact text, the status, and the assignee; never on the pull request. Use when /adf:triage or /adf:open-pr reaches its moment, or when asked to update the client, stakeholder, or requester, to reply on the tracker task, or to tell the client what was done.
argument-hint: "[started | review | delivered] [tracker task link or ID] [pull request number]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/stakeholder-update/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Stakeholder Update

Write the messages that keep the client informed on their tracker task. "Client" means whoever
asked for the work — a customer, a product owner, another team. **The draft shown in chat is the
deliverable.** It goes on the tracker only after the developer approves the exact text; if the
developer posts it themselves, nothing is posted anywhere. It never goes on the pull request:
reviewers aren't its audience, and a second copy drifts from the one the client reads.

## Moments

Tracker-originated work — light changes included — updates its task at three moments. At each one
the agent drafts the status change and the message together, for one yes; the work doesn't wait for
the answer.

| Moment | When | Task status | Message |
|---|---|---|---|
| **Started** | Right after `/adf:triage`, once you understand the task | The project's in-progress status | Only when it's worth the client's time: what we understood and will deliver, a question that blocks the work, a finding — it exists already, it was declined before, a risk. "We've started" alone isn't: the status says it |
| **In review** | Once `/adf:open-pr`'s draft is open and its preview walked | The project's review status | Always: a business-focused report — what changes for visitors or users, the preview and what to test there, and the pull request |
| **Delivered** | Once it's merged or live, or when asked | Where the change is now, such as in acceptance testing or live | Always: why it wasn't working or what was needed, what we did, the status, findings, next steps |

An answer-only task has no review moment: its delivered update is the answer, in the client's terms.

## Project settings

Read these before writing; they hold what this skill doesn't hardcode:

- **Status words** — `CONTRIBUTING.md` § Status words for requesters (mapped to the branching model).
- **Links and the tracker's conventions** — `docs/TRACKER-INTEGRATION.md` § Stakeholder updates: the
  live site, the stable preview address, preview URLs, CMS entry links, the task status for each
  moment and how to list a task's statuses, whether requesters can open pull requests, whether a
  comment can show an image inline, and how to mention someone.

## Steps

1. **Gather context.** Read the tracker task — description and every comment: who asked, who is
   copied, what was agreed — the pull request, and the spec folder if there is one (what was decided
   and why, change requests). Include all the work done for the task: content entered in the CMS,
   settings changed, and data fixed, as well as code. If you're unsure what non-code work was done,
   ask the developer. Name the moment: the argument, or where the work is.

2. **Verify every claim.** Check each statement and finding against the live site, the preview, the
   CMS, or the pull request before including it. A finding you couldn't verify is left out or
   flagged to the developer — never stated to the client. State the status as it actually is, in the
   project's status words. Typical mapping:
   - work started → "in progress"
   - pull request open → "in review"
   - merged to the integration or preview branch for combined testing → "in acceptance testing"
   - merged or released to production → "live"

   Don't give dates unless the developer provides one.

3. **Write the draft** for its moment, following the style rules and the moment's template below,
   in the language the client uses on the task. Where a screenshot belongs, put a line of its own:
   `[Screenshot N: <what it shows>]`. A started moment with nothing worth saying has no message:
   the draft is the status change alone.

4. **Take the screenshots** — only when a picture shows the client something words can't, such as
   the fix working. Take them from the preview or the live site, **read-only**: submit no form,
   change no setting, edit no content. With Playwright (the `e2e` module, or a browser tool the
   session has):
   - Use a desktop viewport, such as 1440×900, and `deviceScaleFactor: 2`, so text stays sharp
     when the tracker scales the image down.
   - Wait for the data the shot depends on: the element with its content, not only the page load.
   - Hide consent banners by injecting CSS after load, such as
     `page.addStyleTag({ content: '<banner selector> { display: none !important; }' })`. **Never
     accept or decline cookies** — either one records a consent choice on the site.
   - Screenshot the element the sentence points at (`locator.screenshot()`), not the full page.
   - Save each file outside the repository, named for what it shows.

   Show each image to the developer before it's used, and drop one that shows what it shouldn't:
   personal data, a draft entry, an error.

5. **Show the full draft to the developer in chat,** as the last text of your turn — text written
   just before a tool call can reach the developer only as a summary, and a question dialog's
   preview may not display. Hand over the screenshots with it, each file's path next to its
   placeholder. Always ask before posting, even when the developer asked for the update: close with
   the one question it needs — whether to post it on the tracker task, the status to move it to, and
   the assignee (step 6): "Post this on the task, move it to Review, and assign it to Dana?" At the
   started and review moments, the draft closes `/adf:triage`'s or `/adf:open-pr`'s message, and the
   work goes on without waiting. The developer may post it themselves instead; then nothing is
   posted anywhere.

6. **Post it on the tracker only on an explicit yes to the exact text, the status, and the
   assignee.** They're one approval; a change to any of them is a new draft to approve.
   - **Assign** the comment to the requester when it asks them a question or needs an action or a
     decision from them. Don't assign a purely informational one. Mention people with the
     tracker's mention syntax (§ Stakeholder updates); a bare `@Name` may notify no one.
   - **Images.** When the tracker's comment tool can't show an image inline, post the text with
     each `[Screenshot N: <what it shows>]` line in place, and ask the developer to paste each
     image over its placeholder in the tracker. Never upload the images to the task to "embed"
     them: an attachment lands on the task, away from the sentence it illustrates. Once the
     developer has pasted them, read the comment again where the tracker shows a pasted image in
     its text (§ Stakeholder updates), to confirm each one replaced its placeholder.
   - **Read it back** after posting: fetch the comment and confirm the text and the assignee came
     out as approved — mentions, links, formatting. A correction edits that comment, so the client
     reads one version.
   - **Status:** list the task's valid statuses with the tracker's tools, and propose the one
     § Stakeholder updates maps to the moment. A status the task doesn't have is a question for the
     developer, not a guess. Move it in the same approval as the text, never on its own.

## Style rules

- **Write for the client, not for developers.** Greet the requesters by name: the task creator and
  anyone copied.
- **Follow the moment's template.** The delivered update's order: why it wasn't working (or what
  was needed) → what we did → status → findings → next steps for the client.
- **Make it easy to read — a message, not a report.** Short paragraphs for why, what, and status,
  with no section headings. Bullets only for findings; a numbered list for direct questions.
- **Leave out technical detail.** No code, file or component names, queries, branches, or tool
  names. Explain causes and fixes in terms of pages and what visitors or users see.
- **Add relevant links inline:**
  - the affected live pages
  - the preview — an example of the fix working, and in the review update, where to test — at the
    stable preview address when `docs/TRACKER-INTEGRATION.md` § Stakeholder updates names one: a
    deploy's own URL changes with the next push
  - in the review update only, the pull request — unless § Stakeholder updates says requesters
    can't open it
  - reference pages
  - the exact CMS entries the client would edit

  Don't link commits, branches, CI, or other internal tools in the client text.
- **Include only findings that matter to the client and are verified** — content gaps, content
  shared between pages or sites, branding or SEO issues, known limitations — saying whether we're
  handling each one.
- **Keep it short.** Don't over-explain, and leave out anything obvious, such as asking the client
  to click the links to check them.

## Templates

### Started

```markdown
Hi <names>,

We've started on <topic>. <What we understood you need, and what we'll deliver, in one or two
sentences.>

<A finding worth knowing now, with a link — only when there is one.>

<N> questions before we go further:

1. **<Topic>:** <direct question, with the options and our recommendation>?

Thanks!
```

### In review

```markdown
Hi <names>,

<Topic> is ready for you to try. <What changes for visitors or users, in one or two sentences.>

You can try it on the [preview](<the stable preview address, when there is one>):

1. <Where to go and what to do, in their terms> — <what they should see>.
2. <…>

[Screenshot 1: <what it shows>]

<What isn't in it yet, or what to ignore on the preview — only when it matters.>

The team is reviewing the change in its [pull request](<link>). <What happens next, in the project's
status words — e.g. once you're happy with it, it goes live with the next release.>

<N> questions for you:

1. **<Topic>:** <direct question, with the options and links>?

Thanks!
```

### Delivered

```markdown
Hi <names>,

Here's a quick update on <topic>.

<Why it wasn't working, or what was needed, in one or two sentences.> To fix it, we <what we did,
with links>. <What visitors or users get now.>

[Screenshot 1: <what it shows>]

<What's live, what's pending, and when it goes live — in the project's status words.> We'll let you
know once it's up.

We noticed a few things along the way:

- **<Finding>** <one sentence, with a link — and whether we're handling it>.

<N> questions for you:

1. **<Topic>:** <direct question, with the options and links>?

Thanks!
```

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll post it to the tracker to save time" | It reaches the client under the developer's name. Show it in chat; the tracker only on an explicit yes to the exact text. |
| "I'll also put it on the pull request, so the team has it" | Reviewers aren't its audience, and a second copy drifts from the one the client reads. The draft in chat is the deliverable. |
| "I'll link the PR in every update so they can see the work" | Only the review update carries it, beside the preview and what to test — and not when requesters can't open it. Elsewhere, link pages they can act on. |
| "I'll post 'we've started' so they know" | The status change says that. A started message earns its place with what we understood, a question, or a finding. |
| "The draft is open — I'll move the task to Review now" | A status change is a write the requester sees. It goes in the same approval as the review update's text. |
| "I'll wait for the yes before I go on with the task" | The update is a draft beside the work. The work goes on; only the post waits for the yes. |
| "I'll explain the technical root cause so they trust the fix" | Trust comes from verified outcomes in their terms — pages and behavior — not from component names. |
| "It's probably live by now" | State the status you verified, in the project's words. A wrong "live" costs more than a correct "in review". |
| "I'll add every finding to be thorough" | Only verified findings that matter to them. Noise buries the questions you need answered. |
| "I'll upload the screenshots to the task so they're embedded" | An attachment lands on the task, not in the comment. Hand the files over; the developer pastes each over its placeholder. |
| "I'll accept the cookie banner to get it out of the shot" | That records a consent choice on the site. Hide the banner with CSS after load. |
| "I'll assign it to the requester so they see it" | Assign only a comment that needs something from them: an answer, an action, a decision. And only with the developer's yes to that assignee. |
| "It posted without an error, so it's right" | Read it back. Mentions, links, and formatting can come out differently from the draft. |
| "The work is done — I'll post the update now" | Drafting on your own is fine; posting isn't. Show the draft and ask. |

## Red flags (stop and reassess)

- A claim in the draft that you haven't verified yourself.
- Code, branch, file, or tool names in the client-facing text.
- A question to the client that the spec or the tracker thread already answers.
- You're about to write to the tracker — a comment or a status — without the developer's explicit yes to the text, the status, and the assignee.
- You're about to post the update anywhere but the tracker task — the pull request included.
- A screenshot the developer hasn't seen, or one taken by clicking through a consent banner.

## Verification

- [ ] The task, its comments, the pull request(s), and the spec folder were all read
- [ ] Every claim was verified against the site, the preview, the CMS, or the pull request
- [ ] Status uses the project's status words and gives no unconfirmed dates
- [ ] The moment was named; its status is the one § Stakeholder updates maps to it, from the task's valid statuses
- [ ] A started update has a message only when it's worth the client's time; a review update gives the preview, what to test there, and the pull request (unless requesters can't open it)
- [ ] No technical detail or internal links in the client text — the pull request only in the review update
- [ ] The full draft was shown in chat; nothing was posted on the pull request
- [ ] Screenshots, if any, were taken read-only, of single elements, shown to the developer, and handed over as files
- [ ] Nothing was posted or changed on the tracker without explicit approval of the exact text, the status, and the assignee
- [ ] A posted comment was read back: text and assignee as approved

## Principles

- Write for the person who asked, in their terms and their language.
- Keep them informed as the work moves — started, in review, delivered — with nothing they'd skip.
- Verified claims only; state the real status.
- The draft is the deliverable; the developer decides what reaches the tracker, and when.
