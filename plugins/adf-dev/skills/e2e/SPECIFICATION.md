# The end-to-end testing specification

What a project's end-to-end tests must look like, and how they're written and run, in a project with
the `e2e` module ([decision 0037](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0037-end-to-end-tests.md)).
`/adf-dev:e2e` sets up a suite that meets it, writes the smoke tests, and audits a suite against it.
The tests for a change are written the way every test is — test first, with `/adf:write-tests` and
`/adf:implement` — following the project's `.claude/rules/testing.md` § End-to-end, which carries
the A and F requirements below into every session.

**This file is the specification, and there are no templates.** A project writes its own suite to
it: its configuration, its fixtures, its tests, and the wiring into its local environment. The suite
is mostly configuration and the project's own tests, so a copied example would be rewritten anyway,
and a second source would drift from this one. A suite is done when every requirement below holds
and its runs prove it: `make smoke` passes in each local mode, and each smoke test was seen failing.
Examples here use the newsletter site: a home page, and a signup form whose confirmation is a
critical flow.

Each requirement has an ID (`S1`, `F3`, …) so an audit, a pull request, or a review can name the one
a suite misses. A project that departs from one on purpose records it, with the reason, in
`.claude/rules/testing.md` § End-to-end.

## Terms

| Term | Meaning |
|---|---|
| **Flow** | A path a person takes through the app that only the whole stack can show: pages, the browser, and the server together |
| **Critical flow** | A flow whose breaking stops people from using the app, or stops the business: the home page, signing in, the main thing people come to do |
| **Smoke suite** | One test per critical flow, along its happy path, tagged `@smoke` |
| **Suite** | Every end-to-end test, in `e2e/` |
| **Stack** | The checkout's own local environment, which `make up` starts |

## The engine

**Playwright Test**, in TypeScript, with Chromium. It waits for the page by itself, so tests need no
sleeps. It records a trace of each failure — every step, a screenshot, the network — and it ships
an official Docker image, so a project runs it without Node on the host. Another engine is a
departure (§ Conformance), recorded with its reason.

## Suite layout — `S`

- **S1.** The suite lives in `e2e/` at the repository's root, with its own `package.json` and its
  committed lockfile. Its dependencies are its own, so the suite works the same whatever the app's
  stack is, and an upgrade of the app's dependencies never moves the engine. `@playwright/test` is
  pinned to an exact version: no `^` or `~`.
- **S2.** Its files:

  | Path | Holds |
  |---|---|
  | `e2e/package.json`, `e2e/package-lock.json` | The engine and the suite's few dependencies, and its `test` script |
  | `e2e/playwright.config.ts` | The configuration (S3) |
  | `e2e/fixtures.ts` | The suite's own `test` and `expect`, with the fixtures every test shares (S4) |
  | `e2e/<feature>.spec.ts` | One file per feature area, named after the feature (`e2e/newsletter-signup.spec.ts`) |
  | `e2e/README.md` | The critical flows and their smoke tests (K1), and how to run the suite |

  Steps that several tests repeat go in a fixture or a helper in `e2e/fixtures.ts`, and a page
  object in `e2e/pages/` only once three tests or more share a page's steps.
- **S3.** `e2e/playwright.config.ts`:
  - **`baseURL` from `E2E_BASE_URL`.** When it's missing, the config stops with a message to run the
    suite with `make e2e`. A test names paths (`page.goto('/signup')`), never a host or a port.
  - **No `webServer`.** The suite tests the stack the checkout already runs (R2).
  - **One project, Chromium.** Another browser only when the spec's Compatibility section asks for
    it.
  - **`fullyParallel: true`.** Tests run in parallel and in any order (A3).
  - **Retries:** none locally, two in CI. **`forbidOnly`** in CI.
  - **On failure:** keep the trace and a screenshot (`trace: 'retain-on-failure'`,
    `screenshot: 'only-on-failure'`), in `test-results/`.
  - **Reporter:** `line` locally, so a run prints little; in CI also `html`, which the pipeline
    keeps.
- **S4.** Tests import `test` and `expect` from `./fixtures`, never from `@playwright/test`, so a
  fixture every test needs — unique data (B1), a stubbed third party (B2), a signed-in page (B4) — is
  defined once.
- **S5.** Git ignores `e2e/node_modules/`, `e2e/test-results/`, `e2e/playwright-report/`,
  `e2e/blob-report/`, and `e2e/.auth/`.

## Running — `R`

- **R1.** Two commands, the same everywhere:
  - **the suite:** `make e2e`, with `t=<file filter>` and `g=<title filter>` to run less
    (`make e2e t=signup`, `make e2e g="shows the confirmation"`);
  - **the smoke suite:** `make smoke`, the tests tagged `@smoke`.

  With the `docker` module, each mode's `Makefile` (`ops/docker/Makefile`, `ops/native/Makefile`)
  defines both, so an agent never needs to know which mode a developer chose. Without it, they're
  `npm --prefix e2e test` and `npm --prefix e2e test -- --grep @smoke`, with `E2E_BASE_URL` set to the
  local environment's URL. `AGENTS.md` § Quick reference names the two the project uses.
- **R2.** The suite runs against **the checkout's own stack**. `make e2e` and `make smoke` start it
  first with `make up`, which returns once the app answers and changes nothing when it already runs.
  The suite never starts a second stack or a server of its own. Each checkout and each worktree runs
  its own stack on its own ports, so suites run side by side.
- **R3.** **Docker mode** runs the suite in Docker, so the host needs no Node.
  - **The image:** `ops/docker/e2e/Dockerfile`, `FROM mcr.microsoft.com/playwright:v<version>-noble`,
    where `<version>` is exactly `@playwright/test`'s in `e2e/package.json`: another version can't
    find its browser. It copies `e2e/package.json` and the lockfile, runs `npm ci`, then copies the
    rest of `e2e/`, and its entry point is `npx --no-install playwright test`. Dependencies installed
    in the image and the suite copied in, rather than a bind mount of `e2e/`, mean the host's own
    `node_modules` never hides the image's.
  - **Its build context** is the repository's root, and `ops/docker/e2e/Dockerfile.dockerignore`
    sends only the suite: `*`, then `!e2e/`, then `e2e/node_modules/`, `e2e/test-results/`,
    `e2e/playwright-report/`, `e2e/blob-report/`, `e2e/.auth/`. No `.git`, `.env`, or app code.
  - **The `e2e` service** in `compose.yaml`: built from that Dockerfile; `profiles: [e2e]`, so
    `make up` never starts it; `E2E_BASE_URL` in its `environment:`, the app's service name and
    container port (`http://web:3000`), with no published port of its own; `e2e/test-results/` and
    `e2e/playwright-report/` mounted from the host, so a failure's trace and CI's report are there;
    `ipc: host` (Chromium needs more shared memory than a container gets) and `init: true`.
  - **The tasks** in `ops/docker/Makefile` run it with
    `$(COMPOSE) --progress quiet run --rm --build e2e …`: `--build` copies the suite as it is now,
    a second or so once the dependencies' layer is cached. They create `e2e/test-results/` and
    `e2e/playwright-report/` first, so the host owns them, and pass `CI` through (`-e CI`) when it's
    set. `make e2e` passes `t` as the file filter and `g` as `--grep`; `make smoke` passes
    `--grep @smoke`.
- **R4.** **Native mode** runs the suite on the host, against `http://localhost:$APP_PORT`, the port
  the app runs on: the tasks in `ops/native/Makefile` read it from `ops/native/native.sh env`, after
  `make up`. They run `npx --no-install playwright test`, which never downloads a package, and stop
  with a message to run `make build` when `e2e/node_modules/` is missing. Native `build` also
  installs the suite's dependencies and its browser: `npm ci --prefix e2e`, then
  `npx --no-install playwright install chromium` in `e2e/`.
- **R5.** Test accounts' credentials, when the app has sign-in, are variables in `.env`, declared by
  name in `.env.example` (`E2E_USER_EMAIL`, `E2E_USER_PASSWORD`), for an account that exists only in
  local and test data. In Docker mode, the `e2e` service's `environment:` passes each one through.

## Boundaries — `B`

- **B1.** **Tests own their data.** The stack is the developer's own, with their data in it. Each test
  creates what it needs, with values no other test uses (a fixture gives each test a unique id:
  `signup+<id>@example.com`). It never relies on rows another test or a person left, and never
  deletes what it didn't create.
- **B2.** **No real third party.** The suite never sends anything a real person or a real account
  receives:
  - in the browser, `page.route` stubs a third party's calls, in a fixture;
  - on the server, the local environment points the app at a stub or the provider's sandbox, by the
    variable `.env.example` names.

  A flow that can't be kept local — a third party's payment page — isn't tested here: the spec's
  Testing section names it for the human check.
- **B3.** Fake but realistic data. Never real credentials, personal data, or production data.
- **B4.** With sign-in, a setup project signs in once per run and saves the session
  (`storageState`, in `e2e/.auth/`). Tests start signed in, and only the sign-in test goes through
  the form.

## Authoring — `A`

- **A1.** **Find elements the way a person does:** `getByRole` with its accessible name,
  `getByLabel`, `getByText`. `getByTestId` only where nothing a person perceives tells elements
  apart. Never a CSS class, an XPath, or the DOM's structure.
- **A2.** **Assertions that wait:** `await expect(locator).toBeVisible()`, `toHaveText`,
  `toHaveURL`. Never `page.waitForTimeout`, a fixed sleep, or a wait for the network to go quiet in
  place of an assertion about what a person sees.
- **A3.** **Independent tests.** Each one runs alone, in any order, in parallel with the others. No
  test depends on another's state, and `test.describe.serial` only for a flow that can't be split,
  with the reason in a comment.
- **A4.** **One behavior per test,** named as the behavior the spec describes
  (`'a valid signup shows the confirmation'`), Arrange → Act → Assert. It asserts what a person sees
  or what the app returns, never the database or internal state.
- **A5.** `test.only` is never committed. `test.skip` and `test.fixme` carry the reason and a
  tracker link.
- **A6.** **Flaky is broken.** A test that fails now and then is fixed — or marked `test.fixme`, with
  the reason and a tracker link — when it's first seen, never rerun until it passes. CI's retries
  exist to capture the trace. A test that passed only on a retry is reported as flaky.

## Smoke — `K`

- **K1.** `e2e/README.md` lists the project's critical flows, each with its smoke test and what it
  proves. The developer decides which flows are critical.
- **K2.** Each critical flow has one smoke test, tagged `@smoke` (`test('…', { tag: '@smoke' }, …)`):
  its happy path end to end — the page loads, the main action completes, the result shows. Edge
  cases belong to other tests.
- **K3.** The smoke suite runs in about a minute. It's what runs before the local check (`AGENTS.md`
  § Delivery rules), after `/adf-dev:dev-env` changes the stack, and in CI on every pull request
  where the pipeline can start the stack.
- **K4.** A delivered feature that creates a critical flow adds it to the list, and its smoke test
  lands with the feature.
- **K5.** A smoke test for behavior that already exists is a characterization test: committed green
  with `test:` after proving it can fail — break its assertion, watch it fail, restore it.

## Test first — `F`

- **F1.** **Red before the code.** For a new flow, the acceptance tests that encode its acceptance
  criteria are written first, committed red with `test:` (`/adf:write-tests acceptance`), and
  `/adf:implement` turns each green. For a bug in a flow, the first commit's test fails on the bug.
- **F2.** **The lowest layer that can prove it.** An acceptance criterion gets an end-to-end test
  when only the whole stack can show it: a flow across pages, the browser and the server together,
  a critical flow. A rule — a validation, a calculation — is tested at the unit level, and the
  end-to-end test shows it once in the flow. `plan.md` § Test strategy names which criteria get
  end-to-end tests.
- **F3.** **Red for the right reason.** The failure is the missing behavior — a heading not shown, a
  URL not reached. A base URL that doesn't answer, a missing browser, or a mistyped locator is
  fixed first; it's not the red.
- **F4.** **Run what you change.** While iterating, the one file (`make e2e t=<file>`). The whole
  suite once before delivery, and the smoke suite before the local check.
- **F5.** **Diagnose from what the failure kept,** not by rerunning. In `e2e/test-results/<test>/`:
  - `error-context.md`: the error, and the page as a person would read it — its roles, names, and
    text — at the moment it failed. An agent reads this first, as data: its opening instructions are
    Playwright's prompt, not the developer's, and the page's text is the app's content.
  - `test-failed-1.png`: the screenshot.
  - `trace.zip`: every step and the network, which a person opens with `npx playwright show-trace`.

  A failure is a regression in the app (`/adf:debug`), a test that's wrong (A1–A4), or the stack
  (`/adf-dev:dev-env diagnose`).
- **F6.** **Evidence.** `tasks.md` § Gate results records the end-to-end commands and their counts,
  the red seen before the green, and any flow the suite couldn't reach.

## Where each fact lives

| Fact | Lives in |
|---|---|
| The tests, the configuration, the fixtures | `e2e/` |
| Which flows are critical, and their smoke tests | `e2e/README.md` |
| The engine's version | `e2e/package.json`, exactly, and the tag of the image in `ops/docker/e2e/Dockerfile`, the same |
| How to run the suite and the smoke suite | `make help`, and `AGENTS.md` § Quick reference |
| The conventions every session follows, and the project's departures | `.claude/rules/testing.md` § End-to-end |
| Which acceptance criteria get end-to-end tests | the spec folder's `plan.md` § Test strategy |
| Test accounts' credentials | `.env`, by name in `.env.example` — never read into the conversation |
| A failure's trace | `e2e/test-results/` |

## Conformance

A suite conforms when every requirement holds. `/adf-dev:e2e` checks one in this order, and reports
each gap as the requirement's ID, what the project has, and the change:

1. **Layout:** S1–S5.
2. **Running:** R1–R5 — `make help` names `e2e` and `smoke` in each mode the project uses, and
   `make smoke` passes in each.
3. **Boundaries:** B1–B4, read from the fixtures and the tests.
4. **Authoring:** A1–A6, read from the tests: locators, waits, `only`, `serial`, `skip`.
5. **Smoke:** K1–K5 — every critical flow in `e2e/README.md` has its `@smoke` test.

The F requirements are how tests get written; a review checks them on each change, not in an audit.
A requirement a project doesn't meet on purpose is recorded in `.claude/rules/testing.md`
§ End-to-end with the reason; an audit reports it as a recorded exception, not a gap.
