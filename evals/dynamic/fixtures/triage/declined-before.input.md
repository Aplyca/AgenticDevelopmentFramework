# Input — triage: a request that was declined before comes back with its reason

This fixture verifies that `/triage` checks whether new behavior was ruled out before — in the
*Out of scope* sections of related spec folders and in the decision records — and surfaces the
earlier decision and its reason before planning anything.

## Repository context to give the AI

A Next.js marketing site with the framework adopted. `specs/007-newsletter-signup/` is delivered
(`status: implemented`). Its *Out of scope* section says "Double opt-in confirmation emails — the
audience is single opt-in", and its Clarifications record the question and the answer: single
opt-in, from the marketing lead, with a date.

## Prompt to give the AI

```
/triage New readers should get a confirmation email and only join the newsletter list once they
click the link in it.
```

## What to do with this fixture

1. Load the repository context, then paste the prompt into your AI tool.
2. Capture the AI's first message (the triage) and the next step it takes.
3. Compare against `declined-before.expected.md`.
