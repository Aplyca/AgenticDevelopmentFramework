# Wrap-up from the main checkout

`/adf:wrap-up` reads this when the session is in the main checkout of a project with the
parallel-agents module (step 1): `ops/agent/worktree.conf` or `scripts/agent/worktree.conf` exists,
and `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`.

This session never moved to a worktree, so its task was an **answer**, or it has none of its own — a
change it took went to a worktree, whose session wraps it up. Close it up as an answer, from here:
- **No pull request, branch, or worktree is this task's.** Skip the pull request's read in step 2
  and steps 6.2, 6.4, and 6.5. The branch checked out here is the base, or the developer's: never
  switch it, pull it, or delete it, here or on origin.
- **The main checkout is shared.** Its uncommitted changes, stashes, commits, and running
  environment belong to the developer or to other sessions. Only what this session made counts
  as left over, and only what it started is stopped: a stash it created, a background command or
  environment it started, a follow-up it promised. Name anything else once, in the close-up, and
  leave it.
- **The ending** is `The answer is delivered`, or, with no task of its own,
  `Nothing is left in this session`.

A worktree whose session is gone is removed from here with `adf-worktree-rm <branch>`, only when
the developer asks.

Before the report, check:

- [ ] Closed up as an answer, with no branch switched, pulled, or deleted; only what this session made counted as left over, and only what it started was stopped

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "This is the main checkout, so there's nothing to wrap up" | An answer that only reads ends here. It still gets the check, the delivered step for a tracker task, and the archive; only the branch, the worktree, and the base update are skipped. |
| "The main checkout has a stash, so the answer left work behind" | The main checkout is shared. A stash, a change, or a container this session didn't make is the developer's or another session's: name it once, and neither block on it nor clear it. |

## Red flags (stop and reassess)

- You're about to switch, pull, or delete the branch checked out here, locally or on origin, or to
  stop or drop something this session didn't start.
