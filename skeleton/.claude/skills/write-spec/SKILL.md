---
name: write-spec
description: Write or update a feature specification. Use when starting a new feature or changing existing behavior.
user_invocable: true
argument-hint: "[feature description]"
---

# Write Spec

Write a feature specification following the spec-driven development workflow.

## Steps

1. **Check existing specs** — Read `specs/` to find any specs that already cover this area. Don't duplicate — update the existing spec if one exists.

2. **Understand the request** — Ask clarifying questions if the feature description is ambiguous. Understand:
   - Who is the user? (which role or persona)
   - What problem does this solve?
   - What does success look like?
   - Is this a new feature, a modification, or a bug fix?

3. **Clarify ambiguities** — Before drafting, systematically identify gaps in the requirements. Ask about:
   - Boundary conditions (what happens at limits? empty inputs? maximum values?)
   - Error scenarios (what if the API is down? what if data is missing?)
   - User permissions (who can and can't do this?)
   - Interactions with existing features (does this change anything else?)
   Record all questions and answers in the spec's **Clarifications** section so they're preserved as context for testing and implementation.

4. **Draft the spec** — Use the template at `specs/_template.md`. Include:
   - **Overview**: one paragraph explaining what and why
   - **User stories**: As a [role], I want [action], so that [value]
   - **Acceptance criteria**: concrete, testable behaviors (the user sees X, clicking Y does Z)
   - **Clarifications**: Q&A from step 3
   - **Edge cases**: empty states, errors, missing data, boundary conditions
   - **Out of scope**: what this spec intentionally does NOT cover

5. **For modifications** — When updating an existing spec:
   - Clearly mark what changed vs what stays the same
   - Update affected acceptance criteria rather than rewriting the entire spec
   - Add new edge cases if the change introduces them
   - The git diff of this update will drive the test and implementation scope

6. **Review rules** — Check that the spec doesn't contradict any existing specs or project conventions in CLAUDE.md.

7. **Set status to draft** — Never mark a spec as approved. Present it to the user for review.

8. **After approval** — Once the user approves, update the status to `approved`. Remind the user to commit the spec before writing tests — the next step is `/write-tests` (TDD), then `/implement`. The spec's git diff scopes both the tests and the implementation.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The requirements are clear enough, I'll skip clarification" | Ambiguities always exist. Uncovered gaps leak into tests and code as bugs. 5 minutes of questions saves hours of rework. |
| "I'll combine these into one acceptance criterion" | Each AC must be independently testable. Combined ACs hide untested behavior. |
| "Edge cases aren't needed for this simple feature" | Simple features break at edges. Empty states, missing data, and error scenarios are where real users encounter bugs. |
| "I'll add implementation details to help the developer" | Specs describe WHAT, not HOW. Implementation details in specs constrain the solution and become stale. |
| "Out of scope isn't needed" | Without explicit boundaries, implementation drifts. Out of scope prevents scope creep. |

## Verification

- [ ] Every acceptance criterion is testable by an automated test
- [ ] Clarifications section records all ambiguity resolutions
- [ ] Edge cases cover: empty states, error states, boundary conditions
- [ ] Out of scope section explicitly excludes adjacent features
- [ ] Status is set to `draft` (never auto-approve)

## Principles

- Business requirements only — no code, no file paths, no implementation details.
- Every acceptance criterion must be testable by an automated test.
- User-facing text must match the application's language.
- When in doubt, ask the user rather than assume.
