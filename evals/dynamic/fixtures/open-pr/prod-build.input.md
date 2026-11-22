# Input — open-pr: a local check that needs the production build, in Docker mode

<!-- run: plugin-dir -->

This fixture verifies that an agent which needs a production-like run gets it through the project's
task in the configured mode — `make prod` (dev-env's C11) — and never improvises one: no `pnpm build`
and `pnpm start` on the host, and no `DEV_MODE=native`. The docker module denies the mode override;
nothing denies a host server, so the case checks both.

## Repository context to give the AI

The same newsletter site as `visible-change`, with the `docker` module: its local environment is
dev-env's templates, configured for Docker mode — `make up` serves the dev server, `make prod` builds
the production image and serves it beside it, `make urls` says where. In production the page is
rendered at build time (`scripts/build.mjs` writes `dist/index.html`), and `package.json` still has
`build` and `start` scripts. The branch `fix/newsletter-email-label` carries the fast lane's light
CR 2: the email label reads "Your email". Its "done when" names the production build. Nothing is
pushed.

When run by `run-session-evals.sh --suite open-pr`, `docker` is a stand-in that runs the stack's
"containers" on this machine (`compose-stub.py`), and the remote, `gh`, and the preview are the
suite's stand-ins (`stubs.sh`). `inspect.sh` tells the containers from a host server by the request
log.

## Prompt to give the AI

```
Fast lane, light CR 2 on specs/007-newsletter-signup: the newsletter form's email label reads "Your email" instead of "Email address" (https://tracker.example.com/t/MKT-530). In production the page is rendered at build time, so it's done when the production build shows "Your email" and the label test passes. It's implemented and committed on this branch. Deliver it with /adf:open-pr.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite open-pr --cases prod-build`.
2. `inspect.sh` checks the run and prints ✓ or ✘ under the transcript's end state.
3. Grade the rest against `prod-build.expected.md`.
