# Module: gitlab

GitLab-hosted repositories, on GitLab.com or a self-managed instance — the counterpart of the
`github` module. Puts the framework's traceability and gates where reviewers and CI see them
([decision 0075](../../docs/decisions/0075-the-gitlab-module.md)).

## What it adds

| File | Purpose |
|---|---|
| `.gitlab/merge_request_templates/Default.md` | The merge request description: traceability (spec folder + tracker task), what changed and why, how to review and test — the review instructions — **verified / not verified**, and quality and constitution checklists — unchecked boxes are explained, never deleted. The same sections and `adf:` markers as the `github` module's pull request template, which `/adf:open-pr` fills |
| `.gitlab/issue_templates/Default.md` | Every new issue's starting text: issues are a queue for engineering-originated work, and business requirements go to the tracker — GitLab has no contact links, so the redirect lives here |
| `.gitlab/issue_templates/Bug.md` | A bug template with the sections that matter (reproduction, expected vs actual, environment, severity), a PII warning, and `/label ~bug` |
| `.gitlab-ci.yml` | The project's pipeline: merge request pipelines while a merge request is open (`workflow:`), the branch model's variables, and the include. Yours to extend |
| `.gitlab/ci/adf.yml` | The merge request gates, replaced on each upgrade: `secret-scan` scans only the commits a merge request adds, with the open-source gitleaks CLI — new secrets fail the job without failing on old history — and `branch-policy` fails a merge request that targets the wrong branch, saying in its log how to fix it |
| `.gitleaks.toml` | Extends the default gitleaks rules; allowlists env *templates* (placeholders only) |

GitLab reads the templates from the default branch, so they apply once the adoption's merge request
merges. A `Default.md` is used on every tier; a default set in the project's settings (Premium) wins
over it.

## Install

`cp -R modules/gitlab/files/. <repo>/`, never overwriting. **With a `.gitlab-ci.yml` of your own,**
merge the module's three blocks into it:

- **`include:`** the local `.gitlab/ci/adf.yml`.
- **`variables:`** the `ADF_` ones (step 4 below).
- **`workflow:`** — unless yours already chooses between branch and merge request pipelines. Without
  it, a push to a branch with an open merge request runs two pipelines: the gates in a merge request
  pipeline, your jobs in a branch pipeline the merge request doesn't wait for. Jobs with `only:` or
  `except:` keep their own pipelines; give the ones that should gate a merge request a
  `$CI_PIPELINE_SOURCE == "merge_request_event"` rule, or move them to `rules:`.

The jobs run in the `test` stage. If your `stages:` has none, set each job's stage in
`.gitlab-ci.yml` (`secret-scan: { stage: verify }`): the main file's keys win over the include's.

## Customize

1. **Merge request template** — make the quality checklist list your real commands, and the
   constitution checklist mirror your `docs/CONSTITUTION.md` (one box per principle).
2. **`issue_templates/Default.md`** — set the link to your tracker's requirement intake. If GitLab
   issues are your tracker (`docs/TRACKER-INTEGRATION.md` § Issues as the tracker), say there which
   labels a requirement takes instead.
3. **`Bug.md`** — adjust the environments to your app, and create the `bug` label once (Manage →
   Labels; *Generate a default set of labels* includes it): `/label` applies only labels that exist.
4. **The branch model** — in `.gitlab-ci.yml`'s `variables:` (or the project's CI/CD variables, which
   win over the file), set `ADF_GUARDED_BASE` and either `ADF_ALLOWED_HEADS` (integration-branch
   model: only `staging` and `hotfix/*` may target `main`) or `ADF_FORBIDDEN_HEADS` (trunk model: the
   integration branch `dev` must never target `main`). Leave both empty if neither applies: the job
   then passes every merge request.
5. **Quality gates** — add your stack's lint, typecheck, and unit-test jobs to `.gitlab-ci.yml` (this
   module stays stack-agnostic), and a dependency audit (`npm audit`, `pip-audit`, …) that reports
   without blocking until the existing backlog is triaged (`allow_failure: true`). Keep layers that
   need services (integration, end-to-end) on demand (`when: manual`). Don't give a gating job a
   `changes:` rule: a required check that never runs is not a gate.

The secret scan runs in the `zricethezav/gitleaks` image, and the branch policy in `alpine`: both
need a runner that runs Docker images — GitLab.com's shared runners do. A shell runner ignores
`image:`, and needs `gitleaks` on its path.

## Optional: a stable preview address per merge request

The `github` module's [§ Optional: a stable preview address per pull
request](../github/MODULE.md#optional-a-stable-preview-address-per-pull-request) holds on GitLab
too, with a merge request's review app: people get a stable alias, automation the deploy's own
address. Set the alias in the deploy job, and remove it from the review app's `on_stop` job, which
GitLab runs when the merge request merges or closes. A review app whose environment URL already
names the merge request (`review/$CI_MERGE_REQUEST_IID`) has a stable address already: write it
down where people and agents find it — `AGENTS.md` § Quick reference's *Preview* line, and
`docs/TRACKER-INTEGRATION.md`.

## Make it a gate

Jobs only block merges once the project requires them: **Settings → Merge requests → Merge checks →
Pipelines must succeed** (every tier) makes the merge request pipeline, and so both gates, a
condition of merging. Protect the permanent branches (**Settings → Repository → Protected
branches**) so nobody pushes to them directly. Until then the gates are advisory — say so honestly in
`CONTRIBUTING.md` § What's enforced. Requiring approvals and passing pipelines is a maintainer
decision; record it as a PDR.
