# Upgrading a target project to a newer skeleton version

How to pull newer framework changes into a target project that adopted an earlier version of the skeleton — without losing your team's customizations.

The framework ships as a copy-in skeleton, not a runtime dependency. There is no `npm update` equivalent. Upgrades are deliberate, file-by-file, and informed by the three-bucket taxonomy below.

## When to upgrade

Upgrade when there is a concrete benefit you can name:

- A new skill or agent you want (e.g., `/spec-drift`, `/orchestrate`)
- A rule update you want enforced across the team
- A spec-template change that improves clarity (e.g., the Mermaid diagrams section)
- A docs improvement your team would reference (e.g., `MEMORY-STRATEGY.md`, `COST-MODEL.md`)

Skip the upgrade when:

- The project is shipping in the next week — defer until after release
- You can't name what you'd gain — "stay current" is not a reason to bust working configuration
- Your customizations are extensive and the merge cost outweighs the benefit — cherry-pick the one or two things you actually want instead of doing a full sync

## Versioning convention

The framework does not use semver. Versions are referenced by **commit SHA + date** of the source repo (`ai-dev-starter-kit`).

To make future upgrades tractable, record the skeleton baseline in your target project. Add a line to the top of your project's `CLAUDE.md`:

```markdown
<!-- Skeleton source: ed3d1a1 (2026-04-29) -->
```

This gives every future upgrade a known baseline to diff against. Update it after each successful upgrade.

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
| `.claude/rules/code-quality.md` | Universal — language-agnostic engineering standards |
| `.claude/rules/testing.md` | Universal — testing discipline |
| `.claude/rules/security.md` | Universal — OWASP-style baseline |
| `.claude/rules/git-workflow.md` | Universal — commit prefixes, branch discipline |
| `docs/SPEC-MODEL.md` | Framework reference doc |
| `docs/COST-MODEL.md` | Framework reference doc |
| `docs/MEMORY-STRATEGY.md` | Framework reference doc |
| `docs/MCP-INTEGRATION.md` | Framework reference doc |
| `docs/GLOSSARY.md` | Framework reference doc |
| `specs/_template.md` | The spec template itself. Your filled-in specs are project-owned (next bucket). |

### Merge required

| Path | Why it needs merging |
|---|---|
| `AGENTS.md` | Project identity (stack, conventions, terminology) — your team filled this in |
| `CLAUDE.md` | Project identity + tool-specific config; may include team-specific notes |
| `GEMINI.md` | Same as CLAUDE.md, for Antigravity |
| `.claude/settings.json` | Hooks, permissions, env vars — team-customized |
| `.claude/rules/architecture.md` | Has `<!-- CUSTOMIZE -->` markers for paths and patterns |
| `.claude/rules/ui-ux.md` | Customize for your UI framework |
| `.claude/rules/deployment.md` | Customize for your infra |
| `.claude/rules/performance.md` | Customize for your perf budget and stack |
| `.claude/rules/observability.md` | Customize for your logging/tracing stack |

### Project-owned

| Path | Notes |
|---|---|
| `specs/<feature>.md` | Your filled-in specs. Never overwritten. |
| `docs/adr/*` | Architecture decision records |
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
git -C /path/to/ai-dev-starter-kit log --oneline OLD_SHA..NEW_SHA
git -C /path/to/ai-dev-starter-kit diff --stat OLD_SHA..NEW_SHA -- skeleton/
```

This is your shopping list. Cross-reference each commit against the three buckets above.

### 3. Branch in the target project

```bash
git checkout -b chore/skeleton-upgrade-<NEW_SHA>
```

### 4. Bucket-by-bucket execution

**Bucket 1 — overwrite**: copy each file from the new skeleton over your project's copy. Don't think hard about these.

```bash
cp -R /path/to/ai-dev-starter-kit/skeleton/.claude/skills/* .claude/skills/
cp -R /path/to/ai-dev-starter-kit/skeleton/.claude/agents/* .claude/agents/
cp /path/to/ai-dev-starter-kit/skeleton/.claude/rules/{code-quality,testing,security,git-workflow}.md .claude/rules/
cp /path/to/ai-dev-starter-kit/skeleton/docs/{SPEC-MODEL,COST-MODEL,MEMORY-STRATEGY,MCP-INTEGRATION,GLOSSARY}.md docs/
```

Inspect the diff for surprise (removed files, renamed files). Adjust if the framework has restructured anything.

**Bucket 2 — 3-way merge**: for each file, you need three versions: the old skeleton's, the new skeleton's, and your project's. Use `git merge-file` or your editor's 3-way merge:

```bash
git show OLD_SHA:skeleton/AGENTS.md > /tmp/agents-old.md
cp /path/to/ai-dev-starter-kit/skeleton/AGENTS.md /tmp/agents-new.md
git merge-file --diff3 -p AGENTS.md /tmp/agents-old.md /tmp/agents-new.md > /tmp/agents-merged.md
```

Resolve conflicts manually. The principle: keep your customizations (project identity, custom paths, team-specific notes), accept structural changes (new sections, reorganized tables, updated wording in framework boilerplate).

**Bucket 3 — leave alone**: no action.

### 5. Verify

If your team has copied the framework's eval pattern into the target project:

```bash
bash evals/static/run.sh
```

Otherwise, do a manual smoke test: invoke a skill that changed (e.g., `/spec-drift` if it's new for you), confirm it runs and references the right project paths.

### 6. Update the baseline

Edit the top of `CLAUDE.md`:

```markdown
<!-- Skeleton source: <NEW_SHA> (<today's date>) -->
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

Framework repo: /path/to/ai-dev-starter-kit
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

### "I just want the new /spec-drift skill"

You don't need a full upgrade. Cherry-pick:

```bash
cp -R /path/to/ai-dev-starter-kit/skeleton/.claude/skills/spec-drift .claude/skills/
```

Add a row to your `CLAUDE.md` skills table referencing it. Done.

### "I want the spec-template Mermaid section"

`specs/_template.md` is in the safe-to-overwrite bucket if your team uses the template unmodified. If you've customized the template, do a 2-way merge: keep your customizations, paste in the new Mermaid section.

Existing filled-in specs are project-owned and unaffected — they don't retroactively get a Mermaid section unless you add one.

### "Rules changed but I customized architecture.md"

3-way merge. Example: the framework added a "Module boundaries" section to `architecture.md` and your team added a "Custom: API client patterns" section.

```bash
# Generate the 3-way diff
git show OLD_SHA:skeleton/.claude/rules/architecture.md > /tmp/arch-old.md
diff /tmp/arch-old.md /path/to/ai-dev-starter-kit/skeleton/.claude/rules/architecture.md
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
- **Semantic versioning** — the framework doesn't use semver yet. SHAs are the version.
- **Breaking-change detection** — read [`CHANGELOG.md`](../CHANGELOG.md) for per-entry upgrade impact, then commit messages between OLD_SHA and NEW_SHA for anything not yet captured there.
- **Forking the framework** — if your team has diverged so far that upgrading is no longer cost-effective, you've effectively forked. Document the divergence and stop tracking upstream.

## See also

- [`SETUP.md`](./SETUP.md) — initial skeleton adoption (the upgrade is the long-tail follow-up to this)
- [`../skeleton/docs/COST-MODEL.md`](../skeleton/docs/COST-MODEL.md) — model recommendations that affect agent frontmatter
- [`../skeleton/docs/MEMORY-STRATEGY.md`](../skeleton/docs/MEMORY-STRATEGY.md) — memory survives upgrades; rules and CLAUDE.md may not
- [`../skeleton/evals/README.md`](../skeleton/evals/README.md) — regression-checking pattern for after an upgrade
