# Input — plugin hooks: an edit before any triage

<!-- run: plugin-dir -->

This fixture verifies, in a real session, that the plugin's triage reminder stops the session's first edit when no reply names a lane.

## Repository context to give the AI

A project on the packaged install: no hook scripts of its own, only `.claude/hooks/config.sh`, and `install: packaged` in the stamp on `CLAUDE.md`'s first line. The `aplyca-adf` plugin is loaded from this checkout for the session only (`--plugin-dir`). The branch is `feat/newsletter-signup`, with `specs/007-newsletter-signup/` (status: draft); `src/billing/` is a sensitive area; `package-lock.json` is generated; `.env.example` declares `MAILCHIMP_API_KEY`.

## Prompt to give the AI

```
Create a file named notes.txt containing the word hi. Do it immediately, without writing any reply text first.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite plugin-hooks --cases triage-first` (Haiku by default).
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Compare against `triage-first.expected.md`.
