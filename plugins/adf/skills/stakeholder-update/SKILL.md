---
name: stakeholder-update
description: Draft the requester's message on a tracker task — started, in review (the preview and what to test), delivered — in their terms, with screenshots when they help; post it only on the developer's yes to its exact text and the assignee, never on the pull request. Use when /adf:triage, /adf:open-pr, or /adf:wrap-up reaches its moment, or when asked to update the client, stakeholder, or requester, to reply on the tracker task, or to tell the client what was done.
argument-hint: "[started | review | delivered] [status] [tracker task link or ID] [pull request number]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/stakeholder-update/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Stakeholder Update

Write the messages that keep the client informed on their tracker task. "Client" means whoever
asked for the work — a customer, a product owner, another team. **The draft shown in chat is the
deliverable.** It goes on the tracker only after the developer approves the exact text; if the
developer posts it themselves, nothing is posted anywhere. It never goes on the pull request:
reviewers aren't its audience, and a second copy drifts from the one the client reads.

**The task's status is not a message, and it doesn't wait for a yes.** It moves with the work —
see § Status moves — so the board shows where the task is, without the developer remembering to
move it.

## Moments

Tracker-originated work — light changes included — updates its task at three moments. At each one
the agent moves the status (§ Status moves) and drafts the message for the developer's yes; the work
doesn't wait for the answer.

| Moment | When | Task status | Message |
|---|---|---|---|
| **Started** | Right after `/adf:triage`, once you understand the task | The project's in-progress status — moved by the triage | Only when it's worth the client's time: what we understood and will deliver, a question that blocks the work, a finding — it exists already, it was declined before, a risk. "We've started" alone isn't: the status says it |
| **In review** | Once `/adf:open-pr`'s draft is open and its preview walked | The project's review status — moved at the push, not here | Always: a business-focused report — what changes for visitors or users, the preview and what to test there, and the pull request |
| **Delivered** | Once it's merged or live, or when asked | The project's done status — where the change is now, such as in acceptance testing, ready for release, or done | Always: why it wasn't working or what was needed, what we did, the status, findings, next steps |

An answer-only task has no review moment: its delivered update is the answer, in the client's terms.

## Status moves

The status follows the work, on its own — the developer isn't asked each time, and the move isn't
part of any message's approval. The skill that reaches the moment makes the move in a step of its
own, without loading this skill: `/adf:triage` to the in-progress status once the triage is stated,
`/adf:open-pr` to the review status once the branch is pushed and the pull request is open,
`/adf:wrap-up` to the done status (`delivered` in the settings) once the pull request merged or an
answer is delivered. `/adf:stakeholder-update status <moment>` makes a move too, when asked or when
one didn't happen at its moment.

The rules for a move — the task's own statuses, forward only, the developer's tasks only, the
status alone, through the project's server, one line to say so — are in
`<this skill's base directory>/status.md`. Read it for a move made here.

## Project settings

Read these before writing; they hold what this skill doesn't hardcode:

- **Status words** — `CONTRIBUTING.md` § Status words for requesters (mapped to the branching model).
- **Links and the tracker's conventions** — `docs/TRACKER-INTEGRATION.md` § Stakeholder updates: the
  live site, the stable preview address, preview URLs, CMS entry links, the task status for each
  moment (in progress, in review, done) and how to list a task's statuses, whether requesters can open pull requests, whether a
  comment can show an image inline, how to mention someone, how a link to another task shows, and
  what an edit to a posted comment keeps.

## Steps

**With the argument `status`,** make only the move for the named moment, by `status.md` (§ Status
moves) — no draft, no message — and stop.

1. **Gather context.** Read the tracker task — description and every comment: who asked, who is
   copied, what was agreed — the pull request, and the spec folder if there is one (what was decided
   and why, change requests). Include all the work done for the task: content entered in the CMS,
   settings changed, and data fixed, as well as code. If you're unsure what non-code work was done,
   ask the developer. Name the moment — the argument, or where the work is — and read its template
   with these reads: `<this skill's base directory>/started.md`, `review.md`, or `delivered.md`.

2. **Verify every claim.** Check each statement and finding against the live site, the preview, the
   CMS, or the pull request before including it. A finding you couldn't verify is left out or
   flagged to the developer — never stated to the client. State the status as it actually is, in the
   project's status words. Typical mapping:
   - work started → "in progress"
   - pull request open → "in review"
   - merged to the integration or preview branch for combined testing → "in acceptance testing"
   - merged or released to production → "live"

   Don't give dates unless the developer provides one.

3. **Write the draft** for its moment, following the style rules and the moment's template (step 1),
   in the language the client uses on the task. Where a screenshot belongs, put a line of its own:
   `[Screenshot N: <what it shows>]`. A started moment with nothing worth saying has no message:
   the draft is the status change alone.

4. **Take the screenshots** — only when a picture shows the client something words can't, such as
   the fix working. Read `<this skill's base directory>/screenshots.md` first and follow it: shots
   taken read-only, from the preview or the live site, and shown to the developer before they're
   used.

5. **Show the full draft to the developer in chat,** as the last text of your turn — text written
   just before a tool call can reach the developer only as a summary, and a question dialog's
   preview may not display. Hand over the screenshots with it, each file's path next to its
   placeholder. Always ask before posting, even when the developer asked for the update: close with
   the one question it needs — whether to post it on the tracker task, and the assignee (step 6):
   "Post this on the task and assign it to Dana?" The status has moved already (§ Status moves). At the
   started and review moments, the draft closes `/adf:triage`'s or `/adf:open-pr`'s message, and the
   work goes on without waiting. The developer may post it themselves instead; then nothing is
   posted anywhere.

6. **Post it on the tracker only on an explicit yes to the exact text and the assignee.** They're
   one approval; a change to either is a new draft to approve.
   - **Through the project's tracker server, as the developer** (`docs/TRACKER-INTEGRATION.md`
     § Rules for agents) — never a tracker connector built into the host app. Before the session's
     first post, ask the server who is signed in and say which account will post.
   - **Assign** the comment to the requester when it asks them a question or needs an action or a
     decision from them. Don't assign a purely informational one. Mention people with the
     tracker's mention syntax (§ Stakeholder updates); a bare `@Name` may notify no one. Where the
     tracker moves mentions, greet by name in plain text and put the mentions where it places them.
   - **Links to other tasks or comments** go out as plain links when the tools can't make the
     tracker's preview (§ Stakeholder updates): ask the developer to paste each one that should show
     as a preview in the tracker's editor, and read the comment again once they have.
   - **Images:** as `<this skill's base directory>/screenshots.md` § Posting them says — the
     developer pastes each one over its placeholder.
   - **Read it back** after posting: fetch the comment and confirm the author, the text, and the
     assignee came out as approved — mentions, links, formatting. A correction edits that comment, so
     the client reads one version — through the tools only when the comment holds nothing an edit
     would lose (a mention, a pasted image, a link preview — § Stakeholder updates). Otherwise show
     the corrected text, and the developer edits the comment in the tracker.
   - **Status:** already moved at its moment (§ Status moves). If it wasn't — the tracker wasn't
     connected then, say — move it now, by `status.md`.

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
  - in the delivered update, the published end-user page, with the `end-user-docs` module — once
    `/adf:end-user-docs` has published it; never its draft, which end users can't open

  Don't link commits, branches, CI, or other internal tools in the client text.
- **Include only findings that matter to the client and are verified** — content gaps, content
  shared between pages or sites, branding or SEO issues, known limitations — saying whether we're
  handling each one.
- **Keep it short.** Don't over-explain, and leave out anything obvious, such as asking the client
  to click the links to check them.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll post it to the tracker to save time" | It reaches the client under the developer's name. Show it in chat; the tracker only on an explicit yes to the exact text. |
| "I'll also put it on the pull request, so the team has it" | Reviewers aren't its audience, and a second copy drifts from the one the client reads. The draft in chat is the deliverable. |
| "I'll link the PR in every update so they can see the work" | Only the review update carries it, beside the preview and what to test — and not when requesters can't open it. Elsewhere, link pages they can act on. |
| "I'll post 'we've started' so they know" | The status change says that. A started message earns its place with what we understood, a question, or a finding. |
| "I'll hold the status until the developer approves the update" | The status and the message are separate. The status moves with the work; only the message waits for the yes. |
| "I'll wait for the yes before I go on with the task" | The update is a draft beside the work. The work goes on; only the post waits for the yes. |
| "It's probably live by now" | State the status you verified, in the project's words. A wrong "live" costs more than a correct "in review". |
| "I'll assign it to the requester so they see it" | Assign only a comment that needs something from them: an answer, an action, a decision. And only with the developer's yes to that assignee. |
| "It posted without an error, so it's right" | Read it back. Mentions, links, and formatting can come out differently from the draft. |
| "The tracker connector in the app is already signed in, so I'll post through it" | It may be signed in to someone else's account. Post through the project's server, once you've said which account will post. |
| "The mention came out wrong — I'll fix it by editing the comment" | An edit through the tools can drop mentions, pasted images, and link previews. Show the fix; the developer edits the comment in the tracker. |

## Red flags (stop and reassess)

- A claim in the draft that you haven't verified yourself.
- Code, branch, file, or tool names in the client-facing text.
- A question to the client that the spec or the tracker thread already answers.
- You're about to post a comment, or change an assignee, priority, due date, or time entry, without the developer's explicit yes.
- You're about to post the update anywhere but the tracker task — the pull request included.
- You're about to post through a server other than the project's, or before saying which account posts.

## Verification

- [ ] The task, its comments, the pull request(s), and the spec folder were all read
- [ ] Every claim was verified against the site, the preview, the CMS, or the pull request
- [ ] Status uses the project's status words and gives no unconfirmed dates
- [ ] The moment was named; the status moved to the one § Stakeholder updates maps to it, from the task's valid statuses, forward only, and said in one line
- [ ] A started update has a message only when it's worth the client's time; a review update gives the preview, what to test there, and the pull request (unless requesters can't open it)
- [ ] No technical detail or internal links in the client text — the pull request only in the review update
- [ ] The full draft was shown in chat; nothing was posted on the pull request
- [ ] Screenshots, if any, were taken read-only, of single elements, shown to the developer, and handed over as files
- [ ] Nothing was posted, assigned, or changed on the tracker beyond the status without explicit approval of the exact text and the assignee
- [ ] A comment was posted through the project's server, as the account the developer was told, and read back: author, text, and assignee as approved

## Principles

- Write for the person who asked, in their terms and their language.
- Keep them informed as the work moves — started, in review, delivered — with nothing they'd skip.
- Verified claims only; state the real status.
- The status follows the work; the draft is the deliverable, and the developer decides what message reaches the tracker, and when.
