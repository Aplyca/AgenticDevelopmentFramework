# 0036: After the merge, a task's session wraps itself up with one yes

- **Status:** accepted
- **Date:** 2026-10-11

## Context

`git-workflow.md` says to update the base branch and delete the merged branch after a merge.
`adf-worktree-rm` does both for a task's worktree. Nothing says when to run it, and nothing covers the
rest of what a task leaves behind:
- the containers or the app it started, and its background commands;
- its branch on the host, when the host doesn't delete it on merge;
- its session in the desktop app's sidebar.

Testing in an adopting project showed what that costs. After a week of parallel tasks, the
developer had stale worktrees beside the main checkout, stacks still holding memory and ports, and
a sidebar of finished sessions to read past. Each one was cleaned up by hand, when someone noticed.

The desktop app can archive a session when its pull request closes. That removes only the worktrees
the app created itself. It doesn't remove the ones the worktree scripts create beside the main
checkout, and it doesn't stop what a task started.

## Decision

- **`/wrap-up`, a core skill,** runs in a task's session once its pull request merges: when the
  developer says so, when the app reports it, or when asked to close up.
- **The check comes first, and it is strict.** The pull request must be merged by the host's own
  state. The task has no uncommitted changes, no stash, no commits after the pull request's last one,
  no open task in `tasks.md`, and no promise the session left open. Anything found is listed for the
  developer, and nothing is removed.
- **One yes covers the close-up.** The developer sees the full list, with real paths and branches,
  and answers once. Then, in this order:
  1. stop what the task started;
  2. delete the branch on the host;
  3. remove the worktree and the local branch (`adf-worktree-rm`, with `-D` after a squash merge),
     and update the base branch in the main checkout;
  4. report, then archive the session.

  The archive comes last because the session ends with it, and the worktree's removal takes away the
  session's folder.
- **The hub's session is never wrapped up.** The dispatcher stays open. A worktree whose session is
  gone is removed from the hub only when the developer asks for it.
- **A terminal session** does the same close-up, then tells the developer to `/exit`.

## Consequences

- **Positive:**
  - A finished task leaves nothing running and nothing in the sidebar.
  - The base branch in the main checkout is current for the next task.
  - Unfinished work can't be cleared by accident: the check lists it, and only the developer settles it.
- **Negative / cost:**
  - **One more question at the end of each task.** It replaces several manual steps, and its answer
    covers all of them.
  - **The session's conversation is archived, not kept open.** The app's Archived list brings it
    back.
  - **With the app's auto-archive on,** the session may end on the merge before it can wrap up.
    Then the worktree and what it started stay behind until the developer asks the hub to remove
    them with `adf-worktree-rm`.
  - **The check reads the session's own promises from the conversation.** A follow-up never said
    there isn't caught. The record — `tasks.md`, the spec, the pull request — is what the check
    trusts most.

## Alternatives considered

- **A Stop hook that checks after every turn.** Declined. It would call the host's API at the end of
  every turn, and a hook can't ask the developer anything.
- **Close up without asking once the check passes.** Declined. Removing a worktree deletes files, and
  archiving hides the conversation, so a person confirms both.
- **Ask for each step.** Declined. Several prompts for one decision train the developer to approve
  without reading.
- **Rely on the app's auto-archive.** Declined. It doesn't remove the scripts' worktrees or stop what
  a task started, and it can't check for work left over.
