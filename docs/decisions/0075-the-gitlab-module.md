# 0075: The gitlab module — GitHub's gates, in GitLab's own terms

- **Status:** accepted
- **Date:** 2026-11-12
- **Extends:** [0009](0009-optional-modules.md) — a module per Git host; [0074](0074-github-and-gitlab-alike.md)
  — it made the machinery work on GitLab and left the `github` module GitHub's own

## Context

- **After 0074, a GitLab project had the machinery and none of the committed harness.** The
  description template `/adf:open-pr` fills, the issue templates that redirect requirements to the
  tracker, the secret scan, and the base-branch policy were all in `.github/`, which GitLab doesn't
  read. `/adf:open-pr`'s `gitlab.md` already pointed at `.gitlab/merge_request_templates/Default.md`,
  a file nothing shipped.
- **GitLab's equivalents differ in shape, not only in path:**
  - Description templates are Markdown files in `.gitlab/merge_request_templates/` and
    `.gitlab/issue_templates/`, read from the default branch; one named `Default.md` is the default on
    every tier. There are no issue forms and no contact links.
  - CI is one `.gitlab-ci.yml` per project, where most projects already keep their jobs. A job runs in
    a merge request pipeline only with a rule for it, and a merge request's *Pipelines must succeed*
    reads its merge request pipeline, never a branch pipeline that runs beside it.
  - The CI job token can't write a merge request note, so a job can't comment as GitHub's
    branch-policy workflow does without a token the project would have to store.
  - GitLab's own secret detection runs on every tier, but acts on what it finds — merge request
    reports, approval policies — only on Ultimate.

## Decision

- **A `gitlab` module beside `github`,** the same harness: a merge request template, issue templates,
  a secret scan, a branch policy, and `.gitleaks.toml`. `/adf:adopt` and `/adf:upgrade` offer it when
  the repository is on GitLab.
- **The merge request template is the pull request template,** section for section and marker for
  marker, with GitLab's words: *merge request*, *review app*, and `Related to #N` for a requester's
  issue, as `gitlab.md` says. `Default.md`, so every new merge request starts from it. A static check
  keeps the two templates' sections and markers the same.
- **The redirect to the tracker lives in `issue_templates/Default.md`,** a comment every new issue
  starts with, since GitLab has no contact links. `Bug.md` carries the bug form's sections as
  Markdown, and `/label ~bug`.
- **The gates are one CI include the framework owns,** `.gitlab/ci/adf.yml`, overwritten on each
  upgrade: `secret-scan` and `branch-policy`, in the `test` stage, only in merge request pipelines.
  The project's `.gitlab-ci.yml` includes it and holds what the team sets — the branch model's
  `ADF_` variables — so an upgrade never merges the jobs. The module ships a `.gitlab-ci.yml` with
  the include, the variables, and GitLab's `workflow:` rules that run merge request pipelines while a
  merge request is open and branch pipelines otherwise; a project with its own merges the three blocks.
- **The secret scan is the gitleaks CLI,** as on GitHub, in its pinned image: it fails the job on a
  finding on every tier, and scans only the merge request's commits — its diff base to its source
  head, which a merged results pipeline names apart from the merge commit it builds.
- **The branch policy fails the job and explains in its log,** with the `glab` command that retargets
  the merge request. No comment: that would need a stored token with write access.

## Consequences

- **Positive:**
  - A GitLab project gets the same traceability and gates as a GitHub one, and `/adf:open-pr` finds
    its template.
  - An upgrade replaces the jobs without a merge; the team's settings stay in its own file.
  - The `workflow:` rules make the merge request pipeline the one that runs, so the gates and the
    project's own jobs share the pipeline the merge request waits for.
- **Negative / cost:**
  - **A project with a `.gitlab-ci.yml` merges three blocks by hand,** and the `workflow:` rules
    change when its existing jobs run: in merge request pipelines while a merge request is open. Jobs
    with `only:` or `except:` keep their own pipelines, and gate nothing until they get a rule.
  - **The branch policy's message is in the job log,** one click further than GitHub's comment.
  - **The jobs need a runner that runs Docker images** — GitLab.com's shared runners do; a shell
    runner needs `gitleaks` installed.
  - **Two templates and two CI setups to keep in step.** The static check covers the templates'
    sections; the CI jobs' scripts are tested in the module tests, but no GitLab pipeline runs in
    this repository's CI, and `glab` isn't installed where the framework is developed.

## Alternatives considered

- **One host-agnostic module with both `.github/` and `.gitlab/`.** Declined: every project would
  delete the half it can't use, and the deletion would come back on each upgrade.
- **The CI jobs in `.gitlab-ci.yml` itself.** Declined: most GitLab projects already have one, so the
  module's file would always collide, and every upgrade would merge jobs the team never edits.
- **Two includes, `secret-scan.yml` and `branch-policy.yml`, as GitHub's two workflows.** Declined:
  the branch model would live in a file the upgrade must merge; in the project's own variables, both
  jobs stay framework-owned.
- **GitLab's Secret-Detection template.** Declined: below Ultimate it reports without blocking, and
  the framework's gate must block on every tier.
- **A branch-policy comment through a project access token.** Declined: a write token stored in CI
  for one message; the failed job already stops the merge once pipelines must succeed.
