# 0042: Each task's session moves to its own worktree; the main checkout hands nothing out

- **Status:** accepted
- **Date:** 2026-10-16
- **Amends:** [0008](0008-dispatcher-and-worker-worktrees.md) — the main checkout as a dispatcher;
  [0020](0020-every-task-through-dispatch.md) — every task through `/dispatch` in the main checkout;
  [0021](0021-sibling-worktree-and-chip.md) — a new session for every task, from a chip or a command;
  [0040](0040-workers-move-out-of-the-apps-worktree.md) — which branch a session in the app's
  worktree takes

## Context

`/dispatch` exists so that a task never shares its session, worktree, branch, or pull request with
an unrelated one, and never lands on the default branch. Decisions 0020 and 0021 got there with a
hub: a session in the main checkout took every task, named it, and handed it to a new session, which
created the task's worktree beside the main checkout and moved in.

That hub is a root session the others are created from, and each task costs two sessions: the
dispatcher's and the worker's. Developers already start a new session for each new task, so the hub
adds a session and a hop to every one of them.

The parts that move a session already worked on their own. Since 0040, a session that starts in the
desktop app's worktree creates the task's worktree with `adf-worktree-new --no-start` and moves
there — `change_directory` in the app, approved without a prompt by the approve-worktree-move hook
(0035). In a terminal, `EnterWorktree` with `path` switches the session into an existing worktree
that `git worktree list` shows, from the folder the session started in.

## Decision

- **The session that takes a task moves with it.** A developer starts a new session for each task,
  in the main checkout or wherever the app opens it. It triages there — reading needs no worktree —
  and the triage names the branch. Then `/dispatch` creates the task's worktree beside the main
  checkout, on a new branch from the base branch, and moves this session into it, where the task
  goes on from its triage.
- **What needs a worktree:** a change, in any lane, and an answer whose triage needs an environment
  (the app, the tests, the database), which gets the worktree's own stack and ports. An answer that
  only reads stays where it is and changes nothing; a change it recommends moves once the developer
  approves it.
- **Another task, another session.** A session that has a task — in a worktree on a task branch, or
  one already done in its conversation — doesn't take a second. `/dispatch` offers the other one a
  new session: a task chip in the desktop app, titled with the task, or `claude "<prompt>"` in a
  terminal. The prompt is the task and "follow `AGENTS.md`, starting with triage"; that session
  triages and moves the same way. It no longer names the branch: its triage does.
- **The main checkout takes no edits,** as before: the protect-hub hook stops them, so nothing lands
  on the base branch and a session that skips the move is stopped at its first edit.
- **The hooks say so.** The session-context hook's main-checkout line becomes "triage first, then
  the task's worktree", without the dispatcher role, and protect-hub's message points at
  `/adf:dispatch` after triage. A session in Claude Code's own worktree takes the branch triage names.
- **A terminal session in Claude Code's own worktree** can't reach a folder outside
  `.claude/worktrees/` with `EnterWorktree`: `/dispatch` gives the developer `cd <path> && claude` and
  stops.

## Consequences

- **Positive:**
  - One session per task, from its first message: no root session to go back to, and no second
    session to start for each task.
  - Triage reads where the task arrives; the worktree comes once a change is certain.
  - An answer that only reads costs no worktree at all.
- **Negative / cost:**
  - **The session's instructions load from the main checkout,** before the move. Both are on the same
    release, so the difference is only uncommitted local edits.
  - **A developer who reuses a session for a new task** depends on `/dispatch` offering the chip; the
    hub hook doesn't catch it, since the session is already in a worktree.
  - **Triage happens in the shared checkout.** It reads only; the hub hook still stops any edit.

## Alternatives considered

- **Keep the hub.** Declined: it adds a session and a hop to every task, for a guarantee the hub hook
  and the move already give.
- **Move every task, answers included.** Declined: an answer that only reads needs neither a branch
  nor a stack, and a worktree for it is setup nobody uses.
- **Move a session again for its next task.** Declined: one session per task keeps its context, its
  branch, and its pull request apart, which is the point of the module.
