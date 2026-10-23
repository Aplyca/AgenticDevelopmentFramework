---
name: stakeholder-update
description: Draft the client-facing update for a tracker task once its pull request is open or merged — why it wasn't working or what was needed, what was done, its status, verified findings, and direct questions, in the client's terms — with screenshots when they help, and show it in chat; the draft is the deliverable. Posts it on the tracker only after the developer approves the exact text and its assignee; never on the pull request. Use when asked to update the client, stakeholder, or requester, to reply on the tracker task, to tell the client what was done, or to write the final message to the client.
argument-hint: "[tracker task link or ID] [pull request number]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/stakeholder-update/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Stakeholder Update

Write the message that tells the client what was done on their tracker task. "Client" means whoever
asked for the work — a customer, a product owner, another team. **The draft shown in chat is the
deliverable.** It goes on the tracker only after the developer approves the exact text; if the
developer posts it themselves, nothing is posted anywhere. It never goes on the pull request:
reviewers aren't its audience, and a second copy drifts from the one the client reads.

It is the last step of every workflow for tracker-originated work, light changes included.

## Project settings

Read these before writing; they hold what this skill doesn't hardcode:

- **Status words** — `CONTRIBUTING.md` § Status words for requesters (mapped to the branching model).
- **Links and the tracker's conventions** — `docs/TRACKER-INTEGRATION.md` § Stakeholder updates: the
  live site, the stable preview address, preview URLs, CMS entry links, how to list task statuses,
  whether a comment can show an image inline, and how to mention someone.

## Steps

1. **Gather context.** Read the tracker task — description and every comment: who asked, who is
   copied, what was agreed — the pull request, and the spec folder if there is one (what was decided
   and why, change requests). Include all the work done for the task: content entered in the CMS,
   settings changed, and data fixed, as well as code. If you're unsure what non-code work was done,
   ask the developer.

2. **Verify every claim.** Check each statement and finding against the live site, the preview, the
   CMS, or the pull request before including it. A finding you couldn't verify is left out or
   flagged to the developer — never stated to the client. State the status as it actually is, in the
   project's status words. Typical mapping:
   - pull request open → "in review"
   - merged to the integration or preview branch for combined testing → "in acceptance testing"
   - merged or released to production → "live"

   Don't give dates unless the developer provides one.

3. **Write the draft**, following the style rules and template below, in the language the client
   uses on the task. Where a screenshot belongs, put a line of its own:
   `[Screenshot N: <what it shows>]`.

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
   the one question it needs — whether to post it on the tracker task, and with which assignee
   (step 6): "Post this on the task and assign it to Dana?" The developer may post it themselves
   instead; then nothing is posted anywhere.

6. **Post it on the tracker only on an explicit yes to the exact text and its assignee.** The
   assignment is part of the same approval; a change to either is a new draft to approve.
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
   - **Status:** change the task's status only when the developer asks, confirming the target status
     first. List the task's valid statuses with the tracker's tools before proposing one.

## Style rules

- **Write for the client, not for developers.** Greet the requesters by name: the task creator and
  anyone copied.
- **Follow this order:** why it wasn't working (or what was needed) → what we did → status →
  findings → next steps for the client.
- **Make it easy to read — a message, not a report.** Short paragraphs for why, what, and status,
  with no section headings. Bullets only for findings; a numbered list for direct questions.
- **Leave out technical detail.** No code, file or component names, queries, branches, or tool
  names. Explain causes and fixes in terms of pages and what visitors or users see.
- **Add relevant links inline:**
  - the affected live pages
  - an example of the fix working — on the preview, the stable preview address when
    `docs/TRACKER-INTEGRATION.md` § Stakeholder updates names one: a deploy's own URL changes with
    the next push
  - reference pages
  - the exact CMS entries the client would edit

  Don't link pull requests, commits, CI, or other internal tools in the client text.
- **Include only findings that matter to the client and are verified** — content gaps, content
  shared between pages or sites, branding or SEO issues, known limitations — saying whether we're
  handling each one.
- **Keep it short.** Don't over-explain, and leave out anything obvious, such as asking the client
  to click the links to check them.

## Template

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
| "I'll mention the PR so they can see the work" | Internal links confuse clients and may expose what they shouldn't see. Link pages they can act on. |
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
- You're about to write to the tracker without the developer's explicit yes to the text and the assignee.
- You're about to post the update anywhere but the tracker task — the pull request included.
- A screenshot the developer hasn't seen, or one taken by clicking through a consent banner.

## Verification

- [ ] The task, its comments, the pull request(s), and the spec folder were all read
- [ ] Every claim was verified against the site, the preview, the CMS, or the pull request
- [ ] Status uses the project's status words and gives no unconfirmed dates
- [ ] No technical detail or internal links in the client text
- [ ] The full draft was shown in chat; nothing was posted on the pull request
- [ ] Screenshots, if any, were taken read-only, of single elements, shown to the developer, and handed over as files
- [ ] Nothing was posted or changed on the tracker without explicit approval of the exact text and the assignee
- [ ] A posted comment was read back: text and assignee as approved

## Principles

- Write for the person who asked, in their terms and their language.
- Verified claims only; state the real status.
- The draft is the deliverable; the developer decides what reaches the tracker, and when.
