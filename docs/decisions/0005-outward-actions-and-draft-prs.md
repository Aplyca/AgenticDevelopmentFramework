# 0005: Outward actions only on request; pull requests stay drafts until a human QCs them

- **Status:** accepted
- **Date:** 2026-10-01

## Context

Two related problems with agents in the delivery loop:

- **Things left the machine that nobody asked for.** A push, a pull request, a tracker comment, or a
  tag is visible to others the moment it happens — under the developer's identity — and some (a
  release tag, a comment to a client) can't be taken back.
- **"Ready for review" became a claim nobody had checked.** A pull request that opens ready asks for
  reviewer attention immediately. Reviewers then spent that attention on the first pass of QC — a
  broken preview the author would have caught in a minute. With an agent as author it's worse: the
  agent has no eyes on the preview, so a ready pull request carries an implicit claim it can't make.

Teams that adopted "every pull request opens as a draft; promote after QC" found the draft/ready
distinction became information instead of decoration.

## Decision

- **Outward actions happen only when a human asks:** push; open, ready, or merge a pull request; tag
  or release; comment on a pull request, issue, or tracker task. Commits stay local.
- **Pull requests open as drafts.** "Ready" means a person has exercised the change (its preview,
  or a read-back when there is nothing to preview). **Agents never mark a pull request ready on their
  own initiative**; they report what they verified and what they could not. A developer who has QC'd
  the change promotes it — or asks the agent to, and the permission prompt confirms it.
- **Requester-visible writes are confirmed every time**, with the exact text shown first.
- Enforced, not only written: `permissions.ask` in the skeleton's `.claude/settings.json` prompts
  for every push and pull request action; `/open-pr` and `/client-update` are user-invoked only
  (`disable-model-invocation`); `guard-git.sh` blocks pushes to protected branches outright.

## Consequences

- **Positive:** nothing reaches others by surprise; reviewers land on changes someone has exercised;
  agents get an unambiguous stopping point.
- **Negative / cost:** more confirmations, and one more step to forget — a pull request left in draft
  after QC stalls silently. Draft-until-QC itself is a convention the Git host doesn't enforce.

## Alternatives considered

- **Let agents promote their own pull requests when CI is green.** CI is a signal, not the gate;
  green tests aren't a working preview. Rejected.
- **Allow pushes freely and rely on review.** Review doesn't undo a comment the client already read or
  a tag that already shipped.
