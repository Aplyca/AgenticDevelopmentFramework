---
paths:
  - "**/*"
---

# Git Workflow Rules

The base branch, integration branches, and release process are project-specific: they live in
`CONTRIBUTING.md` and `AGENTS.md` § Delivery rules. These rules apply whatever that model is.

## Commits

- Imperative mood, concise ("add signup endpoint", not "added" or "adds"). The subject says what
  changed; the body says *why* when the diff doesn't.
- **One task = one commit.** In spec-driven work each task in `tasks.md` lands as one commit, made
  once its test passes; tick the task in the same commit. The docs-first tasks are the exception:
  they land together in one `docs:` commit, reviewed as one description of how the feature is used.
  In the fast and careful lanes there is no `tasks.md`: one change and the test that proves it make
  one commit, and a light change request's `CR N` entry goes in that same commit.
- Stage files by name — never `git add .` or `git add -A`.
- Never bypass hooks (`--no-verify`, `git commit -n`); fix what the hook reports.
- Don't amend or rewrite commits that have been pushed unless the developer asks.
- Never discard work — uncommitted changes, a stash, an unmerged branch (`git reset --hard`, `clean`,
  `restore`, `stash drop`, `branch -D`) — unless the developer asks: no permission prompt stops it.

## Commit prefixes and phase order

| Prefix | When | What it captures |
|---|---|---|
| `spec:` | After the approval gate, before any other work | The approved spec folder (spec, plan, tasks) — intent, change surface, verification map. Later amendments (change requests, plan corrections) and the pull request link (`spec: link <slug> pull request`) also use `spec:`. A draft saved before the gate at the developer's request says so: `spec: draft <slug>` |
| `docs:` | Before implementation, when the plan lists pre-implementable docs | Design intent for usage — admin guides, API contracts, end-user copy |
| `test:` | Contract-first acceptance tests, or a task that only adds tests | Acceptance tests committed red, ahead of the code that will satisfy them; or tests of behavior that already exists — end-to-end acceptance tests after the stories, characterization tests before a refactor or change — committed green after proving each can fail |
| `feat:` / `fix:` | One per task, after its test went red then green | The test and the code that makes it pass, together |
| `refactor:` | A task — or standalone work — with no behavior change | Structure only; tests stay green throughout |
| `docs:` | During and after implementation | Reconciling docs with what was built; post-implementable backfill (runbooks, troubleshooting); the gate results in `tasks.md`, with `status: implemented` (`docs: record <slug> gate results`); ADRs and PDRs |
| `chore:` / `style:` | Tooling, dependencies, CI, formatting | Work with no behavior change and nothing to decide |

Small doc corrections discovered while implementing a task can fold into that task's commit —
say so in the body. Meaningful doc revisions get their own `docs:` commit.

## Branches

- Name work branches `<type>/<slug>`: `<type>` is the commit type (`feat`, `fix`, `chore`,
  `docs`, `refactor` — plus `hotfix` where the branching model uses it), `<slug>` matches the spec
  folder (`feat/newsletter-signup` ↔ `specs/007-newsletter-signup/`). No ticket numbers or spec
  numbers — the slug is the join.
- A **change request** after the merge gets a fresh branch that starts with the feature's slug and
  names the change: `feat/newsletter-signup-topics` (feedback while the pull request is still open
  rides its branch and draft). Never reuse the feature's earlier branch — after a squash merge it
  can survive with pre-merge history, and new work on it starts from old code.
- Branch from the base branch named in `CONTRIBUTING.md`, **up to date with its remote**
  (`git switch <base> && git pull --ff-only` first); never commit directly to it or to any other
  protected branch. The session context says when the base branch is behind (as of the last fetch).
- Keep branches short-lived: one spec folder per branch, one branch per pull request.
- **After the merge**, update the base branch locally (`git switch <base> && git pull --ff-only`),
  then delete the merged branch — `git branch -d` checks the merge against the updated base; a
  squash-merged branch needs `-D` once its work is upstream. `/wrap-up` does both once it finds
  nothing left in the task, and with one yes also stops what the task started, removes its worktree,
  and archives the session.

## Outward actions

Pushing, opening a pull request, marking it ready, merging, tagging, releasing, and commenting
on a pull request, issue, or tracker task all leave this machine. An agent does them **only when
a human asks**, and marking ready, merging, reviewing, and releases are confirmed again when
Claude Code's permissions prompt. One exception: once the agent has walked the change on the
local environment (`AGENTS.md` § Delivery rules) — or, with nothing to run, once the full gate and
`/review` pass — the agent pushes the work branch and opens its **draft** pull request on its own, then
keeps it current: later pushes to the work branch, edits to its description, and comments on it
take no prompt. The git guard hook refuses a pull request that isn't a draft and any push to a
protected branch.

## Pull requests

- **Open after the local check.** When the change alters something a person can see or use, the
  agent runs it on the local environment and walks the changed flow before it pushes — a change
  nothing has run never reaches a pull request (`AGENTS.md` § Delivery rules). The developer tests
  it by hand after the draft opens, locally and on the preview.
- **Open as a draft.** Promote to ready only after a human has exercised the change (preview,
  manual QC). An agent never marks a pull request ready on its own initiative — it hasn't seen the
  result; it runs `gh pr ready` only when the developer, having QC'd the change, asks it to.
- **Reviewing, readying, and merging are the developer's, on their schedule.** The agent's report
  names that next step once — test it, then ready and merge, then the agent's wrap-up — and doesn't
  remind them again, offer to promote it, or request reviewers or a review.
- **Check it on the preview too.** Once the draft's preview deploys, the agent walks the changed flow
  there, read-only, after its local check, and adds what it saw to the description
  (`AGENTS.md` § Delivery rules).
- **Title:** a commit-style subject under 70 characters.
- **Body:** the spec folder path and the tracker task link; what changed and why; how to verify;
  what the author verified and what they could not; screenshots for UI changes. Follow the
  repository's pull request template when there is one.
- **One spec folder per pull request.** Don't bundle unrelated work.
- **CI is a signal, not the gate.** Green checks don't make a change correct, so the human review
  is the gate. Tests pass before merge; a failure the reviewer accepts is explained in the pull
  request.
- **Verify the pull request, not just the diff:** the description must match what the diff
  actually does — no phantom changes, no claims the diff doesn't support.

## Syncing with the base branch

When the base branch moves on under an open pull request, bring it in only when there's a reason:
the pull request conflicts, the work needs something that landed there, or the developer asks.
Each sync costs a re-run and a new deploy. The steps, in order:

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
   § Gate results (the pull request's *Verified* line in the fast and careful lanes). `/open-pr
   refresh` brings the description up to date.

**In the desktop app,** its `sync_with_base_branch` tool, where you have it, fetches and merges on
the host, where it can write the files the sandbox protects. Resolve what it reports, then carry on
from step 3. It works only in a worktree the app made, and refuses a merge that touches protected
settings files: elsewhere, merge with git; a refused merge goes to the developer.

## What NOT to commit

- Generated files and build output; dependency directories (unless vendoring is the convention).
- `.env` and any file containing credentials. Every variable the code reads is declared by name
  in the env template instead.
- Test artifacts (screenshots, reports, coverage) unless the project tracks them deliberately.
- Personal editor settings.
