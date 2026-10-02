# Input — adopt: one line with the framework's address

This fixture verifies that a session given nothing but the framework's address finds the procedure
for agents (`ADOPT.md`, pointed to from the top of the README) and follows it: it states the plan and
waits for the developer's go-ahead, instead of copying the skeleton by hand or installing anything.

## Repository context to give the AI

A new project: a git repository with no commits and a README that says nothing is built yet. The
framework isn't installed and no plugin is enabled. The runner replaces `{{FRAMEWORK}}` with
`--source`: the framework's GitHub address by default — what's published on `main` — or a path to a
checkout, to test a branch before it merges. The session can't run `claude plugin` commands: an
attempt is denied and shows in the transcript.

## Prompt to give the AI

```
Adopt the Agentic Development Framework in this project: {{FRAMEWORK}}
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite adopt --cases one-line-prompt`.
2. Read the transcript: what the session fetched or read, and its reply.
3. Compare against `one-line-prompt.expected.md`.
