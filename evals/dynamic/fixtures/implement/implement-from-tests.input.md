# Input — implement plans cover all filled spec sections + reads docs as design context

This fixture verifies that `/implement`:
- Refuses to plan if pre-impl docs are listed but not committed
- Reads ALL filled spec sections (not just Functional)
- Treats committed docs as design context to honor
- Surfaces doc-reconciliation steps when the chosen approach diverges
- Presents a plan before writing code

## Setup

Assume:
- `specs/contact-form.md` is committed (the contact-form spec from previous fixtures)
- Tests are committed and currently failing
- `docs/admin/contact-form.md` and `docs/copy/contact-form-defaults.md` are committed

## Prompt to give the AI

```
/implement contact-form
```

## What to do with this fixture

1. Ensure all three commits are in place (spec, tests, docs).
2. Run the prompt.
3. Capture the AI's implementation plan (Phase 1 output, before any code).
4. Compare against `implement-from-tests.expected.md`.

## Variant — missing docs commit

To verify docs enforcement, also run after committing the spec and tests but BEFORE committing the docs. The AI should refuse to plan and tell the user to run `/write-docs` first.
