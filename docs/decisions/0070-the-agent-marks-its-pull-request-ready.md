# 0070: The agent marks its pull request ready once its own tests pass

- **Status:** accepted
- **Date:** 2026-11-07
- **Amends:** [0005](0005-outward-actions-and-draft-prs.md) — who marks a pull request ready, and what
  ready means; [0033](0033-pull-request-upkeep-without-prompts.md) — `gh pr ready` no longer prompts;
  [0045](0045-agent-local-check-opens-the-draft.md) — a criterion only a shared service can run is
  tested on the preview; [0059](0059-task-status-follows-the-work-and-stakeholder-guides.md) — the
  review status moves when the pull request is ready

## Context

- **The agent already tests every change before a person does.** Since decision 0045 it walks the
  changed flow on its own local environment before the push — every acceptance criterion, or the
  fast lane's "done when" — and since 0039 it walks it again on the preview after the draft opens.
  The pull request's *Verified / not verified* section records both.
- **The developer's promotion came after that evidence.** Decision 0005 made "ready" mean "a person
  has exercised the change", so every pull request waited for a manual promotion after the agent's
  report — and 0005 named its cost: a pull request left in draft stalls silently.
- **Ready means "ready for review" on the hosts.** GitHub's own button says so; a reviewer still
  reads the change, tests it, and decides the merge. The step that asks a person to decide is the
  review, not the promotion.
- **The draft can carry information again.** Once the agent promotes its own pull request, a draft
  says "the agent is still testing this, or something blocks it", and ready says "tested; a person's
  turn".
- **A criterion that needs a shared service stopped the work.** Under 0045, anything only a shared
  service has — a real payment sandbox, a CMS webhook — meant no push at all, and the developer had
  to unblock a change the preview could have tested.

## Decision

- **Ready means the agent's own tests passed, and the change waits on a person's review.** The agent
  runs `gh pr ready` itself — no prompt, no question — once all of these hold:
  - the full gate passed since the last commit;
  - every acceptance criterion, or the "done when", was walked on a test environment and worked —
    the local environment first, then the preview when the project has one — or, for work with
    nothing to run, `/review` came back clean;
  - CI finished green, or the project has none — awaited in the background, like the preview's
    deploy;
  - nothing a criterion depends on is listed as *Not verified*.
- **Until then the pull request stays a draft,** and the report says what holds it: a failing check
  is fixed on the branch and the conditions are checked again; a criterion the agent couldn't test is
  named, with why.
- **The local environment first; the preview for what only a shared service has.** When a criterion
  needs something only a shared service has, the agent walks the rest locally, opens the draft, and
  walks that criterion on the preview — read-only — before ready. With no preview, it stops before
  the push and says what blocks it, as before. An environment that won't start still stops the push:
  the fix is usually quick, and otherwise nothing would have run the change.
- **The task moves to the review status when the pull request is ready,** not when the draft opens.
  A draft the agent isn't confident about leaves the task in progress. The review update for the
  requester is drafted at the same moment.
- **The pull request stays the agent's to keep current after ready.** A fix the developer asks for
  rides the same branch: walked locally again, pushed, the description refreshed, the preview
  rechecked. It stays ready.
- **Review and merge stay the developer's:** `gh pr merge` and `gh pr review` still ask, the agent
  requests no reviewers, and the report gives the developer the local and preview URLs and what to
  try on each.
- **Enforced:** `gh pr ready` leaves the skeleton's `permissions.ask`. `guard-git.sh` still refuses a
  pull request that doesn't open as a draft: the draft is where the preview walk and CI run before
  anyone is asked for attention.

## Consequences

- **Positive:**
  - No manual step stands between the agent's evidence and the review.
  - The draft and ready states mean something to everyone watching: still testing or blocked, then
    tested and waiting on a person. The tracker's status matches.
  - A change that needs a shared service gets tested on the preview instead of waiting on the
    developer.
- **Negative / cost:**
  - **Ready is the agent's judgment.** On GitHub, it sends the review requests a `CODEOWNERS` file
    names and notifies watchers. What only a person sees — a layout that looks wrong, copy that reads
    badly — can still reach a reviewer. The evidence in the description and the developer's review
    before the merge are what catch it.
  - **Waiting for CI lengthens the time to ready.** It runs in the background, beside the preview's
    deploy, so the session isn't idle, but the report comes later.
  - **A criterion tested only on the preview reaches a shared environment before any local run.**
    The walk is read-only, and only for what the local environment can't have.
  - **The rule rests on the agent following `/open-pr`.** No hook can tell whether every criterion was
    walked before `gh pr ready`; the reviewer sees it in the *Verified / not verified* section.

## Alternatives considered

- **Keep the developer's promotion (0005 as it was).** Declined: a manual step after every pull
  request, after a report that already says what was tested. The review is where a person decides.
- **Open the pull request ready, with no draft.** Declined: the preview walk and CI run before a
  reviewer is asked to look; the draft is that window.
- **Ready on green CI alone** — 0005's rejected alternative. Still rejected: CI is one condition, not
  the gate. Ready follows the walk of every criterion.
- **Any test environment for any criterion.** Declined: the local environment is cheaper, private,
  and reaches no real service. The preview is for what only a shared service has.
- **A project setting choosing who marks ready.** Declined for now: one rule is simpler to follow and
  to check. A team that wants a person's promotion can say so in `AGENTS.md` § Delivery rules, and
  the agent leaves the draft.
