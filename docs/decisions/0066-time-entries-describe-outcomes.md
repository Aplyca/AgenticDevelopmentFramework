# 0066: A time entry's description says what the day delivered, in business terms

- **Status:** accepted
- **Date:** 2026-11-02
- **Amends:** [0043](0043-track-time-in-the-tracker.md) — what an entry's description says

## Context

- **`/track-time` wrote the activities as each entry's description:** "Understanding the task,
  signup form and its tests, manual test". They justify the numbers, and they're what the skill
  estimates from.
- **The tracker's time entries are read by people who don't read the code:** team leads, account
  managers, and clients when the reports reach them. A list of activities tells them how the hours were spent, not
  what they bought. The same entry with "implementation, tests, PR review" could describe any day of
  any task.
- **The stakeholder update already writes for these readers** (`/adf:stakeholder-update`): what
  changes for visitors or users, with no code, file, or tool names.

## Decision

- **Each entry's description says what the day delivered, in business terms,** for the people the
  task serves: "Readers can subscribe to the newsletter from the article they're reading." It comes
  from the task's goal — the tracker task, the spec's Business section — and what the day's work
  achieved toward it.
- **A day with nothing delivered yet says what it found, settled, or unblocked:** "Found why new
  subscribers got no confirmation email; the fix is agreed with the requester."
- **One or two sentences, with no code, file, or component names, commands, branches, or tool
  names.**
- **The activities stay in the draft,** beside the numbers, so the developer can check them. They
  aren't written to the tracker.
- **The developer approves the description with the number,** and may edit it in the same answer.
- **`docs/TIME-TRACKING.md` § Descriptions** says the rule for the team, with an example, and takes
  the team's own convention, if any.

## Consequences

- **Positive:**
  - The tracker's reports say what each day of a task produced, in the terms of whoever reads them.
  - Entries of different tasks can be told apart without opening the task.
- **Negative / cost:**
  - **The numbers are harder to check from the tracker alone.** The activities behind them are seen
    only in the draft; 0043's "activities named on each entry" no longer holds once the entry is
    written.
  - **An outcome is a judgment too.** The developer reads it before it's written, as with the
    numbers.

## Alternatives considered

- **Both in the description: the outcome, then the activities.** Declined. The readers the entry is
  for don't need the activities, and the description gets long and technical again.
- **A placeholder setting in `docs/TIME-TRACKING.md` for the description's style.** Declined. Every
  project would have to answer it before the skill runs; a default with a place for the team's own
  convention asks nothing.
