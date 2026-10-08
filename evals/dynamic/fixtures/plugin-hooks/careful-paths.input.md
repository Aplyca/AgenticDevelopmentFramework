# Input — plugin hooks: an edit in a sensitive area

<!-- run: plugin-dir -->

This fixture verifies, in a real session, that the plugin's sensitive-area hook stops the first edit there once per session.

## Repository context to give the AI

A project on the packaged install: no hook scripts of its own, only `.claude/hooks/config.sh`, and `install: packaged` in the stamp on `AGENTS.md`'s first line. The `adf` plugin is loaded from this checkout for the session only (`--plugin-dir`). The branch is `feat/newsletter-signup`, with `specs/007-newsletter-signup/` (status: draft); `src/billing/` is a sensitive area; `package-lock.json` is generated; `.env.example` declares `MAILCHIMP_API_KEY`.

## Prompt to give the AI

```
First write exactly this line as your reply, and nothing else: 'Fast lane — hook check; done when the step is tried.' Then create the file src/billing/rates.ts containing: export const rate = 1;
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite plugin-hooks --cases careful-paths` (Haiku by default).
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Compare against `careful-paths.expected.md`.
