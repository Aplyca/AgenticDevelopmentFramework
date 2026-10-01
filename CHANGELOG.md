# Changelog

All notable changes to the AI-Assisted Development Framework. Versions are referenced by **commit SHA + date** — the framework does not use semver.

Adopting projects: see [`docs/UPGRADING.md`](docs/UPGRADING.md) for the procedure to pull these changes into a project that already adopted an earlier skeleton version.

For each entry, **Upgrade impact** classifies the change against the [three-bucket file taxonomy](docs/UPGRADING.md#file-taxonomy-three-buckets):
- **Overwrite** — file is safe to copy verbatim from the new skeleton
- **Merge** — file has customization expectations; reapply your customizations on top
- **Additive** — new file, no existing project version to merge against

## Unreleased

### Field-practices reconciliation (`aplyca-framework` 0.2.0)

Practices proven in client projects — some built on this framework, some grown alongside it — reconciled into the skeleton, generalized for any stack, and tested. The rationale for each decision is in [`docs/decisions/`](docs/decisions/README.md).

#### Fixed — affects every adopting repository
- **Claude Code never loaded `AGENTS.md`.** When a repository has both files, Claude Code reads `CLAUDE.md` *instead of* `AGENTS.md`; the skeleton's `CLAUDE.md` didn't import it, so the workflow, critical rules, and conventions were invisible to Claude Code. `CLAUDE.md` now starts with `@AGENTS.md` (and `GEMINI.md` does the same).
- **Hooks never ran.** `.claude/settings.json` declared hooks as flat `{"matcher", "command"}` entries reading `$CLAUDE_FILE_PATH`; Claude Code requires a nested `hooks` array and passes tool input as JSON on stdin. Replaced with a valid schema and tested scripts.
- **Skill frontmatter `user_invocable` was ignored** (the key is `user-invocable`; unknown keys are silently dropped). Removed; outward-facing skills use `disable-model-invocation: true`.
- **Stray test text** committed into `specs/_template.md` (commit `719f27b`) is gone with the new templates.
- **Links that break in adopting repos** — the skeleton pointed at framework-only docs (`docs/ONBOARDING.md`, `docs/scenarios/`, `evals/STRATEGY.md`) and at example files that don't exist. Fixed, and a static check now fails on any such link.
- `permissions.allow` contained `Bash(git branch:*)`, which also auto-approved `git branch -D`. Removed.
- The skeleton's `CONTRIBUTING.md` sent contributors to `CLAUDE.md` for project rules (now `AGENTS.md`); `/init-project` had duplicate step numbers.
- The reference MCP server in `docs/MCP-INTEGRATION.md` misread its own URIs (`specs` parses as the URL host, so every path segment was off by one) and cut sections with `\Z`, which JavaScript treats as a literal `Z`. Rewritten for spec folders and legacy specs, and the helpers were tested.

#### Added
- **Spec folders** — `specs/README.md` (the process: when a spec is needed, flow, granularity, status, change requests) and `specs/_templates/{spec,plan,tasks}.md`, replacing `specs/_template.md`. A change request appends a `CR N` part to each file, its tasks numbered from `T<N>00` ([0001](docs/decisions/0001-spec-folders-as-record-of-intent.md)).
- **Skills:** `/triage` ([0004](docs/decisions/0004-triage-before-setup.md)), `/write-plan` with the approval gate ([0002](docs/decisions/0002-one-approval-gate-on-the-change-surface.md)), `/open-pr` and `/client-update` (the client-facing update, generalized from a field-proven skill — links, CMS entries, and statuses are project settings in `docs/TRACKER-INTEGRATION.md`) ([0005](docs/decisions/0005-outward-actions-and-draft-prs.md)), `/record-decision` ([0007](docs/decisions/0007-process-decision-records.md)), `/context-audit`.
- **Agent:** `@spec-analyzer` — adversarial, read-only analysis of a spec folder before the gate.
- **Dynamic workflows** (`.claude/workflows/`): `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep` — fan-out with independent verification of every finding.
- **Guardrail hooks** (`.claude/hooks/`): `session-context.sh` (branch, worktree role, and the spec folder the branch belongs to — change-request branches included), `guard-git.sh`, `protect-paths.sh`, `check-env-declared.sh`, with project values in `config.sh` ([0006](docs/decisions/0006-guardrails-as-configuration.md)). `permissions.ask` on pushes and pull-request actions; `permissions.deny` on reading `.env` files.
- **Docs:** `docs/process/` (PDR index and template; records are named `NNNN-<slug>.md`, like ADRs), `docs/reference/` (on-demand, code-level subsystem pages), `docs/TRACKER-INTEGRATION.md` (requirements pipeline, rules for agents, MCP setup with a read-only allowlist).
- **Optional modules** (`modules/`, [0009](docs/decisions/0009-optional-modules.md)): `github` (PR template with traceability and constitution gates, issue forms, secret scan, base-branch policy, `.gitleaks.toml`), `git-hooks` (tool-agnostic `pre-push`), `parallel-agents` (worktree scripts — idempotent create, env seeded from the main checkout, ports reserved under a lock, `--no-start` / `--setup-only` / `--refresh-env` / `--from <tag>`, a warning when reusing a stale branch — plus `/dispatch` and `docs/PARALLEL-AGENTS.md`; [0008](docs/decisions/0008-dispatcher-and-worker-worktrees.md)).
- **Framework decision records** — `docs/decisions/0001`–`0010`.
- **Evals:** `evals/static/test-hooks.sh` and `test-modules.sh` (functional tests in throwaway repositories); `check-skills.sh` now also checks agents, workflows, the settings and hook schema, the `@AGENTS.md` import, the spec templates, links, and modules.

#### Changed
- **The feature workflow:** triage → spec → plan and tasks → **one approval gate on scope, change surface, and assumptions** → `spec:` commit → docs first → **one red → green cycle and one commit per task** → gate results recorded in `tasks.md` → review → **draft** pull request only when asked ([0002](docs/decisions/0002-one-approval-gate-on-the-change-surface.md), [0003](docs/decisions/0003-tdd-at-task-granularity.md), [0005](docs/decisions/0005-outward-actions-and-draft-prs.md)). Change requests amend the same spec folder (`CR N`) on a fresh branch named after the feature and the change (`feat/newsletter-signup-topics`); hotfixes that changed behavior are backfilled the same way.
- **`AGENTS.md`** restructured: ground rules (constitution precedence, never invent requirements, nothing outward unasked), how work flows, requirements & traceability, delivery rules, boundaries & antipatterns, the comments rule. **`CLAUDE.md`** rewritten around the import, skills/agents/workflows, and the table of enforced guardrails.
- **Skills updated:** `write-spec` (folders, change-request mode; approval moved to the gate), `write-tests` (task, acceptance, and standalone modes), `write-docs` (driven by the plan's documentation plan), `implement` (per-task loop, change-surface discipline, gate results, then `status: implemented`), `review` (change surface, constitution, evidence, comments rule, PR vs diff), `refactor` (characterization tests proven able to fail, a step plan with its file list, one `refactor:` commit per green step, an ADR for lasting structural decisions), `commit`, `spec-workflow`, `spec-drift`, `orchestrate`, `init-project`, `debug`.
- **Agents updated** for spec folders; `security-reviewer` checks authorization loosening; `test-runner` requires red for the right reason and reports evidence.
- **Rules:** `code-quality` gains "Comments — write almost none" and "types are load-bearing"; `git-workflow` covers per-task commits (the docs-first tasks share one; test-only tasks are proven able to fail), where the pull-request link and gate results are committed, `<type>/<slug>` branches, outward actions, drafts, "CI is a signal; review is the gate"; `testing` covers red-then-green per task and evidence.
- **Templates:** `CONSTITUTION.md` (field-proven example principles, precedence, amendment via PDR and never in the PR that benefits), `CONTRIBUTING.md` (two branching models, draft PRs, status vocabulary, what's enforced), `SPEC-MODEL.md` (folders; the Technical section moves to `plan.md`), `COST-MODEL.md` (aliases, current models and prices, workflow cost), `MEMORY-STRATEGY.md` (new layers), `DEV-SETUP.md` (one command surface), `.claudeignore` (`.claude/worktrees/`), Cursor rules, `GEMINI.md`.
- **Default model** is the alias `"sonnet"` — shipped in the model-aliases entry below; [0010](docs/decisions/0010-model-aliases.md) records why.
- **Plugin 0.2.0:** `/adopt` can register the marketplace for the whole team (`extraKnownMarketplaces`, in the object form Claude Code expects — a static check rejects the array form), offers modules, discovers the branching model and tracker, configures the hooks, records PDR-0001, and verifies hooks and the import; it can add modules to an adopted repo. `/upgrade` handles modules, the new buckets, and changelog migration steps.
- **Framework docs:** README (install and update steps, a workflow per situation), SETUP, UPGRADING, ONBOARDING, SKILLS-REFERENCE, AGENTS-REFERENCE, worked examples (now a spec folder and a change request), and scenarios (new: change request, answer-only task, parallel agents).

#### Removed
- `skeleton/specs/_template.md` (replaced by `specs/_templates/`).
- `docs/scenarios/modifying-existing-feature.md` (replaced by `change-request.md`); the examples' separate test, doc, and implementation plans (folded into `plan.md` and `tasks.md`).

#### Upgrade impact
- **Migration — do these even if you skip everything else:**
  1. Add `@AGENTS.md` as the first instruction of `CLAUDE.md` (below the `Skeleton source` comment). Start a new session and confirm with `/memory` that both files load.
  2. Replace any flat hook entry in `.claude/settings.json` with the nested `{"matcher": …, "hooks": [{"type": "command", "command": …}]}` form. Copy `.claude/hooks/`, set `config.sh`, and port custom hooks to read the event from stdin (`tool_input.file_path`, `tool_input.command`) and exit 2 to block or report.
  3. Remove `user_invocable:` from custom skills (use `user-invocable` / `disable-model-invocation`).
- **Overwrite:** all skills (six new), all agents (`spec-analyzer` new), `.claude/workflows/` (new), hook scripts (new), `.claude/rules/{code-quality,git-workflow,testing}.md`, `.cursor/rules/*`, `docs/SPEC-MODEL.md`, `docs/COST-MODEL.md`, `docs/MEMORY-STRATEGY.md`, `docs/process/0000-pdr-template.md`, `specs/_templates/` (new).
- **Merge:** `AGENTS.md` (restructured — move your critical rules into Ground rules, add Boundaries & antipatterns, keep identity, conventions, structure, commands), `CLAUDE.md` (rewritten — keep your project name and stamp, add the import), `GEMINI.md`, `CONTRIBUTING.md` (keep the branching model you use; add the status vocabulary), `.claude/settings.json` (alias model, `ask`/`deny`, hooks), `.claude/hooks/config.sh` (new — set protected branches, append-only and generated paths), `docs/CONSTITUTION.md` (keep your principles; adopt the precedence and amendment wording), `.claudeignore`, `docs/getting-started/DEV-SETUP.md`, `README.md`.
- **Additive:** `specs/README.md`, `docs/process/README.md`, `docs/reference/README.md`, `docs/TRACKER-INTEGRATION.md`.
- **Specs:** existing single-file specs are untouched; new work uses folders; move a legacy spec into a folder the next time it changes. Delete `specs/_template.md` if you never customized it.
- **Modules:** optional — install with `/adopt` (module mode) or `cp -R modules/<name>/files/.`, and list them in the stamp.
- **Framework-internal:** `docs/decisions/`, `evals/`, the plugin, examples, scenarios, onboarding.

### Changed
- **Version-less model aliases instead of pinned model IDs.** `skeleton/.claude/settings.json` now sets `"model": "sonnet"` (was `claude-sonnet-5`), and `skeleton/CLAUDE.md` explains that the alias follows the latest Sonnet as Claude Code updates. Pinned IDs went stale with every model release, and every adopting project inherited the outdated pin. Agent frontmatter already used `haiku` / `sonnet` and needed no change. `skeleton/docs/COST-MODEL.md`: the tier table lists aliases with their current models (Haiku 4.5, Sonnet 5.5, Opus 5.5); relative costs refreshed to current list prices (1× / 2× / 4× Haiku — previously ~3-5× / ~15×), with notes on the newer tokenizer, cache-read pricing, and `fable` above the tiers; savings claims softened to match the narrower Sonnet-vs-Opus gap; `/model` examples use aliases; `/fast` rewritten (Opus 5.5 / 5 / 4.8, premium pricing, Anthropic API or usage credits only). Framework-internal: `evals/dynamic/run-dynamic.md` keeps a full model ID (the Messages API doesn't accept Claude Code aliases), updated to `claude-sonnet-5-5`, and now reads the first text block since Sonnet 5.5 thinks by default. **Upgrade impact:** Merge for `.claude/settings.json` and `CLAUDE.md` — if your settings pin a model (e.g. `claude-sonnet-5`), switch it to the alias during this upgrade unless your team deliberately pins a version; Overwrite for `docs/COST-MODEL.md`.
- **Repo renamed: `aplyca/ai-dev-starter-kit` → `aplyca/AgenticDevelopmentFramework`** (`aplyca-framework` 0.1.3, framework-internal). GitHub redirects the old URLs (web, clone, push), so existing checkouts, marketplace installs, and adopted repos keep working — but update remotes and re-add the marketplace under the new slug at the next opportunity: `claude plugin marketplace add aplyca/AgenticDevelopmentFramework`. All live references in README, docs, and the plugin (homepage, clone fallbacks, baseline stamp) now use the new slug; historical changelog entries are left as written. Nothing lands in adopted repos — already-stamped `Skeleton source:` lines referencing the old name stay valid.
- **`/adopt` refinements from the first pilot adoption** (`aplyca-framework` 0.1.2, framework-internal): `evals/` is now opt-in — the skill asks whether the team writes custom skills/rules/spec patterns needing automated checks and deletes the scaffold otherwise (the pilot's review dropped it as unused); the skill also prunes `.claudeignore` entries that can't apply to the target stack.
- **`skeleton/.claudeignore` is now self-documenting** — explanatory header covering why the file exists (context quality, secret defense-in-depth, token cost), how it's enforced (advisory patterns; Claude Code's hard read-protection lives in `.claude/settings.json` permissions), and a CUSTOMIZE note to tailor entries per stack. Also added `.claudeignore` to UPGRADING.md's merge-required bucket — teams tailor its entries.

### Fixed
- **Plugin skills' skeleton resolution on installed machines** (`aplyca-framework` 0.1.1) — installed plugins run from a version cache (`~/.claude/plugins/cache/…`), so `${CLAUDE_PLUGIN_ROOT}/../../skeleton` never resolves there (found during the first live `/upgrade` run). Both skills now resolve in order: repo checkout (dev installs) → marketplace checkout (`~/.claude/plugins/marketplaces/<name>/`, the normal installed case, after a `marketplace update`) → fresh clone. `/upgrade`'s clone fallback is now explicitly a full clone — the OLD_SHA → NEW_SHA diff needs history. Framework-internal; nothing lands in adopted repos.

### Added
- **Open-source release readiness** — `LICENSE` (MIT; the README already declared it but no license file existed, so GitHub couldn't detect it), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, a Contributing section in `README.md`, and `.github/workflows/evals.yml` so the static evals actually run on every pull request as the README already claimed. Also removed the last organization-specific wording from the skeleton: `skeleton/docs/COST-MODEL.md` and `skeleton/docs/MEMORY-STRATEGY.md` no longer say "Aplyca-style consultancy". **Upgrade impact:** Overwrite for `docs/COST-MODEL.md` and `docs/MEMORY-STRATEGY.md` (wording only, safe to skip); the root community files are framework-internal and don't land in adopted repos.
- **`skeleton/docs/CONSTITUTION.md`** — non-negotiable principles template (Agentic Development Guide alignment). Short principles list + amendment process; `/write-spec` now gate-checks specs against it before approval (new step in mandatory-section enforcement + verification checklist). Referenced from `AGENTS.md` Critical rules.
- **Context metadata headers** — `<!-- owner · last_updated · scope -->` on every customizable doc template (ARCHITECTURE, GLOSSARY, SECURITY, OVERVIEW, DEV-SETUP, CONSTITUTION), with guidance in SETUP.md: context without an owner rots silently.
- **Nested `AGENTS.md` guidance** — monorepo guidance in `skeleton/AGENTS.md` (Project structure) and SETUP.md: nested files per module, nearest wins.
- **`plugins/aplyca-framework/` + `.claude-plugin/marketplace.json` — the framework repo is now its own Claude Code plugin marketplace.** The plugin carries two skills: `/adopt` (automates `docs/SETUP.md`: inspect the target repo, copy the skeleton, fill placeholders from verified repo facts only, stamp the baseline SHA, deliver an adoption PR) and `/upgrade` (automates `docs/UPGRADING.md`: OLD_SHA → NEW_SHA diff, three-bucket classification, plan-then-execute merge). Install: `claude plugin marketplace add aplyca/ai-dev-starter-kit && claude plugin install aplyca-framework@aplyca`. The plugin contains no framework content — adopted repos still get plain committed files readable by all AI tools; the plugin is installer/updater tooling only.
- `docs/UPGRADING.md` — guide for upgrading a target project to a newer skeleton version. Covers the three-bucket file taxonomy, OLD_SHA → NEW_SHA procedure, AI-assisted upgrade pattern, and four common scenarios.
- `CHANGELOG.md` (this file) — per-commit changelog so upgrade consumers don't have to read git log.
- `<!-- Skeleton source: [SHA] ([date]) -->` template line at the top of `skeleton/CLAUDE.md`. Adopting projects fill in their baseline SHA so future upgrades have a known starting point.
- `skeleton/.claude/settings.json` — wired the default model (`claude-sonnet-4-6`) and a starter `permissions.allow` list of universally-safe read-only commands (git status/diff/log, ls, rg, grep, find). Cuts permission-prompt interruptions and aligns the default with `docs/COST-MODEL.md` instead of relying on each user's tool-level setting.
- `skeleton/CLAUDE.md` — new "Lightweight mode — when to skip the full workflow" section with a per-change-type table (feature vs bug fix vs typo vs refactor vs tooling vs spike) and a perf tip about deleting unused rule files to shrink the auto-loaded prefill.
- `skeleton/docs/COST-MODEL.md` — new "Switching tiers in Claude Code" subsection documenting `/model`, agent `model:` frontmatter, and the `/fast` Opus-4.6-only output-speed toggle.
- `docs/AGENTS-REFERENCE.md` and `docs/SKILLS-REFERENCE.md` (in the framework repo, NOT in `skeleton/docs/`) — full catalogs of the seven shipped agents and thirteen shipped skills. These document framework-defined deliverables, so they live in the framework repo as the single source of truth — adopting projects don't get a local copy. Skills are grouped (workflow phase / reference + setup / quality + analysis); agents include tool access and model tier.

### Changed
- **Model defaults updated to the Claude 5 family** — `skeleton/.claude/settings.json` and `skeleton/CLAUDE.md` now default to `claude-sonnet-5`; `docs/COST-MODEL.md` tier table updated (`claude-sonnet-5`, `claude-opus-5`; Haiku unchanged), `/model` examples updated, `/fast` description corrected (available on Opus 5 and 4.8). Agent frontmatter uses tier aliases (`haiku`/`sonnet`) and needed no change.
- `README.md` — added pointer to `docs/UPGRADING.md` in the Get started section.
- `docs/SETUP.md` — replaced the brief "Updating" paragraph with a pointer to the full upgrading guide.
- `skeleton/CLAUDE.md` cost-model paragraph now points at `.claude/settings.json` as the source of truth for the default model.
- **Scope cleanup — removed framework-author voice from skeleton-targeted files.** Target-project files should not narrate the framework that produced them; that voice belongs in framework docs only. Changes:
  - `skeleton/CLAUDE.md` perf tip — "the framework auto-loads…" → "Claude Code auto-loads…" (the original phrasing was ambiguous since "framework" reads as the project's web framework in a target context).
  - `skeleton/CLAUDE.md` Evals section — removed *"Evals test the framework that produced this skeleton, not your project"* meta-narration; rewritten in target-project voice.
  - `skeleton/evals/README.md` — full rewrite. Was written as a letter from framework authors to adopters (5 references to "the framework"); now reads like a normal target-project README with one closing reference to the source repo as a worked example.
  - `skeleton/.claude/skills/spec-drift/SKILL.md` and `skeleton/.claude/rules/git-workflow.md` — single-word swaps: "The framework uses…" / "The framework enforces…" → "This workflow uses…" / "This workflow enforces…".
- **Prefill trim — moved duplicated content out of the always-loaded files.** `AGENTS.md` and `CLAUDE.md` load on every turn for every adopting project; trimming them compounds across every conversation. Changes:
  - `skeleton/AGENTS.md` — left the full 15-step feature workflow + 4-step hotfix path **intact** (workflow detail is the framework's flagship and stays maximally visible in the always-loaded prefill). Only trimmed the duplicated 6-row commit-prefix table (~9 lines) → 1-line pointer at `.claude/rules/git-workflow.md`, which has the full 7-prefix table with phase semantics. Net: ~9 lines removed.
  - `skeleton/CLAUDE.md` — replaced the "Specialized agents" table (~14 lines) and the "Workflow skills" table (~18 lines) with a single 3-line section pointing at the framework's `AGENTS-REFERENCE.md` and `SKILLS-REFERENCE.md` catalogs. Type `@` or `/` to see the live index; the long-form catalogs live in the framework repo. Kept the "When to use skills vs agents" guidance section (load-bearing for routing). Net: ~26 lines removed.
  - `skeleton/CLAUDE.md` perf tip corrected — earlier version claimed Claude Code auto-loads `.claude/rules/`, which is false (rule bodies load on demand; only Cursor auto-loads `.cursor/rules/*.mdc` by glob). Replaced with accurate guidance that points to the highest-leverage trim targets.
  - Total per-turn skeleton-side prefill reduction: ~38 lines (~17%). No skill/agent descriptions were trimmed (preserves routing quality). The 15-step workflow in `AGENTS.md` was preserved verbatim — explicit choice to favor procedural visibility over marginal cost savings, since the workflow IS the framework's flagship.

### Upgrade impact
- **Merge**: `.claudeignore` — reapply your pruned/extended entries under the new header (newly classified as merge-required).
- **Additive**: `skeleton/docs/CONSTITUTION.md` — drop in and customize.
- **Merge**: `skeleton/AGENTS.md` (constitution pointer + nesting guidance), `skeleton/.claude/settings.json` (model id), `skeleton/CLAUDE.md` (model id), customizable docs (metadata headers).
- **Overwrite**: `skeleton/.claude/skills/write-spec/SKILL.md`, `skeleton/docs/COST-MODEL.md`.
- **Framework-internal (not copied to adopting projects)**: `plugins/aplyca-framework/`, `.claude-plugin/marketplace.json` — installer tooling lives in the framework repo only; nothing lands in adopted repos beyond what the skeleton already defines.
- **Additive**: `docs/UPGRADING.md`, `CHANGELOG.md`. Drop in.
- **Framework-internal (not copied to adopting projects)**: `docs/AGENTS-REFERENCE.md`, `docs/SKILLS-REFERENCE.md` — these live in the framework repo and adopting projects link to them, so there is nothing to merge or copy on upgrade.
- **Merge**: `skeleton/AGENTS.md` (Development workflows + Commit prefixes sections were trimmed to pointers — if your project customized either, condense your customizations the same way and keep the pointers); `skeleton/CLAUDE.md` (new comment line near the top, updated cost-model paragraph, new Lightweight-mode section, scope-cleanup edits, perf tip rewritten, agent/skill tables replaced with pointers — keep your project name and any team-specific notes); `skeleton/.claude/settings.json` (if your project added hooks or extra permissions, merge them on top of the new model + permissions block); `skeleton/evals/README.md` (full rewrite — overwrite unless you customized it).
- **Overwrite**: `skeleton/.claude/skills/spec-drift/SKILL.md` and `skeleton/.claude/rules/git-workflow.md` (single-word phrasing fixes; safe verbatim).
- **Overwrite-with-care**: `README.md` and `docs/SETUP.md` are framework-owned and not part of the skeleton, so adopting projects don't copy these. The change is internal to the framework repo.

## ed3d1a1 — 2026-04-29 — Mermaid diagrams + MCP integration

### Added
- Mermaid subsection in `specs/_template.md` with worked examples for system context, sequence, state, and ER diagrams.
- `skeleton/docs/MCP-INTEGRATION.md` — when to set up an MCP server, what to expose, reference TypeScript implementation, wiring instructions for Claude Code / Cursor / Antigravity.

### Upgrade impact
- **Overwrite**: `skeleton/docs/MCP-INTEGRATION.md` (new file).
- **Merge**: `specs/_template.md` if your team has customized the template; otherwise overwrite.
- Existing filled-in specs are project-owned and unaffected.

## 6020538 — 2026-04-29 — `/orchestrate` skill

### Added
- `skeleton/.claude/skills/orchestrate/` — dispatches multiple specialized agents in parallel for review or investigation. Built-in task types: `review`, `investigate`, `pre-commit`, `custom`.

### Notes
- Explicitly does NOT auto-progress through workflow phases — preserves the plan-then-execute discipline.
- More expensive than `/review`; use only for high-stakes diffs or multi-angle exploration.

### Upgrade impact
- **Overwrite**: skill directory.
- **Merge**: `skeleton/CLAUDE.md` skills table — add a row for `/orchestrate`.

## 348cc2d — 2026-04-29 — Memory strategy doc

### Added
- `skeleton/docs/MEMORY-STRATEGY.md` — documents the six persistence layers (`AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, specs, ADRs, persistent memory) and a decision tree for where any given fact belongs. Includes consultancy-specific guidance for per-client vs cross-client memory.

### Upgrade impact
- **Overwrite**: new file.

## a1c5736 — 2026-04-28 — `/spec-drift` skill

### Added
- `skeleton/.claude/skills/spec-drift/` — read-only audit that detects divergences between a committed spec and the current code, tests, and docs. Reports findings categorized by severity; does not fix.
- Recommended cadence: monthly per spec area.

### Upgrade impact
- **Overwrite**: skill directory.
- **Merge**: `skeleton/CLAUDE.md` skills table — add a row for `/spec-drift`.

## 4fac0ec — 2026-04-28 — Cost model and model tiering doc

### Added
- `skeleton/docs/COST-MODEL.md` — three-tier model recommendation (Haiku / Sonnet / Opus), per-skill recommendations, per-agent recommendations, prompt-caching strategy, cost attribution patterns for consultancies, tool integrations (Anthropic Console, Helicone, LiteLLM), budget enforcement guidance.

### Changed
- Agent frontmatter `model:` fields adjusted to match recommendations:
  - Haiku: `@code-reviewer`, `@security-reviewer`, `@architect`, `@ux-reviewer`
  - Sonnet: `@spec-writer`, `@test-runner`, `@debugger`

### Upgrade impact
- **Overwrite**: `skeleton/docs/COST-MODEL.md` (new file), all `.claude/agents/*` files (the `model:` field is framework-owned; if your team intentionally overrode it, document the override and re-apply after copying).

## 23f009c — 2026-04-28 — Eval framework for the framework itself

### Added
- Top-level `evals/` directory in the framework repo with static structural checks (bash + grep) and dynamic fixture-based AI-invocation evals.
- Currently 48/48 static checks passing.

### Notes
- Adopting projects do NOT get evals copied in by default. The pattern is documented in `evals/README.md` for teams that author custom skills / rules / spec patterns and want regression coverage.

### Upgrade impact
- **N/A for adopting projects** — framework-internal change. Optionally adopt the pattern for your custom artifacts; see `evals/README.md`.

## 965d253 — 2026-04-28 — Docs-first phase coverage in onboarding, examples, Antigravity guide

### Fixed
- Onboarding, worked examples, and Antigravity (`GEMINI.md`) guidance now explicitly cover the docs-first phase between tests and implement.

### Upgrade impact
- **Merge**: `skeleton/GEMINI.md` if your team uses Antigravity.
- **Overwrite**: docs/onboarding files.

## 8277b5d — 2026-04-28 — Cursor rules and agents extended to multi-perspective + docs-first

### Changed
- `.cursor/rules/*.mdc` files updated to reflect the multi-perspective spec model and the docs-first phase.

### Upgrade impact
- **Overwrite**: all `.cursor/rules/*.mdc` files.

## 9332f73 — 2026-04-28 — Docs-first delivery as a third discipline

### Added
- `/write-docs` skill — plans and writes pre-implementable user-facing docs (admin guides, API contracts, end-user copy defaults) BEFORE implementation.
- New phase added to the workflow between tests and implement; `/write-docs` skips cleanly when the spec has no pre-implementable docs.
- `docs:` commit prefix added to `git-workflow.md` for the new phase.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/skills/write-docs/`, `skeleton/.claude/rules/git-workflow.md`.
- **Merge**: `skeleton/CLAUDE.md` skills table.

## 2b22837 — 2026-04-27 — Multi-perspective spec model + repositioning

### Added
- Multi-perspective spec model: every spec captures input from all relevant roles (business, functional, security, accessibility, privacy, design, performance, testing, documentation, deployment, etc.) in one document. Mandatory sections enforced before approval.
- `skeleton/docs/SPEC-MODEL.md` — full structure and worked examples.
- `docs/scenarios/` playbooks (modifying-existing-feature, hotfix, refactor, debugging).
- `docs/examples/newsletter-signup/` end-to-end worked example on Next.js + Contentful + Vercel.

### Changed
- Framework repositioned from "starter kit" to "AI-Assisted Development Framework" in all user-facing materials. Repo slug `ai-dev-starter-kit` preserved for URL stability.

### Upgrade impact
- **Overwrite**: `skeleton/docs/SPEC-MODEL.md`, `specs/_template.md` (if unmodified by your team).
- **Merge**: `specs/_template.md` if customized; `AGENTS.md` and `CLAUDE.md` if your team's wording referenced "starter kit".

## 466d205 — 2026-04-26 — Anti-rationalization tables, verification gates, red flags

### Added
- Skills now include explicit anti-rationalization tables (common excuses for skipping a step → why they don't apply), verification gates, and red-flag patterns.

### Upgrade impact
- **Overwrite**: all `skeleton/.claude/skills/*/SKILL.md`.

## cd04fa6 — 2026-04-26 — Explicit plan-then-execute gates

### Added
- `/write-tests` and `/implement` skills now have explicit plan-then-execute gates: the AI presents a plan and waits for approval before writing tests or code.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/skills/write-tests/`, `skeleton/.claude/skills/implement/`.

## c68e165 — 2026-04-26 — TDD by committing tests before implementation

### Changed
- Workflow enforces committing tests before implementation. Tests are the verification contract that defines "done".
- `test:` commit prefix formalized in `git-workflow.md`.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/rules/git-workflow.md`, affected skills.

## e447f90 — 2026-04-26 — Initial release

### Added
- Initial skeleton with 7 specialized AI agents, 11 workflow skills, 9 engineering standards (4 universal + 5 customizable), spec template, documentation templates, AGENTS.md / CLAUDE.md / GEMINI.md, Cursor compatibility, Antigravity compatibility.

### Upgrade impact
- **N/A** — this is the baseline.

## See also

- [`docs/UPGRADING.md`](docs/UPGRADING.md) — how to apply these changes to an existing project
- [`docs/SETUP.md`](docs/SETUP.md) — initial adoption
- [`README.md`](README.md) — what's in the skeleton
