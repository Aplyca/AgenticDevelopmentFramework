# Sync — bring the base branch in

`/adf:open-pr sync`, when the base branch moved on under your open pull request and there's a reason
to bring it in: the pull request conflicts, the work needs something that landed there, or the
developer asks. Each sync costs a re-run and a new deploy. The steps, in order:

1. **Check the pull request is still open:** `gh pr view <n> --json state`. Never push to the
   branch of a merged or closed pull request. New commits there reach no one: say so, and leave
   any remaining work to a fresh branch.
2. **Merge, never rebase:** `git fetch origin`, then `git merge origin/<base>`, a normal merge
   commit. Never rebase or force-push history that's already pushed: the review's comments and
   every other checkout point at it.
3. **Resolve each conflict by keeping both sides' intent,** never by taking one side whole, and
   report how you resolved each one, file by file.
4. **Re-run only what the merged files affect.** `git diff --stat HEAD^1 HEAD` lists what the merge
   brought in:
   - no app files — source, tests, package manifests, the app framework's configuration: the
     earlier gate stands, and you say so;
   - otherwise the unit tests and lint, plus the build and the end-to-end tests when shared UI or
     configuration changed.
5. **Re-check the cross-spec contracts the merge brought in:** an API, schema, or shared type
   another spec changed still gives this work what it relies on.
6. **Push to your own draft pull request's branch** — upkeep, with no prompt.
7. **Expect the preview to move.** A new deploy can change the preview's address, and links
   already sent to people show the old build: give the new address in your report.
8. **Record it** when it changed the evidence: the sync, and what you re-ran, in `tasks.md`
   § Gate results (the pull request's *Verified* line in the fast and careful lanes), then refresh
   the description (`refresh.md`, beside this file).

**In the desktop app,** its `sync_with_base_branch` tool, where you have it, fetches and merges on
the host, where it can write the files the sandbox protects. Resolve what it reports, then carry on
from step 3. It works only in a worktree the app made, and refuses a merge that touches protected
settings files: elsewhere, merge with git; a refused merge goes to the developer.
