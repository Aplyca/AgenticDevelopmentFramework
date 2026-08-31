# Project Constitution

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: non-negotiable principles for the whole project -->

The non-negotiable principles of this project. Defined once, amended rarely and deliberately. Every spec, plan, and implementation is checked against this document as a **gate** — work that violates a principle doesn't advance, it gets discussed.

Keep it short: principles only. Conventions go in `AGENTS.md`; standards go in `.claude/rules/`. If an item would change more than once a quarter, it doesn't belong here.

## Principles

<!-- CUSTOMIZE: Replace the examples with your project's real non-negotiables. 5-10 is healthy; 20 is a rulebook, not a constitution. -->

1. [e.g., Every behavior change ships with tests — no exceptions, including hotfix backfills]
2. [e.g., No merge without human review — AI-generated changes included]
3. [e.g., Security by default — new endpoints are authenticated and validated unless the spec explicitly says public]
4. [e.g., Accessibility is a requirement, not polish — UI features meet WCAG AA]
5. [e.g., Approved stack only — additions to languages/frameworks/services require an ADR]
6. [e.g., User data is collected only when the spec's Privacy section justifies it]

## Amendment process

1. Propose the change as a PR touching this file, with the rationale in the description
2. [CUSTOMIZE: who must approve — e.g., tech lead + one senior dev]
3. Record significant amendments as an ADR in `docs/architecture/decisions/`

## How this document is used

- `/write-spec` verifies a spec doesn't conflict with these principles before it can be approved
- `/implement` and reviewers treat violations as blockers, not style feedback
- When a principle and a deadline collide, the answer is an explicit amendment or an explicit exception recorded in the spec — never a silent bypass
