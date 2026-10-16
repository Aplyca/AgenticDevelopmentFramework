# 0042: The plugin reports time per task, writes docs outside the repository, and turns recurring tasks into project skills

- **Status:** accepted
- **Date:** 2026-10-16

## Context

Three gaps showed up in adopting projects, each covered by a personal skill a developer kept beside
the framework ([issue #79](https://github.com/aplyca/AgenticDevelopmentFramework/issues/79)):

- **Time per task.** Teams that log time in their tracker rebuilt it by hand. `/adf:cost-report`
  already reads the transcripts and measures active time, but per session and in dollars, not per
  task and day. Work outside the sessions — manual checks, staging checks, client updates — left no
  trace, so it was either forgotten or guessed.
- **Docs outside the repository.** `/adf:write-docs` writes the docs a plan lists, in the
  repository, before implementation. Editor and client guides often live in the tracker's docs or a
  shared document, and drafts for them invented labels and read machine-written: filler,
  reassurance, a bold lead-in on every line.
- **A project's recurring tasks.** Adoption brings the process, but a project's own repeated tasks —
  add a redirect, scaffold a content block — stayed in people's heads. Where a team wrote skills for
  them ad hoc, some restated what the framework already holds: a `/verify` skill repeating the
  project's check commands, which belong in the Quick reference.

## Decision

- **`/adf:time-report`, plugin-only, beside `/adf:cost-report`.** Its script reuses
  `session_cost.py`'s parsing. It measures blocks of session activity per day and branch, splits
  overlapping sessions' time evenly, counts subagents with their session, and lists the developer's
  commits. The skill adds labeled estimates for work outside the sessions, applies the project's
  rounding once per task, and proposes entries; logging needs the developer's yes. A project's
  rounding, allowances, and fallback tasks live in `docs/TRACKER-INTEGRATION.md` § Time reports;
  without them it reports minutes with default allowances.
- **An external mode in `/adf:write-docs`,** not a new skill: a brief first (reader, purpose,
  destination), the destination read and its voice copied, every fact sourced, the full page
  returned for review, never published without a yes. A slop pass now ends every mode.
- **`/adf:new-skill`, plugin-only.** It writes one project skill in `.claude/skills/` from two or
  more past occurrences, in the framework's skill shape, with the lane named and a check script only
  for an invariant a script can decide. It never shadows a framework skill, and points checks at
  `AGENTS.md` § Quick reference.

## Consequences

- **Positive:**
  - Time proposals rest on evidence the developer can check line by line, and arrive at the
    delivery, once, instead of at the end of the week.
  - External guides get the same discipline as repository docs: sourced facts, the reader's register.
  - A project's recurring tasks become skills that read like the framework's, and don't fork it.
- **Negative / cost:**
  - **Two more plugin-only skills** in every session's skill list where the plugin is on.
  - **Session time isn't work time.** Blocks miss thinking away from the keyboard and include idle
    minutes under the gap; the proposal says measured, and the developer decides.
  - **`--worktrees` sees only worktrees git still lists.** A close-out runs before `/adf:wrap-up`
    removes the task's worktree.
  - **`write-docs` grows** by an external mode; the first pass and update mode are unchanged.

## Alternatives considered

- **A `time-report` module.** Declined: the skill writes nothing to the repository, like
  `/adf:cost-report`; a team that doesn't log time leaves § Time reports out and never runs it.
- **Calendar and meeting notes as evidence.** Declined for now: they need a per-developer Google or
  Microsoft connection and a project-specific meeting map. A team can add them in its own skill.
- **A separate `write-external-docs` skill.** Declined: it would repeat `write-docs`' sourcing rules
  and drift from them.
- **A project `/verify` skill per project.** Declined: the Quick reference already holds the
  project's checks, and every skill reads it.
