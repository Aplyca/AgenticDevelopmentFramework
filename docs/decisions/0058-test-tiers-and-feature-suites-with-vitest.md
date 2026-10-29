# 0058: Tests run by tier and by feature suite; Vitest is the preferred engine for unit and integration tests

- **Status:** accepted
- **Date:** 2026-10-28

## Context

The `e2e` module (decision 0037) gave end-to-end tests one engine, Playwright, and one tier, the
`@smoke` suite. Unit and integration tests had no engine, no layout, and no way to run less than
everything. Two needs came up together:
- **Run less, in steps.** A developer iterating wants the fastest proof; a pull request wants the
  critical flows; a release wants everything.
- **Run one part.** A change to billing should run billing's tests, at any depth, without a command
  per project.

## Decision

- **Vitest is the preferred engine for unit and integration tests** in a JavaScript or TypeScript
  app, carried by a new `unit` module and its skill, `/adf-dev:unit`, written like `e2e`: a
  specification, no templates, set up and audited by the skill (decision 0037's pattern). A project
  on another stack keeps its own runner and follows the same tiers and feature suites.
- **Three cumulative tiers, the same in Vitest and Playwright:**
  - `@smoke` — one fast test per critical behavior or flow; seconds for unit tests, about a minute
    end to end. Runs while iterating and before the local check.
  - `@critical` — what must not break: the acceptance criteria of delivered features and every
    smoke test. Runs on every pull request in CI. A critical run includes the smoke tests.
  - **Regression** — every test, tagged or not. Runs before delivery of a full-lane change, on a
    schedule, and before a release.
  A test carries only its **lowest** tier; the commands add the tiers below it. Untagged tests are
  regression only. A bug fix's regression test starts untagged, and is promoted to `@critical` when
  the bug could cost users the flow.
- **Feature suites are folders, plus a tag when a flow crosses them.** A test lives in the folder of the
  feature it verifies (`tests/billing/`, `e2e/tests/billing/`), so a path runs one feature suite. An
  end-to-end flow that spans feature suites carries `@suite:<name>` for each. The project lists its feature suites in
  `docs/TEST-SUITES.md`, so an agent picks one instead of inventing a name.
- **One tag form in both engines:** in the test or describe title (`'subscribes @smoke'`) for
  Vitest, which filters by name, and Playwright's `{ tag }` option, which puts the same text in the
  title. Names, not engine features, so the convention survives an engine upgrade.
- **The commands take `tier` and `feature suite`:** `make test tier=critical suite=billing` and
  `make e2e tier=smoke`. `make smoke` stays, as `make e2e tier=smoke`. Without the `docker`
  module the same scripts run as `npm test` and `npm --prefix e2e test`.
- **`.claude/rules/testing.md` gains § Tiers and feature suites,** so every session tags and places tests
  the same way, and the test-first rules, unchanged, apply at every tier.

## Consequences

- `e2e`'s specification gains the `@critical` tier, feature suites, and the `tier` and `feature suite` arguments;
  its K requirements stay. `make smoke` and `@smoke` keep working, so nothing breaks.
- A project that adopts `unit` gets permissions to run the suite without a prompt, and
  `/adf-dev:unit set up` writes the configuration, the scripts, and the feature suite list.
- Tags are a convention a test can omit: `/adf-dev:unit audit` reports a delivered feature
  with no `@critical` test.
