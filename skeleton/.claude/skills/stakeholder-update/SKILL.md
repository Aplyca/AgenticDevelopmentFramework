---
name: stakeholder-update
description: Draft the client-facing update for a tracker task once its pull request is open or merged — why it wasn't working or what was needed, what was done, its status, verified findings, and direct questions, in the client's terms — show it, and post it on the pull request so the team can relay it. Posts on the tracker only when the developer asks. Use when asked to update the client, stakeholder, or requester, to reply on the tracker task, to tell the client what was done, or to write the final message to the client.
argument-hint: "[tracker task link or ID] [pull request number]"
---

# Stakeholder Update

Write the message that tells the client what was done on their tracker task. "Client" means whoever
asked for the work — a customer, a product owner, another team. The team relays the message, so the
draft goes on the pull request. **Nothing reaches the tracker without the developer's approval of
the exact text.**

It is the last step of every workflow for tracker-originated work, light changes included.

## Project settings

Read these before writing; they hold what this skill doesn't hardcode:

- **Status words** — `CONTRIBUTING.md` § Status words for requesters (mapped to the branching model).
- **Links the client can act on, and the tracker's valid statuses** — `docs/TRACKER-INTEGRATION.md`
  § Stakeholder updates: the live site, preview URLs, CMS entry links, and how to list task statuses.

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
   uses on the task.

4. **Show the full draft to the developer in chat,** as the last text of your turn: text written just
   before a tool call can reach the developer only as a summary, and a question dialog's preview
   may not display.

5. **Post it on the pull request** as a single comment, with the team note from the template on top
   (Claude Code asks you to confirm `gh pr comment`). If the developer didn't ask for the update —
   you started this yourself, say at the end of a delivery — ask before posting. For revisions, edit that same comment instead
   of adding new ones:
   `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<file>`.
   With no pull request — an answer-only task — the draft in chat is the deliverable.

6. **Leave the tracker alone unless asked.** Post the comment or change the task status only when
   the developer explicitly asks, and confirm the exact text and the target status first. List the
   task's valid statuses with the tracker's tools before proposing one.

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
  - an example of the fix working
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
> **For the team:** suggested client reply for the tracker task [<task name>](<task URL>).

---

Hi <names>,

Here's a quick update on <topic>.

<Why it wasn't working, or what was needed, in one or two sentences.> To fix it, we <what we did,
with links>. <What visitors or users get now.>

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
| "I'll post it to the tracker to save time" | It reaches the client under the developer's name. Post on the pull request; the tracker only on an explicit yes to the exact text. |
| "I'll mention the PR so they can see the work" | Internal links confuse clients and may expose what they shouldn't see. Link pages they can act on. |
| "I'll explain the technical root cause so they trust the fix" | Trust comes from verified outcomes in their terms — pages and behavior — not from component names. |
| "It's probably live by now" | State the status you verified, in the project's words. A wrong "live" costs more than a correct "in review". |
| "I'll add every finding to be thorough" | Only verified findings that matter to them. Noise buries the questions you need answered. |
| "I'll post a new comment with the revised text" | Edit the same comment, so the team relays one current version. |
| "The work is done — I'll post the update now" | Drafting on your own is fine; posting isn't. Show the draft and ask, unless the developer asked for the update. |

## Red flags (stop and reassess)

- A claim in the draft that you haven't verified yourself.
- Code, branch, file, or tool names in the client-facing text.
- A question to the client that the spec or the tracker thread already answers.
- You're about to write to the tracker without the developer's explicit yes.

## Verification

- [ ] The task, its comments, the pull request(s), and the spec folder were all read
- [ ] Every claim was verified against the site, the preview, the CMS, or the pull request
- [ ] Status uses the project's status words and gives no unconfirmed dates
- [ ] No technical detail or internal links in the client text
- [ ] The full draft was shown in chat, then posted as one pull-request comment (revisions edit it)
- [ ] Nothing was posted or changed on the tracker without explicit approval of the exact text

## Principles

- Write for the person who asked, in their terms and their language.
- Verified claims only; state the real status.
- The team relays it; the developer decides what reaches the tracker, and when.
