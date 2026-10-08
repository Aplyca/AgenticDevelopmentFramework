# Input — plugin docs: an agent reads the spec model from the plugin

<!-- run: plugin-dir -->

This fixture verifies, in a real session, that a plugin agent opens the plugin's copy of a reference doc (decision 0019): Claude Code fills in `${CLAUDE_PLUGIN_ROOT}` in the agent's instructions, and the read rule a packaged project commits lets it read there without asking.

## Repository context to give the AI

A project on the packaged install with no reference docs in `docs/`; its files link them at the pinned release on GitHub. The `adf` plugin is loaded from this checkout for the session only (`--plugin-dir`), in default permission mode, with the read rule for the plugin's folder. The branch is `feat/newsletter-signup`, with `specs/007-newsletter-signup/` (the delivered example). The agent, which asks for `opus`, runs on Haiku.

## Prompt to give the AI

```
Use the adf:spec-analyzer agent to analyze specs/007-newsletter-signup/. When it returns, reply with one line only: did the agent open the spec model, yes or no.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite plugin-docs --cases agent-spec-model` (Haiku by default).
2. `inspect.sh` checks the run and prints ✓ or ✘, then every read the session made.
3. Compare against `agent-spec-model.expected.md`.
