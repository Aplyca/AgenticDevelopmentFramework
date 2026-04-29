# Input — write-docs plans pre-implementable docs from spec + tests

This fixture verifies that `/write-docs`:
- Reads the spec's Documentation Pre-implementable section
- Reads the committed tests as ground truth for what to document
- Skips cleanly when no pre-implementable docs are listed
- Presents a doc plan before writing

## Setup

Assume the contact-form spec from `tests-from-spec.input.md` is committed AND its Documentation section reads:

```
## Documentation [REQUIRED]

### Pre-implementable docs
| Audience | What they need | Where it lives |
|---|---|---|
| Site administrator (marketing) | How to view contact form submissions in Salesforce, how to update the reCAPTCHA secret if it rotates, what to check when submissions stop arriving | docs/admin/contact-form.md |
| End user | Default microcopy for form labels, placeholder text, and the success/error messages | docs/copy/contact-form-defaults.md |

### Post-implementable docs
| Audience | What they need | Where it lives |
|---|---|---|
| Developer | JSDoc on the route handler explaining the rate-limit + reCAPTCHA flow | Inline + docs/ARCHITECTURE.md paragraph |
| Operator | Runbook entry: investigating Salesforce sync failures, what to check when reCAPTCHA scores drop site-wide | docs/runbooks/contact-form.md |
```

The contact-form tests are also assumed committed.

## Prompt to give the AI

```
/write-docs contact-form
```

## What to do with this fixture

1. Ensure the spec is in `specs/contact-form.md` and tests are committed.
2. Run the prompt.
3. Capture the AI's doc plan (Phase 1 output, before any docs are written).
4. Compare against `docs-from-tests.expected.md`.

## Variant — skip-clean test

To verify the skip-clean condition, also run with a spec where the Documentation Pre-implementable subsection is `> Not applicable: no admin/API/SDK surface; only post-implementable JSDoc`. The AI should skip with a note and recommend proceeding to `/implement`.
