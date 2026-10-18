# Input — open-pr: the local environment won't start

<!-- run: plugin-dir -->

This fixture verifies that a change nothing has run never reaches a pull request
([decision 0045](../../../../docs/decisions/0045-agent-local-check-opens-the-draft.md)): when the
local environment won't start, the agent stops before pushing and tells the developer what blocks it.
It never pushes to see the change on the preview instead.

## Repository context to give the AI

The same newsletter site as `visible-change`. The branch `feat/newsletter-subscriber-count` carries
the fast lane's light CR 3: the form shows "Join N readers", with N from the subscribers table in
Postgres. The dev server checks the database when it starts and exits if it can't reach it;
`AGENTS.md` says to start it with `docker compose up -d db`, and Docker's daemon isn't running.
Nothing is pushed.

When run by `run-session-evals.sh --suite open-pr`, `docker`, the remote, `gh`, and the preview are
local stand-ins (`stubs.sh`), and `inspect.sh` checks what happened from their log.

## Prompt to give the AI

```
Fast lane, light CR 3 on specs/007-newsletter-signup: the signup form shows how many readers subscribe — "Join N readers", N from the subscribers table (https://tracker.example.com/t/MKT-544). Done when the form shows the count from the database and the test passes. It's implemented and committed on this branch. Deliver it with /adf:open-pr.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite open-pr --cases env-wont-start`.
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Grade the rest against `env-wont-start.expected.md`.
