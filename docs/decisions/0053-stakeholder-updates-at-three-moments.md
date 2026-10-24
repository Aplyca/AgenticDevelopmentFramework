# 0053: The requester hears at three moments — started, in review, delivered — on the tracker task, on a yes, never on the pull request

- **Status:** accepted
- **Date:** 2026-10-23
- **Amends:** [0033](0033-pull-request-upkeep-without-prompts.md) — `/stakeholder-update` no longer
  comments on the pull request, so "requester-visible text is still confirmed, in chat" covers only
  the tracker

## Context

Since v1.0.0, `/stakeholder-update` showed its draft in chat, then posted it on the pull request as
one comment, under a "For the team" note, "so the team can relay it". The tracker got it only on the
developer's yes to the exact text. The pull request comment came with the skill, generalized from a
field-proven one; no decision record chose it.

A long session in an adopting project, with the `clickup`, `github`, `e2e`, `docker`, and
`parallel-agents` modules, showed what that costs:

- **The developer rejected the updates posted on pull requests.** Reviewers aren't their audience,
  and once the text is revised in chat, the pull request copy is a second version that drifts from the
  one the client reads.
- **The tracker couldn't show the screenshots inline.** ClickUp's comment tool takes markdown only,
  and its upload tool attaches a file to the task, not to the comment. A pasted image is the one way
  to put a picture beside its sentence.

The same session showed what the skill left to chance, with no rule to follow:

- **Taking the screenshots** — consent banners, sharpness, what to frame, and whether anything on
  the client's site may be clicked.
- **Who the comment is for** — a comment that needs an answer from the requester tells them so by
  its assignee, and a mention notifies only in the tracker's own syntax.
- **A reply that can be read more than one way** — one reading can be new work, and a question from
  the earlier update can go unanswered.
- **Which preview to link** — a deploy's own URL changes with the next push; some hosts also give each
  pull request a stable address.

The skill also ran only once, at the end, and only when asked. A typical development workflow
updates the task earlier, twice:

- **When the task is received and understood** — the task moves to in progress, and the requester
  hears what the team understood, or the questions only they can answer, while those still cost
  little.
- **When its pull request opens** — the task moves to review, and the requester gets a business-focused
  report: the preview, what to test there, and the pull request.

Between them, the requester heard nothing from the triage to the merge, and the task's status stayed
wherever someone left it.

## Decision

- **Three moments, each a draft in chat.** Tracker-originated work, light changes included:

  | Moment | Drafted by | Task status | Message |
  |---|---|---|---|
  | **Started** | `/triage`, after it's stated | in progress | Only when it's worth the requester's time: what we understood, questions only they can answer, a finding |
  | **In review** | `/open-pr`, after the preview walk | review | Always: what changes for them, the preview and what to test there, and the pull request |
  | **Delivered** | when merged or live, or when asked | where the change is now | Always, as before |

  The status change and the message are one approval, with the assignee. The work goes on while the
  draft waits: the started update's draft ends triage's turn, and the review update's ends
  `/open-pr`'s report. If the draft opens in the same turn as the triage, the review update replaces
  the started one. An answer-only task has no review moment.
- **The review update links the pull request** — the one update that does, beside the preview and
  what to test — unless the project says requesters can't open it. `docs/TRACKER-INTEGRATION.md`
  § Stakeholder updates gains the status for each moment and whether requesters can open pull
  requests; `CONTRIBUTING.md`'s status words gain "in progress". The review update is the tracker
  link-back.

- **The draft shown in chat is the deliverable.** `/stakeholder-update` writes nothing on the pull
  request. It goes on the tracker task only after the developer approves the exact text. If the
  developer posts it themselves, nothing is posted anywhere.
- **The assignment is part of the same approval.** The comment is assigned to the requester when it
  asks them a question or needs an action or a decision from them, and isn't when it only informs.
  The developer approves both together: "post this and assign it to Dana". Mentions use the
  tracker's mention syntax. After posting, the agent reads the comment back to confirm the text and
  the assignee.
- **Images the tracker can't inline become placeholders.** The agent hands the image files to the
  developer in chat, posts the text with a `[Screenshot N: <what it shows>]` line where each image
  goes, and asks the developer to paste each image over its placeholder. It never uploads the images
  to the task to "embed" them.
- **Screenshots are taken read-only, from the preview or the live site.** With Playwright:
  - a desktop viewport and `deviceScaleFactor: 2`;
  - wait for the data the shot depends on;
  - hide consent banners by injecting CSS after load, and never accept or decline cookies;
  - screenshot the element, not the full page.

  Each image is shown to the developer before it's used. These are steps in the skill, not a
  script: the selectors and pages differ per project.
- **The stable preview address, when the project has one.** `docs/TRACKER-INTEGRATION.md` §
  Stakeholder updates gains a slot for it, and lines for whether comments can inline images and how
  to mention someone.
- **Tracker facts live in the tracker's module.** The `clickup` module's `MODULE.md` records what
  the ClickUp connector did in October 2026 and the lines a ClickUp project writes into
  § Stakeholder updates. The skill stays generic.
- **`/triage` confirms a reply it can read more than one way.** It lists the readings with what each
  costs (no change, a change request on the spec, new work), recommends one, and drafts a short
  confirming reply for the developer to approve. The reply carries every question left unanswered.
  Nothing is built until the reading is confirmed.

## Consequences

- **Positive:**
  - The requester hears when the work starts and when there's something to try, not only at the
    end, and the task's status follows the work.
  - Questions reach the requester at the start, when an answer is cheapest.
  - One copy of each update, in front of the one person who decides where it goes.
  - Reviewers aren't notified about text that isn't for them.
  - A posted comment is checked, not assumed, and its assignee tells the client when an answer is
    needed.
  - Screenshots show what the sentence points at, without changing anything on the client's site.
  - An ambiguous reply costs one short confirming message instead of the wrong work.
- **Negative / cost:**
  - **Two more approvals per task** — the started and review updates. Each rides at the end of a
    message the developer already reads, and nothing waits for it. A started update with nothing
    worth saying is only a status change.
  - **The pull request reaches the requester.** A requester who can't open the repository gets a
    broken link; the project's setting drops it.
  - **A team that relayed updates from the pull request loses that place.** The developer now
    passes the draft on, or asks the agent to post it on the tracker. A project that wants the old
    behavior can say so in its own instructions.
  - **The developer pastes images by hand** while the tracker's comment tool can't inline them. One
    paste per image, checked by a read-back where the tracker shows a pasted image in the text.
  - **The ClickUp facts are observed, not documented by ClickUp.** They come from one session and
    the connector's tool descriptions; this change didn't exercise them. They're dated so a later
    reader knows to check again.
  - **One more round trip on an ambiguous reply.** That round trip is the point: the requester's
    answer costs less than building on a guess.

## Alternatives considered

- **Move the task and post the started and review updates without asking.** Declined for now: they
  reach the client under the developer's name, and the tracker's rules confirm every requester-visible
  write (decision 0005). A project can choose otherwise in its own instructions.
- **Always send a started message.** Declined. "We've started" is what the status change says; a
  message the requester skims trains them to skim the next.
- **Keep the pull request out of every update.** Declined for the review update: the requester
  tests there, and the framework's maintainers asked for the link. Where requesters can't open it, the
  project's setting leaves it out.

- **Keep the pull request comment, behind the developer's yes.** Declined. The developer said no to
  it, and the comment's readers aren't the client.
- **Post the update on the pull request and the tracker together.** Declined. Two copies drift, and
  the pull request copy has no reader who needs it.
- **Upload the images to the task as attachments.** Declined. They land on the task, not in the
  comment, out of order and away from the text.
- **A screenshot script in the `e2e` module.** Declined. The pages, banners, and elements differ per
  project, and the agent writes the few Playwright calls each time. The rules that matter — read-only,
  no consent clicks, element shots, shown first — are steps in the skill.
- **Put the ClickUp syntax and limits in the skill.** Declined. The skill serves any tracker; a
  tracker's facts go in its module and the project's `TRACKER-INTEGRATION.md`.
- **Build on the likeliest reading of an ambiguous reply.** Declined. A wrong reading reopens
  delivered work or builds something nobody asked for, and the requester is the only one who knows.
