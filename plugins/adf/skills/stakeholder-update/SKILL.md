---
name: stakeholder-update
description: Write the requester's update on a tracker task (a ClickUp task, a GitHub or GitLab issue) in their terms, at three moments — started, in review, and delivered once the change is live. Use when /adf:triage, /adf:open-pr, or /adf:wrap-up reaches its moment, when a merged change goes live, or when asked to update or reply to the client, stakeholder, or requester on a task. `guide` posts or updates the task's usage guide.
argument-hint: "[started | review | delivered | guide] [status] [tracker task link or ID] [pull request number]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/stakeholder-update/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Stakeholder Update

Write the messages that keep the client informed on their tracker task — a ClickUp task, a GitHub
issue, a GitLab issue. "Client" means whoever asked for the work — a customer, a product owner,
another team.

**The ticket is for business communication with stakeholders; the pull request is for technical
communication with the developer** ([decision 0073](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0073-the-ticket-for-stakeholders-the-pull-request-for-the-developer.md)).
The update says what changes for the people who use the system, in their terms, and never goes on
the pull request; the review instructions, the tests, and the diff stay there (`/adf:open-pr`).

**The review and delivered updates post on their own,** once their moment is reached: they report
an outcome, every claim verified, and your report shows the text you posted. **A message that needs
something from the requester** — a question, an action, a decision, an assignment — **and the
started message are drafts in chat,** posted only on the developer's yes to the exact text. When
`docs/TRACKER-INTEGRATION.md` § Stakeholder updates says **Updates post: on the developer's yes**,
every message is a draft first.

**The task's status is not a message.** It moves with the work — see § Status moves — so the board
shows where the task is, without the developer remembering to move it.

## Moments

Tracker-originated work — light changes included — updates its task at three moments.

| Moment | When | Task status | Message |
|---|---|---|---|
| **Started** | Right after `/adf:triage`, once you understand the task | The project's in-progress status — moved by the triage | A draft, only when it's worth the client's time: what we understood and will deliver, a question that blocks the work, a finding — it exists already, it was declined before, a risk. "We've started" alone isn't: the status says it |
| **In review** | Once `/adf:open-pr` marks the pull request ready, its preview walked | The project's review status — moved by `/adf:open-pr` at ready, not here | Always, posted on its own: the business outcome — what changes for visitors or users, the preview and what to test there — and the pull request, for reference |
| **Delivered** | Once the change is merged **and live** (§ Live), or the answer is given | The project's delivered status — moved then, not at the merge | Always, posted on its own: why it wasn't working or what was needed, what we did, that it's live, findings, next steps. The usage guide is brought up to date with it |

**Between review and delivered, the task is the developer's.** Quality control, acceptance testing,
and release are statuses they set: never move the task to one, or back from one.

An answer-only task has no review moment: its delivered update is the answer, in the client's terms
— an analysis, an estimate, a recommendation. It's the developer's to send: a draft, posted on
their yes.

## Live

Delivered means the requester can use it, not that it merged. `docs/TRACKER-INTEGRATION.md`
§ Stakeholder updates › **Live when** says which: on the merge, on a release, or when the developer
says. No line: ask once. Verify it before the delivered update or the status — the live site shows
the change, or the release's deploy finished.

Merged but not live: post nothing and move nothing. Say once, in one line, that the delivered step
waits for the release, and that `/adf:stakeholder-update delivered <task>` runs it then, from any
session.

## Status moves

The status follows the work, on its own — the developer isn't asked each time. The skill that
reaches the moment makes the move in a step of its own, without loading this skill: `/adf:triage`
to the in-progress status once the triage is stated, `/adf:open-pr` to the review status once the
pull request is ready, `/adf:wrap-up` to the delivered status once the change is live or an answer
is delivered. `/adf:stakeholder-update status <moment>` makes a move too, when asked or when one
didn't happen at its moment — the delivered one after a release, with the delivered update.

The rules for a move — the task's own statuses, forward only, the session's own task, the status
alone, through the project's tracker tool, one line to say so — are in
`<this skill's base directory>/status.md`. Read it for a move made here.

## Project settings

Read these before writing; they hold what this skill doesn't hardcode:

- **Status words** — `CONTRIBUTING.md` § Status words for requesters (mapped to the branching model).
- **Links and the tracker's conventions** — `docs/TRACKER-INTEGRATION.md` § Stakeholder updates:
  whether updates post on their own, when a merged change is live, the live site, the stable preview
  address, preview URLs, CMS entry links, the task status for each moment (in progress, in review,
  delivered) and how to list a task's statuses, whether requesters can open pull requests, where a
  usage guide lives, whether a comment can show an image inline, how to mention someone, how a link
  to another task shows, and what an edit to a posted comment keeps.
- **The tracker tool** — the project's server in `.mcp.json`, or `gh` or `glab` when the tracker is
  GitHub or GitLab issues: `docs/TRACKER-INTEGRATION.md` § Issues as the tracker has each command.

## Steps

**With the argument `status`,** make only the move for the named moment, by `status.md` (§ Status
moves) — no draft, no message — and stop.

**With the argument `guide`,** read `<this skill's base directory>/guide.md`, follow it, and stop.

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
   - pull request ready for review → "in review"
   - merged to the integration or preview branch for combined testing → "in acceptance testing"
   - merged or released to production → "live"

   A delivered update needs "live" verified (§ Live); merged alone isn't its moment. Don't give
   dates unless the developer provides one.

3. **Write the update** for its moment, following the style rules and the moment's template (step 1),
   in the language the client uses on the task. A started moment with nothing worth saying has no
   message: the status change is all of it.

4. **Take the screenshots** — only when a picture shows the client something words can't, such as
   the fix working. Read `<this skill's base directory>/screenshots.md` first and follow it: shots
   taken read-only, from the preview or the live site, and shown to the developer before they're
   used. In a draft, a line of its own marks where each goes: `[Screenshot N: <what it shows>]`.
   An update that posts on its own carries no placeholder: hand the files to the developer in your
   report, to add in the tracker if they want them.

5. **Decide how it goes out.**
   - **A review or delivered update that only reports** posts on its own (step 6). If it also has
     questions for the requester, post the outcome now and make the questions a second message — a
     draft — so the outcome doesn't wait for an answer.
   - **A draft, for the developer's yes:** the started message; an answer-only task's answer; any
     message that asks the requester a question or needs an action or a decision from them, with
     its assignee; and every message
     when § Stakeholder updates says **Updates post: on the developer's yes**. Show the full draft in
     chat, as the last text of your turn — text written just before a tool call can reach the
     developer only as a summary, and a question dialog's preview may not display — with the
     screenshots' files, each path next to its placeholder. Always ask before posting a draft, even when the developer
     asked for the update: close with the one question it needs:
     "Post this on the task and assign it to Dana?" The work goes on without waiting; if the
     developer posts it themselves, nothing more is posted.

6. **Post it** — on its own, or on an explicit yes to the exact text and the assignee, as step 5
   says. A change to either is a new draft to approve.
   - **Through the project's tracker tool, as the developer** (`docs/TRACKER-INTEGRATION.md`
     § Rules for agents) — its server, or `gh` or `glab` for issues; never a tracker connector built
     into the host app. Before the session's first post, ask the tool who is signed in, and
     say which account will post.
   - **Can't post** — no tracker tool, or only a built-in connector: open your report with that, the
     text ready to paste and the status to set. Don't leave it for the end.
   - **Assign** a comment to the requester only when it asks them a question or needs an action or a
     decision from them — never one that posts on its own. Mention people with the tracker's mention
     syntax (§ Stakeholder updates); a bare `@Name` may notify no one. Where the tracker moves
     mentions, greet by name in plain text and put the mentions where it places them.
   - **Links to other tasks or comments** go out as plain links when the tools can't make the
     tracker's preview (§ Stakeholder updates): ask the developer to paste each one that should show
     as a preview in the tracker's editor, and read the comment again once they have.
   - **Images:** as `<this skill's base directory>/screenshots.md` § Posting them says — in a draft
     the developer approved, they paste each one over its placeholder.
   - **Read it back** after posting: fetch the comment and confirm the author, the text, and the
     assignee came out as written — mentions, links, formatting. A correction edits that comment, so
     the client reads one version — through the tools only when the comment holds nothing an edit
     would lose (a mention, a pasted image, a link preview — § Stakeholder updates). Otherwise show
     the corrected text, and the developer edits the comment in the tracker.
   - **Show what you posted:** the text, in your report, with the comment's link — "Posted on the
     task:" — so the developer reads what went out under their name.
   - **Status:** already moved at its moment (§ Status moves). If it wasn't — the tracker wasn't
     connected then, or the release came after the wrap-up — move it now, by `status.md`.
   - **At delivered,** bring the usage guide up to date when the task has one (`guide.md`).

## Style rules

- **Write for the client, not for developers.** Greet the requesters by name: the task creator and
  anyone copied.
- **Follow the moment's template.** The delivered update's order: why it wasn't working (or what
  was needed) → what we did → status → findings → next steps for the client.
- **Make it easy to read — a message, not a report.** Short paragraphs for why, what, and status,
  with no section headings. Bullets only for findings; a numbered list for direct questions.
- **Leave out technical detail.** No code, file or component names, queries, branches, or tool
  names. Explain causes and fixes in terms of pages and what visitors or users see. How it was
  tested and how to review it are the pull request's.
- **Add relevant links inline:**
  - the affected live pages
  - the preview — an example of the fix working, and in the review update, where to test — at the
    stable preview address when `docs/TRACKER-INTEGRATION.md` § Stakeholder updates names one: a
    deploy's own URL changes with the next push
  - in the review update only, the pull request, for reference — worded for the team when
    § Stakeholder updates says requesters can't open it
  - reference pages
  - the exact CMS entries the client would edit
  - in the delivered update, the usage guide — or the published end-user page, with the
    `end-user-docs` module, once `/adf:end-user-docs` has published it; never its draft, which end
    users can't open

  Don't link commits, branches, CI, or other internal tools in the client text.
- **Include only findings that matter to the client and are verified** — content gaps, content
  shared between pages or sites, branding or SEO issues, known limitations — saying whether we're
  handling each one.
- **Keep it short.** Don't over-explain, and leave out anything obvious, such as asking the client
  to click the links to check them.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll draft the review update and wait for a yes, to be safe" | A drafted outcome report leaves the ticket empty until someone says yes. Verified, it posts on its own, and the report shows its text. Only a message that asks the requester for something waits. |
| "It has one question, so I'll post it all and assign it" | A question or an assignment is the developer's call. Post the outcome; the question is a second message, a draft. |
| "I'll also put it on the pull request, so the team has it" | The pull request is for the developer: review instructions and tests. A second copy of the client's text drifts from the one they read. |
| "I'll add how I tested it, so they trust the result" | That's technical communication, and it lives in the pull request. The ticket says what changes for them and what to try. |
| "I'll link the PR in every update so they can see the work" | Only the review update carries it, for reference. Elsewhere, link pages they can act on. |
| "I'll post 'we've started' so they know" | The status change says that. A started message earns its place with what we understood, a question, or a finding — and it's a draft. |
| "It merged, so I'll post the delivered update and close the task" | Delivered means live. Until § Live says it is, post nothing and move nothing: acceptance testing and release are the developer's statuses. |
| "The developer moved it to acceptance testing — I'll move it on once the checks pass" | Those statuses say a person checked or released it. Leave them; your next move is delivered, once it's live. |
| "It's probably live by now" | State the status you verified, in the project's words. A wrong "live" costs more than a correct "in review". |
| "The developer isn't assigned to the task, so I'll leave it alone" | The task they handed this session is theirs to move and update. Only another task asks first. |
| "The tracker isn't connected — I'll mention it at the end" | Then the ticket stays empty and nobody notices. Open the report with what to set and the text to paste. |
| "It posted without an error, so it's right" | Read it back. Mentions, links, and formatting can come out differently from what you wrote. |
| "The tracker connector in the app is already signed in, so I'll post through it" | It may be signed in to someone else's account. Post through the project's tracker tool, once you've said which account posts. |
| "The mention came out wrong — I'll fix it by editing the comment" | An edit through the tools can drop mentions, pasted images, and link previews. Show the fix; the developer edits the comment in the tracker. |

## Red flags (stop and reassess)

- A claim in the update that you haven't verified yourself.
- Code, branch, file, or tool names — or how it was tested — in the client-facing text.
- A question to the client that the spec or the tracker thread already answers.
- You're about to post, on your own, a message that asks the requester something or assigns it to them.
- You're about to change an assignee, priority, due date, or time entry without the developer's explicit yes.
- You're about to post the delivered update, or move the task to delivered, for a change that merged but isn't live.
- You're about to move the task to, or back from, a quality-control, acceptance, or release status.
- You're about to post the update anywhere but the tracker task — the pull request included.
- You're about to post through a tool other than the project's, or before saying which account posts.

## Verification

- [ ] The task, its comments, the pull request(s), and the spec folder were all read
- [ ] Every claim was verified against the site, the preview, the CMS, or the pull request
- [ ] Status uses the project's status words and gives no unconfirmed dates
- [ ] The moment was named; the status moved to the one § Stakeholder updates maps to it, from the task's valid statuses, forward only, and said in one line — to delivered only once the change was verified live
- [ ] A review update gives what changes for them, the preview, what to test there, and the pull request for reference; a delivered update says it's live, and the usage guide matches what shipped
- [ ] No technical detail or internal links in the client text — the pull request only in the review update; nothing was posted on the pull request
- [ ] A review or delivered update that only reports was posted on its own, and the report shows its text and link; a message that asks the requester for something, the started message, an answer, or any message under *Updates post: on the developer's yes* was a draft, posted only on a yes to its exact text and assignee
- [ ] Screenshots, if any, were taken read-only, of single elements, shown to the developer, and handed over as files
- [ ] Nothing else changed on the tracker — assignee, priority, due date, time entries, another task — without explicit approval
- [ ] A comment was posted through the project's tracker tool, as the account the developer was told, and read back: author, text, and assignee as written
- [ ] With no tool that can write, the report opened with the status to set and the text to paste

## Principles

- The ticket is for the people who asked, in their terms and their language; the pull request is for the developer.
- Keep them informed as the work moves — started, in review, delivered — with nothing they'd skip.
- Verified claims only; state the real status. Delivered means live.
- Outcomes post on their own, and the developer reads what went out; anything that asks the requester for something is the developer's to send.
