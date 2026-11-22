# 0067: A task's pull request carries its whole record, and a gap after the merge is a miss

- **Status:** accepted
- **Date:** 2026-11-03
- **Amends:** [0036](0036-wrap-up-after-the-merge.md) — what the wrap-up does with a record the
  merge left short

## Context

- **On an adopting project, a spec's `status: implemented` landed after the wrap-up,** in a pull
  request of its own. That pull request delivered nothing; it only finished the record of one that
  had merged.
- **The framework meant the record to merge with the work.** Since v1.0.0, `/adf:implement` sets
  `status: implemented` in the branch, so it merges with the pull request. But it sets it only
  "with every task ticked", and nothing checks it again:
  - **A task left for later** — a post-implementable doc "listed for later" — stays unticked, so the
    status is never set.
  - **Pushes after the draft opens** — the developer's fixes, a full change request on the open pull
    request, which moves the status back to `in-review` — go through `/adf:open-pr refresh`, which
    rebuilds the description but not the record. `/adf:open-pr` checked the ticks, not the status.
  - **`/adf:wrap-up` finds the gap after the merge** and lists "commit and push" to clear it. After a
    merge, that means a new pull request.
- **New work after the merge already has its own branch:** a change request gets
  `<type>/<slug>-<change>`, and a follow-up starts its own session. Only the task's own record had no
  rule.

## Decision

- **A task's pull request carries everything the task changes in the repository,** its record
  included: every task ticked, the gate results, and `status: implemented`. After the merge, what's
  left is outside the repository — the tracker's status and delivered update, an end-user page's
  publish, time entries — and the close-up. A change to the repository after the merge is a change
  request, a fix, or a follow-up, on a branch of its own.
- **A task that can't be done now is struck through, not left open:** `— follow-up: <why>` in
  `tasks.md`, and a line under the pull request's Follow-ups. The status can then be set.
- **`/adf:open-pr` checks the record before every push,** the first and each one after it
  (`refresh`): every task ticked or struck through, and `status: implemented` once the work it records
  is done. What's missing is committed in the branch first. A full change request still under way
  keeps its status, and the description says the pull request waits for it.
- **`/adf:wrap-up` names a gap the merge left as a miss.** It never commits on the merged branch. It
  asks whether each open task was done: a fix to the record, or a follow-up for the work. Either
  starts as a follow-up of the close-up, from the updated base branch.

## Consequences

- **Positive:**
  - The merge leaves the spec folder reading as built, and the record and the code it describes
    land in the same review.
  - No pull request exists only to finish another's bookkeeping, except after a miss, which is
    named as one.
- **Negative / cost:**
  - **One more read before each push:** the task list and one frontmatter line.
  - **Still a rule, not a check.** An agent that skips `/adf:open-pr` step 2, or a developer who
    pushes by hand, can still merge a short record. The wrap-up catches it, one pull request late.

## Alternatives considered

- **Set the status at the wrap-up, after the merge.** Declined. It needs a pull request for one line
  each time, and the folder reads as unbuilt until it merges.
- **A CI check in the `github` module** that fails a pull request that isn't a draft when a spec
  folder in its diff isn't `implemented` with every task ticked. Not now: it reaches only projects
  with the module, and a pull request that carries only a spec would need an exception. The skills'
  check comes first; the CI check can follow if misses persist.
- **Fold the record's fix into the next follow-up's branch.** Declined. A follow-up may belong to
  another spec folder, and one branch carries one.
