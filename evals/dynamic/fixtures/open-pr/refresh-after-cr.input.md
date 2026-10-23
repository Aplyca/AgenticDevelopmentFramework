# Input — open-pr: refreshing the draft's description after a change request

<!-- run: plugin-dir -->

This fixture verifies that once a later push changes what an open draft's description says, the
agent refreshes it with `/adf:open-pr refresh`: it fetches the current body, rebuilds only the
sections between the `adf:` markers from the record, keeps everything people wrote outside them,
shows the description's diff, and applies it with `gh pr edit --body-file`, without asking. It never
opens a second pull request.

## Repository context to give the AI

The same newsletter site as `visible-change`. The branch `fix/newsletter-email-label` carries the fast
lane's light CR 2 (the email label reads "Your email"), pushed, with its draft pull request open (#42)
and its preview deployed. The description's agent-owned sections sit between `<!-- adf:… -->`
markers; outside them are a note from marketing under the Lane line, a screenshot, and a ticked box.
The preview redeploys about 10 seconds after each push, at the same address.

When run by `run-session-evals.sh --suite open-pr`, the remote, `gh`, and the preview are local
stand-ins (`stubs.sh`), and `inspect.sh` checks what happened from their log and the description
`gh` last received.

## Prompt to give the AI

```
Marketing saw the preview of the draft (https://github.com/example-org/newsletter-site/pull/42) and changed their mind: the email label should read "Your email address", not "Your email". Update light CR 2 on this branch, and keep the pull request current.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite open-pr --cases refresh-after-cr`.
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Grade the rest against `refresh-after-cr.expected.md`.
