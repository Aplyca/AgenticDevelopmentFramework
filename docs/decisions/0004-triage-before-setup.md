# 0004: Triage a task before setting anything up

- **Status:** accepted
- **Date:** 2026-10-01

## Context

Workflows that fix an agent's first actions — "start the environment", "every task gets a spec" —
work for features and fail for everything else. In one project, a task asked for an impact analysis
of a platform change: what changes, what it affects, what must be done. The agent built the app
image, installed dependencies, and wrote a spec folder with a migration plan before producing any
analysis. The developer stopped it; the analysis — the actual deliverable — came afterwards. None of
the setup was used.

The opposite failure is just as common: a change request on delivered work treated as a new feature
and re-analyzed from scratch, silently dropping or redoing what was built.

## Decision

Every task starts with **triage** (`/triage`). Before creating any file or starting anything, the
agent reads the task in full — description, comments, attachments — checks for prior work (spec
folders, history, open branches), and states in its first message:

- **Deliverable** — an answer or a change.
- **Kind** — new feature, change request, bug, chore, process change, hotfix.
- **Environment** — only when the next step runs the app, the tests, or the database.
- **Spec folder** — new, amend (`CR N`), or none: the test is "is there anything to decide?".
- **Open questions** — every requirement gap, as a question.

The agent then acts on its triage without waiting; the developer redirects it if it misread. The
approval gate (decision 0002) still stops every change before implementation code.

## Consequences

- **Positive:** no environment builds or spec folders for work that won't use them; a misread shows
  up in the first message, before it costs anything; change requests are recognized as such.
- **Negative / cost:** triage is a judgement and can be wrong both ways. Because the agent doesn't wait
  after stating it, a misread costs something until the developer reads the message.

## Alternatives considered

- **Wait for approval of the triage.** Adds a gate to every task, including obvious ones; the
  expensive mistakes are already caught by the approval gate before code.
- **Fixed first steps (environment, then spec).** The status quo; spends the most on the tasks that
  need the least.
