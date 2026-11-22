---
paths:
  - "**/*"
---

# Git Workflow Rules

These apply whatever the project's branching and release model is (`CONTRIBUTING.md`, `AGENTS.md`
§ Delivery rules).

## Commits

- Imperative mood, concise ("add signup endpoint"); the body says *why* when the diff doesn't.
- **One task = one commit**, made once its test passes, with the task ticked in `tasks.md` — except
  the docs-first tasks, which land together in one `docs:` commit. In the fast and careful lanes, one
  change and the test that proves it make one commit, with a light `CR N` entry when there is one.
- Stage files by name — never `git add .` or `git add -A`.
- Never bypass hooks (`--no-verify`, `git commit -n`); fix what the hook reports.
- Never discard work — uncommitted changes, a stash, an unmerged branch (`git reset --hard`, `clean`,
  `restore`, `stash drop`, `branch -D`) — unless the developer asks: no permission prompt stops it.

## Commit prefixes and phase order

| Prefix | When | What it captures |
|---|---|---|
| `spec:` | After the approval gate, before any other work | The approved spec folder; a full change request's approved spec, plan, and tasks; a plan correction made outside a task; the pull request link. A draft saved before the approval gate at the developer's request: `spec: draft <slug>`. A light `CR N` entry, or a plan fix a task needs, rides that task's commit |
| `docs:` | Before implementation, when the plan lists pre-implementable docs | Admin guides, API contracts, end-user copy |
| `test:` | Contract-first acceptance tests, or a task that only adds tests | Acceptance tests committed red ahead of the code, or tests of existing behavior committed green once each is proven able to fail |
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
- One spec folder per branch, one branch per pull request; feedback while the pull request is open
  rides its branch.
- **After the merge,** `/wrap-up` updates the base branch, deletes the merged branch (`-D` after a
  squash merge), and closes up the task.

## Pull requests and outward actions

The work branch's pull request — a draft, opened after the local check —
follows `AGENTS.md` § Delivery rules; every other outward action — a push elsewhere, a tag, a
release, a comment — happens only when a human asks (§ Ground rules). The git guard hook
refuses a pull request that isn't a draft and any push to a protected branch, and asks before a
tag is pushed.

- **Title:** a commit-style subject under 72 characters. The body follows the repository's template
  and matches what the diff does.
- A CI failure the reviewer accepts is explained in the pull request.

## Syncing with the base branch

Only for a reason — the pull request conflicts, the work needs something that landed, or the
developer asks: each sync costs a re-run and a deploy. Never push to the branch of a merged or closed
pull request, and merge — never rebase or force-push pushed history. The steps: `/open-pr sync`.

## What NOT to commit

Build output and dependency directories (unless vendoring is the convention);
`.env` and any file with credentials; test artifacts the project doesn't track; personal editor
settings.
