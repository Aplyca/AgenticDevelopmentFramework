# 0037: End-to-end tests follow a specification: Playwright in `e2e/`, against the checkout's own stack

- **Status:** accepted
- **Date:** 2026-10-12

## Context

The framework's process is test first: every change starts with a test seen failing
(`.claude/rules/testing.md`). It said little about end-to-end tests:
- where they live;
- what runs them;
- what they run against;
- how an agent writes one that doesn't flake.

Each adopting project answered differently, or not at all. An agent writing an end-to-end test for a
fix had no groundwork to build on: no configuration, no fixtures, no command, no list of the flows
that matter.

The `docker` module already gives every checkout its own stack, with ports of its own (decisions
0032, 0034). An end-to-end suite can test that stack instead of starting another.

## Decision

- **A new `e2e` module,** carried by `adf-dev` like `docker` (decision 0023). Its skill,
  `/adf-dev:e2e`, sets up, audits, and extends a suite. It carries a `SPECIFICATION.md`, each
  requirement with an ID. It works without the `docker` module, and with it, it adds tasks to each
  local mode.
- **No templates.** The project writes its suite to the specification, and its runs prove it:
  `make smoke` passes in each local mode, and each smoke test was seen failing. The suite is
  configuration and the project's own tests, with no script of real logic — unlike `dev-env`'s
  `native.sh` and `guard.sh`, which stay templates. The details that are easy to get wrong — the
  image at the engine's exact version, the dependencies installed in the image, the build context
  that sends only the suite — are requirements in the specification, not files.
- **The engine is Playwright Test, in TypeScript, with Chromium:**
  - it waits for the page by itself, so tests need no sleeps;
  - it keeps a failure's trace, screenshot, and the page as a person reads it, which an agent can
    diagnose from;
  - it ships an official Docker image, so a project runs it without Node on the host;
  - it runs tests in parallel, and it has the widest use.
- **The suite lives in `e2e/`, with its own `package.json`.** The engine is the same whatever the
  app's stack is, and it's pinned exactly, to the same version as its Docker image.
- **It runs against the checkout's own stack.** `make e2e` and `make smoke` start it with `make up`,
  then test it. The suite never starts a second stack or a server of its own. In Docker mode it runs
  in an `e2e` Compose service under a profile, built on Playwright's image, reaching the app by its
  service name. In native mode it runs on the host, against the app's port.
- **Tests own their data.** The stack is the developer's own, with their data in it, so each test
  creates what it needs with unique values. It never reaches a real third party.
- **A smoke suite:** one `@smoke` test per critical flow, which the developer names in
  `e2e/README.md`. It runs before the local check and in CI.
- **The tests for a change are written the way every test is,** test first with `/adf:write-tests`
  and `/adf:implement`. `.claude/rules/testing.md` gains § End-to-end, which carries the
  specification's authoring and test-first rules into every session. An acceptance criterion gets an
  end-to-end test only when the whole stack is needed to show it.
- **The module's rules allow running the suite** (`make e2e`, `make smoke`, `npm --prefix e2e test`)
  without a prompt, so a test-first loop reruns a test as often as it needs.

## Consequences

- **Positive:**
  - Every adopting project's suite has the same shape, commands, and conventions, so an agent's
    end-to-end test fits the first time.
  - A fix or a feature has groundwork for its test from the first commit: the configuration, the
    fixtures, a command that starts what it needs.
  - Worktrees run their suites side by side, each against its own stack.
  - A failure leaves text an agent reads (`error-context.md`) instead of a rerun.
- **Negative / cost:**
  - **Tests write to the developer's local data.** Unique values keep them apart, but rows pile up
    until a `make reset`.
  - **Docker mode pulls Playwright's image,** about 2 GB, once per version. Each run rebuilds the
    image's last layer, about a second.
  - **Running the suite starts the stack without a prompt,** which `make up` alone would ask about.
    Starting the checkout's own stack is what a test run needs.
  - **TypeScript tests in a project of another language.** The suite is separate from the app's
    code, and Playwright's test runner is TypeScript-first. Another binding (Python) is a recorded
    departure.
  - **`native.sh env` changed:** while the app runs, it reports the app's own port, so `make test`
    and `make e2e` reach it. Before, it made up a free one. Projects that copied the earlier template
    merge the fix.

## Alternatives considered

- **A separate stack for the suite** (`<project>-e2e`), fresh each run. Declined. It's isolated, but
  every run pays for startup and an image rebuild under the new project name. That's too slow for a
  red-green loop, and CI starts from a fresh stack anyway.
- **Part of the `docker` module.** Declined. A project without Docker would get no end-to-end
  support.
- **Cypress.** Declined. It runs inside the browser, is heavier, and needs a paid service to run in
  parallel. **Puppeteer** has no test runner. **WebdriverIO** and **Selenium** take more setup for
  the same result.
- **Templates of the suite, the image, the service, and the tasks.** Tried first, and declined. Most
  of it is project-specific — the tests, the flows, the fixtures — so a project rewrites it anyway.
  A second source drifts from the specification, and every engine upgrade would touch both.
- **Playwright in the app's own `package.json`.** Declined as the default. It ties the engine to the
  app's dependency upgrades, and to Node. A JavaScript project may record it as a departure.
