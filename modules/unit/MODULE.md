# Module: unit

For JavaScript and TypeScript apps. Adds `/unit`, which sets up unit and integration tests with
Vitest to the [specification](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/plugins/adf-dev/skills/unit/SPECIFICATION.md)
it carries — or audits an existing suite against it — so tests run **by tier** and **by feature suite**
([decision 0058](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0058-test-tiers-and-feature-suites-with-vitest.md)).
A change's own tests are written test first, like every test, with `/write-tests` and
`/implement`, following the project's `.claude/rules/testing.md` § Tiers and feature suites.

## Tiers and feature suites

Three cumulative **tiers**, the same in Vitest and in the `e2e` module's Playwright suite:

| Tier | Holds | Runs |
|---|---|---|
| `@smoke` | One fast test per critical behavior or flow | While iterating; before the local check |
| `@critical` | The acceptance criteria of delivered features, and every smoke test | Every pull request, in CI |
| Regression | Every test | Before delivering a full-lane change; nightly; before a release |

A test carries only its lowest tier, in its title; the commands add the tiers below it. An **feature suite**
is the feature a test verifies — its folder, listed in `docs/TEST-SUITES.md`.

```
npm run test:smoke                         # seconds
npm run test:critical -- tests/billing     # one feature suite, critical tier
npm test -- --project integration          # the integration layer, everything
make test tier=critical suite=billing       # with the docker module, in the configured mode
```

## What it adds

| File | Purpose |
|---|---|
| `.claude/settings.json` (merged) | `permissions.allow` for running the tiers: `npm test`, `npm run test:smoke`, `npm run test:critical`, `npx --no-install vitest run`, so a test-first loop reruns a test without a prompt |
| `.claude/skills/unit/` | **Committed install only:** the skill and its `SPECIFICATION.md`. A packaged project gets `/adf-dev:unit` from the development plugin, `adf-dev`, which `module.json` names ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)) |

The module copies no files into the project. `/unit set up` writes Vitest's pinned dependency,
`vitest.config.ts`, the scripts, and `docs/TEST-SUITES.md`, tags the tests that exist, and runs every
tier.

## Install

`/adopt` and `/upgrade` install it when you choose the module. By hand:

- **Committed install:** `scripts/build-committed.py /path/to/your-repo --modules unit`, then
  `modules/unit/install.sh /path/to/your-repo`.
- **Packaged install:** run `modules/unit/install.sh /path/to/your-repo`, and turn the plugin on in
  `.claude/settings.json` beside `adf` — `"adf-dev@aplyca": true` in `enabledPlugins`, and
  `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`.

Then add `unit` to the `modules:` list in the stamp on `AGENTS.md`'s first line: `/unit` stops in
a project whose stamp doesn't name it.

## Customize

Run `/unit set up` (packaged: `/adf-dev:unit set up`) in a worktree. It proposes the feature suites for
you to choose and fills these, for you to review:

1. **`docs/TEST-SUITES.md`** — each feature suite, its folders, what it covers.
2. **`.claude/rules/testing.md` § Tiers and feature suites** — the project's commands, and any departure from
   the specification with its reason.
3. **`AGENTS.md` § Quick reference** — the tier and feature suite commands.

CI runs `test:critical` on every pull request and `test:regression` nightly; `/unit set up`
proposes the jobs, and you add them. The framework ships no pipeline file.

## Prerequisites

Node.js 20 or later, and a JavaScript or TypeScript app. For another stack, keep your runner and
follow the tiers and feature suites in `.claude/rules/testing.md`.
