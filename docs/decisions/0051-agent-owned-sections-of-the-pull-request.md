# 0051: The agent owns marked sections of its pull request's description, and refreshes them from the record

- **Status:** accepted; amended by [0055](0055-lean-context-and-acting-model-routing.md) (the sync procedure moves to `/adf:open-pr sync`)
- **Date:** 2026-10-23

## Context

An agent opens its draft pull request with a description that says what changed, how to verify it,
and what was verified (decision 0045). The work rarely stops there. The developer asks for a fix after
testing it, a change request amends what's being delivered, or the base branch is merged in. Each push
can make the description wrong, and the description is what a reviewer reads first.

Keeping it current was already upkeep that needs no prompt (decisions 0033 and 0049). How to keep it
current was left open. An adopting team on v2.2.0 saw both failure modes: descriptions that still
described the first push, and descriptions rewritten by hand, from the agent's memory, which dropped
what people had added. A description has two authors. The agent writes what the record supports: the
change, the steps to verify it, and the evidence. People add notes, tick boxes, and attach screenshots.

The same team's agents also improvised syncs with the base branch: rebases of pushed history, pushes to
a merged pull request's branch, and full re-runs after a merge that touched no code.

## Decision

- **Markers say who owns what.** In the pull request template (`github` module) and `/adf:open-pr`'s
  own body, the agent's sections sit between HTML comment markers: `<!-- adf:what-changed -->`,
  `<!-- adf:how-to-verify -->`, and `<!-- adf:verified -->`, each closed by its `<!-- /adf:… -->`. The
  markers don't render. Everything outside them is the people's.
- **`/adf:open-pr refresh` rebuilds them.** After a later push changes what the description says, the
  agent fetches the current body and rebuilds only the marked sections. It works from the record, not
  from memory: `tasks.md` § Gate results and the spec's change requests, or in the fast and careful
  lanes the light `CR N` and the gate it just ran. It shows the description's diff, then applies it
  with `gh pr edit --body-file`, without a prompt, on its own open draft. A body without the markers,
  or a pull request no longer a draft, is applied only on the developer's yes.
- **Syncing with the base branch is a procedure in `git-workflow.md`,** not a skill: an open pull
  request checked first, a merge commit and never a rebase, conflicts resolved for both sides' intent
  and reported, only what the merged files affect re-run, cross-spec contracts re-checked, the push,
  a note that the preview's address may change, and the evidence recorded. `/adf:spec-workflow` and the
  parallel-agents guide point to it. Where the desktop app's `sync_with_base_branch` tool reaches the
  worktree, it does the fetch and the merge.

## Consequences

- **Positive:**
  - The description matches the latest push, and a reviewer's note or a ticked box survives every
    refresh.
  - The refresh is mechanical enough to check: an eval fetches, rebuilds, and compares the text
    outside the markers byte for byte (`evals/dynamic/fixtures/open-pr/refresh-after-cr`).
  - Syncs re-run what changed, not everything, and never rewrite history a reviewer has seen.
- **Negative / cost:**
  - **Markers in the template.** People see them when they edit the description, and a person who
    deletes one turns that section into theirs: the agent then asks before replacing it.
  - **Existing pull requests have no markers.** Their first refresh asks once.
  - **A rule, not a guard.** No hook stops a rebase of pushed history or a push to a merged pull
    request's branch: the git guard refuses a force-push only to a protected branch.

## Alternatives considered

- **Rewrite the whole description on each push.** Declined: it drops what people wrote.
- **Append an "Update" section per push.** Declined: the description grows into a log, and its first
  sections stay wrong, which is what a reviewer reads.
- **Recognize the sections by their headings.** Declined: people rename and reorder headings, and a
  wrong guess deletes their text.
- **A `/sync` skill.** Declined: the steps are short, and they belong where the git rules already
  live, which every session loads.
