# Test feature suites

The features and modules this project's tests are grouped by. A test lives in its feature suite's
folder, so a path runs one suite at any tier (`.claude/rules/testing.md` § Tiers and feature suites).
Pick a suite from this list; add a new one here first.

<!-- CUSTOMIZE: one row per feature or module. Names are kebab-case feature words. With the vitest
     module, `/vitest set up` proposes the rows from your folders and delivered features. -->

| Suite | Unit and integration folders | End-to-end folder | Covers |
|---|---|---|---|
| `[billing]` | `[tests/billing/]` | `[e2e/tests/billing/]` | `[Plans, invoices, payment methods]` |
