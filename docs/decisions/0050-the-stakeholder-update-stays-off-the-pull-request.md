# 0050: The stakeholder update stays off the pull request — the draft in chat is the deliverable, and the tracker gets it only on a yes

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

## Decision

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
  - One copy of the update, in front of the one person who decides where it goes.
  - Reviewers aren't notified about text that isn't for them.
  - A posted comment is checked, not assumed, and its assignee tells the client when an answer is
    needed.
  - Screenshots show what the sentence points at, without changing anything on the client's site.
  - An ambiguous reply costs one short confirming message instead of the wrong work.
- **Negative / cost:**
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
