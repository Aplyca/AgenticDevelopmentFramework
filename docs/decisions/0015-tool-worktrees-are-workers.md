# 0015: Worktrees that Claude Code creates are workers too (parallel-agents module)

- **Status:** accepted; amended by [0020](0020-every-task-through-dispatch.md) (every task goes through `/dispatch`, and the project picks its route)
- **Date:** 2026-10-02
- **Amends:** [0008](0008-dispatcher-and-worker-worktrees.md) — how a task gets its worktree

## Context

Decision 0008 gives each task its own worktree, branch, pull request, and session, and keeps the main
checkout as a hub that only dispatches. It creates worktrees one way: `/dispatch` runs
`scripts/agent/worktree-new.sh`, which seeds the env file from the main checkout and, when a project
needs it, reserves a port and runs setup and start commands. Worktrees that Claude Code creates
itself are treated as foreign. In the desktop app those come from a new session with the **worktree**
option; in the terminal, from `claude --worktree`. The session-context hook gives a session in one
"no role" and asks for a dispatch, and `worktree-ls.sh` flags task branches in them.

Two projects show that developers use those worktrees for task work anyway:

- **The project the module came from** had four of them parked, one on a task branch the scripts
  never set up. That finding is recorded in 0008 and was met by the "no role" message.
- **A second project — a marketing site, upgraded to `d5934b3` with the module chosen —** had four
  more under `.claude/worktrees/`: two on task branches and two on detached HEADs. The team works in
  the desktop app. Its worktree option already gives one task its own worktree, branch, and session.
  With the hub on, the framework would send those developers to a second tool for the same result.

Claude Code now covers most of what the scripts were added for:

- **`.worktreeinclude`** copies gitignored files, such as `.env`, from the main checkout into every
  worktree Claude Code creates — the desktop app's included. Seeding from the main checkout is the
  same rule 0008 set for the scripts.
- **Project-scope plugins and the main checkout's local settings** reach every worktree of the
  repository (Claude Code 2.1.200 and 2.1.211).
- **The desktop app removes its worktrees** when a session is archived, or on its own once the pull
  request merges, with auto-archive on.

What it doesn't cover:

- **Ports, env overrides, and setup or start commands** — what a worktree that runs a server needs.
- **A base branch other than the default.** App worktrees branch from the default branch; the
  `worktree.baseRef` setting takes `"fresh"` or `"head"`, never a branch name. That's wrong for a
  project whose tasks start from an integration branch (Model B).
- **The branch name.** It is generated (`worktree-<name>`, or the app's prefix plus a name), so it
  doesn't carry the task's `<type>/<slug>`, which is how a branch joins its spec folder (0001).

The "no role" rule also depends on where the worktree is. It matches `.claude/worktrees/`, and the
desktop app's **Worktree location** setting can move them anywhere, where the same kind of worktree
is called a worker.

## Decision

With the `parallel-agents` module installed, **every linked worktree is a worker**, whichever tool
created it. A task gets its worktree by one of two routes:

- **Claude Code's worktree** — a new desktop session with the worktree option, or
  `claude --worktree`. This is the default when the project's worktrees run no server and tasks start
  from the default branch. The worker renames the branch to `<type>/<slug>` after triage
  (`git branch -m`), before its first commit.
- **The scripts** — `/dispatch` and `worktree-new.sh`, as in 0008. Use them when a worktree needs what
  only they provide: a port, `ENV_OVERRIDES`, `SETUP_CMD` or `START_CMD`, or a `BASE_BRANCH` other than
  the default branch.

What changes:

- **`session-context.sh`** (core) gives a session in any linked worktree the WORKER role. In a
  worktree the scripts didn't create, it adds one line for each thing that worktree lacks:
  - a generated branch name: rename it after triage;
  - no env file: `.worktreeinclude` should list it;
  - a project whose worktrees need a port or start command: dispatch through the scripts for task
    work that runs the app;
  - a `BASE_BRANCH` other than the default branch: this worktree started from the wrong base.
- **`worktree-new.sh`** marks the worktrees it sets up, with a file in the worktree's own git
  directory, so the hook and `worktree-ls.sh` can tell them apart wherever they sit. Worktrees from
  before the marker are recognized by their folder, which is named after the branch.
- **The module** ships a `.worktreeinclude` listing `ENV_FILE`, so Claude Code's worktrees get the
  env file. Its `MODULE.md` adds a customize step to keep the two in step.
- **`worktree-ls.sh`** lists Claude Code's worktrees as workers. It flags the ones on a generated
  branch or a detached HEAD, which are candidates to archive in the app.
- **`docs/PARALLEL-AGENTS.md` and `/dispatch`** describe the two routes and when each fits.
- **`protect-hub.sh`** still stops every edit in the main checkout; its message names both routes.

## Consequences

- **Positive:**
  - Developers dispatch with the tool they already use, and the desktop flow needs no pasted prompt.
  - For the common case it needs no dispatcher session at all: a new session with the worktree
    option replaces the second session 0008 counted as a cost.
  - The role no longer depends on where the worktree sits.
- **Negative / cost:**
  - Branch naming moves from creation to after triage. A worker that forgets leaves a branch that
    joins no spec folder. The session-context line is the reminder, and `/open-pr` already
    stops on a branch that isn't `<type>/<slug>`.
  - Two routes to explain instead of one, and the choice depends on facts in `worktree.conf`.
  - A project that runs a server still needs the scripts for that task work. Starting it from the app
    gives a worktree without a port, and the hook can only say so.
  - Claude Code's worktrees pile up unless sessions are archived; the pilot had two on detached HEADs.
    `worktree-ls.sh` flags them, and auto-archive in the desktop app removes them.

## Alternatives considered

- **Keep "no role" (today).** Two projects worked around it, and the cost lands on desktop users: a
  second tool, a dispatcher session, and a pasted prompt for what the app already does.
- **Route Claude Code's worktree creation through the scripts with a `WorktreeCreate` hook.** Every
  worktree would get the full setup, but the hook replaces creation for every worktree Claude Code
  makes, including subagent and background-session worktrees. Those would each reserve a port and run
  setup. It also turns off `.worktreeinclude`. Its input is a generated name like `bold-oak-a3f2`,
  since the task isn't known yet, so the scripts' `<type>/<slug>` contract breaks. Cleanup moves to a
  `WorktreeRemove` hook. Worth revisiting for a project that wants server setup on every worktree, as
  an opt-in.
- **Drop the scripts.** A project whose worktrees run servers needs ports, env overrides, and start
  and stop commands, and Claude Code has no equivalent.
