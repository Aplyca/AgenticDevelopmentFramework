# 0082: Follow-ups found along the way are filed as issues, not started as sessions

- **Status:** accepted
- **Date:** 2026-11-15
- **Amends:** [0054](0054-found-along-the-way.md) — where a finding outside the task goes, and the
  improvement question's "not now"; [0061](0061-wrap-up-starts-follow-ups-first-and-asks-about-time.md)
  — the close-up files the findings before it starts the sessions

## Context

0054 routes a bug or an improvement found outside the task to the pull request's `## Follow-ups`.
With the parallel-agents module, `/adf:dispatch` also offers it a new session at once, and
`/adf:wrap-up` offers to start each one left in a session of its own when the task ends.

[#155](https://github.com/aplyca/AgenticDevelopmentFramework/issues/155) reports that unrelated
follow-ups are better addressed as issues in the repository than as new sessions:

- **A session is the wrong default for unrelated work.** Starting it now is a scheduling decision,
  made mid-task or at the close-up, for work nobody has prioritized.
- **A follow-up nobody starts is lost.** It ends in a merged pull request's description, where no one
  searches, assigns, or prioritizes work.

The framework already has the right queue. `docs/TRACKER-INTEGRATION.md` § The pipeline defines
repository issues as "a queue for engineering-originated work … with no tracker task", and the
`github` and `gitlab` modules' issue templates say the same. A finding is exactly that.

## Decision

- **With the `github` or `gitlab` module, a follow-up found along the way becomes an issue in the
  project's repository, not a new session** (`specs/README.md` § Found along the way). Never a
  tracker task: the tracker is the requester's channel, and this work has no requester.
- **It's filed on the developer's yes, at a moment that already asks.** There's no new question:
  - **at the close-up**, `/adf:wrap-up`'s one yes lists the findings under "File as issues in
    `<repository>`, as `<account>`". The developer can move any of them to a session of its own, or
    drop it. The commands an upgrade writes (work the merge made necessary) still start as sessions;
  - **for an improvement to what this branch builds**, the developer's question gains a fourth
    answer: an issue, filed at once. The others are now (a change request), later as a follow-up
    line, and declined;
  - **whenever the developer says to file one.**
- **No session at once for a finding.** With either module, `/adf:dispatch` offers a new session for
  a finding only when the developer wants it started now. Without them, nothing changes: the chip at
  once, and a session at the close-up.
- **The issue carries the follow-up line.** Its title is the task. Its body has the why, `file:line`,
  how it's known and the lane when the session said, and where it was found: the pull request, which
  the host then links, or the answer's question. It gets the `bug` label when it's a bug and the
  repository has that label. A matching open issue is named instead of filed again. It's filed with
  `gh` or `glab`, signed in as the developer. When filing can't happen, the report gives the text to
  paste.
- **The pull request's line records it.** A follow-up filed during the task is ticked, with its link
  (`→ #<n>`): the developer's yes is the tick, and the close-up doesn't offer it again. At the
  close-up, the issue names the pull request and the host links the two. The merged description
  isn't edited.

## Consequences

- A finding the developer doesn't start now still reaches the team's queue, searchable and
  assignable, instead of a merged pull request's description.
- Fewer sessions. An unrelated finding no longer brings a chip mid-task, or a session at the
  close-up by default.
- No new stop. Filing rides on the close-up's existing yes and on the improvement question.
- Projects without the `github` or `gitlab` module behave as before.
- An issue is seen by whoever sees the repository's issues. That's the audience of the pull request's
  description, which already carried the line.

## Alternatives considered

- **File each finding at once, without a yes.** Declined. Unlike a line in the session's own pull
  request, an issue is a new item under the developer's name, and it notifies watchers.
- **Ask about each finding when it's found.** Declined. That adds a stop per finding, and the chip
  was already that question.
- **Ask in `/adf:open-pr`.** Declined. It reaches ready for review without a question, and the
  close-up already asks.
- **File in the tracker.** Declined. The tracker holds the requester's work; engineering work has no
  tracker task.
- **Replace `## Follow-ups` with issues.** Declined. Without the modules, the section is the only
  record, and the close-up reads it.
