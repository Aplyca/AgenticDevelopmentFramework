# 0021: `/dispatch` hands every task to a new session that creates its worktree beside the main checkout and moves into it (parallel-agents module)

- **Status:** accepted; amended 2026-10-07 (the chip's title is the task's title, without the branch)
- **Date:** 2026-10-06
- **Amends:** [0020](0020-every-task-through-dispatch.md) — how a task gets its worktree and its session

## Context

Decision 0020 sent every task through `/dispatch` and let the project's settings pick one of two
routes:

- **Claude Code's worktree**, handed over as a task chip that was expected to create it.
- **The scripts' worktree**, handed over as a prompt to paste.

The first real dispatches through a chip, and a team's requirements, changed the picture.

**What the team wants:**

- Every task's worktree beside the main checkout, never inside it under `.claude/worktrees/`.
- The dispatcher does nothing but hand the task over: a chip with a minimal prompt.
- The new session creates the worktree, and its first step is the task's new branch.
- The new session's folder, as the desktop app shows it, is that worktree.

**What a chip does** (desktop app 2.19675.0, Claude Code 2.1.286, probes on 2026-10-06 in throwaway
repositories):

- **A chip opens its session in a folder, and creates no worktree.**
  - Every chip in the probes — nine — opened its session in the folder it was given or, given none,
    in its dispatcher's folder.
  - Chips started with the card's worktree option got no worktree, in both repositories the app
    accepted as projects; its log shows each session starting in the main checkout.
  - The app does create worktrees for some chips: in another project, chips started with the worktree
    option got worktrees under `.claude/worktrees/`, on generated `claude/<name>` branches.
- **A `WorktreeCreate` hook can place a worktree beside the main checkout, but a chip can't be relied
  on to call it.**
  - `claude --worktree` ran the hook, and the session opened where the hook put the worktree.
  - The hook is told only a generated name: not the task, not the branch.
  - The app's log from 2026-09-22 shows it calling such a hook twice for chips. Between those two
    calls it reused one of its parked worktrees instead and skipped the hook.
- **`EnterWorktree` with a sibling worktree's path moved the agent but not the session.** The agent's
  shell ran in the worktree; the app still listed the session in the main checkout.
- **The desktop app's `change_directory` moved the session.**
  - The app's record of the session's folder became the worktree.
  - The header showed the new folder.
  - The session carried on there by itself after the turn ended.
  - Session-start hooks didn't run again.

## Decision

- **The dispatcher only hands the task over.** `/dispatch` names the task (`<type>/<slug>`) and offers
  a three-line prompt: the task, the branch, and the first step.
  - **Desktop app:** a task chip for the main checkout, titled with the branch and the task's title —
    `feat/newsletter-signup-topics · Show the chosen topics after signup` — since the app shows the
    session's folder but not its branch.
  - **Terminal:** `claude "<prompt>"` in the main checkout.

  The dispatcher runs nothing: no script, no fetch.
- **The new session's first step is the worktree.**
  1. `scripts/agent/worktree-new.sh <type>/<slug> --no-start` creates the worktree. It sits beside the
     main checkout (or under `WORKTREE_PARENT`), named after the branch, on a new branch from
     `BASE_BRANCH`, with the env file and, where the project uses them, a port. Nothing starts.
  2. The session moves into it: `change_directory` in the desktop app, `EnterWorktree` in a terminal.
  3. `pwd` confirms the move, and only then does triage start.
- **The session-context hook tells a session in the main checkout both roles.** It is the dispatcher,
  unless its prompt hands it one task and its branch: then it is that task's worker, and its first
  step is the worktree. Hooks don't run again after the move, so this is said up front. The
  protect-hub hook's message says the same to a worker that tries to edit before moving.
- **Nothing is left to route.** 0020's route choice by project, and the developer's per-task
  override, go. A session a developer starts with Claude Code's worktree option is still a worker
  (0015).

*Amended 2026-10-07:* the chip's title is the task's title alone, without the branch. Once the
session moves into its worktree, the app shows that folder as the session's, and the folder is named
after the branch, so the title doesn't repeat it. The consequence "the chip's title carries it"
below no longer holds: the folder carries it.

## Consequences

- **Positive:**
  - The dispatcher's work is a name and a chip. It runs no command.
  - Every task's worktree sits beside the main checkout, named after its branch, with the branch's
    `<type>/<slug>` name from the start.
  - The app shows the worker's session in the worktree's folder.
  - Every task's worktree can run the app when its triage needs it, because it has the env file and,
    where the project uses one, its port.
- **Negative / cost:**
  - **The worker starts in the shared main checkout.** It runs the script and moves before anything
    else. The protect-hub hook stops an edit there, and the move takes one approval of the new folder.
  - **The worker's first lines are the dispatcher's.** Session-start hooks don't run after the move,
    so the hook's main-checkout lines name the worker's first step, and triage finds the spec folder.
  - **The app doesn't label the branch.** The chip's title carries it.
  - **The card's worktree option is one wrong click away.** It makes the app's own worktree under
    `.claude/worktrees/`, on a generated branch. Moving out of that worktree may be refused. Then the
    worker gives the developer the path of the worktree it created, and the developer opens a session
    there and pastes the prompt.
  - **The app doesn't own these worktrees.** Archiving a session doesn't remove one; `worktree-rm.sh`
    does, after the merge.
  - **Chips have changed behavior before.** The first lines and `pwd` show where a session really is.

## Alternatives considered

- **The dispatcher creates the worktree, and the chip opens in it.** This works: a chip given the
  worktree as its folder opens there. But the dispatcher runs the scripts and the fetch, and the team
  wants the hub to hand over and nothing more.
- **Keep 0020's two routes.** Claude Code's route puts the worktree inside the main checkout, on a
  generated branch, and in these probes the card's worktree option created none.
- **A `WorktreeCreate` hook that puts the app's worktrees beside the main checkout.** The hook isn't
  told the task or the branch. It isn't called when the app reuses a parked worktree. And the chips in
  these probes never reached it.
- **The app's Worktree location setting.** It is one app-wide folder, the same for every project, not
  beside each main checkout, and the branch is still generated.
- **`EnterWorktree` in the desktop app.** It moves the agent, but the app keeps showing the session in
  the main checkout.
