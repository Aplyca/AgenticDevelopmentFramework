# 0035: A dispatched session moves into its task's worktree without a prompt

- **Status:** accepted
- **Date:** 2026-10-11
- **Amends:** [0021](0021-sibling-worktree-and-chip.md) — "the move takes one approval of the new folder"

## Context

Under decision 0021, a dispatched session opens in the main checkout and creates its task's worktree
with the worktree scripts. It then moves there with the desktop app's `change_directory`. The app asks
the developer to approve that folder every time.

Testing in an adopting project showed that this prompt adds nothing. The developer already chose the
task when they started its chip, and decision 0021 made the move the session's first step. The folder
it names is the worktree the scripts printed a moment before. So the developer approves it without
reading, which is the habit a prompt is meant to prevent.

The app grants a folder in bypass mode without asking, so the approval is a permission check. A
`PreToolUse` hook can answer it, and only for the folders it recognizes. A `permissions.allow` rule
would answer it for any folder on the machine.

## Decision

- **The `approve-worktree-move.sh` hook** (PreToolUse, matcher `mcp__ccd_directory__change_directory`)
  approves the move when the folder is:
  - the top of a git worktree;
  - a linked worktree, not a main checkout;
  - a worktree of the session's own repository, which means they share git's common directory.

  That covers the scripts' worktrees beside the main checkout and Claude Code's own under
  `.claude/worktrees/`.
- **Every other folder still prompts.** For a main checkout, a folder inside a worktree, another
  repository, a folder outside git, or a relative path, the hook says nothing, and the app asks as
  before.
- **`APPROVE_WORKTREE_MOVE`** in `.claude/hooks/config.sh` turns the hook off when empty. Its default is
  `"1"`, so a project upgrading without the new line gets it.

## Consequences

- **Positive:**
  - A dispatched task goes from the chip to its worktree with no click after the chip.
  - The approval the developer still sees for a folder means something: it's one the session didn't
    create for its task.
- **Negative / cost:**
  - **An agent can move a session into any worktree of the repository without asking.** That includes
    another task's worktree. Its edits there would mix with that task's work. The worktree is
    already readable from the main checkout, and the session-context hook and `/dispatch` name the
    worktree each task works in.
  - **The hook depends on the desktop app's tool name.** If the app renames `change_directory`, the
    hook stops matching and the prompt comes back. Nothing breaks.
  - **A terminal session moves with `EnterWorktree`**, which this hook doesn't cover.

## Alternatives considered

- **Allow `mcp__ccd_directory__change_directory` in `permissions.allow`.** Declined. A permission rule
  for an MCP tool can't name the folder, so it would approve a move into any folder on the machine.
- **Start each chip in a new worktree.** Declined, as in 0021. The app's worktrees sit under
  `.claude/worktrees/` on generated branches, without the env file or a port, and a chip's
  `WorktreeCreate` hook can't be relied on to run.
