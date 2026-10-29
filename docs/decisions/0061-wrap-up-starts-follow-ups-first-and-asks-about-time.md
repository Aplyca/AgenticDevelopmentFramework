# 0061: The wrap-up starts the follow-ups before the worktree goes, and asks about the time before the close-up

- **Status:** accepted
- **Date:** 2026-10-28
- **Amends:** [0036](0036-wrap-up-after-the-merge.md) — the close-up's order;
  [0043](0043-track-time-in-the-tracker.md) — the wrap-up asks about the time instead of offering it

## Context

- **Follow-ups.** `/wrap-up` removed the worktree, then started the follow-ups. Removing the worktree
  takes away the session's folder, and a session without its folder can't start another: the
  follow-ups never started.
- **Time.** `/wrap-up` offered `/track-time` inside the step that lists what's left. When nothing was
  left, the offer was skipped with the rest of that step, and the developer's "merged" closed up the
  task before the time was logged. Once the worktree is gone, the time is harder to measure.

## Decision

- **The close-up runs in this order:** stop what the task started; update the base branch in the main
  checkout; start the follow-ups the developer kept, each in its own session, from it; delete the
  branch on the host; remove the worktree and the local branch; report, then archive. `adf-worktree-rm`
  still fast-forwards the base branch, which is then already up to date.
- **With the `time-tracking` module, the wrap-up asks about the time** as a step of its own, after the
  check and before the close-up's question, and waits: on a yes, `/track-time` runs to its end; on a
  skip, the close-up goes on. It doesn't ask again when `/track-time` already ran in the session after
  the task's last work. The developer's "merged" still answers the close-up, not the time.

## Consequences

- The follow-ups start while the session still has its folder, and from the merged base branch.
- With the module, every wrap-up has one more question; the developer can skip it in a word.
- Without the module, nothing changes: the wrap-up says nothing about time.
