---
name: upgrade
description: Upgrade a repository that already adopted the Aplyca framework skeleton (and any optional modules) to a newer version, using the three-bucket file taxonomy (overwrite / merge / project-owned), OLD_SHA → NEW_SHA diff discipline, and the changelog's migration steps. Use when asked to upgrade, sync, or update the agentic framework or skeleton in a repo.
---

# Upgrade an adopted repository to a newer skeleton version

Automates `docs/UPGRADING.md` from the framework repo. Read that document for the full rationale;
this skill is the executable procedure. The upgrade is deliberate and file-by-file — there is no
blind sync.

## Ground rules

- **Never commit to the default branch.** Work on a feature branch (suggest
  `chore/skeleton-upgrade-<NEW_SHA>`); deliver a reviewable draft PR.
- **Plan before touching.** No file is modified until the user approves the per-file plan.
- **An upgrade needs a nameable benefit.** If the user can't name one, say so and suggest
  cherry-picking the one or two changes they actually want.

## Step 1 — Establish OLD_SHA and the installed modules

Read the baseline from the top of the target's `CLAUDE.md`:
`<!-- Skeleton source: <SHA> (<date>) · modules: <list> -->` (older stamps have no `modules:` part —
treat it as `none`, and check for module files on disk: `.github/pull_request_template.md`,
`.githooks/pre-push`, `scripts/agent/`, a `clickup` server in `.mcp.json`).

For the `clickup` module, rerun `modules/clickup/install.sh <repo>` from NEW_SHA instead of copying:
it merges new read-only patterns into `.claude/settings.json` and keeps everything else.

If the line is missing, infer the baseline from `git log` on skeleton-derived files (rules, skills,
agents) and confirm the inferred SHA with the user before proceeding.

## Step 2 — Locate the framework source and NEW_SHA

Same resolution order as `/adopt` Step 1: repo checkout via `${CLAUDE_PLUGIN_ROOT}/../..`
(development installs), else the marketplace checkout `~/.claude/plugins/marketplaces/<name>/`
(normal case — run `claude plugin marketplace update <name>` first), else a **full** clone of
`https://github.com/aplyca/AgenticDevelopmentFramework` (not shallow — the diff needs history).
NEW_SHA is its current HEAD.

Read `CHANGELOG.md` entries between OLD_SHA and NEW_SHA. Each entry's **Upgrade impact** pre-classifies
changes into the buckets below, and some entries carry **Migration** steps that must happen even for
files the project customized. Summarize for the user what the upgrade brings before doing anything.

## Step 3 — Classify every changed file

`git -C <framework-root> diff --name-status OLD_SHA NEW_SHA -- skeleton/ modules/<each installed module>/files/`
gives the changed set (module paths map into the repo by dropping `modules/<name>/files/`). Classify
per the taxonomy in `docs/UPGRADING.md`:

| Bucket | Typical contents | Action |
|---|---|---|
| **Safe to overwrite** | `.claude/skills/*`, `.claude/agents/*`, `.claude/workflows/*`, hook scripts (`.claude/hooks/*.sh`), universal rules, framework reference docs, `specs/_templates/*` (if unmodified), `docs/process/0000-pdr-template.md`, module scripts | Copy verbatim from the new version |
| **Merge required** | `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `CONTRIBUTING.md`, `.claude/settings.json`, `.claude/hooks/config.sh`, customizable rules, `.claudeignore`, `docs/CONSTITUTION.md`, `specs/README.md`, `docs/process/README.md`, `docs/reference/README.md`, `docs/TRACKER-INTEGRATION.md`, module config (`worktree.conf`, the PR template, `branch-policy.yml`, `.githooks/pre-push`) | 3-way merge: reapply the project's customizations on top of the new template |
| **Project-owned** | Spec folders and legacy specs, ADRs, PDRs, project docs, `docs/reference/*` pages, everything the team authored | Never touched |

Files deleted upstream: propose deletion only if the target's copy is unmodified from OLD_SHA;
otherwise flag for the user. Files that moved (e.g. `specs/_template.md` → `specs/_templates/`)
follow the changelog's migration notes.

## Step 4 — Present the plan

One table: `file → bucket → action → risk note`, plus the changelog's migration steps as their own
checklist. For merge-required files, show which customizations were detected (diff of the target file
vs the OLD_SHA version) and confirm they will survive. Wait for approval.

## Step 5 — Execute

- Bucket 1: copy verbatim. Keep executable bits on scripts.
- Bucket 2: apply the new template, then reapply each detected customization; where the new template
  restructured a section, place the customization where it now belongs and flag it in the PR body.
- Migration steps from the changelog, in order.
- Restamp: `Skeleton source:` → `NEW_SHA (<date>) · modules: <list>`.

## Step 6 — Verify and deliver

1. Run the verification from `/adopt` Step 6: settings JSON valid with nested hook entries; hook
   smoke tests (sample events piped to each script); `@AGENTS.md` import present; skill frontmatter
   uses hyphenated keys only. Re-run the target's lint and tests if config files changed.
2. Commit with a `docs:` or `chore:` prefix, e.g. `chore: upgrade framework skeleton OLD_SHA → NEW_SHA`.
3. PR body: changelog summary, the plan table as executed, migration steps done, customizations
   reapplied, anything needing human judgment.
4. Push and open the PR **as a draft, only after the user approves**.
