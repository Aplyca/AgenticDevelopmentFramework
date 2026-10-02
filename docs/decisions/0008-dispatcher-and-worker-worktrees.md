# 0008: The main checkout dispatches; worktrees do the work (optional module)

- **Status:** accepted
- **Date:** 2026-10-01

## Context

Teams running several agent sessions on one repository hit two costs when a session started in the
main checkout read the task, analyzed it, planned, and only then created a worktree:

- **The hub is shared.** Every developer and session starts in the main checkout; an edit or a dev
  server there collides with whoever starts next.
- **The analysis is thrown away.** The session in the hub can't run the app or the tests, so its
  conclusions are unverified, and the worker in the worktree re-reads everything anyway — now with
  tools that can check it. The hub spent its context on something the worker discards.

The rule existed in one developer's habit, not in the repository, so no agent elsewhere followed it.
Worktrees that each run the app also need their own env file, port, and container project — set up
by hand, they collided.

## Decision

- Ship it as the **`parallel-agents` module**, not in the core: many teams run one session at a time.
- **Dispatcher** (main checkout, `/dispatch`): read only enough of the task to name it; run
  `scripts/agent/worktree-new.sh <type>/<slug> --no-start`; start a worker session in the worktree —
  or, where the tooling can't root a session in a chosen folder, give the developer a three-line
  prompt to paste; point the worker at the process without restating it. Reads only, no writes.
- **Worker** (worktree): everything from triage on.
- The scripts seed each worktree's env file from the **main checkout's** (never from the worktree
  that ran them, to avoid drift between hops), reserve a port derived from the branch name under a
  lock (sibling env files are the registry), run optional setup/start commands, and are idempotent.
- The core `session-context.sh` hook tells each session its role when the module is installed. The
  core `AGENTS.md` keeps a one-line rule for everyone: one worktree per session, never two sessions in
  one checkout.

## Consequences

- **Positive:** the hub stays clean; the dispatcher's context stays cheap; analysis happens where it
  can be verified; the handoff is explicit, so any agent on any machine can pick a task up.
- **Negative / cost:** two sessions per task; the handoff prompt is a real artifact. Tools that create
  their own worktrees (some desktop flows) can't be used for task work, so the handoff can be a pasted
  prompt — one manual step. Shared services (one local database for all worktrees) are a hazard for
  schema work; isolating them costs memory per worktree.

- **Found later (2026-10-01), from the project this module came from** — three gaps, closed without
  changing the decision:
  - *Shared services blocked ordinary work.* With one sibling worktree active, a migration refused to
    apply (the shared history held the sibling's version), and the reset that verifies a migration
    couldn't run without destroying the sibling's data. `worktree-new.sh --isolated` now gives one
    worktree its own services: their ports come from the block each worktree already owns, they are
    started and stopped by project commands, and they are removed with the worktree. Shared stays the
    default, because an isolated stack costs about 1 GB per worktree. The project designed and
    implemented this but hadn't merged it; the module ships the general pattern, not that project's
    stack.
  - *Environments were found by hand.* Ports, URLs, and sign-in accounts were read from each env file
    and the database every time. `worktree-ls.sh` now shows own or shared services, and `--info` runs
    a project command for endpoints and accounts — derived on each run, because a committed table goes
    stale.
  - *Task work ended up in the tools' own worktrees anyway.* Four were parked in the project, one on a
    task branch with no env file or port. The session-context hook now gives a session there no role,
    and `worktree-ls.sh` flags task branches in them.

  The handoff principle — point at the record, never restate it — now also covers work handed on
  mid-task, through the core `/handoff` skill.

## Alternatives considered

- **Keep working in the same session after creating the worktree.** A `cd` doesn't move the session's
  history; the hub stays occupied.
- **Let the dispatcher analyze and pass findings along.** Doubles the reading and hands unverified
  conclusions across the boundary.
- **Have the dispatcher mint an identifier** (an issue, a spec number) for the branch. An outward
  write in a step that's otherwise local, and numbers collide between parallel dispatchers; the slug
  is the join (decision 0001).
