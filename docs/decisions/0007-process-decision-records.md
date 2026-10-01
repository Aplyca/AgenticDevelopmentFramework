# 0007: Process decisions are recorded as PDRs; the constitution is amended through them

- **Status:** accepted
- **Date:** 2026-10-01

## Context

ADRs capture decisions about the application. Decisions about *how the team works* — the approval
gate, draft pull requests, who may push, how agents hand off work — are argued just as often and
forgotten just as fast, but had no home: they lived in a pull request description or in one
developer's habit, where no agent on another machine could read them.

The constitution has a sharper version of the problem. It overrides `AGENTS.md` on conflict, so a
stale line in it is the most dangerous instruction in the repository. In one project the
constitution said feature work merges into `main` while `AGENTS.md` (correctly) said `staging`; an
agent resolving the conflict by precedence would have opened every feature pull request against
production. The fix was itself a process decision, and needed a record.

## Decision

- Adopting repositories get `docs/process/` — **Process Decision Records** with the ADR shape
  (context with evidence, decision, consequences including cost, alternatives), append-only:
  superseded by new records, corrected with dated notes, never silently rewritten.
- **Constitution amendments are recorded as PDRs**, in their own pull request — never inside the
  change that benefits from the amendment.
- Every instruction file that describes the decided behavior is updated in the **same** pull request
  as the record, so record and instructions can't disagree.
- `/record-decision` writes ADRs and PDRs and maintains the indexes; `/context-audit` (and the
  `/deep-context-audit` workflow) look for contradictions between the constitution, `AGENTS.md`,
  `CONTRIBUTING.md`, decision records, CI, and hook configuration.
- `/adopt` records the adoption itself as PDR-0001.

## Consequences

- **Positive:** "why do we do it this way?" has an answer in the repository; precedence conflicts are
  found by audit instead of by an agent acting on them.
- **Negative / cost:** another directory to keep current; small process tweaks now cost a short
  record.

## Alternatives considered

- **Put process decisions in ADRs.** Mixes two audiences; ADR indexes get noisy and teams stop
  reading them.
- **Keep process in `CONTRIBUTING.md` only.** It says *what*, not *why* — so the same debates recur.
