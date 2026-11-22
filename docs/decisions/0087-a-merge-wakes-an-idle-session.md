# 0087: A merge wakes an idle session

- **Status:** accepted
- **Date:** 2026-11-16
- **Amends:** [0047](0047-sessions-move-to-done.md) — when the merge is noticed

## Context

0047's `pr-state.sh` hook notices a merge only when the session runs: at session start, or on the
developer's next prompt. A session left idle after `/adf:open-pr` keeps its last report until
someone types into it, so a merged task sits in the sidebar looking unfinished, and the wrap-up
waits on a prompt whose only purpose is to ask "did it merge?".

Claude Code runs a command hook in the background with `asyncRewake`: when that hook exits 2, its
stderr reaches the model as a system reminder and **wakes the session, even when it's idle**. Its
`timeout` is still enforced. No other hook path reaches an idle session: an `async` hook's output
waits for the next turn, and a `Notification` hook's never reaches the model.

## Decision

- **At Stop, the same hook watches.** `pr-state.sh` is wired under `Stop` with `asyncRewake` and a
  24-hour `timeout`. On a work branch with an open pull request, it asks the host's CLI every five
  minutes. A merge or a close updates the hook's record and exits 2 with the same line a prompt
  would read, saying it happened while the session waited. The session wakes, and the line asks it
  to offer `/adf:wrap-up` (merged) or ask whether the task is dropped (closed).
- **One watcher per checkout.** Each turn's Stop starts a watcher, which takes over the checkout's
  `adf-pr-watch` file; an older watcher sees it gone and ends. A state another check already
  reported (a session start, a prompt) ends it too, so nothing is said twice.
- **Bounded.** `PR_WATCH_HOURS` (default 8) is how long a watcher asks after its turn ends. Empty
  turns the watch off; empty `PR_STATE` turns off both. Without a pull request, on a protected
  branch, or without `gh` or `glab`, the watcher ends at once.

## Consequences

- **Positive:** a merge made while the developer is away reaches the session in five minutes, and
  the wrap-up is offered without a prompt. The session-start and prompt checks stay for a session
  closed, or idle past the watch.
- **Negative / cost:**
  - **One background process per idle session with an open pull request,** and a host call every
    five minutes for up to `PR_WATCH_HOURS`: twelve an hour per session, well under the hosts'
    rate limits.
  - **A woken session spends a turn** to offer the wrap-up.
  - **Only Claude Code wakes.** Other AI tools keep 0047's checks.
  - **Untested in a live session** when this was written: the evals run the hook with a fake CLI,
    not Claude Code's wake. A session closed while its watcher sleeps may leave the watcher running
    until its deadline, depending on how Claude Code ends background hooks.

## Alternatives considered

- **The desktop app's own pull request monitor.** It exists only in the app, and only for a pull
  request bound to the session; the framework stays tool-generic.
- **A scheduled task or `/loop` the agent starts.** It rests on the agent remembering, costs a
  model call per check, and outlives the session.
- **A shorter interval.** A merge needs no faster answer than five minutes, and it matches the
  prompt check's cadence.
