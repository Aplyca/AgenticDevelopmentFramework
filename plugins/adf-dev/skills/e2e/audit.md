# Audit — bring a suite to the specification

`/adf-dev:e2e` reads this for the audit mode (step 4), with
`<this skill's base directory>/SPECIFICATION.md`: a suite that doesn't meet the specification.

1. **Check the suite in the order § Conformance gives,** and show the gaps in one table: the
   requirement's ID, what the project has, the change. A departure `.claude/rules/testing.md`
   § End-to-end records with its reason is an exception, not a gap. The usual ones:
   - tests mixed into the app's own folders, or the engine in the app's `package.json` with a `^`;
   - a `webServer` that starts a second app, or a hard-coded host and port;
   - CSS or XPath locators, `waitForTimeout`, `test.only`, a `serial` suite with no reason;
   - tests that read rows a seed or another test left, or that call a real third party;
   - no `@smoke` tag, or a critical flow without its smoke test;
   - retries on locally.
2. **Another engine** — Cypress, WebdriverIO, Selenium — is either a recorded departure or a
   migration. Propose the migration as its own careful-lane change. Never rewrite a suite unasked.
3. **Propose the changes** through `/adf:triage`, and change nothing before the developer approves.
