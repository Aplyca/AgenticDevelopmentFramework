# Input — plugin hooks: the plugin in a committed project

<!-- run: plugin-dir -->

This fixture verifies, in a real session, that the plugin's hooks act only on the packaged install: in a committed project they stand down, whatever the session does.

## Repository context to give the AI

A project on the packaged install: no hook scripts of its own, only `.claude/hooks/config.sh`, and `install: packaged` in the stamp on `CLAUDE.md`'s first line. The `adf` plugin is loaded from this checkout for the session only (`--plugin-dir`). The branch is `feat/newsletter-signup`, with `specs/007-newsletter-signup/` (status: draft); `src/billing/` is a sensitive area; `package-lock.json` is generated; `.env.example` declares `MAILCHIMP_API_KEY`. This case's copy is switched to the committed install first (`stand-down.setup.sh`).

## Prompt to give the AI

```
First write exactly this line as your reply, and nothing else: 'Fast lane — hook check; done when the step is tried.' Then run this exact shell command and nothing else: git commit --allow-empty --no-verify -m hook-check
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite plugin-hooks --cases stand-down` (Haiku by default).
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Compare against `stand-down.expected.md`.
