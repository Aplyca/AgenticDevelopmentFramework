---
paths:
  - "**/*"
---

# Git Workflow Rules

The base branch, integration branches, and release process are project-specific: they live in
`CONTRIBUTING.md` and `AGENTS.md` § Delivery rules. These rules apply whatever that model is.

## Commits

- Imperative mood, concise ("add signup endpoint"). The subject says what changed; the body says
  *why* when the diff doesn't.
- **One task = one commit**, made once its test passes, with the task ticked in `tasks.md` — except
  the docs-first tasks, which land together in one `docs:` commit. In the fast and careful lanes, one
  change and the test that proves it make one commit, with a light `CR N` entry when there is one.
- Stage files by name — never `git add .` or `git add -A`.
- Never bypass hooks (`--no-verify`, `git commit -n`); fix what the hook reports.
- Don't amend or rewrite commits that have been pushed unless the developer asks.
- Never discard work — uncommitted changes, a stash, an unmerged branch (`git reset --hard`, `clean`,
  `restore`, `stash drop`, `branch -D`) — unless the developer asks: no permission prompt stops it.

## Commit prefixes and phase order

| Prefix | When | What it captures |
|---|---|---|
| `spec:` | After the approval gate, before any other work | The approved spec folder; later amendments (change requests, plan corrections) and the pull request link. A draft saved before the gate at the developer's request: `spec: draft <slug>` |
| `docs:` | Before implementation, when the plan lists pre-implementable docs | Admin guides, API contracts, end-user copy |
| `test:` | Contract-first acceptance tests, or a task that only adds tests | Acceptance tests committed red ahead of the code; or tests of existing behavior, committed green after proving each can fail |
| `feat:` / `fix:` | One per task, after its test went red then green | The test and the code that makes it pass, together |
| `refactor:` | A task — or standalone work — with no behavior change | Structure only; tests stay green throughout |
| `docs:` | During and after implementation | Docs reconciled with what was built, post-implementable backfill, the gate results (`docs: record <slug> gate results`), ADRs and PDRs |
| `chore:` / `style:` | Tooling, dependencies, CI, formatting | No behavior change and nothing to decide |

A small doc correction found while implementing a task folds into that task's commit — say so in
the body.

## Branches

- Name work branches `<type>/<slug>`: `<type>` is the commit type (`feat`, `fix`, `chore`, `docs`,
  `refactor`, plus `hotfix` where the branching model uses it), `<slug>` matches the spec folder
  (`feat/newsletter-signup` ↔ `specs/007-newsletter-signup/`). No ticket or spec numbers.
- A **change request** after the merge gets a fresh branch named for the change
  (`feat/newsletter-signup-topics`); never reuse the feature's merged branch. Feedback while the pull
  request is open rides its branch and draft.
- Branch from the base branch in `CONTRIBUTING.md`, **up to date with its remote**
  (`git switch <base> && git pull --ff-only`); never commit directly to it or another protected
  branch. One spec folder per branch, one branch per pull request.
- **After the merge,** `/wrap-up` updates the base branch, deletes the merged branch (`-D` after a
  squash merge), and closes up the task.

## Pull requests and outward actions

Pushing, opening, readying, merging, or reviewing a pull request, tagging, releasing, and commenting
on a pull request, issue, or tracker task leave this machine: an agent does them **only when a human
asks** — with one exception, the work branch's **draft**:

- **Open after the local check** (`AGENTS.md` § Delivery rules): the agent pushes the work branch and
  opens its draft on its own, then keeps it current — later pushes, its description, comments on it.
  The git guard hook refuses a pull request that isn't a draft and any push to a protected branch.
- **Reviewing, readying, and merging are the developer's, on their schedule.** An agent never marks a
  pull request ready on its own; it runs `gh pr ready` when the developer, having QC'd the change,
  asks. The report names that next step once, and never requests reviewers.
- **Title:** a commit-style subject under 70 characters. **Body:** the spec folder and the tracker
  link, what changed and why, how to verify, what was and wasn't verified — following the
  repository's template. The description matches what the diff does.
- **CI is a signal; the human review is the gate.** A failure the reviewer accepts is explained in
  the pull request.

## Syncing with the base branch

Only for a reason — the pull request conflicts, the work needs something that landed, or the
developer asks: each sync costs a re-run and a deploy. Never push to the branch of a merged or closed
pull request, and merge — never rebase or force-push pushed history. The steps: `/open-pr sync`.

## What NOT to commit

Generated files, build output, and dependency directories (unless vendoring is the convention);
`.env` and any file with credentials — every variable the code reads is declared by name in the env
template; test artifacts the project doesn't track; personal editor settings.
