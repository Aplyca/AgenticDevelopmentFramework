# 0085: A session moves to its task's worktree with `EnterWorktree`, in the desktop app too (parallel-agents module)

- **Status:** accepted
- **Date:** 2026-11-16
- **Amends:** [0035](0035-move-into-the-worktree-without-a-prompt.md) — which tool the
  approve-worktree-move hook answers; [0040](0040-workers-move-out-of-the-apps-worktree.md) — how a
  session leaves the desktop app's worktree; [0042](0042-each-session-moves-to-its-task-worktree.md)
  — the move `/adf:dispatch` makes; [0083](0083-task-worktrees-under-claude-worktrees.md) — the open
  problem in its § Found later

## Context

Since 0021, a session moved to its task's worktree with the desktop app's `change_directory`, and
with `EnterWorktree` in a terminal. 0083's runtime check found that the app now refuses
`change_directory` for a session that "runs in an isolated worktree, shares another session's
folder, or runs on a remote host", whatever the target. Every chip's session starts in the app's own
worktree, so `/adf:dispatch` gave the developer the path and stopped: a manual step, and a second
session, for every chip.

**A probe (2026-11-16).** A session the desktop app started in its own worktree, on a generated
branch, in auto permission mode, with the app's Claude Code 2.1.325. Its targets were worktrees it
added with git under the main checkout's `.claude/worktrees/`, on a branch of their own.

- **`EnterWorktree` with the path moved the session, with no prompt.**
  - `pwd` and the branch were the worktree's, and Claude Code's working directory for the session
    became the worktree.
  - A command that ended outside the session's folders (`cd /tmp`) brought the shell back to the
    worktree, not to the app's.
  - The app's record of the session didn't change: `get_session` still gave its own worktree and its
    generated branch. As 0021 found, the app keeps showing the session in its own folder.
  - `ExitWorktree` with `keep` brought the session back to the app's worktree and left the other in
    place.
  - This record was written from a task worktree this session entered the same way.
- **Once it entered, Claude Code kept the session's git commands to that worktree.** `git -C <main
  checkout> log` and `cd <main checkout> && git log` were refused: "a worktree-isolated session's git
  operations must target its own worktree". The same `git -C` ran from the app's worktree, before the
  move and again after `ExitWorktree`.
- **`request_directory`, then `cd`, moved it only until the next command left.**
  - The folder was granted with no prompt: auto mode, and the folder is inside a workspace the
    developer trusts. The tool says the developer is asked in the other modes.
  - `cd` into the worktree moved the session's working directory.
  - The next command that ended outside the session's folders brought the shell back to the app's
    worktree, the folder the session must not edit.
- **The pull request reaches the app's PR bar from the session's commands.** The app binds a pull
  request when the session runs `gh pr create`, or pushes a branch that has one. Neither depends on
  the folder the app records: this record's pull request was bound to the session as soon as
  `gh pr create` ran in the task's worktree.
- **The hooks see the session's working directory.** Claude Code passes it to every hook as `cwd`,
  and the probe showed it moving with `EnterWorktree`. Not observed in a hook: this repository runs
  none. Session-start hooks don't run at the move, as 0021 found.

## Decision

- **The move is `EnterWorktree` with the path the script printed,** in the desktop app and in a
  terminal, from the main checkout or from Claude Code's own worktree. One route, which carries on in
  the same turn.
- **Not `change_directory`.** The app refuses it for a session in its own worktree, which every
  chip's is, and for a folder another session shares, which a main checkout often is. Where it's
  allowed, the move waits for the end of the turn.
- **The approve-worktree-move hook answers `EnterWorktree` too,** with the same check: the top of a
  linked worktree of the session's own repository. So Claude Code's permission check doesn't ask in
  any permission mode. It still answers `change_directory`, for a move the developer asks for.
- **If the move is refused,** the session still gives the developer the path and stops (0040).
- **The app keeps showing the session where it started,** and the session works in the task's
  worktree. The pull request reaches the PR bar when the session opens it.
- **`/adf:wrap-up` leaves the worktree before the main checkout's steps.** Updating the base branch
  and removing the worktree run git in the main checkout, so once what the task started is stopped,
  the session runs `ExitWorktree` with `keep` and goes on from the folder it started in. Archiving
  still parks the app's worktree, and `adf-worktree-rm` still removes the task's.
- **The text follows:** `/adf:dispatch`, `/adf:wrap-up`, the parallel-agents guide, the hooks' README, the
  scenario, `.claude/hooks/config.sh`'s comment, and the session-context hook, whose lines name the
  move, so a session that moves without the skill doesn't reach for `change_directory`.

## Consequences

- **Positive:**
  - A chip's session reaches its task's worktree with no step from the developer.
  - The move takes effect at once: the session carries on with its task in the same turn.
  - One move to explain and test, for the desktop app and a terminal alike.
- **Negative / cost:**
  - **The app's view stays on its own folder.** Its header and diff pane show the app's worktree,
    which has no changes. The developer reviews through the pull request, as 0073 says.
  - **It relies on `EnterWorktree` accepting a task's worktree from the app's.** Claude Code's
    documentation says a session already in a worktree may switch only to another under
    `.claude/worktrees/`, which a task's worktree now is (0083). An older worktree beside the main
    checkout is reached from the app's worktree after a prompt (0083's check). Whether the hook's
    approval answers that prompt wasn't tested.
  - **Not tested in the default permission mode.** The hook answers Claude Code's permission check
    there; no other prompt was seen.
  - **A moved session runs no git in the main checkout** until it leaves the worktree. Only the
    close-up needs to, and it leaves first. The same holds for a terminal session, which has moved
    with `EnterWorktree` since 0042.
  - **Whether `CLAUDE_PROJECT_DIR` follows the move wasn't observed.** A committed install's hooks run
    from it. If it stays on the folder the session started in, they run that folder's copies, from
    the same release.

## Alternatives considered

- **`request_directory`, then work there with `cd`.** Declined: any later command that leaves the
  session's folders brings the shell back to the app's worktree, and outside auto and bypass modes the
  developer approves the folder first.
- **Keep stopping, and have the developer open a session on the folder.** Declined: a manual step
  and a second session for every chip, which 0042 removed.
- **`change_directory` where the app allows it, `EnterWorktree` elsewhere.** Declined: two routes, a
  refused call wherever the main checkout is shared, and a move that waits for the turn's end. Its gain,
  the app showing the task's folder, reaches only sessions started in a main checkout no other session
  shares.
