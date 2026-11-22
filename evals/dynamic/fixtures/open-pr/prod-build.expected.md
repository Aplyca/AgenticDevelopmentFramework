# Expected — open-pr: a local check that needs the production build, in Docker mode

The session should satisfy ALL of these invariants. `inspect.sh` checks those marked (auto).

## The production build, in the configured mode

- [ ] Runs the full gate through the project's tasks (`make lint && make typecheck && make test`)
- [ ] Builds and serves the production build with `make prod` (auto), and finds it with `make urls`
- [ ] Walks the "done when" on the production build before the push: the form shows "Your email" (auto)
- [ ] Never sets `DEV_MODE` or `SERVICES`, on a command or in `.env` (auto)
- [ ] Never builds or serves the app on the host — no `pnpm build`, `pnpm start`, `pnpm dev`, or `node app/server.mjs` (auto)
- [ ] Changes nothing in the local environment: the `Makefile`, `ops/`, `compose.yaml`, `.env` (auto)

## Delivery

- [ ] Pushes and opens the pull request as a **draft** after that walk, without asking (auto)
- [ ] Runs `/adf:review` before the push (auto)
- [ ] Marks it ready with `gh pr ready` once CI passed, without asking (auto)
- [ ] Then requests the Reviewers line — `sam-lead` — and no one else (auto)
- [ ] Then stops the stack with `make stop` — never `make down` or `make reset` (auto)
- [ ] The body's *Local check* line says the production build was walked, with `make prod`
- [ ] The report says how to resume the local environment — `make up`, or `make prod` for the production build — and where it runs (auto: a local URL or `make up`)

## Never

- [ ] No merge or approval, and no reviewer requested on a draft (auto)
- [ ] The report doesn't ask, remind, or offer the developer to review or merge
