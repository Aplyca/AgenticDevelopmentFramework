# 0052: A production-like run is the optional `make prod` task, in the configured mode

- **Status:** accepted
- **Date:** 2026-10-23

## Context

The local environment's specification (decisions 0032 and 0034) gives every mode the same tasks:
`up`, `down`, `urls`, `logs`, and the rest. An agent runs them in the mode the checkout is configured
for, and only the developer changes it (M10). The docker module denies the mode overrides.

None of those tasks builds the app the way a deploy does. Some bugs show only in the production
build: a page rendered at build time, a minified bundle, an environment the dev server doesn't read.
An adopting team's agents, on a Docker-mode project, built and served the app on the host to see one:
`build` and `start` from the package manifest, outside the configured mode, with the host's runtime
and variables. Nothing denied it, because a host command isn't a mode override. The specification
already says a command agents keep needing becomes a task of its own (C10). This one was missing.

## Decision

- **An optional task, `prod`, in every local mode (C11).** It builds the app for production, serves
  it, and returns once it answers, then prints where it is.
  - **Docker mode:** a `<APP>-prod` service in Compose's `prod` profile, so `make up` never starts
    it. It's built from the app Dockerfile's `prod` stage, with no source mount, published on
    `APP_PROD_PORT` (empty: Docker picks), and runs beside the dev server.
  - **Native mode:** `NATIVE_PROD_CMD` runs through `native.sh` in place of the dev server, on its
    port, until the next `make up`. `ops/native/.run/app.kind` says which one runs, so `app.env`
    keeps exactly `PID` and `APP_PORT` (M7) and the band above the prompt still finds the app.
- **The tasks people already use cover it.** `make urls` shows its address, `make logs s=web-prod`
  prints its log, and `make down` stops it.
- **Agents use it, and nothing else, for a production build.** The `/adf-dev:dev-env` skill rejects
  the host build-and-start, AGENTS.md's Quick reference names the command, and an open-pr session
  eval checks it. A project without a production-like run deletes the task, the service, and the
  stage. An agent that needs one then says so and asks.

## Consequences

- **Positive:**
  - A bug that shows only in production reproduces locally, in the same mode as everything else,
    without a deploy.
  - The production build runs beside the dev server in Docker mode, so the local check can compare
    the two.
- **Negative / cost:**
  - **Another service, stage, and command to fill** when the stack is written, or to delete.
  - **Native mode replaces the dev server** while the production build runs, so the developer's
    reloads stop until `make up`.
  - **A rule, not a guard.** No deny rule can tell a host `build` from a legitimate one, such as
    native mode's own. The skill, the Quick reference line, and the eval carry it.

## Alternatives considered

- **Deny `npm run build`, `start`, and the like.** Declined: the commands differ by stack, and
  native mode runs them legitimately.
- **A production stage in the dev service, switched by a variable.** Declined: switching it is a
  mode change by another name, and the dev server would stop while it runs.
- **A Docker-only task.** Declined: the same task names in every mode is what lets an agent ignore
  the mode (M9).
