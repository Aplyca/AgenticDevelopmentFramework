# 0033: An agent pushes, opens, edits, and comments on its draft pull request without a prompt

- **Status:** accepted
- **Date:** 2026-10-09
- **Amends:** [0005](0005-outward-actions-and-draft-prs.md) — which outward actions a permission prompt confirms; [0022](0022-local-check-before-the-pull-request.md) — "everything past the draft still asks"

## Context

Decision 0005 put every push and pull-request action behind `permissions.ask`. Decision 0022 took
`git push` and `gh pr create` out of it, so the developer's approval in the local check opens the
draft. It kept everything past the draft asking: ready, merge, edit, comment, and review.

Testing in an adopting project showed what that costs. Keeping a draft up to date is routine: the
body gains the local check's results, a fix changes the summary, and a CI note goes in a comment.
Each one stopped for a prompt. The developer approved them all without reading, which is the habit
a prompt is meant to prevent.

The two rules 0022 removed from `permissions.ask` were never added to `permissions.allow` either. In
the default permission mode, Claude Code asks about any command the allowlist doesn't name, so the
push and the draft still prompted.

## Decision

- **Allowed:** `git push`, `gh pr create`, `gh pr edit`, and `gh pr comment`, in the skeleton's
  `.claude/settings.json` `permissions.allow`.
- **Still asking:** `gh pr ready`, `gh pr merge`, `gh pr review`, issue writes, releases, and
  `gh api` writes. They change a pull request's state, speak for a reviewer, or reach past the pull
  request.
- **The hooks still hold the line:** `guard-git.sh` blocks a push to a protected branch and a
  `gh pr create` without `--draft`.
- **Requester-visible text is still confirmed (0005), in chat:** `/stakeholder-update` posts its
  comment only after the developer approves the draft. No prompt confirms `gh pr comment` now.

## Consequences

- **Positive:**
  - Keeping a draft current takes no clicks, so the prompts left mean something: ready, merge, and
    review.
  - The push and the draft open without a prompt in every permission mode, as 0022 meant.
- **Negative / cost:**
  - **A comment is visible to everyone watching the repository.** An agent that comments on its own
    initiative notifies reviewers without a click. `AGENTS.md`'s delivery rules still say when an
    agent posts, and `/stakeholder-update` asks in chat.
  - **`gh pr edit` covers more than the body:** base branch, reviewers, labels. A wrong base is
    visible on the pull request and easy to undo. The github module's branch policy flags it.
  - **A force-push to the work branch doesn't prompt.** It's the agent's own branch. Protected
    branches stay blocked.

## Alternatives considered

- **Allow only `gh pr edit`.** Declined. A CI note or a reply to a review comment is as routine as
  an edit, and it prompted just as often.
- **A hook that allows edits only on a draft.** Declined. It needs a network call on every `gh`
  command, and a hook can't make a confirmation mean more than the permission rule does.
- **Leave the rules and tell teams to allow them in `settings.local.json`.** Declined. Every developer
  would do it by hand, and the skeleton's defaults would keep producing prompts nobody reads.
