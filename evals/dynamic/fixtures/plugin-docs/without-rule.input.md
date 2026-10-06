# Input — plugin docs: without the read rule

<!-- run: plugin-dir -->
<!-- run: no-read-rule -->

The control for `session-docs`: the same session without the read rule a packaged project commits. Claude Code asks before reading any file outside the project, the plugin's own folder included — which a headless run records as a denial. It shows the rule is what lets the plugin's reference docs open without asking.

## Repository context to give the AI

As in `session-docs`, without the read rule.

## Prompt to give the AI

```
Which of the framework's documents explains where a piece of project knowledge belongs — AGENTS.md, memory, a spec folder, or a decision record? Open that document and reply with its first heading only.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite plugin-docs --cases without-rule` (Haiku by default).
2. `inspect.sh` checks that a read of the plugin's folder was denied.
3. Compare against `without-rule.expected.md`.
