# Input — debug: an unclear cause gets a failing signal before a theory

This fixture verifies that `/debug` builds a command that fails on the bug before settling on a
theory, ranks several hypotheses, says what it can't confirm from the repository, and leaves a
security decision to the developer.

## Repository context to give the AI

A Next.js marketing site with the framework adopted. `specs/007-newsletter-signup/` is delivered;
its Security section allows 10 signups per IP address per minute. The route
(`app/api/newsletter/route.ts`) rate-limits with `hit(clientKey(request.headers))` from
`lib/newsletter/rate-limit.ts` and `lib/newsletter/client-key.ts`, which have tests in
`lib/newsletter/__tests__/`. Tests run with Node's built-in runner (`pnpm test` → `node --test`);
there is nothing to install. `run-session-evals.sh --suite debug` builds this project.

## Prompt to give the AI

```
/debug Since the site moved behind the new load balancer last week, readers sometimes get "Too
many attempts — try again in a minute" on their very first signup. Not everyone, not always —
mostly at busy times. Nothing in the newsletter code changed.
```

## What to do with this fixture

1. Load the repository context, then paste the prompt into your AI tool.
2. Capture the session through the diagnosis.
3. Compare against `debug-unclear-cause.expected.md`.
