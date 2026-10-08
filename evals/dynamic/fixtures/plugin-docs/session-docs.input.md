# Input — plugin docs: the session finds a reference doc in the plugin

<!-- run: plugin-dir -->

This fixture verifies, in a real session, that Claude itself — not a skill or an agent — finds a reference doc in the plugin: the plugin's SessionStart hook names the folder, and the read rule lets Claude read it, instead of fetching the GitHub link the project's files carry.

## Repository context to give the AI

A project on the packaged install with no reference docs in `docs/`; its files link them at the pinned release on GitHub. The `adf` plugin is loaded from this checkout for the session only (`--plugin-dir`), in default permission mode, with the read rule for the plugin's folder.

## Prompt to give the AI

```
Which of the framework's documents explains where a piece of project knowledge belongs — AGENTS.md, memory, a spec folder, or a decision record? Open that document and reply with its first heading only.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite plugin-docs --cases session-docs` (Haiku by default).
2. `inspect.sh` checks the run and prints ✓ or ✘, then every read the session made.
3. Compare against `session-docs.expected.md`.
