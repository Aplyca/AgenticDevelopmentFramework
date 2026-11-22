# Set up — a new end-to-end suite

`/adf-dev:e2e` reads this for the set up mode (step 4), with
`<this skill's base directory>/SPECIFICATION.md`: the project has no end-to-end suite. The
requirement IDs below are the specification's.

1. **Triage it.** A new suite adds a test folder, a Compose service, and make tasks: `/adf:triage`
   it, the careful lane at least, done when "`make smoke` passes in the configured mode, and each
   smoke test was seen failing".
2. **Agree on the critical flows.** From what `SKILL.md` step 3 read, propose three to seven flows whose
   breaking stops people from using the app — the home page, signing in, the main thing people come
   to do — each in one line, with your recommendation. The developer decides (K1). Wait.
3. **Write the suite (S1–S5, B1–B4).** In `e2e/`, never over a file that's there:
   - **`package.json`** with `@playwright/test` at the newest version released at least two weeks
     ago (`npm view @playwright/test time --json`), exactly. Check that Playwright's image has the
     same tag (`docker manifest inspect mcr.microsoft.com/playwright:v<version>-noble`).
   - **The lockfile:** `npm install --prefix e2e --no-audit --no-fund`. With the `docker` module
     in Docker mode, or without Node on the host, never on the host:
     `docker run --rm -v "$PWD/e2e:/suite" -w /suite node:<lts> npm install --no-audit --no-fund`.
   - **`playwright.config.ts`** to S3, and **`fixtures.ts`** to S4: a unique id per test (B1), a stub
     for each third party the browser calls (B2), and, with sign-in, the setup project and its
     `.env.example` variables (B4, R5).
   - **`.gitignore`:** the S5 entries.
4. **Wire the commands (R1–R4).**
   - **With the `docker` module:** the image, its `.dockerignore`, the `e2e` service, and the `e2e`
     and `smoke` tasks in `ops/docker/Makefile`, each as R3 states; the tasks in
     `ops/native/Makefile`, and the suite's install line in its `build`, as R4 states. Add both tasks
     to each file's `.PHONY` with a `##` description, so `make help` lists them. Write both files,
     whichever mode this checkout runs in: the other mode's tasks are read, not run (step 6).
   - **Without it:** `npm --prefix e2e test`, and `-- --grep @smoke` for the smoke suite, are the
     commands, with `E2E_BASE_URL` set to the local environment's URL.
5. **Write one smoke test per critical flow (K2),** as `SKILL.md` § Writing a smoke test says —
   each one proved able to fail (K5).
6. **Run it — this is what proves the suite** — in the mode this checkout is configured for, the
   one `make help` names, and only that one (`SKILL.md` § Safety):
   - `make smoke`, then `make e2e`: both pass, and the smoke suite takes about a minute (K3);
   - a missing `E2E_BASE_URL` (run Playwright in `e2e/` without it) stops with S3's message;
   - when that mode is Docker, a failure's `error-context.md` and trace appear in `e2e/test-results/`
     on the host, and an edited test is what runs next;
   - the other mode's tasks, with the `docker` module: read against R3 or R4, and listed as not run
     in the pull request's *Verified / not verified*.
7. **Write down what you verified** — docs go through triage too:
   - `e2e/README.md`: the critical flows, each with its smoke test and what it proves (K1);
   - `.claude/rules/testing.md` § End-to-end: the project's commands, and any departure from the
     specification with its reason;
   - `AGENTS.md` § Quick reference: `make smoke` and `make e2e`;
   - `docs/getting-started/DEV-SETUP.md`: how to run the suite, and in native mode what the host
     needs (Node, and the browser `make build` installs).

   CI that can start the stack runs `make e2e tier=critical` on every pull request (K3, K6): propose the job to the
   developer. The framework's CI files carry no test job.
8. **Commit** with `/adf:commit`, in two commits. First `chore:` for the suite's groundwork: the
   folder, the configuration, the service, and the tasks. Then `test:` for the smoke tests, green,
   with how each was seen failing in the body.
