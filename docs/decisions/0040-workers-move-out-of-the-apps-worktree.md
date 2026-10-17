# 0040: A worker that starts in the desktop app's worktree moves to the task's worktree beside the main checkout

- **Status:** accepted; amended by [0042](0042-each-session-moves-to-its-task-worktree.md) (the branch is the one triage names, and `/adf:dispatch` makes the move)
- **Date:** 2026-10-15
- **Amends:** [0021](0021-sibling-worktree-and-chip.md) — where a chip's session opens;
  [0015](0015-tool-worktrees-are-workers.md) — a worker in Claude Code's own worktree renames its
  generated branch and works there

## Context

Decision 0021 had `/dispatch` offer a chip "for the main checkout, started in that folder". The chip's
session would open in the main checkout, create the task's worktree beside it with the scripts, and
move in.

In an adopting project, every task worktree ended up in `main/.claude/worktrees/`, under generated
names such as `silly-cannon-b424ff`, and none beside the main checkout. The desktop app gives every
chip's session a fresh worktree of its own, at its worktree location: inside the project by default,
on a `claude/<name>` branch. The session never opened in the main checkout.

The framework then kept it there. The worker's prompt said to create the task's worktree and move,
but the session-context hook, following 0015, told a session in Claude Code's worktree "this worktree
is yours for one task… rename the generated branch". Workers did that. Nested in the main checkout,
the worktrees also picked up its tool configuration: ESLint walked up into the main checkout's config
and failed.

## Decision

- **With the parallel-agents module, the app's worktree is where a session starts, not where it
  works.** A session in Claude Code's own worktree on a generated branch (or a detached HEAD) creates
  the task's worktree beside the main checkout as its first step, the same way a session in the main
  checkout does:
  - `adf-worktree-new <branch> --no-start`, with the branch its prompt names, or the one triage
    names;
  - then it moves there, with `change_directory` in the desktop app (the approve-worktree-move hook,
    0035, approves a worktree of this repository) or `EnterWorktree` in a terminal.

  It edits and commits nothing in the app's worktree, and never renames the generated branch. The
  app removes that worktree when the session is archived (`/wrap-up`).
- **The session-context hook says so.** It replaces "this worktree is yours… rename the generated
  branch", and the worker line no longer claims the current worktree.
- **A worktree already on a task branch,** from before this change, stays a worker as 0015 says. The
  hook still names what it lacks.
- **`/dispatch` and `PARALLEL-AGENTS.md`** no longer tell the developer to start the chip "in this
  folder, not in a new worktree". The app decides, and the worker moves either way.
- **Without the module,** nothing changes. A session in Claude Code's worktree renames its branch
  and works there (0015).

## Consequences

- **Positive:**
  - Every task's worktree sits beside the main checkout, named after its branch, with the scripts'
    setup, whatever the app's worktree location.
  - Nothing a task runs walks up into the main checkout's configuration.
- **Negative / cost:**
  - **Two worktrees per task while the session lives:** the app's, empty, and the task's. The app's
    goes when the session is archived.
  - **It depends on the move.** A refused `change_directory` leaves the session in the app's
    worktree. The worker gives the developer the task worktree's path and stops, as 0021 says.

## Alternatives considered

- **Set the app's worktree location to the main checkout's parent folder.** Declined as the fix. It's
  each developer's own setting, the framework can't apply it, and the app's worktrees still get
  generated names and no setup. A developer may still choose it, so the app's temporary worktree isn't
  nested either.
- **A `WorktreeCreate` hook that places the app's worktree.** Declined, as in 0021. A chip can't be
  relied on to call it, and it receives a generated name, not the task's branch.
