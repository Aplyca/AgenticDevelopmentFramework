# 0095: Each step has one owner

- **Status:** accepted
- **Date:** 2026-11-22
- **Amends:** [0065](0065-always-loaded-text-says-each-rule-once.md) — a character budget backs it;
  [0079](0079-no-file-count-in-the-lanes.md) — the review and the lane rules follow it

## Context

A review of the framework found steps that two places owned, and the two disagreed:

- **`/review` ran twice.** `/implement` ran it before the local check, and `/open-pr` ran it again
  after. A full-lane review reads the spec folder, the constitution, and the diff, so the cost was
  paid twice, and it was unclear which run counted.
- **A diff that touched more files than stated forced a lane move,** and `/review` made it a Critical
  finding. 0079 had already said such a change is triaged again: files are not a risk trigger.
- **The fast and careful lanes had nowhere to keep the evidence `/review` checks.** The red run and
  the triage's "done when" lived only in the conversation, and a compaction dropped them.
- **No step ran the careful-lane checklists or `@security-reviewer`.** Only `/triage`'s routing table
  named them, and that drops out of context too.
- **Skills stopped for approvals `AGENTS.md` doesn't ask for.** "Ask a person only at a gate", yet
  `/write-tests` (standalone), `/write-docs` (update mode), `/refactor` (several files), and
  `/orchestrate` waited for a yes.
- **`/spec-workflow` was a fourth copy of the lanes and the flow,** and it had already drifted from
  `AGENTS.md` on the hotfix order and on who runs the review.
- **The always-loaded text had grown back past 0065's figures.** The "under 200 lines" check passed
  only because lines ran up to 217 words.

## Decision

- **`/open-pr` runs `/review`, once, after the local check.** `/implement` ends with a self-review and
  the local check, and the lane table in `claude-code.md` reads `… → local check → /open-pr`.
- **The lane moves for risk, not size.** A trigger that appears, a test outside the area that fails,
  or a behavior change no test can prove moves the lane up. A diff past its stated files is triaged
  again: a new trigger moves the lane; otherwise the new files are stated and the work goes on.
  `/review` makes a trigger the lane doesn't cover Critical, and unstated files a Warning.
- **A fast- or careful-lane commit carries its evidence.** Its body has `Lane`, `Done when`, `Files`,
  `Red`, and `Green` lines (`/commit`), and `/review` reads them from `git log`.
- **`/review` runs the careful lane's checks.** It checks the area's checklist in the diff and tests,
  and runs `@security-reviewer` for authorization, personal data, or payments — in the full lane too
  when the diff hits a careful trigger.
- **Skills state their plans and go on.** The approval gate stays the full lane's one stop. A
  standalone test plan, a doc-update plan, or a refactor plan is stated in the report, and the
  developer can redirect. `/orchestrate` waits only for a `custom` plan or one that departs from its
  table.
- **`/spec-workflow` routes.** One row per kind of task, pointing to the skill or section that holds
  its steps, with no copy of them.
- **The always-loaded text has a character budget.** The static checks hold `AGENTS.md` to 21,000
  characters and `claude-code.md` with `git-workflow.md` to 10,500. `AGENTS.md` § Delivery rules keeps
  the policy, and `/open-pr` the procedure.

## Consequences

- **Positive:**
  - One review per delivery, so a full-lane change pays for it once.
  - The lane rules, the review, and 0079 agree.
  - The fast lane's evidence survives a compaction, and the reviewer reads it from the history.
  - Authorization, personal-data, and payment changes get the security reviewer without the agent
    having to remember it.
  - No waits in the middle of the work that the developer didn't ask for.
- **Negative / cost:**
  - **A fast-lane commit body is longer:** five short lines.
  - **The security reviewer costs a subagent call** on every change in those areas.
  - **Raising a budget needs a reason in the CHANGELOG,** which is the point.

## Alternatives considered

- **Keep `/review` in `/implement` and drop it from `/open-pr`.** Declined. The fast and careful
  lanes never run `/implement`, and the review should see the change after the local walk's fixes.
- **Delete `/spec-workflow`.** Declined for now. Teams type it, and a routing table is cheap; what
  hurt was the copy.
- **A line budget only.** Declined. Long lines defeat it, as the current file shows.
