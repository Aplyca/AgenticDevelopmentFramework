# 0021: `/dispatch` creates every task's worktree beside the main checkout and hands it over with a chip (parallel-agents module)

- **Status:** accepted
- **Date:** 2026-10-06
- **Amends:** [0020](0020-every-task-through-dispatch.md) — how a task gets its worktree and its session

## Context

Decision 0020 sent every task through `/dispatch` and let the project's settings pick one of two
routes:

- **Claude Code's worktree**, handed over as a task chip that was expected to create it.
- **The scripts' worktree**, handed over as a prompt to paste. A chip had been seen, on 2026-09-22, to
  create a worktree of its own even when it was given another folder.

The first real dispatches through a chip, and a team's requirement, changed the picture:

- **A team using the module wants every task's worktree beside the main checkout**, named after its
  branch — never inside it under `.claude/worktrees/`.
- **The chip's card decides whether the app creates a worktree.** It offers the choice. From the same
  dispatcher, with the same inputs:
  - One chip opened its session in the main checkout, with no worktree. The worker noticed and moved
    itself into a worktree under `.claude/worktrees/`.
  - Another chip, started with the card's worktree option, got a worktree of the app's own.
- **Three probes on 2026-10-06** (desktop app 2.19675.0, Claude Code 2.1.286), in a throwaway
  repository:
  - A chip given an existing sibling worktree as its folder opened its session there, on that
    worktree's branch, and created nothing.
  - A chip given the main checkout opened there, on the base branch, and created nothing.
  - End to end: `worktree-new.sh feat/chip-check --no-start` created the worktree beside the main
    checkout, with the env file. A chip pointed at it, carrying the three-line prompt, opened its
    session there. The session-context hook said `Role: WORKER`, and the prompt arrived as written.

  So the chip's folder decides where the session runs, unless the card's worktree option is picked.
  The 2026-09-22 finding no longer holds.
- **The app labels only its own worktrees.** It shows a session's folder and branch only for a
  worktree it created. A session a chip starts in a folder shows its title instead.

## Decision

- **One route for every task.** `/dispatch` always creates the task's worktree with
  `scripts/agent/worktree-new.sh <type>/<slug> --no-start`. That worktree sits beside the main checkout
  (or under `WORKTREE_PARENT`), named after the branch, on a new branch from `BASE_BRANCH`. It gets the
  env file and, where the project uses them, a port. Nothing starts.
- **The hand-off:**
  - **Desktop app:** a task chip whose folder is that worktree. The developer starts it in that folder,
    not in a new worktree. Its title carries the branch and the task's title,
    `feat/newsletter-signup-topics · Show the chosen topics after signup`, because the app shows the
    title, not the folder or the branch, for such a session.
  - **Terminal:** `cd <worktree> && claude "<prompt>"`.
  - **Fallback:** open a session on the worktree's folder and paste the prompt. This is for when the
    new session's first lines say DISPATCHER: the session opened in the main checkout.
- **Nothing is left to route.** 0020's route choice by project, and the developer's per-task
  override, go. The branch has its `<type>/<slug>` name from the start, so a dispatched task never
  renames it after triage.
- **The session-context hook** tells the dispatcher what `/dispatch` does, and names the base branch
  tasks start from. A session a developer starts with Claude Code's worktree option is still a worker
  (0015).

## Consequences

- **Positive:**
  - One route, one click, and worktrees where the team keeps them.
  - The branch joins its spec folder from the start.
  - Every task's worktree can run the app when its triage needs it, because it has the env file and,
    where the project uses one, its port.
- **Negative / cost:**
  - **The app doesn't label these sessions with their folder and branch.** The chip's title carries
    the branch, and the session-context lines name the worktree.
  - **The card's worktree option is one wrong click away.** It makes a second worktree inside the main
    checkout. The skill and `PARALLEL-AGENTS.md` say which to pick.
  - **The app doesn't own these worktrees.** Archiving a session doesn't remove one; `worktree-rm.sh`
    does, after the merge.
  - **The chip's behavior has changed once already.** If a chip given a folder again creates a worktree
    of its own, the fallback is the pasted prompt, and the first lines show which happened.

## Alternatives considered

- **Keep 0020's two routes.** Claude Code's route puts the worktree inside the main checkout, and
  depends on the card's choice. The team wants worktrees beside it.
- **Let the app create the worktree**, through the card's worktree option or the app's worktree-location
  setting. The app would label the session. But the location is one app-wide setting, the same folder
  for every project, not beside each main checkout. And the branch is generated.
- **A `WorktreeCreate` hook that routes the app's worktrees through the scripts.** 0020's finding
  stands: the hook is told neither the folder nor the task, and is skipped when the app reuses a
  worktree.
