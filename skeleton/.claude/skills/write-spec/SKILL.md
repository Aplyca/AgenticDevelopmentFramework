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

3. **Draft the spec** — Use the template at `specs/_template.md`. Include:
   - **Overview**: one paragraph explaining what and why
   - **User stories**: As a [role], I want [action], so that [value]
   - **Acceptance criteria**: concrete, testable behaviors (the user sees X, clicking Y does Z)
   - **Edge cases**: empty states, errors, missing data, boundary conditions
   - **Out of scope**: what this spec intentionally does NOT cover

4. **For modifications** — When updating an existing spec:
   - Clearly mark what changed vs what stays the same
   - Update affected acceptance criteria rather than rewriting the entire spec
   - Add new edge cases if the change introduces them
   - The git diff of this update will drive the implementation scope

5. **Review rules** — Check that the spec doesn't contradict any existing specs or project conventions in CLAUDE.md.

6. **Set status to draft** — Never mark a spec as approved. Present it to the user for review.

7. **After approval** — Once the user approves, update the status to `approved`. Remind the user to commit the spec before writing tests — the next step is `/write-tests` (TDD), then `/implement`. The spec's git diff scopes both the tests and the implementation.

## Principles

- Business requirements only — no code, no file paths, no implementation details.
- Every acceptance criterion must be testable by an automated test.
- User-facing text must match the application's language.
- When in doubt, ask the user rather than assume.
