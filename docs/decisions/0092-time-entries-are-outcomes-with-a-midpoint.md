# 0092: A time entry is an outcome, with a midpoint between the two numbers

- **Status:** accepted
- **Date:** 2026-11-21
- **Amends:** [0043](0043-track-time-in-the-tracker.md) — what an entry covers, and the numbers it
  offers; [0066](0066-time-entries-describe-outcomes.md) — its description says what the outcome
  delivered, not the day

## Context

- **`/track-time` wrote one entry per day worked.** Since 0066 each description says what the day
  delivered, but the entry is still cut by the calendar: an outcome that took three days shows as
  three entries, each describing a share of it, and two outcomes finished in one afternoon share one
  entry. The tracker's reports read as days worked, not as what the time bought.
- **The work already has outcomes of its own:** the plan's tasks, ticked in the commit that completes
  them; the tracker task's subtasks and milestones; the pull request's approval, its acceptance on
  the preview, the merge. The skill runs at those moments — after a milestone, after significant
  partial work, after the merge.
- **The two numbers sit far apart.** The AI-assisted time undercounts what the work is worth to the
  people who read the reports, and the manual estimate is a hypothetical. Teams asked for a value
  between them they can log as a fair figure — and how far apart the two are depends on the
  activity: a meeting takes as long either way, debugging and review rest on the developer's
  judgment, routine code is what AI speeds up most.

## Decision

- **One entry per outcome:** a milestone reached, a completed task of the plan, value delivered to
  the people the task serves — the smallest piece they would recognize as done or settled. Tasks
  that deliver only together are one outcome. A commit, a session, or a day is never one.
- **The time goes to the outcome it served.** Each working block from the transcripts, and each
  off-session activity, is assigned by what it did — the commits it made, the tasks it ticked, what
  it was about. A block that served two outcomes is split; each minute counts once.
- **Each entry ends at its outcome's delivery:** its start is the delivery minus the chosen
  duration. The end of the latest entry still sets where the next run starts.
- **Work toward an outcome not delivered yet:** before the latest delivery, it is an outcome of its
  own — what it found, settled, or unblocked. After it, it waits for the next run, unless the run is
  the wrap-up's or the developer asks to log it now.
- **A third number, the midpoint,** between the AI-assisted time and the manual estimate, set
  activity by activity: as spent (the AI-assisted time), halfway, or nearer one end — a quarter of
  the way from it. `docs/TIME-TRACKING.md` § Activities gives each activity its default — meetings,
  manual testing, and task management as spent; debugging and code review nearer the manual
  estimate; the rest halfway — and the team may move them. The evidence may move one too, with the
  reason in the draft. Never below the AI-assisted time or above the manual estimate. The midpoint
  is the sum of its activities' midpoints, rounded up once.
- **The developer picks one of the three, an edited value, or skip,** and the entry is labelled
  with the number it carries; the label for the midpoint is the project's setting.

## Consequences

- **Positive:**
  - The tracker's entries say what each piece of time bought, one outcome at a time, and line up
    with the plan's tasks and the task's milestones.
  - A team that logs a fair figure has one with a rule behind it, instead of editing a number by
    hand.
- **Negative / cost:**
  - **Assigning blocks to outcomes is a judgment.** Interleaved work splits by what each block did,
    a ballpark the developer checks in the draft.
  - **An entry's place in the tracker is approximate.** It ends at the delivery and stretches back
    by its duration, which may not match when the work was done; overlapping entries are possible.
  - **The midpoint is judgment twice over:** it rests on the manual estimate, and its weighting per
    activity is a convention, not a measurement.
  - **Upgrading projects merge `docs/TIME-TRACKING.md`.** Without the midpoint column, the skill uses
    halfway, and as spent for a meeting or a manual test.

## Alternatives considered

- **Keep one entry per day, with the outcome in the description (0066).** Declined. An outcome that
  spans days is split, and a day with two outcomes merges them.
- **The plain average of the two totals.** Declined. It would halve the time of a meeting that took
  as long either way, and it ignores where the developer's judgment carried the work.
- **A fixed ratio of the manual estimate.** Declined for the same reason: the gap differs by
  activity.
- **Wait for every outcome to be delivered before logging anything.** Declined. A long investigation
  would go unlogged; it is logged for what it found or settled.
