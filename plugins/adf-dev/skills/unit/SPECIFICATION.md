# The unit and integration testing specification

What a project's unit and integration tests must look like, and how they're run by tier and by
feature suite, in a project with the `unit` module
([decision 0058](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0058-test-tiers-and-feature-suites-with-vitest.md)).
`/adf-dev:unit` sets up a suite that meets it and audits one against it. The tests for a change
are written the way every test is — test first, with `/adf:write-tests` and `/adf:implement` —
following the project's `.claude/rules/testing.md`, § Tiers and feature suites included.

**This file is the specification, and there are no templates.** A project writes its configuration
and its tests to it. A suite is done when every requirement holds and its runs prove it: `npm run
test:smoke`, `npm run test:critical`, and `npm test` pass, and one test per tier was seen failing.

Each requirement has an ID (`S1`, `T2`, …) so an audit or a review can name the one a suite misses.
A project that departs from one on purpose records it, with the reason, in
`.claude/rules/testing.md` § Tiers and feature suites.

## Terms

| Term | Meaning |
|---|---|
| **Unit test** | One module through its public interface, with only the system's boundary mocked |
| **Integration test** | Several of the app's own modules, or a module and a real local dependency (a test database), together; no browser |
| **Tier** | How soon a test must run: `@smoke`, `@critical`, or regression |
| **Feature suite** | The feature or module a test verifies; its folder |

## The engine

**Vitest**, in TypeScript, for a JavaScript or TypeScript app. A project on another stack keeps its
own runner and follows T and A below; the module doesn't apply, and a departure is recorded.

## Suite layout — `S`

- **S1.** Vitest is a dev dependency of the app's own `package.json`, pinned to an exact version
  (no `^` or `~`), with the lockfile committed. `vite` is its required peer, so it is a pinned dev
  dependency too, at a version Vitest's `peerDependencies` accepts: without it, Vitest stops at start-up
  with `Cannot find package 'vite'`. Its configuration is `vitest.config.ts`.
- **S2.** Two Vitest **projects** in that configuration: `unit` (`*.test.ts`, `*.test.tsx`) and
  `integration` (`*.int.test.ts`), so `--project integration` runs the slower layer alone.
- **S3.** Tests live in their feature suite's folder — `tests/<suite>/`, or beside the code in
  `src/<suite>/` when the project colocates — never in a folder named for the layer (`unit/`).
  One test file per module or behavior, named after it.
- **S4.** The test environment is `node` unless the feature suite renders components, where it's `jsdom` or
  `happy-dom` for that feature suite's files only. Coverage is a report (`@vitest/coverage-v8`), never a gate
  that decides done: a test is judged by what it asserts (`.claude/rules/testing.md`).
- **S5.** Integration tests own their data and use a dedicated test database or in-memory store,
  never the developer's own; no real third party (`.claude/rules/testing.md` § External service
  mocking).

## Tiers — `T`

- **T1.** Three cumulative tiers. `@smoke` ⊂ `@critical` ⊂ regression:

  | Tier | Holds | Runs |
  |---|---|---|
  | `@smoke` | One fast test per critical behavior; seconds in all | While iterating, before the local check |
  | `@critical` | The acceptance criteria of delivered features, and every smoke test | Every pull request, in CI |
  | Regression | Every test, tagged or not | Before delivering a full-lane change, nightly, before a release |

- **T2.** A test carries **only its lowest tier**, as `@smoke` or `@critical` in its title or its
  `describe`'s (`test('rejects an empty email @smoke', …)`). Tagging a `describe` tags its tests.
  An untagged test is regression only. Tags are in the title because Vitest filters by name (`-t`),
  which every version supports.
- **T3.** Scripts in `package.json`:
  - `test` — `vitest run`, the regression run;
  - `test:smoke` — `vitest run -t @smoke`;
  - `test:critical` — `vitest run -t "@smoke|@critical"`;
  - `test:regression` — `vitest run`, so a pipeline names the tier it means;
  - `test:watch` — `unit`, for a developer.

  With the `docker` module, `make test` takes `tier=<smoke|critical|regression>` and `suite=<name>`
  and runs these in the configured mode, so an agent never needs to know which one.
- **T4.** The smoke tier is seconds: a test that needs a network, a database, or a second of setup
  is `@critical` at most. If `test:smoke` outgrows about ten seconds, `/adf-dev:unit audit` names
  the slowest tests to demote.
- **T5.** A delivered feature adds at least one `@critical` test for its main acceptance criterion;
  a bug fix's regression test is untagged, and is promoted when the bug could cost users the flow.
- **T6.** A tier's test is never skipped to pass. A failing test is diagnosed; a flaky one is fixed
  or marked `skip` with the reason and a tracker link.

## Feature suites — `U`

- **U1.** The project's feature suites are listed in `docs/TEST-SUITES.md`: each feature suite's name (kebab-case,
  singular feature words), its folder or folders for each layer, and what it covers. An agent picks
  a feature suite from the list; a new feature suite is added there first.
- **U2.** A feature suite runs by path, so any tier and layer is reachable:
  - `npm test -- tests/billing` — the feature suite, regression;
  - `npm run test:critical -- tests/billing` — the feature suite's critical tests;
  - `npm test -- --project integration tests/billing` — one layer of one feature suite.
  With the `docker` module, `make test suite=billing tier=critical`, which resolves the feature suite's
  paths from `docs/TEST-SUITES.md`'s table (T3).
- **U3.** `vitest related <file> --run` (or `--changed`) runs the tests for what changed; an agent uses it
  while iterating on a change that crosses feature suites, then runs each affected feature suite once.
- **U4.** An end-to-end flow that spans feature suites is tagged `@suite:<name>` for each in `e2e/`
  (`/adf-dev:e2e`); unit and integration tests need no feature suite tag, since their folder is it.

## Test first — `F`

- **F1.** **Red before the code**, at every tier and in every lane
  (`.claude/rules/testing.md` § Red, then green).
- **F2.** **The lowest layer that proves it:** a rule is a unit test; modules that must agree, an
  integration test; the whole stack in a browser, an end-to-end test (`/adf-dev:e2e`, F2).
- **F3.** **Run what you change:** the test file while iterating, the feature suite when the file is green,
  `test:critical` before the local check, `test` once before delivery.
- **F4.** **Evidence:** `tasks.md` § Gate results records each tier run, its command and counts, and
  the red seen before the green.

## Where each fact lives

| Fact | Lives in |
|---|---|
| The tests, the configuration | `tests/`, `src/`, `vitest.config.ts` |
| The feature suites | `docs/TEST-SUITES.md` |
| The engine's version | `package.json`, exactly |
| How to run a tier or a feature suite | `AGENTS.md` § Quick reference, and `make help` |
| The conventions every session follows, and the project's departures | `.claude/rules/testing.md` § Tiers and feature suites |

## Conformance

`/adf-dev:unit` checks in this order, and reports each gap as the requirement's ID, what the
project has, and the change:

1. **Layout:** S1–S5.
2. **Tiers:** T1–T6 — the scripts exist, each tier's run passes, every smoke test is tagged and fast.
3. **Feature suites:** U1–U4 — every folder under the test roots is in `docs/TEST-SUITES.md`, and the reverse.

The F requirements are how tests get written; a review checks them on each change.
