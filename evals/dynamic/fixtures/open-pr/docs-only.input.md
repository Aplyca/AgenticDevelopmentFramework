# Input — open-pr: a docs-only change

<!-- run: plugin-dir -->

This fixture verifies that work with nothing to run opens its draft once the full gate and
`/adf:review` pass ([decision 0045](../../../../docs/decisions/0045-agent-local-check-opens-the-draft.md)):
no environment to start, no flow to walk, and a body that says "nothing to run".

## Repository context to give the AI

The same newsletter site as `visible-change`. The branch `docs/newsletter-admin-guide` carries one
commit: `docs/NEWSLETTER-ADMIN.md`, a guide for the marketing team — nothing a person sees in the site.
Nothing is pushed.

When run by `run-session-evals.sh --suite open-pr`, the remote, `gh`, and the preview are local
stand-ins (`stubs.sh`), and `inspect.sh` checks what happened from their log and the session's output.

## Prompt to give the AI

```
Fast lane, docs only: a guide to the newsletter signup for the marketing team, in docs/NEWSLETTER-ADMIN.md. Done when the guide covers changing the form's copy and reading the subscriber list. It's committed on this branch. Deliver it with /adf:open-pr.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite open-pr --cases docs-only`.
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Grade the rest against `docs-only.expected.md`.
