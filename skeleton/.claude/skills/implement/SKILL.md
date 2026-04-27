---
name: implement
description: Implement a feature from an approved spec. Use after the spec has been approved and committed.
user_invocable: true
argument-hint: "[spec name or path]"
---

# Implement from Spec

Build the feature according to an approved, committed specification.

## Steps

1. **Identify the scope from git diff** — Run `git diff HEAD~1 -- specs/` (or the appropriate range) to see what changed in the spec. This tells you exactly what to implement:
   - **New spec file** → implement all acceptance criteria from scratch
   - **Modified spec** → focus on the diff: new ACs added, existing ACs changed, edge cases added or removed. Don't re-implement unchanged criteria.

2. **Read the full spec** — Read the complete spec in `specs/` for full context. The diff tells you what's new; the full spec tells you how it fits together.

3. **Check existing code** — Read the files you'll modify. Understand the current patterns, imports, and conventions before making changes. For modifications, understand what already works and must be preserved.

4. **Plan the implementation** — Before writing code, outline which files need changes and what each change does. For non-trivial features, present the plan to the user for alignment.

5. **Implement** — Write code that satisfies each acceptance criterion. Follow the project's rules and conventions:
   - Match existing patterns in neighboring code
   - Handle edge cases listed in the spec
   - Validate at system boundaries
   - Handle errors gracefully

6. **Self-review** — Before presenting to the user:
   - Does each acceptance criterion (especially new/changed ones from the diff) have corresponding code?
   - Are edge cases handled?
   - Does the code follow project rules (naming, typing, error handling)?
   - No speculative features beyond what the spec says?
   - For modifications: is existing behavior preserved where the spec didn't change?

## Principles

- Build exactly what the spec says — no more, no less.
- For modifications, the git diff is your scope. Changed ACs = changed code. Unchanged ACs = unchanged code.
- Follow existing patterns. Don't introduce new patterns unless the spec requires it.
- If something in the spec is unclear or seems wrong, ask the user before implementing a guess.
