# Module: github

GitHub-hosted repositories. Puts the framework's traceability and gates where reviewers and CI see
them.

## What it adds

| File | Purpose |
|---|---|
| `.github/pull_request_template.md` | Traceability (spec folder + tracker task), what changed and why, how to verify, **verified / not verified**, and quality and constitution checklists — unchecked boxes are explained, never deleted |
| `.github/ISSUE_TEMPLATE/config.yml` | Issues are a queue for engineering-originated work; a contact link redirects business requirements to the tracker |
| `.github/ISSUE_TEMPLATE/bug-report.yml` | A bug form with the fields that matter (reproduction, expected vs actual, environment, severity) and a PII warning |
| `.github/workflows/secret-scan.yml` | Scans only the commits a pull request adds, with the open-source gitleaks binary — new secrets are blocked without failing on old history |
| `.github/workflows/branch-policy.yml` | Flags a pull request that targets the wrong base branch, and comments how to fix it |
| `.gitleaks.toml` | Extends the default gitleaks rules; allowlists env *templates* (placeholders only) |

## Customize

1. **Pull request template** — make the quality checklist list your real commands, and the
   constitution checklist mirror your `docs/CONSTITUTION.md` (one box per principle).
2. **`config.yml`** — set the contact link to your tracker's requirement intake.
3. **`bug-report.yml`** — adjust the environments and affected areas to your app.
4. **`branch-policy.yml`** — set `GUARDED_BASE` and either `ALLOWED_HEADS` (integration-branch model:
   only `staging` and `hotfix/*` may target `main`) or `FORBIDDEN_HEADS` (trunk model: the
   integration branch `dev` must never target `main`). Delete the workflow if neither applies.
5. **Quality gates** — add your stack's lint, typecheck, and unit-test job (this module stays
   stack-agnostic), and a dependency audit (`npm audit`, `pip-audit`, …) that reports without
   blocking until the existing backlog is triaged. Keep layers that need services (integration,
   end-to-end) in a separate, on-demand workflow. Don't put a `paths:` filter on a workflow you'll
   require: a required check that never runs is not a gate.

## Optional: a stable preview address per pull request

A host that deploys a preview on every push gives each deploy an address of its own, and some — a
deploy from a CLI — give a new one on every push. A link sent to a person yesterday then shows
yesterday's build. A stable address per pull request fixes that, for the people who follow the
link; automation keeps the deploy's own address. Any host that can point a name at a deploy can do
this, from the workflow that deploys:

- **People get the stable alias:** the developer's check, reviewers, and stakeholders. It always shows
  the pull request's latest deploy.
- **Automation gets the deploy's own, immutable address:** a smoke check or an end-to-end job in CI,
  a link checker. A later push can't change the build under a running test. The agent's end-to-end
  suite isn't one of them: it runs only on a local stack (`/adf-dev:e2e`).
- **Set the alias after each deploy,** from the deploy's address. On Vercel, for example:

  ```bash
  vercel alias set "$DEPLOY_URL" <name>-pr-<number>.vercel.app
  ```

- **Send `X-Robots-Tag: noindex` on aliased previews yourself.** The host's protection for its own
  preview addresses may not reach an alias.
- **Remove the alias when the pull request closes,** from a workflow that runs then
  (`on: pull_request: types: [closed]`).
  Decide what a pull request closed without merging gets — usually the same removal, so nobody
  tests a build that will never ship — and write it down.
- **An alias on a shared domain is unique across all of the host's customers** (`*.vercel.app`):
  prefix it with the project's name, and handle the name being taken.
- **Write the address down** where people and agents find it: `AGENTS.md` § Quick reference's
  *Preview* line, and the stable preview address in `docs/TRACKER-INTEGRATION.md`, which
  `/stakeholder-update` links in the requester's update.

## Make it a gate

Checks only block merges once a repository ruleset (or branch protection) requires them. Until you
do that, they are advisory — say so honestly in `CONTRIBUTING.md` § What's enforced. Requiring
approvals and passing checks is a repository-admin decision; record it as a PDR.
