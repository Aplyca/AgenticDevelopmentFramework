# 0073: The ticket is for stakeholders, the pull request for the developer

- **Status:** accepted; amended by [0075](0075-a-status-only-tracker-update-needs-no-prompt.md) — a status-only move can pass the tracker tool's prompt
- **Date:** 2026-11-12
- **Amends:** [0053](0053-stakeholder-updates-at-three-moments.md) — the review and delivered updates
  post on their own, and the delivered moment is when the change is live;
  [0059](0059-task-status-follows-the-work-and-stakeholder-guides.md) and
  [0063](0063-reference-files-and-status-moves-in-the-calling-skill.md) — the status moves for the
  session's own task, assigned or not, and to delivered only once live;
  [0064](0064-tracker-writes-through-the-projects-server.md) — the project's tracker tool is its
  server, or `gh` or `glab` for issues; [0072](0072-agents-implement-and-review-humans-decide.md) —
  the review instructions live in the pull request's description, not the chat report

## Context

Adopting projects reported that agents weren't keeping the ticket current. The parts existed — a
status that follows the work (0059), an update at three moments (0053) — but four gaps left tickets
empty:

- **The ticket's text waited for a yes that often never came.** Every update was a draft in chat,
  posted only on the developer's approval of its exact text. The pull request link rode on the
  review update, so an unanswered draft left the ticket with no outcome and no link.
- **Status moves skipped quietly.** The agent moved a status only on a task the developer was
  assigned to. A task handed to the session by someone not yet assigned stayed where it was.
- **"Delivered" fired at the merge.** `/wrap-up` moved the task to done once the pull request
  merged, though a project with quality control, acceptance testing, or a release step isn't live
  then, and those statuses are the developer's to set.
- **Only ClickUp was worked out.** GitHub issues had one line, GitLab issues none, and neither has
  statuses for the three moments to map to.

Two smaller ones: the usage guide was an optional paragraph no skill owned, and the developer's
review instructions — where to look, what to try — were in the agent's chat report, not in the pull
request the reviewers open.

## Decision

- **The principle: the ticket is for business communication with stakeholders; the pull request is
  for technical communication with the developer.** A ticket is a ClickUp task, a GitHub issue, or a
  GitLab issue; a pull request is GitHub's, or GitLab's merge request.

  | Moment | The ticket — business | The pull request — technical |
  |---|---|---|
  | Work starts | Moves to in progress | — |
  | Specification | The usage guide's draft, when the task needs one | — |
  | Ready for review | Moves to in review; the outcome update, with the pull request for reference | Marked ready; the description carries the review instructions |
  | Quality control, acceptance testing, release | The developer's statuses — the agent leaves them | The developer reviews, approves, and merges |
  | Merged and live | The outcome update; the usage guide brought up to date; moves to delivered | — |

- **The review and delivered updates post on their own.** They report an outcome in the requester's
  terms, from the template, with every claim verified, through the project's tracker tool as the
  developer, and read back. The agent's report shows the text it posted. Still a draft in chat, for
  the developer's yes to its exact text: the started message, an answer-only task's answer — an
  analysis, an estimate, a recommendation — and any message that needs something from the requester:
  a question, an action, a decision, an assignment. Questions that come with an
  outcome are a second message, so the outcome doesn't wait for them. A project that wants every
  message approved says so: **Updates post: on the developer's yes** in
  `docs/TRACKER-INTEGRATION.md`. The tracker's own permission prompt still applies.
- **The ticket always gets its pull request, for reference** — in the review update. Where the
  project says requesters can't open pull requests, the line is worded for the team. On GitHub and
  GitLab issues the host links the two when the description says `Refs #N` (`Related to #N`).
- **The review instructions live in the pull request's description.** *How to verify* becomes *How
  to review and test*: where to review it (the preview), the steps to try and what to expect, what
  deserves the reviewer's attention, and the tests. *Verified / not verified* is the summary of the
  tests done. Both are rebuilt just before the pull request is marked ready, so the reviewers
  requested then find them. The chat report points there instead of repeating them. The section's
  marker stays `adf:how-to-verify`, so an open pull request still refreshes.
- **Delivered means live, not merged.** A **Live when** setting says which: on the merge, on a
  release, or when the developer says. Until then the agent posts nothing and moves nothing — quality
  control, acceptance testing, and release statuses are the developer's — and says once that the
  delivered step waits. `/stakeholder-update delivered` runs it from any session once the change is
  verified live: the outcome update, the usage guide, the status.
- **The usage guide is decided and drafted with the spec.** `/write-spec` fills *Documentation ›
  Usage guide* — how the requester will use what the task delivers, in their terms — or says Not
  applicable. It's approved with the spec at the gate, posted then as a draft where the project keeps
  it (a comment on the task, by default), reconciled with the docs when the build changes it, and
  brought up to date at delivered (`/stakeholder-update guide`). With the `end-user-docs` module, the
  doc tool's page is the guide (0048). The fast and careful lanes have no spec phase: a guide such a
  change needs goes in its delivered update.
- **GitHub and GitLab issues are trackers too.** `docs/TRACKER-INTEGRATION.md` § Issues as the
  tracker gives each action's `gh` and `glab` command. An issue has no statuses, so in progress and
  in review are labels the project names, and delivered closes the issue after its outcome comment.
  A label the repository lacks is a question, not one the agent creates. A requester's issue is
  referenced (`Refs #N`), never closed by the merge (`Closes #N`): a merge isn't live. Board fields —
  GitHub Projects, GitLab boards beyond labels — are out of scope.
- **The session's own task needs no assignment check.** The task the developer handed the session is
  theirs to move and update. Any other task still asks first.
- **A tracker the agent can't write to is said first, not last.** With no tracker tool, or only a
  connector built into the host app (0064), the report opens with what the developer should set and
  post, the text ready to paste.

## Consequences

- **Positive:**
  - A ticket shows where the work is and what it delivered without the developer remembering to
    approve a draft, and carries its pull request.
  - The reviewer finds how to review in the pull request; the requester finds the outcome on the
    ticket. Neither reads the other's text.
  - "Delivered" on the board means the requester can use it.
  - A project on GitHub or GitLab issues gets the same three moments.
- **Negative / cost:**
  - **A message reaches the requester under the developer's name without their reading it first.**
    It's limited to outcome reports, verified, with nothing asked; the report shows the text, and a
    correction edits the comment. A project that can't accept that sets *Updates post*.
  - **An upgraded project gets the new default** without choosing it: the changelog says how to keep
    the yes.
  - **The delivered step can outlive the session.** When a release comes days after the merge,
    someone has to run `/stakeholder-update delivered`; the wrap-up says so once, and nothing reminds.
  - **Labels are a convention.** A repository that doesn't have them gets a question at the first
    task, and an issue's "status" is only as good as its labels.
  - **The usage guide's text is in the spec,** so the repository holds a copy of what the task shows.
    The spec is the source; the task's copy is rewritten from it.

## Alternatives considered

- **Keep every post behind a yes (0053 as it was).** Declined as the default: it's what left the
  tickets empty. Kept as a setting.
- **Post everything on its own, questions included.** Declined: a question or an assignment asks the
  requester for something in the developer's name; that stays the developer's call.
- **Put the review instructions in a pull request comment at ready.** Declined: a comment drifts
  from the description after the next push, and the description is what `refresh` keeps current.
- **Move the task through acceptance testing and release on the agent's own.** Declined: those say a
  person checked or released it, which the agent can't know.
- **Close a requester's issue with `Closes #N`.** Declined: the host closes it at the merge, before
  the change is live and before the outcome is written.
- **A usage guide file in the spec folder.** Declined: a fourth file in every folder for a section's
  worth of text. It's a subsection of *Documentation*.
- **Create missing labels.** Declined: labels are the repository's vocabulary; the team names them.
