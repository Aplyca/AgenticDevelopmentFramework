# 0080: Answers in the main checkout close up there — without touching a branch, and counting only what the session made

- **Status:** accepted
- **Date:** 2026-11-15
- **Amends:** [0047](0047-sessions-move-to-done.md) — an answer delivered closes up in the main
  checkout too, with no worktree or branch to remove

## Context

- **0042 keeps read-only answers in the main checkout.** `/adf:dispatch` moves a change, or an answer
  that runs the app, the tests, or the database, to its own worktree. An answer that only reads stays
  where the session started.
- **0047 gave every ending a close-up,** an answer delivered included, and described it as stopping
  what the task started, removing its worktree, and archiving the session. It assumed the answer had
  a worktree.
- **`/adf:wrap-up` stopped in the main checkout.** Its first step still read as it did for the
  dispatcher hub that 0042 retired: a session there had nothing to wrap up. So the answers most
  likely to stay in the main checkout were the ones it refused. Their sessions skipped the check for
  leftovers, the delivered update for a tracker task, and the archive, and stayed in the sidebar
  until the developer archived each by hand.
- **Running the rest of the close-up there as written isn't safe.** The branch checked out in the
  main checkout is the base, or the developer's: the steps that delete a task's branch, on origin and
  locally, would aim at it. The main checkout is also shared, so its stashes, changes, and containers
  aren't this session's.

## Decision

- **A session in the main checkout, with the parallel-agents module, closes up as an answer.** It
  never moved to a worktree, so its task was an answer, or it has none of its own: a change it took
  went to a worktree, whose session wraps it up. The ending is "the answer is delivered", or
  "nothing is left in this session".
- **No branch is touched.** There's no pull request to read, and the base update and both branch
  deletions are skipped. The branch checked out there is never switched, pulled, or deleted, here or
  on origin.
- **Only what the session made counts.** A stash it created, a background command or environment it
  started, a follow-up it promised: these are left over, and only these are stopped. Anything else in
  the main checkout is named once in the close-up and left alone, neither blocking the close-up nor
  cleared by it.
- **The rest runs as for any answer:** the check, the delivered update and status move for a tracker
  task, the time question with the time-tracking module, the one yes, and the archive.

## Consequences

- **Positive:**
  - Every session that ends gets its close-up, wherever it ran, and the sidebar holds only live work.
  - A tracker task answered from the main checkout gets its delivered update.
- **Negative / cost:**
  - **Ownership is the session's own recollection.** Git can't say which stash or container a session
    made. The agent reads its own conversation; when it isn't sure, the item counts as someone else's
    and is only named.
