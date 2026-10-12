# End-to-end tests

Playwright tests of this project's flows, run against this checkout's own stack. The conventions
every test follows are in `.claude/rules/testing.md` § End-to-end.

## Run

| Command | Runs |
|---|---|
| `make smoke` | The smoke suite: one test per critical flow, in about a minute |
| `make e2e` | Every test. `t=<file filter>` and `g=<title filter>` run less: `make e2e t=signup` |

Both start the stack first (`make up`). A failure keeps its trace and a screenshot in
`test-results/`. Open the trace with `npx playwright show-trace <trace.zip>` from this folder, or
drop it on [trace.playwright.dev](https://trace.playwright.dev), which reads it in the browser.

## Critical flows

The flows whose breaking stops people from using the app. Each has one smoke test, tagged `@smoke`.
<!-- CUSTOMIZE: the team decides which flows are critical; a feature that creates one adds it here -->

| Flow | Smoke test | Proves |
|---|---|---|
| The home page | `home.spec.ts` · "the home page shows its heading" | The app answers and renders |
| Newsletter signup | `newsletter-signup.spec.ts` · "a valid signup replaces the form with the success message" | A reader can subscribe |
