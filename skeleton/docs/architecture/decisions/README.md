# Architecture Decision Records (ADRs)

This directory captures significant architectural and technical decisions made during the project.

## What is an ADR?

An Architecture Decision Record documents a decision that has a significant impact on the system's architecture, technology choices, or development practices. It captures the context, the decision itself, and the consequences — so future team members understand *why* things are the way they are.

## When to write an ADR

Write an ADR when you:

- Choose a framework, language, database, or major library
- Define a communication pattern between services
- Select a deployment platform or infrastructure approach
- Change a security or authentication strategy
- Make a decision that would be expensive to reverse
- Resolve a technical disagreement on the team

You do NOT need an ADR for:

- Minor library choices (utility packages, formatting tools)
- Code style decisions (those belong in `.claude/rules/`)
- Bug fixes or feature implementations (those belong in specs)

## How to write an ADR

1. Copy the template: `cp 0000-template.md NNNN-short-title.md`
2. Use the next sequential number
3. Fill in all sections — especially Context and Rationale
4. Set status to `Proposed`
5. Get team review
6. Update status to `Accepted` when approved

## How to supersede an ADR

When a decision changes:

1. Write a new ADR explaining the new decision
2. Reference the old ADR in the Context section
3. Update the old ADR's status to `Superseded by ADR-NNNN`
4. Never delete old ADRs — they preserve history

## Index

| ADR | Title | Status | Date |
|---|---|---|---|
| [0001](0001-framework.md) | [Framework selection] | [Accepted] | [YYYY-MM-DD] |
