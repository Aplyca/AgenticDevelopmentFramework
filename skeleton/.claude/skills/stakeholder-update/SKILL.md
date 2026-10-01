---
name: stakeholder-update
description: Draft the requester-facing update for a tracker task once its pull request is open or merged — what was wrong or needed, what was done, its status, verified findings, and direct questions — in business language. Shows the draft first; posts it (on the pull request for the team to relay, or on the tracker) only when the developer asks. Use when asked to update the client or requester, reply on a task, or close the loop.
argument-hint: "[tracker task link or ID] [pull request number]"
disable-model-invocation: true
---

# Stakeholder Update

Write the message that tells the requester — a client, a product owner, another team — what
happened with their task. It is the last step of every workflow for tracker-originated work,
including the lightweight ones. The developer decides when and where it is sent: **nothing reaches
the requester without their explicit approval of the exact text.**

## Steps

1. **Gather the full picture.**
   - The tracker task: description, every comment, who asked, who is copied, what was agreed.
   - The pull request(s) and the spec folder: what was decided and why (`spec.md`, change requests).
   - Work outside the code: content entered in the CMS, settings changed, data fixed. If you don't
     know what non-code work was done, ask the developer.

2. **Verify every claim** before it goes in: check it against the live site or the preview, the
   CMS, or the pull request. A finding you couldn't verify is left out or flagged to the developer —
   never stated to the requester.

3. **State the status exactly as it is**, using the project's vocabulary (`CONTRIBUTING.md` defines
   it for the branching model). Typical mapping:
   - pull request open → "in review"
   - merged to the integration / preview branch → "in acceptance testing"
   - merged or released to production → "live"

   Give no dates unless the developer provides them.

4. **Write the draft** following the style rules and template below, in the language the requester
   uses on the task.

5. **Show the full draft in chat** — not only inside a question dialog, whose preview may not render.

6. **Deliver only as asked:**
   - **Default — on the pull request, for the team to relay:** one comment with the team note from the
     template on top. For revisions, edit that same comment (for example
     `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -F body=@<file>`) instead of adding
     new ones.
   - **On the tracker:** only when the developer explicitly asks. Confirm the exact text and, if the
     task status should change, list the valid statuses first and confirm the target one.

## Style rules

- **Write for the requester, not for developers.** Greet them by name — the person who asked and
  anyone copied on the task.
- **Order:** why it wasn't working (or what was needed) → what we did → status → findings → next
  steps for them.
- **A message, not a report:** short paragraphs for why, what, and status, with no headings. Bullets
  only for findings; a numbered list for direct questions.
- **No technical detail:** no code, file or component names, queries, branches, or tool names.
  Explain causes and fixes through pages, screens, and what visitors or users see.
- **Link what helps them act:** the affected live pages, an example of the fix working, reference
  pages, and the exact CMS entries they would edit. Never link pull requests, commits, CI, or other
  internal tools in the requester's text.
- **Only findings that matter to them, and verified:** content gaps, content shared between pages
  or sites, branding or SEO issues, known limitations — and whether you're handling each one.
- **Short.** Leave out the obvious, such as asking them to click the links.

## Template

```markdown
> **For the team:** suggested reply for the tracker task [<task name>](<task URL>).

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
| "I'll post it to the tracker to save time" | It reaches the requester under the developer's name. Show the draft; post only on an explicit yes to the exact text. |
| "I'll mention the PR so they can see the work" | Internal links confuse requesters and may expose what they shouldn't see. Link pages they can act on. |
| "I'll explain the technical root cause so they trust the fix" | Trust comes from verified outcomes in their terms — pages and behavior — not from component names. |
| "It's probably live by now" | State the status you verified, in the project's vocabulary. A wrong "live" costs more than a correct "in review". |
| "I'll add every finding to be thorough" | Only verified findings that matter to them. Noise buries the questions you need answered. |
| "The fix is obvious, I'll skip the verification" | Every claim is checked against the live site, preview, CMS, or pull request before it's written. |

## Red flags (stop and reassess)

- A claim in the draft that you haven't verified yourself.
- Code, branch, file, or tool names in the requester-facing text.
- A question to the requester that the spec or tracker thread already answers.
- You're about to post anywhere without the developer's explicit yes.

## Verification

- [ ] The task, its comments, the pull request(s), and the spec folder were all read
- [ ] Every claim was verified against the site, preview, CMS, or pull request
- [ ] Status uses the project's vocabulary and gives no unconfirmed dates
- [ ] No technical detail or internal links in the requester's text
- [ ] The full draft was shown in chat before anything was posted
- [ ] Nothing was posted or changed on the tracker without explicit approval of the exact text

## Principles

- Write for the person who asked, in their terms and their language.
- Verified claims only; state the real status.
- The developer decides what is sent, where, and when.
