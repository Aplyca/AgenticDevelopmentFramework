# 0002: One approval gate, after the plan, on the change surface

- **Status:** accepted
- **Date:** 2026-10-01
- **Refined by:** [0011](0011-lanes-ceremony-follows-risk.md) — the gate applies to the full lane; the fast and careful lanes rely on the diff's review

## Context

The previous workflow asked the developer to approve four things in sequence: the spec, the test
plan, the doc plan, and the implementation plan. Two problems:

- **The riskiest part was checked last, or not at all.** With an agent, the dangerous analysis is not
  the confused one but the convincing one — and the part it most often gets wrong is *which files and
  layers the change actually touches*: a shared component with other consumers, a policy layer, a
  migration. Approving the spec alone is cheap but checks the wrong thing; the change surface isn't
  known until the plan exists. Pull request review catches a wrong surface only once the code exists,
  when fixing it is a rewrite.
- **Four gates put a human on the critical path four times** and encourage rubber-stamping — each
  approval is narrower, so none of them looks at the whole.

Teams that ran the folder model in practice converged on a single stop after `plan.md` and
`tasks.md`, showing scope, change surface, and assumptions together.

## Decision

- `/write-plan` writes `plan.md` (including a **Change surface** table built by reading the code,
  shared code's other consumers, and an **Assumptions** list) and `tasks.md`, checks the folder for
  consistency (optionally with the isolated `@spec-analyzer`, or the `/deep-spec-analysis` workflow
  for high-stakes work), then **stops**.
- The developer sees scope, change surface, assumptions, risks, the test strategy, and the docs
  plan, and either approves or asks for changes. Approval sets `status: approved` and adds a dated
  `approvals:` line. Then the folder is committed (`spec:`).
- No implementation code before approval. `/implement` refuses to start without it.
- If implementation later needs to grow the change surface, it stops and re-confirms.
- Requirements can still be agreed earlier (`status: in-review`) when the requester wants to see the
  acceptance criteria first — an optional step, not a gate.

## Consequences

- **Positive:** the expensive mistake is caught while it's a sentence; assumptions are visible before
  they're baked into commits; the developer reviews one coherent package instead of four fragments.
- **Negative / cost:** an unattended run can't go from task to pull request on its own — the developer
  is on the critical path once per feature. The gate is a convention: `status` is prose in a markdown
  file, and CI can't see it. `/implement`'s refusal and reviewers checking `approvals:` are the
  enforcement.

## Alternatives considered

- **Keep the four plan approvals.** More stops, each checking less; the change surface still arrives
  last.
- **Gate after the spec only.** Cheaper to correct, but blind to the change surface.
- **No gate; rely on pull request review.** Review happens after the code exists — the expensive
  correction this gate exists to avoid.
