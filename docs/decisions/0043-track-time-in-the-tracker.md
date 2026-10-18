# 0043: A task's time goes to the tracker as two numbers, and the developer picks one per entry (time-tracking module)

- **Status:** accepted
- **Date:** 2026-10-17

## Context

Some teams that adopt the framework want an internal productivity measure: what a task actually took
with AI assistance, next to what it would have taken without it. Neither number was recorded
anywhere. Other teams don't track time at all, and shouldn't see the feature.

Most of the inputs already exist:
- Claude Code keeps every session's transcript on the developer's machine. Each event carries its
  timestamp and the branch it ran on, and `/cost-report` already turns the gaps between events into
  active time.
- Each task has its own branch, and with the parallel-agents module its own worktree and session
  (decision 0042), so a session can be tied to a task.
- The tracker connection exists, and its rules already put time entries among the writes that need
  the developer's yes (`docs/TRACKER-INTEGRATION.md` § Rules for agents).

What the transcripts can't see is the work done outside the sessions: understanding the task,
research, debugging, manual tests, code review, task management, reporting, meetings.

## Decision

- **A `time-tracking` module turns the feature on.** Its `module.json` names `/track-time`, which
  `adf` carries, as `/dispatch` is carried for `parallel-agents`. It installs `docs/TIME-TRACKING.md`,
  the project's settings and activities. The skill acts only where the stamp on `AGENTS.md`'s first
  line names the module, and `/wrap-up` offers it only there. A committed install gets the skill only
  with the module.
- **`/track-time`** drafts a task's time entries since its last logged entry: at a milestone, after
  significant partial work, or after the merge. `/wrap-up` offers it once, before the close-up, while
  the task's worktree is still there.
- **One entry per day worked, with two numbers:**
  - **AI-assisted** — the time actually spent. Session time comes from the transcripts: the sessions
    that ran on the task's branch, with the work before the move — all of it in the desktop app's own
    worktree, on its generated `claude/<name>` branch, and only the run just before the move on the
    base branch, where a long-lived session did other work first. Two of the task's sessions at once
    count each minute once. Work outside the sessions is estimated activity by
    activity, from the evidence each one left — the tracker task, the pull request, commits outside
    the sessions, approved checks, what the developer said. An activity with no evidence isn't in the
    draft; the draft asks what else the developer did.
  - **Manual estimate** — what a senior developer, fluent in the stack and familiar with the
    codebase, would have spent on the same activities without AI. There is no calibration against a
    team's reference tasks.
- **Ballpark figures in whole units, rounded up.** The unit is the project's setting, an hour by
  default. A day's numbers rest on the activities actually worked on, not on a count by the minute.
- **The developer picks one number per entry**: AI-assisted, the estimate, an edited value, or skip.
  Only the approved entries are written, each labelled with the number it carries.
- **Each task gets its full time.** Sessions of different tasks that overlap aren't split: the
  measure is per task.
- **The tracker's time entries are the only record.** Nothing about the time goes into the
  repository, the spec folder, the pull request, or a memory. The tracker's existing entries also
  set where the next run starts, so a milestone and the wrap-up never log the same day twice.

## Consequences

- **Positive:**
  - A team that turns it on gets both numbers per task and per day, without anyone timing their work.
  - A team that doesn't never sees it: no offer at the wrap-up, no skill that acts.
  - Nothing new is committed beyond the settings, and no time data reaches the tracker without the
    developer's approval.
  - The script reads local files only, like `/cost-report`.
- **Negative / cost:**
  - **Both numbers are partly judgment.** The off-session time and the manual estimate vary with the
    model and the evidence. Whole units and the activities named on each entry keep them reviewable,
    and the developer edits any entry.
  - **Rounding up per day adds up.** A short day counts as a whole unit. It's a ballpark by design.
  - **Only this machine's transcripts count.** Work on another machine is off-session work.
  - **Session time isn't attention.** An agent working while the developer does something else
    counts as the task's time. Overlapping tasks each count it too, so the sum across tasks can
    exceed the hours worked.
  - **A tracker without time entries** needs the project to name another place in its settings.

## Alternatives considered

- **A section in the skeleton's `TRACKER-INTEGRATION.md`, present or not.** Declined. A project that
  doesn't track time would still carry it, and modules are already how a project turns a feature on
  (decision 0023).
- **A setting in `.claude/hooks/config.sh`.** Declined. That file configures the hooks, and the
  stamp is where `/upgrade` and the skills read a project's modules.
- **Count by the minute, or give a range.** Declined. The measure is a ballpark; whole units rounded
  up are easier to compare and don't suggest a precision the estimate doesn't have.
- **Ask the developer for every off-session duration.** Declined. The skill estimates each activity
  from its evidence, and the developer corrects the draft.
- **Estimate before the work, at triage.** Declined for now. An estimate made after the work rests on
  what was actually done.
- **Split overlapping time across tasks.** Declined. The measure is per task.
- **Keep the breakdown in the spec folder or the pull request.** Declined. The tracker is the only
  record, and time data stays out of the repository.
- **Put it in `adf-dev`.** Declined. Estimating and writing to the tracker are process, which `adf`
  carries (decision 0023).
