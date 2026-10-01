# Project Constitution

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: non-negotiable principles for the whole project -->

The non-negotiable principles of this project. Every change — human- or AI-generated — is checked
against them as a **gate**: specs and plans before the approval gate, code in review. Work that
violates a principle doesn't advance; it gets discussed.

**On conflict with `AGENTS.md` or any other instruction file, this document wins.** That makes its
accuracy critical: an agent that resolves a contradiction by precedence will follow a stale line here
with full confidence. When a principle depends on a decision record (the branching model, the stack),
link it — the two must move together.

Keep it short: principles only. Conventions go in `AGENTS.md`; standards in `.claude/rules/`. If an
item would change more than once a quarter, it doesn't belong here.

## Principles

<!-- CUSTOMIZE: pick and adapt the examples that are true for this project, add your own, delete the rest. 5–10 is healthy; 20 is a rulebook, not a constitution. -->

1. [e.g., **No merge without human review** — AI-generated changes included, and stricter for them: read the whole pull request, not just the diff. CI is a signal; the review is the gate.]
2. [e.g., **Human accountability is indelegable** — whoever merges a change owns it, however much of it was AI-generated.]
3. [e.g., **Quality gates are never bypassed** — git hooks, lint, typecheck, secret scan. "It passes the tests" is not "it is correct".]
4. [e.g., **Security by default** — new endpoints are authenticated and validated unless the spec says public; authorization is never loosened to make data appear.]
5. [e.g., **Secrets never live in code or git** — every environment variable the code reads is declared by name in the env template.]
6. [e.g., **Requirements are never invented** — a gap in a requirement is a question for a human, not an assumption.]
7. [e.g., **Database history is append-only** — schema changes are new migrations; existing migrations are never edited.]
8. [e.g., **Types are load-bearing** — the type system is never silenced to clear an error.]
9. [e.g., **Accessibility is a requirement, not polish** — UI meets WCAG 2.1 AA; accessibility lint stays on.]
10. [e.g., **Approved stack only** — new languages, frameworks, services, or dependencies need a stated justification; stack additions need an ADR.]
11. [e.g., **Changes reach production only through pull requests into [base branch]** — the branching and release model is ADR-NNNN.]

## Amendment process

1. Open a pull request that amends this file — and contains nothing that benefits from the amendment.
   Never amend the constitution inside the change that needs it.
2. Record the amendment as a PDR in `docs/process/` (`/record-decision`): what changed, why, and what
   it costs.
3. In the same pull request, update every file that restates the principle — `AGENTS.md`,
   `CONTRIBUTING.md`, the pull request template — so no instruction file contradicts this one.
4. [CUSTOMIZE: who must approve — e.g., the tech lead and one senior developer]

## How this document is used

- `/write-spec` and `/write-plan` check specs and plans against it; `@spec-analyzer` flags conflicts
  before the approval gate.
- Reviewers treat a violation as a blocker, not as style feedback.
- When a principle and a deadline collide, the answer is an explicit amendment or an explicit
  exception recorded in the spec — never a silent bypass.
