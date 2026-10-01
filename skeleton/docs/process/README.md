# Process Decision Records

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: docs/process/ — decisions about how we work -->

Decisions about **how we work**: the workflow, review gates, the requirements pipeline, how agents
hand off work, tooling conventions. "Why does every pull request open as a draft?", "Why is there one
approval gate after the plan?", "Why can't an agent push?"

Same shape as an ADR — context, decision, consequences, alternatives — and the same discipline:
short, dated, **append-only**. Process decisions get re-argued as often as architectural ones, and
for the same reason: the cost is visible long after the reasoning has been forgotten.

- A decision that no longer holds is **superseded** by a new record; the old one changes only its
  status line.
- A record that turns out to be factually wrong gets a dated **correction note** under the affected
  passage — never a silent rewrite.
- **Constitution amendments** are recorded here.
- Every instruction file that describes the decided behavior (`AGENTS.md`, `CONTRIBUTING.md`, the
  pull request template, skills) is updated in the same pull request as the record.

> Decisions about **the application** — structure, dependencies, interfaces, data model, platform —
> are Architecture Decision Records in [`../architecture/decisions/`](../architecture/decisions/README.md).

## Index

<!-- CUSTOMIZE: one row per record. The first record usually documents adopting this workflow. -->

| # | Record | Status |
|---|---|---|
| 0001 | [`0001-adopt-ai-assisted-workflow.md` — Adopt the AI-assisted development workflow] | [accepted] |

## Writing one

1. Copy [`0000-pdr-template.md`](0000-pdr-template.md) to `NNNN-short-slug.md` with the next free number (`/record-decision` does this). The directory says it's a PDR; in prose it's `PDR-NNNN`.
2. Fill in context (with evidence), decision, consequences, alternatives. State the cost honestly — a
   record with no downsides is one nobody trusts later.
3. Open a pull request, add the record to the index above, and update the files that describe the
   decided behavior.
