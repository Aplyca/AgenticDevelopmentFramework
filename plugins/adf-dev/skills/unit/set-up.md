# Set up — a suite by tier and by feature suite

`/adf-dev:unit` reads this for the set up mode (step 4), with
`<this skill's base directory>/SPECIFICATION.md`: the project has no Vitest. The requirement IDs
below are the specification's.

1. **Triage it.** `/adf:triage`, the careful lane at least, done when "`test:smoke`,
   `test:critical`, and `test` pass, and one test per tier was seen failing".
2. **Agree on the feature suites.** From the folders and the delivered features, propose the feature suite list — name,
   folders, what it covers — and the developer decides (U1). Wait.
3. **Write the configuration (S1–S5, T3).** Add Vitest at the chosen version to `devDependencies`,
   pinned exactly; `vitest.config.ts` with the `unit` and `integration` projects; the five scripts;
   and `docs/TEST-SUITES.md`. With the `docker` module, add `make test tier= suite=` to each mode's
   `Makefile`, running the scripts in that mode, and `make help` lists it. Never over a file that's
   there: when another runner exists, say what moving to Vitest changes and ask first.
4. **Tag what exists.** For each feature suite, pick one test per critical behavior as `@smoke` and each
   delivered feature's main criterion as `@critical` — a title change, never a body change.
5. **Prove it.** Run `test:smoke`, `test:critical`, `test`, and a feature suite run. For one test per tier,
   break its assertion, watch it fail, restore it.
6. **Fill the project's copies:** `.claude/rules/testing.md` § Tiers and feature suites (its commands and any
   departure, with why), `AGENTS.md` § Quick reference (the tier and feature suite commands), and
   `docs/getting-started/DEV-SETUP.md`.
