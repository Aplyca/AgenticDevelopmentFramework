# 0001: Spec folders are the record of intent; trackers are linked, never copied

- **Status:** accepted
- **Date:** 2026-10-01
- **Refined by:** [0011](0011-lanes-ceremony-follows-risk.md) — spec folders belong to the full lane; precise adjustments leave a light change request

## Context

Until this change the framework kept one file per feature (`specs/<name>.md`) holding every
section — requirements, technical notes, and an optional Technical part for architecture. Test,
doc, and implementation plans existed only transiently, in the conversation where a skill presented
them. Three problems showed up in practice:

- **The plan evaporated.** The implementation plan — which files change, which test proves what —
  was approved in chat and then lost. Reviewers had nothing to compare the diff against, and a later
  change request had no record of what had been built where.
- **WHAT and HOW mixed in one file.** The Technical section invited implementation detail into the
  requirements document, and the requirements review had to wade through it.
- **Requirements lived in two systems.** Teams receiving requirements in a tracker tried to restate
  them as repository issues ("user stories"). In one pilot, a rule requiring a user-story issue per
  pull request was followed in roughly 1 of 15 cases over eight months, and no feature pull request
  ever closed one — the issues duplicated the spec field for field and nobody kept both. Issues are
  also the one artifact that lives only in a vendor's database: not discoverable with `ls`, not
  greppable, and lost on a move to another Git host. An agent's working set is the file tree.

The Agentic Development Guide (§6.1) and GitHub Spec Kit already describe the folder shape:
`spec.md` → `plan.md` → `tasks.md`.

## Decision

- Each feature gets a folder, `specs/NNN-<slug>/`, with **`spec.md`** (the multi-perspective spec:
  WHAT and WHY), **`plan.md`** (HOW: constitution check, architecture, change surface, data and
  contracts, test strategy, documentation plan, rollout, risks, assumptions), and **`tasks.md`**
  (commit-sized tasks that each name their test, plus the gate results).
- The multi-perspective model is unchanged inside `spec.md`; the old Technical section moves to
  `plan.md`, leaving a small *Constraints & prior decisions* section for reasoned constraints.
- **The folder is the record of intent.** One folder is one feature: its first pull request creates
  it; change requests amend it (`CR N` sections) rather than opening a new one.
- **The slug is the join** between folder, branch (`<type>/<slug>`), and pull request. A change
  request's branch starts with the feature's slug and names the change
  (`feat/newsletter-signup-topics`) — a fresh branch, because one kept after a squash merge carries
  pre-merge history. `NNN` orders folders; it is not an identifier, so two parallel branches that
  pick the same number don't break anything.
- **The tracker stays the requester's channel and is linked, never copied** into specs, issues, or
  pull requests — the audiences and the access differ. Repository issues are a queue for
  engineering-originated work, not a record.
- Legacy single-file specs remain valid and move into a folder the next time they change.

## Consequences

- **Positive:** the plan and its change surface survive the conversation and can be reviewed and
  diffed; change requests compute their delta against what was actually recorded as built;
  everything an agent needs arrives with `git clone`; WHAT and HOW are reviewed separately but
  approved together.
- **Negative / cost:** three files instead of one — more ceremony, justified only when there is
  something to decide (lightweight changes skip the folder). Acceptance criteria are agreed with the
  diff rather than beforehand unless the team uses the optional `in-review` step. Adopting teams
  with single-file specs live with two shapes for a while.

## Alternatives considered

- **Keep single-file specs and add plan sections to them.** One file becomes very long, and the
  task list — which changes on every commit — would churn the requirements document.
- **User stories as repository issues.** Rejected on the evidence above: low compliance, duplicate
  content, vendor-locked, invisible to an agent's file tree.
- **Ticket IDs or spec numbers in branch names.** Couples every branch to one vendor's ID scheme or
  forces a number to be minted (and possibly collide) before the work starts.
