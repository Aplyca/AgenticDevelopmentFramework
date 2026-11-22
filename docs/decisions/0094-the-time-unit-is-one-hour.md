# 0094: The time unit is one hour, in every project

- **Status:** accepted
- **Date:** 2026-11-22
- **Amends:** [0043](0043-track-time-in-the-tracker.md) — the unit is no longer the project's
  setting

## Context

- **0043 made the unit a setting,** an hour by default, and `/track-time` rounds every number up to a
  whole unit. [0092](0092-time-entries-are-outcomes-with-a-midpoint.md) extended the rule to every
  time the draft shows: no half units, decimals, or minutes.
- **A setting undoes that rule.** A team that sets the unit to 30 minutes gets half-hour entries —
  the precision the whole-unit rule exists to avoid — and its reports no longer compare with another
  team's.
- **Nobody needs the setting.** The measure is a ballpark per outcome, and an outcome rarely takes
  under an hour once the work around it is counted.

## Decision

- **The unit is one hour, in every project.** Every number `/track-time` shows or writes is a whole
  number of hours, rounded up: never a half hour, a decimal, or minutes.
- **`docs/TIME-TRACKING.md` has no Unit setting.** Its intro says the numbers are whole hours, and
  `/adf:adopt` no longer asks for a unit.
- **A Unit line a project kept is no longer read.** The skill says so when it finds one, and rounds
  to whole hours.

## Consequences

- **Positive:**
  - Every team's entries are in the same unit, so reports compare across projects.
  - One less placeholder for a team to fill in.
- **Negative / cost:**
  - **Short outcomes count as an hour.** A 20-minute fix logs one hour. It's a ballpark by design,
    as 0043 already accepted for short days.
  - **A team that wanted finer entries can't have them** without editing the skill.

## Alternatives considered

- **Keep the setting, but refuse a unit under an hour.** Declined. A unit of two hours or a day
  breaks comparison the same way, and nobody asked for one.
- **Keep the setting with a warning.** Declined. The rule would hold only where teams read the
  warning.
