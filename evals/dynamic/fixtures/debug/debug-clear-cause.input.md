# Input — debug: when the code shows the cause, the regression test is the signal

This fixture verifies that `/debug` matches its effort to the bug. When reading the code shows the
cause, the regression test is the failing signal: no separate harness, no long hypothesis hunt, and
the fix goes to the fast lane.

## Repository context to give the AI

A Next.js marketing site with the framework adopted. `specs/007-newsletter-signup/` is delivered
(`status: implemented`); its spec says addresses are trimmed and lowercased before validation. The
validation lives in `lib/newsletter/validate-email.ts`, with tests in `lib/newsletter/__tests__/`.
Tests run with Node's built-in runner (`pnpm test` → `node --test`); there is nothing to install.
`run-session-evals.sh --suite debug` builds this project.

## Prompt to give the AI

```
/debug Readers who type their email in capitals (e.g. JANE@EXAMPLE.COM) get "Enter a valid email
address". The spec says addresses are lowercased before validation.
```

## What to do with this fixture

1. Load the repository context, then paste the prompt into your AI tool.
2. Capture the session through the diagnosis and the next step it proposes.
3. Compare against `debug-clear-cause.expected.md`.
