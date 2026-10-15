# Module: e2e

For projects with flows a person uses in a browser. Adds `/e2e`, which sets up end-to-end tests to
the [end-to-end testing specification](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/plugins/adf-dev/skills/e2e/SPECIFICATION.md)
it carries — or audits an existing suite against it — writes one smoke test per critical flow, and
diagnoses a failing or flaky test from what it kept. A change's own end-to-end tests are written test
first, like every test, with `/write-tests` and `/implement`, following the project's
`.claude/rules/testing.md` § End-to-end
([decision 0037](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0037-end-to-end-tests.md)).

## The conventions

The [specification](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/plugins/adf-dev/skills/e2e/SPECIFICATION.md)
is the source, each requirement with an ID that an audit names. It ships no templates: the project
writes its own suite to it, and its runs prove it. In short:

- **Playwright Test, in TypeScript, with Chromium,** in its own `e2e/` folder with its own
  `package.json`, so the suite is the same whatever the app's stack is. The engine is pinned exactly.
- **Two commands:** `make e2e` (all, or `t=<file>`, `g=<title>`) and `make smoke` (the tests tagged
  `@smoke`). Both start the checkout's own stack first and test it: no second stack, no shared
  environment.
- **In each local mode:** with the `docker` module, Docker mode runs the suite in Playwright's official
  image, so the host needs no Node, and native mode runs it on the host against the app's port.
  Without the module, `npm --prefix e2e test` is the command, with `-- --grep @smoke` for the smoke
  suite.
- **One smoke test per critical flow,** which the team names in `e2e/README.md`, run before the local
  check and in CI.
- **Tests own their data and never reach a real third party.** They find elements by role and name,
  and wait with assertions, never sleeps. Flaky is broken.
- **Test first:** an acceptance criterion gets an end-to-end test only when the whole stack is needed
  to show it, and the test is seen failing before the code exists.

## What it adds

| File | Purpose |
|---|---|
| `.claude/settings.json` (merged) | `permissions.allow` for running the suite: `make e2e`, `make smoke`, and `npm --prefix e2e test`, so a test-first loop reruns a test without a prompt |
| `.claude/skills/e2e/` | **Committed install only:** the skill and its `SPECIFICATION.md`. A packaged project gets `/adf-dev:e2e` from the development plugin, `adf-dev`, which `module.json` names ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)) |

The module copies no files into the project. `/e2e set up` writes the suite to the specification —
`e2e/` (the configuration, the fixtures, a README of the critical flows, and the smoke tests) and,
with the `docker` module, the `e2e` service in `compose.yaml`, its image in `ops/docker/e2e/`, and
the `e2e` and `smoke` tasks in each mode's `Makefile` — and runs it until `make smoke` passes in each
mode. The skeleton's `.claude/rules/testing.md` § End-to-end is the project's
copy of how a test is written.

## Install

`/adopt` and `/upgrade` install it when you choose the module. By hand:

- **Committed install:** `scripts/build-committed.py /path/to/your-repo --modules e2e`, which writes
  `/e2e` and its specification from the `adf-dev` plugin, then `modules/e2e/install.sh /path/to/your-repo`.
- **Packaged install:** run `modules/e2e/install.sh /path/to/your-repo`, and turn the plugin on in
  `.claude/settings.json` beside `adf` — `"adf-dev@aplyca": true` in `enabledPlugins`, and
  `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`.

`install.sh` merges into `.claude/settings.json`: it keeps your rules and their order, adds only
what's missing, and is safe to run again.

Then add `e2e` to the `modules:` list in the stamp on `AGENTS.md`'s first line: `/e2e` stops in a
project whose stamp doesn't name it.

## Customize

Run `/e2e set up` (packaged: `/adf-dev:e2e set up`) once the module is in — in a worktree, with the
`docker` module's stack set up first when the project has it (`/dev-env set up`). It proposes the
critical flows for you to choose, writes the suite and its smoke tests as a careful-lane change you
approve, and fills these from what it verifies, for you to review:

1. **`e2e/README.md`** — the critical flows, each with its smoke test and what it proves.
2. **`.claude/rules/testing.md` § End-to-end** — the project's commands, and any departure from the
   specification with its reason.
3. **`AGENTS.md` § Quick reference** — `make smoke` and `make e2e`.
4. **`docs/getting-started/DEV-SETUP.md`** — how to run the suite, and what native mode needs on the
   host.

CI that can start the stack runs `make smoke` on every pull request: `/e2e set up` proposes the job,
and you add it. The framework ships no pipeline file.

## Prerequisites

- **With the `docker` module:** Docker Compose v2. The suite runs in Playwright's image, about 2 GB
  pulled once.
- **Native mode, or without the `docker` module:** Node.js 20 or later on the host, and Chromium,
  which `make build` (or `npx playwright install chromium` in `e2e/`) downloads to Playwright's cache.
