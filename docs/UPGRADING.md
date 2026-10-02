# Upgrading a target project to a newer skeleton version

How to pull newer framework changes into a target project that adopted an earlier version of the skeleton — without losing your team's customizations.

The framework ships as a copy-in skeleton, not a runtime dependency. There is no `npm update` equivalent. Upgrades are deliberate, file-by-file, and informed by the three-bucket taxonomy below.

## When to upgrade

Upgrade when there is a concrete benefit you can name:

- A new skill, agent, or workflow you want (e.g., `/triage`, `/write-plan`, `/deep-review`)
- A fix you need (e.g., the `@AGENTS.md` import and the hook schema in the `3eb7777` release)
- A rule update you want enforced across the team
- A spec-template change that improves clarity (e.g., the Mermaid diagrams section)
- A docs improvement your team would reference (e.g., `MEMORY-STRATEGY.md`, `COST-MODEL.md`)

Skip the upgrade when:

- The project is shipping in the next week — defer until after release
- You can't name what you'd gain — "stay current" is not a reason to bust working configuration
- Your customizations are extensive and the merge cost outweighs the benefit — cherry-pick the one or two things you actually want instead of doing a full sync

## Versioning convention

From v1.0.0, releases follow **semantic versioning** ([decision 0017](decisions/0017-semantic-versioning.md)):
**MAJOR** when an adopting team has to act (migration steps, a changed workflow rule, a renamed or
removed skill, setting, or plugin), **MINOR** for additive or opt-in capabilities, **PATCH** for fixes
that change no workflow. Each release is tagged `vX.Y.Z`. Releases before v1.0.0 are referenced by
**commit SHA + date**.

To make future upgrades tractable, record the skeleton baseline — and the optional modules you installed — in the first line of your project's `CLAUDE.md`:

```markdown
<!-- Skeleton source: v1.0.0 · 1a2b3c4 (2026-10-02) · modules: github, parallel-agents -->
```

The commit is what an upgrade diffs from, so the stamp keeps it next to the version. Stamps from
before v1.0.0 carry only the SHA (`Skeleton source: ed3d1a1 (2026-04-29)`) and still work.

This gives every future upgrade a known baseline to diff against. Update it after each successful upgrade. Older stamps without `modules:` mean none were installed.

If your project doesn't have this line yet, infer the baseline from `git log` on skeleton-derived files (rules, skills, agents) and pick the latest framework commit SHA whose changes are reflected.

## File taxonomy: three buckets

Every file the skeleton introduces falls into one of three buckets. Your upgrade strategy depends entirely on the bucket.

| Bucket | What it contains | Upgrade strategy |
|---|---|---|
| **Safe to overwrite** | Framework-owned files with no customization expectations | Copy from new skeleton verbatim |
| **Merge required** | Files with `<!-- CUSTOMIZE -->` markers OR project-identity content | 3-way diff: old skeleton → new skeleton → your project. Reapply your customizations on top of the new template. |
| **Project-owned** | Files your team authored | Never touched by an upgrade |

### Safe to overwrite

| Path | Notes |
|---|---|
| `.claude/skills/*` | All skill SKILL.md files. Skills are framework playbooks; rewrite by replacement. |
| `.claude/agents/*` | All agent definitions. The `model:` field in frontmatter is a framework decision — don't override casually (see `docs/COST-MODEL.md`). |
| `.claude/workflows/*` | Dynamic workflow scripts |
| `.claude/hooks/*.sh` | Hook scripts — project values live in `config.sh` (merge bucket), so the scripts stay replaceable. Keep their executable bit |
| `.claude/rules/code-quality.md` | Universal — language-agnostic engineering standards |
| `.claude/rules/testing.md` | Universal — testing discipline |
| `.claude/rules/security.md` | Universal — OWASP-style baseline |
| `.claude/rules/git-workflow.md` | Universal — commit prefixes, branch discipline |
| `docs/SPEC-MODEL.md` | Framework reference doc |
| `docs/COST-MODEL.md` | Framework reference doc |
| `docs/MEMORY-STRATEGY.md` | Framework reference doc |
| `docs/MCP-INTEGRATION.md` | Framework reference doc |
| `docs/process/0000-pdr-template.md` | The PDR template |
| `.cursor/rules/*.mdc` | Cursor mirrors of the rules |
| `specs/_templates/*` | The spec-folder templates (`spec.md`, `plan.md`, `tasks.md`) — merge instead if your team customized them. Your filled-in specs are project-owned |
| Module scripts | `scripts/agent/*.sh`, `.github/workflows/secret-scan.yml` |

### Merge required

| Path | Why it needs merging |
|---|---|
| `AGENTS.md` | Project identity (stack, conventions, terminology) — your team filled this in |
| `CLAUDE.md` | Project identity + tool-specific config; may include team-specific notes |
| `GEMINI.md` | Same as CLAUDE.md, for Antigravity |
| `.claude/settings.json` | Hooks, permissions, env vars — team-customized |
| `.claude/hooks/config.sh` | Protected branches, append-only and generated paths, sensitive paths (`CAREFUL_GLOBS`), env template |
| `CONTRIBUTING.md` | Your branching model, status vocabulary, what's enforced |
| `docs/CONSTITUTION.md` | Your principles (the template's wording around them changes) |
| `specs/README.md` | The spec process — teams sometimes adjust it |
| `docs/process/README.md`, `docs/reference/README.md` | Framework prose around your own index |
| `docs/TRACKER-INTEGRATION.md` | Your tracker, MCP setup, allowlist |
| Module configuration | `scripts/agent/worktree.conf`, `.github/pull_request_template.md`, `.github/workflows/branch-policy.yml`, `.githooks/pre-push`, `.mcp.json` (the `clickup` module — rerun `modules/clickup/install.sh`, which merges) |
| `.claude/rules/architecture.md` | Has `<!-- CUSTOMIZE -->` markers for paths and patterns |
| `.claude/rules/ui-ux.md` | Customize for your UI framework |
| `.claude/rules/deployment.md` | Customize for your infra |
| `.claude/rules/performance.md` | Customize for your perf budget and stack |
| `.claude/rules/observability.md` | Customize for your logging/tracing stack |
| `.claudeignore` | Teams prune/extend entries for their stack |

### Project-owned

| Path | Notes |
|---|---|
| `specs/NNN-<slug>/*` and legacy `specs/<feature>.md` | Your spec folders and specs. Never overwritten. |
| `docs/architecture/decisions/*`, `docs/process/pdr-*` | ADRs and PDRs |
| `docs/reference/*` pages | Your code-level reference pages |
| `docs/architecture/*` | Project-specific architecture docs you authored |
| Any source code | Out of scope for the upgrade |

## Upgrade procedure

Concrete steps. Do this on a branch in the target project.

### 1. Identify the baseline

Read the skeleton-source line at the top of your project's `CLAUDE.md`. If absent, infer it: read the framework's `git log --oneline` and pick the latest SHA whose features you can identify in your project. Record this as `OLD_SHA`.

The new target is the framework's current `main` SHA — call it `NEW_SHA`.

### 2. Read the changelog

Start with [`CHANGELOG.md`](../CHANGELOG.md) at the framework repo root — each entry classifies its upgrade impact against the three buckets, so most of the manual cross-referencing is done for you.

For finer detail (or if the changelog hasn't been updated for a recent commit), drop to git:

```bash
git -C /path/to/AgenticDevelopmentFramework log --oneline OLD_SHA..NEW_SHA
git -C /path/to/AgenticDevelopmentFramework diff --stat OLD_SHA..NEW_SHA -- skeleton/
```

This is your shopping list. Cross-reference each commit against the three buckets above.

### 3. Branch in the target project

```bash
git checkout -b chore/skeleton-upgrade-<NEW_SHA>
```

### 4. Bucket-by-bucket execution

**Bucket 1 — overwrite**: copy each file from the new skeleton over your project's copy. Don't think hard about these.

```bash
FW=/path/to/AgenticDevelopmentFramework/skeleton
cp -R $FW/.claude/skills/* .claude/skills/
cp -R $FW/.claude/agents/* .claude/agents/
mkdir -p .claude/workflows && cp $FW/.claude/workflows/*.js .claude/workflows/
cp $FW/.claude/hooks/*.sh $FW/.claude/hooks/README.md .claude/hooks/   # not config.sh — that one merges
cp $FW/.claude/rules/{code-quality,testing,security,git-workflow}.md .claude/rules/
cp $FW/docs/{SPEC-MODEL,COST-MODEL,MEMORY-STRATEGY,MCP-INTEGRATION}.md docs/
```

Inspect the diff for surprise (removed files, renamed files). Adjust if the framework has restructured anything.

**Bucket 2 — 3-way merge**: for each file, you need three versions: the old skeleton's, the new skeleton's, and your project's. Use `git merge-file` or your editor's 3-way merge:

```bash
git show OLD_SHA:skeleton/AGENTS.md > /tmp/agents-old.md
cp /path/to/AgenticDevelopmentFramework/skeleton/AGENTS.md /tmp/agents-new.md
git merge-file --diff3 -p AGENTS.md /tmp/agents-old.md /tmp/agents-new.md > /tmp/agents-merged.md
```

Resolve conflicts manually. The principle: keep your customizations (project identity, custom paths, team-specific notes), accept structural changes (new sections, reorganized tables, updated wording in framework boilerplate).

**Bucket 3 — leave alone**: no action.

### 5. Verify

- **Configuration is valid:** `python3 -m json.tool .claude/settings.json`, and every hook entry nests its command in a `hooks` array.
- **Hooks fire:** pipe a sample event into each — e.g. `printf '{"cwd":"%s","tool_input":{"command":"git push origin main"}}' "$PWD" | .claude/hooks/guard-git.sh; echo $?` prints `2`.
- **Both instruction files load:** start a new Claude Code session and check `/memory` — `CLAUDE.md`, with `AGENTS.md` through the import.
- **Your own evals,** if the project keeps any (`evals/`).
- **A smoke test** of a skill that changed — invoke it and confirm it references the right project paths.

### 6. Update the baseline

Edit the top of `CLAUDE.md`:

```markdown
<!-- Skeleton source: <NEW_SHA> (<today's date>) · modules: <list or none> -->
```

Commit with a clear message:

```
chore: upgrade skeleton to <NEW_SHA>

What changed:
- Added /spec-drift skill
- Added /orchestrate skill
- Spec template now includes Mermaid section
- New docs: COST-MODEL, MEMORY-STRATEGY, MCP-INTEGRATION

Customizations preserved:
- architecture.md (project paths)
- AGENTS.md (stack notes)
```

## AI-assisted upgrades

You can have Claude Code do most of step 4 for you. The pattern preserves the plan-then-execute gate, so you stay in control.

**Setup**: open the target project in Claude Code. Make sure the framework repo is checked out somewhere local.

**Prompt template**:

```
Upgrade this project's skeleton from <OLD_SHA> to <NEW_SHA>.

Framework repo: /path/to/AgenticDevelopmentFramework
Refer to docs/UPGRADING.md in that repo for the file taxonomy and procedure.

Step 1 (now): produce the merge plan as a checklist — for each
changed file in the framework's git log between those SHAs, classify
it as overwrite / merge / skip, and for merge files note what my
project has customized. Wait for my approval before executing.

Step 2 (after approval): execute file by file. For merge files, show
me the proposed merged content before writing.
```

For ambiguous merge decisions (e.g., "the framework removed a rule we relied on"), invoke `/evaluate` to get options-with-tradeoffs analysis before deciding.

**Don't let the AI skip the plan gate.** Upgrades silently breaking customizations is the failure mode this guide exists to prevent.

## Common upgrade scenarios

### "We adopted before the `3eb7777` release (2026-10-01, plugin 0.2.x)"

That release fixes three defects that affect every adopting repository — do these first, even if you
upgrade nothing else (details in [`CHANGELOG.md`](../CHANGELOG.md)):

1. **Add `@AGENTS.md` as the first instruction of `CLAUDE.md`.** Without it, Claude Code never reads
   `AGENTS.md` when a `CLAUDE.md` exists.
2. **Fix the hook schema in `.claude/settings.json`.** Flat `{"matcher", "command"}` entries never
   ran, and `$CLAUDE_FILE_PATH` doesn't exist. Copy `.claude/hooks/`, set `config.sh`, and wire the
   hooks as nested `hooks` arrays. A custom hook you wrote on the old pattern (for example, "every
   env var read in code is declared in the template") is now `check-env-declared.sh` — or port yours
   to read `tool_input.file_path` from stdin and exit 2 to report.
3. **Remove `user_invocable:` from custom skills** — the key is ignored.

Then decide how far to go: the spec-folder workflow (new skills, templates, `specs/README.md`) is the
main benefit. Existing single-file specs stay as they are; new work uses folders, and a legacy spec
moves into a folder the next time it changes.

### "We adopted before the `7383422` release (2026-10-01, plugin 0.2.4)"

Start with the plugin: install it in the project with `--scope project` (the README's install prompt
does it and reports a user-scope copy to remove), then run `/upgrade` in a new session. It applies
the release's parts newest first and offers the modules you don't have. If the project uses the
dispatcher hub, run it from a worktree: from this release on, the hub's main checkout takes no edits.

### "We use the packaged install" — or want to

A packaged project ([decision 0016](decisions/0016-packaged-install.md)) doesn't commit the skills,
agents, workflows, or hook scripts: they come from the `aplyca-adf` plugin, pinned to a release tag
in `.claude/settings.json`. Upgrading it means two things:

- **Bump the pin:** the marketplace's `"ref"` moves to the new release tag, `vX.Y.Z`. That one line upgrades
  every skill, agent, workflow, and hook. Every project moves from release to release, committed ones
  too: their pin keeps the plugin's copies at the same release as their committed files.
- **Merge the committed layer** as in the procedure above — `AGENTS.md`, `CLAUDE.md`, the settings
  (never adding a `hooks` block), `config.sh`, the rules, the docs, and the modules — and skip every
  path the plugin carries.

`/upgrade` does both, and offers to switch a committed project to packaged (or back). Switching removes
only the machinery files unchanged since your baseline. A skill or hook your team edited stays
committed, under a name of its own, or goes upstream as a change to the framework.

### "We adopted before the modules existed"

Your stamp has no `modules:` part, so nothing optional was installed. `/upgrade` lists the modules
you don't have and recommends the ones your repository's facts support — `parallel-agents` when
several agent sessions may work at once (each task gets its own worktree, branch, pull request, and
session; the main checkout only dispatches), `clickup` when requirements arrive as ClickUp tasks,
`github` on GitHub, `git-hooks` for local gates. The ones you choose join the same upgrade pull
request, with their customize steps. Choosing `parallel-agents` moves the upgrade itself into a
worktree, so the main checkout starts as a clean hub. By hand: `cp -R modules/<name>/files/.` (no
overwrite) and follow its `MODULE.md`.

### "I just want one new skill" (e.g. `/triage`)

You don't need a full upgrade. Cherry-pick the skill directory:

```bash
cp -R /path/to/AgenticDevelopmentFramework/skeleton/.claude/skills/triage .claude/skills/
```

Skills appear in Claude Code's `/` menu automatically. Check that the skill doesn't depend on
something you don't have yet — `/write-plan`, for example, expects the spec-folder templates.

### "I want the spec-folder templates"

`specs/_templates/` is new. Copy it and `specs/README.md`; keep your existing specs where they are.
If your team customized the old single-file `specs/_template.md`, carry those changes into
`specs/_templates/spec.md` (the multi-perspective sections are the same; the Technical section moved
to `plan.md`), then delete the old template.

Existing filled-in specs are project-owned and unaffected — a legacy spec moves into a folder the next
time it changes.

### "Rules changed but I customized architecture.md"

3-way merge. Example: the framework added a "Module boundaries" section to `architecture.md` and your team added a "Custom: API client patterns" section.

```bash
# Generate the 3-way diff
git show OLD_SHA:skeleton/.claude/rules/architecture.md > /tmp/arch-old.md
diff /tmp/arch-old.md /path/to/AgenticDevelopmentFramework/skeleton/.claude/rules/architecture.md
# Manually paste the new "Module boundaries" section into your project's
# architecture.md, preserving your "Custom: API client patterns" section.
```

If the same heading was edited in both (yours and the framework's), read both and decide — usually the framework version is more current; reapply your local notes underneath.

### "An agent's model changed (Sonnet → Haiku)"

Agents are safe-to-overwrite — accept the new model. The framework's per-agent recommendations are documented in `docs/COST-MODEL.md`. If you previously overrode the model for project-specific reasons, document why in your project's `CLAUDE.md` and re-apply the override after copying.

### "A skill was renamed or removed"

Treat as a deliberate framework decision. Read the commit message. If a skill was removed, your project's references to it (in `CLAUDE.md`, in team docs) need updating. If it was renamed, update references.

## What this guide doesn't cover

- **Automated upgrade tooling** — out of scope. Manual or AI-assisted is the current bar. If the framework adopts a release CLI someday, this guide will be replaced.
- **Releases before v1.0.0** — they have no tags; their SHAs are the version.
- **Breaking-change detection** — read [`CHANGELOG.md`](../CHANGELOG.md) for per-entry upgrade impact, then commit messages between OLD_SHA and NEW_SHA for anything not yet captured there.
- **Forking the framework** — if your team has diverged so far that upgrading is no longer cost-effective, you've effectively forked. Document the divergence and stop tracking upstream.

## See also

- [`SETUP.md`](./SETUP.md) — initial skeleton adoption (the upgrade is the long-tail follow-up to this)
- [`../skeleton/docs/COST-MODEL.md`](../skeleton/docs/COST-MODEL.md) — model recommendations that affect agent frontmatter
- [`../skeleton/docs/MEMORY-STRATEGY.md`](../skeleton/docs/MEMORY-STRATEGY.md) — memory survives upgrades; rules and CLAUDE.md may not
- [`../skeleton/evals/README.md`](../skeleton/evals/README.md) — regression-checking pattern for after an upgrade
