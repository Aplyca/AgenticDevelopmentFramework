---
name: upgrade
description: Upgrade a repository that already adopted the Aplyca framework skeleton to a newer version, using the three-bucket file taxonomy (overwrite / merge / project-owned) and OLD_SHA → NEW_SHA diff discipline. Use when asked to upgrade, sync, or update the agentic framework or skeleton in a repo.
---

# Upgrade an adopted repository to a newer skeleton version

Automates `docs/UPGRADING.md` from the framework repo. Read that document for the full
rationale; this skill is the executable procedure. The upgrade is deliberate and
file-by-file — there is no blind sync.

## Ground rules

- **Never commit to the default branch.** Work on a feature branch (suggest
  `chore/skeleton-upgrade-<NEW_SHA>`); deliver a reviewable PR.
- **Plan before touching.** No file is modified until the user approves the per-file plan.
- **An upgrade needs a nameable benefit.** If the user can't name one, say so and suggest
  cherry-picking the one or two changes they actually want (per UPGRADING.md).

## Step 1 — Establish OLD_SHA

Read the baseline from the top of the target's `CLAUDE.md`:
`<!-- Skeleton source: <SHA> (<date>) -->`

If the line is missing, infer the baseline from `git log` on skeleton-derived files
(rules, skills, agents) and confirm the inferred SHA with the user before proceeding.

## Step 2 — Locate the framework source and NEW_SHA

Same resolution as `/adopt`: `${CLAUDE_PLUGIN_ROOT}/../../` if present, else clone
`https://github.com/aplyca/ai-dev-starter-kit`. NEW_SHA is its current HEAD.

Read `CHANGELOG.md` entries between OLD_SHA and NEW_SHA — each entry's **Upgrade impact**
line pre-classifies changes into the buckets below. Summarize for the user what the
upgrade actually brings before doing anything.

## Step 3 — Classify every changed file into the three buckets

`git -C <framework-root> diff --name-status OLD_SHA NEW_SHA -- skeleton/` gives the changed
set. Classify per the taxonomy table in `docs/UPGRADING.md`:

| Bucket | Typical contents | Action |
|---|---|---|
| **Safe to overwrite** | `.claude/skills/*`, `.claude/agents/*`, universal rules, framework reference docs, `specs/_template.md` | Copy verbatim from new skeleton |
| **Merge required** | `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.claude/settings.json`, customizable rules | 3-way merge: reapply the project's customizations on top of the new template |
| **Project-owned** | Filled-in specs, project docs, ADRs, everything the team authored | Never touched |

Files deleted from the skeleton: propose deletion in the target only if the target's copy
is unmodified from OLD_SHA; otherwise flag for the user.

## Step 4 — Present the plan

One table: `file → bucket → action → risk note`. For merge-required files, show which
customizations were detected (diff of target file vs. OLD_SHA skeleton version) and
confirm they will survive. Wait for approval.

## Step 5 — Execute

- Bucket 1: copy verbatim.
- Bucket 2: apply the new template, then reapply each detected customization; where the
  new template restructured a section, place the customization where it now belongs and
  flag it in the PR body for human review.
- Restamp: update the `Skeleton source:` line to `NEW_SHA (<date>)`.

## Step 6 — Verify and deliver

1. Re-run the target's lint/tests if config files changed (hooks and settings can break tooling).
2. Commit with `docs:` prefix, e.g. `docs: upgrade framework skeleton OLD_SHA → NEW_SHA`.
3. PR body: changelog summary, the plan table as executed, customizations reapplied,
   anything needing human judgment.
4. Push and open the PR **only after the user approves**.
