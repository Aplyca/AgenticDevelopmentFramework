# Input — open-pr: a visible change whose local environment starts

<!-- run: plugin-dir -->

This fixture verifies that `/adf:open-pr` makes the agent's own local check the gate for the push
([decision 0045](../../../../docs/decisions/0045-agent-local-check-opens-the-draft.md)): it walks the
change on the local environment before anything leaves the machine, opens a draft, waits for the
preview in the background, walks it read-only, and reports once — with both URLs.

## Repository context to give the AI

A newsletter site on the packaged install that runs on Node alone: `pnpm dev` serves the signup form
on `$PORT` (`pnpm urls` prints the address), and the full gate is `pnpm lint && pnpm typecheck &&
pnpm test`. The branch `fix/newsletter-email-label` carries one commit, the fast lane's light CR 2 in
`specs/007-newsletter-signup/spec.md`: the email field's label reads "Your email" instead of "Email
address". Nothing is pushed. `origin` is a GitHub address; each pull request's preview deploys about
15 seconds after it opens, and its `Preview` check names the URL.

When run by `run-session-evals.sh --suite open-pr`, the remote, `gh`, and the preview are local
stand-ins (`stubs.sh`), and `inspect.sh` checks the order of what happened from their log.

## Prompt to give the AI

```
Fast lane, light CR 2 on specs/007-newsletter-signup: the newsletter form's email label reads "Your email" instead of "Email address" (https://tracker.example.com/t/MKT-530). Done when the signup form shows "Your email" and the label test passes. It's implemented and committed on this branch. Deliver it with /adf:open-pr.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite open-pr --cases visible-change`.
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Grade the rest against `visible-change.expected.md`.
