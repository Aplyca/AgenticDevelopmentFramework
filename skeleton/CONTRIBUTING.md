# Contributing

How work gets from your machine to production — for people and AI agents alike.

## Getting started

1. Set up your environment: [docs/getting-started/DEV-SETUP.md](docs/getting-started/DEV-SETUP.md)
2. Read [AGENTS.md](AGENTS.md) — the project's rules, workflow, and commands (AI agents read the same file)
3. Read [specs/README.md](specs/README.md) — when a change needs a spec folder, and how one flows

## How a change flows

1. **Triage** — read the task in full; decide whether it needs an answer or a change, an environment,
   a spec folder.
2. **Spec folder** — for a change with something to decide: `specs/NNN-<slug>/` with `spec.md`
   (multi-perspective requirements — [docs/SPEC-MODEL.md](docs/SPEC-MODEL.md)), `plan.md` (change
   surface, test strategy), `tasks.md` (one task per commit).
3. **Approval gate** — the scope, the change surface, and the assumptions are signed off before any
   implementation code. Commit the folder (`spec:`).
4. **Docs first** — pre-implementable user-facing docs (`docs:`), when the plan lists any.
5. **One task at a time** — write the test, watch it fail, write the code, watch it pass, commit.
6. **Review**, then a **draft** pull request; QC it in its preview; mark it ready.

Changes with nothing to decide (typo, version bump, copy edit) skip the spec folder. Change requests
on delivered work amend the existing folder.

## Branching and release

<!-- CUSTOMIZE: keep the model you use, delete the other, and record it as an ADR. The constitution,
     AGENTS.md § Delivery rules, .claude/hooks/config.sh (PROTECTED_BRANCHES), and any branch-policy
     CI must all say the same thing. -->

### Model A — feature branches into `main`

`main` is production; every change reaches it through its own pull request.

1. Branch from `main`: `<type>/<slug>` (e.g. `feat/newsletter-signup`, matching `specs/NNN-newsletter-signup/`).
2. Open a pull request into `main`; it is squash-merged after review, so `main` gets one commit per
   pull request while the per-task commits stay on the pull request for review. (Rebase-merge
   instead if you want them on `main`.) Merging deploys.
3. Acceptance-test on the branch's preview deployment before merge.
4. *(Optional)* To test several features together, merge them into an integration branch (e.g. `dev`)
   and use its preview. The integration branch is **never merged into `main`** and nobody branches
   from it; it's refreshed from `main` and reset when cluttered.

### Model B — integration branch, tagged releases

`[staging]` collects reviewed work for the requester's acceptance; `main` + a tag is production.

1. Branch from `[staging]`; open the pull request into `[staging]`. Only `[staging]` and `hotfix/*`
   ever target `main`.
2. The requester reviews `[staging]`. Changes they ask for are new branches into `[staging]`.
3. Release: bump the version on `[staging]`, merge `[staging]` into `main` with a merge commit, and
   push an annotated tag `vX.Y.Z` — the tag ships.
4. Hotfix: branch from the released tag, pull request into `main`, tag a patch release, then
   back-merge `main` into `[staging]` immediately. Hotfixes are code-only — migrations go through
   `[staging]`.

Both models: **never commit directly to a protected branch**, delete branches after merge, and keep
database migrations additive and backward-compatible (you can roll the app back; you can't roll a
schema back).

## Pull requests

- **Open every pull request as a draft.** QC it yourself in its preview (or read it back, if there's
  nothing to preview), then mark it ready — "ready" means a person has exercised it. AI agents open
  drafts and never mark them ready.
- **One spec folder per pull request.** The description names the spec folder, links the tracker
  task, says what changed and why, how to verify it, and what was not verified.
- **No merge without human review** — AI-generated changes included. Read the whole pull request, not
  just the diff. CI is a signal; the review is the gate.

## Status words for requesters

<!-- CUSTOMIZE to the branching model above. /stakeholder-update uses this table. -->

| State | Say |
|---|---|
| Pull request open | "in review" |
| Merged into [the integration branch / preview] | "in acceptance testing" |
| [Merged into `main` / released with a tag] | "live" |

## What's enforced, and what isn't

<!-- CUSTOMIZE: be honest. A rule people believe is enforced but isn't is worse than a stated convention. -->

- **Enforced by the Git host:** [e.g., pull requests required on `main`; no force-push; merge method]
- **Enforced locally:** [e.g., pre-commit lint; pre-push typecheck and unit tests; agent hooks in `.claude/hooks/`]
- **Not enforced — conventions:** [e.g., required approvals, passing checks, draft-until-QC]. We follow
  them because that's the agreement, not because anything stops us.

## Commit messages

Imperative mood; the subject says what, the body says why.

```
spec: approve newsletter-signup scope and plan
docs: add admin guide for newsletter signup
feat: reject invalid emails with an inline error
fix: guard against a non-array topics response
refactor: extract the signup form into a shared component
chore: bump the test runner to the next minor version
```

Prefixes and their order: `.claude/rules/git-workflow.md`.

## Code standards

- Follow `AGENTS.md`, the nested `AGENTS.md` for the folder you're in, and `.claude/rules/` (readable by anyone)
- Match the style of the file you're editing; formatters and linters are the source of truth
- [Add project-specific standards: formatting commands, naming, layers]

## Testing requirements

- Every acceptance criterion has a test; bug fixes start with a test that reproduces the bug
- Tests don't depend on external services being up — mock them
- [Add project-specific requirements: test layers, where each runs, coverage expectations]

## Security

- Never commit credentials, keys, or `.env` files; declare every environment variable by name in the env template
- Validate input at boundaries; never expose internal error details to clients
- Report vulnerabilities privately to [security contact or process]

## Documentation

- Update docs in the same pull request when a change affects architecture, APIs, or setup
- Add domain terms to [docs/GLOSSARY.md](docs/GLOSSARY.md)
- Record significant decisions: technical ones as ADRs (`docs/architecture/decisions/`), process ones as PDRs (`docs/process/`)

## Questions?

- [e.g., Ask in #project-name]
- [e.g., Tag @team-lead in your pull request]
