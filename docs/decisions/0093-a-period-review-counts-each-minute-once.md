# 0093: A day's or a week's review across tasks counts each minute once (time-tracking module)

- **Status:** accepted
- **Date:** 2026-11-22
- **Amends:** [0043](0043-track-time-in-the-tracker.md) — `/track-time` also reviews a day or a week
  across tasks
- **Builds on:** [0092](0092-time-entries-are-outcomes-with-a-midpoint.md) — entries are outcomes,
  with a midpoint, in whole units

## Context

- **`/track-time` measures one task at a time** ([0043](0043-track-time-in-the-tracker.md)). Each
  task gets its full session time, and sessions of different tasks that overlap aren't split. 0043
  already names the cost: the sum across tasks can exceed the hours worked.
- **Issue [#79](https://github.com/aplyca/AgenticDevelopmentFramework/issues/79) asked for a period
  review** of a day or a week. A team that logs its time weekly runs the per-task flow once for each
  task and still has no view of the day. Adding up the tasks' rows counts the minutes two tasks
  shared twice, and with the parallel-agents module, two tasks' sessions often run at once.
- **The manual estimate has no overlap.** Without AI, a developer works on one task at a time.
- **The tracker can't give the review on its own.** Each entry carries the one number the developer
  picked, and work that isn't logged yet isn't there at all.

## Decision

- **`/adf:track-time day [<date>]` or `week [<date>]` reviews every task worked on in that period.**
  Only some runs reach it, so its steps live in a reference file beside the skill, `period.md`
  ([0063](0063-reference-files-and-status-moves-in-the-calling-skill.md)). A week runs Monday to
  Sunday unless `docs/TIME-TRACKING.md` § Settings names another first day.
- **A second script, `period_time.py`, measures the period.** It imports `session_time.py`'s
  measure, so each task's time is the same as in a per-task run.
  - It finds every branch a session ran on in the period, except the base branch. A session that
    moved off the app's generated branch counts for the branch it moved to.
  - For each day, it prints each branch's time and blocks. It also prints the day's own active time,
    with every branch's sessions merged so a shared minute counts once, and the overlap: how far
    the branches' times add up beyond the day's.
  - `--branch` keeps only the tasks in the review, so the day's figures follow when the developer
    leaves a branch out.
- **Each task's rows come from the per-task steps,** one per task and outcome (0092). The period's
  end is a cutoff: work toward an outcome not delivered by then is an outcome of its own for the
  period — what it found, settled, or unblocked. An outcome already logged keeps its row with its
  three numbers, so the period's figures are whole, and shows the entry the tracker holds. It gets
  no pick.
- **Each day gets a row with the time actually spent:** the day's active time from the script, plus
  each task's work outside the sessions that day, rounded up once to a whole unit. An activity for
  several tasks, such as one meeting about two of them, counts once. A day has no midpoint or manual
  estimate: those belong to outcomes, which may span days.
- **The period's row has all three numbers:**
  - **AI-assisted:** the sum of its days. Days don't overlap: a block belongs to the day it starts
    on, as in a per-task run.
  - **Manual estimate:** the sum of the tasks' estimates.
  - **Midpoint:** the sum of the tasks' midpoints. It rates the work, as the manual estimate does,
    so a shared minute doesn't reduce it; it always lies between the period's other two numbers.
  - **The overlap:** the draft says how far the tasks' AI-assisted rows add up beyond the period's.
- **The day's and the period's rows are never entries.** Step 8 writes each approved task row on its
  own task, and the tracker stays the only record.
- **Work with no task stays out.** That covers sessions only on the base branch and a branch the
  developer leaves out. A fallback task for that work is the other gap #79 lists, not covered here.

## Consequences

- **Positive:**
  - A day's or a week's total that counts each minute once, beside each task's full time.
  - Each task's numbers match a per-task run, since both scripts share the measure. A test checks
    this.
  - A team that logs weekly runs one review instead of one run per task.
- **Negative / cost:**
  - **Two figures to read.** The period's AI-assisted total is below the sum of its tasks' rows
    whenever their sessions overlapped. The draft says by how much.
  - **No manual estimate or midpoint per day.** A team that wants the gap day by day reads it per
    outcome or for the period.
  - **A logged outcome is estimated again** so the period's row has its numbers. Its entry in the
    tracker doesn't change.
  - **A day can look shorter than the hours worked.** Work with no task and work on another machine
    aren't in it, except as off-session activities the developer names.
  - **Tasks are found by branch.** A branch's task comes from its spec or its pull request, or the
    developer names it.

## Alternatives considered

- **Add up the tasks' rows for the day.** Declined: overlapping sessions would count twice.
- **Split the overlap across the tasks.** Declined, as in 0043: the measure is per task, and the
  day's row is where the overlap counts once.
- **Merge the manual estimates as well.** Declined: without AI, the tasks' work runs one after the
  other.
- **Count the overlap once in the midpoint too.** Declined: the midpoint rates the work, like the
  manual estimate; only the time actually spent is merged.
- **Split each outcome's estimates across the days it spans.** Declined: the split would be a guess
  on top of an estimate, and the entries are per outcome.
- **Build the review from the tracker's entries alone.** Declined: each entry carries one number, and
  work not logged yet is missing.
- **A `--period` mode in `session_time.py`.** Declined: its arguments are a branch and a project, and
  a second script keeps both command lines plain while sharing the measure.
