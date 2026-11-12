# GitLab — the `glab` command for each step

`/adf:open-pr` reads this first when the remote is on GitLab (`git remote -v`), for its steps and
for `refresh`, `sync`, and the preview check. GitLab calls a pull request a **merge request**;
everything else in the steps holds as written.

| Step | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|
| Open the draft (step 5) | `gh pr create --draft --base <base> --title "<title>" --body-file <file>` | `glab mr create --draft --target-branch <base> --title "<title>" --description-file <file> --yes` |
| Wait for CI and the preview's deploy (steps 7, 8) — a background command | `gh pr checks <n> --watch` | `glab ci status --wait`, on the work branch; then `glab ci status --output json` for each job's result |
| Read the state and the description (`refresh`, `sync`) | `gh pr view <n> --json state,isDraft,body` | `glab mr view <n> --output json` — `state` (`opened`, `merged`, `closed`), `draft`, `description` |
| Update the description (`refresh`, the *Preview* line) | `gh pr edit <n> --body-file <file>` | `glab mr update <n> --description-file <file>` |
| Mark it ready (step 8) | `gh pr ready <n>` | `glab mr update <n> --ready` |
| Request the reviewers (step 8) | `gh pr edit <n> --add-reviewer <a>,<b>` | `glab mr update <n> --reviewer +<a>,+<b>` |
| Request a reviewer again (`refresh`) | `gh pr edit <n> --add-reviewer <a>` | `glab mr note create <n> --message "/request_review @<a>"` |

## What differs

- **The draft:** `--draft`, or `--wip`. glab's `-d` is `--description`, not a draft flag. The git
  guard hook refuses a `glab mr create` without one of the two.
- **Reviewers are usernames,** with no teams, and the `+` matters: `--reviewer <a>` without it
  replaces the reviewers already there. `CODEOWNERS` in the Reviewers line means nothing here — GitLab's
  code owners are approvers, not reviewers it asks — so name the people. Premium and Ultimate take
  several reviewers; on a tier that takes one, request the first and say so in the report.
- **CI and the preview are one pipeline.** A review app deploys as one of its jobs, so
  `glab ci status --wait` returns once both are done. Its URL is the merge request's environment,
  or where `AGENTS.md` § Quick reference says previews deploy.
- **The description's template:** `.gitlab/merge_request_templates/Default.md` when it exists, in
  place of `.github/pull_request_template.md`.
- **A requester's issue** is referenced in the description with `Related to #<n>`, never
  `Closes #<n>`: GitLab closes the issue at the merge, before the change is live.
- **Permissions:** the project's settings carry the `glab` rules beside the `gh` ones; marking a merge
  request ready and requesting its reviewers need no prompt, and merging or approving one asks.
