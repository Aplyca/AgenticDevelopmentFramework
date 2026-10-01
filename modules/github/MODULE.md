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

## Make it a gate

Checks only block merges once a repository ruleset (or branch protection) requires them. Until you
do that, they are advisory — say so honestly in `CONTRIBUTING.md` § What's enforced. Requiring
approvals and passing checks is a repository-admin decision; record it as a PDR.
