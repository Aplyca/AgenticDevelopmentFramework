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
- A **change request** gets a fresh branch that starts with the feature's slug and names the change:
  `feat/newsletter-signup-topics`. Never reuse the feature's earlier branch — after a squash merge it
  can survive with pre-merge history, and new work on it starts from old code.
- Branch from the base branch named in `CONTRIBUTING.md`; never commit directly to it or to any
  other protected branch.
- Keep branches short-lived: one spec folder per branch, one branch per pull request.
- Delete branches after merge.

## Outward actions

Pushing, opening a pull request, marking it ready, merging, tagging, releasing, and commenting
on a pull request, issue, or tracker task all leave this machine. An agent does them **only when
a human asks** — and each one is confirmed again when Claude Code's permissions prompt.

## Pull requests

- **Open as a draft.** Promote to ready only after a human has exercised the change (preview,
  manual QC). An agent never marks a pull request ready on its own initiative — it hasn't seen the
  result; it runs `gh pr ready` only when the developer, having QC'd the change, asks it to.
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

## What NOT to commit

- Generated files and build output; dependency directories (unless vendoring is the convention).
- `.env` and any file containing credentials. Every variable the code reads is declared by name
  in the env template instead.
- Test artifacts (screenshots, reports, coverage) unless the project tracks them deliberately.
- Personal editor settings.
