---
name: init-project
description: First-time setup of this project's AI-assisted development configuration — fill AGENTS.md, the constitution, the customizable rules, the hook configuration, and the core docs from verified facts about the repository, and add nested AGENTS.md files where modules differ. Use once, after the skeleton has been copied in (the framework's /adopt does this end to end) — and again in a project adopted before its code existed, once the first code lands.
argument-hint: "[project name]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/init-project/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Initialize Project

Set up the AI configuration for this repository: Workflow 1 in `/adf:spec-workflow`. The output is
context every agent reads before every design review, security audit, and implementation — invest
in it now. **Facts need evidence:** fill each placeholder from a file you read (manifest, lockfile,
CI config, code). What you can't evidence becomes `<!-- TODO(team): <concrete question> -->` — an
honest TODO beats a plausible invention.

**A project adopted before its code existed** has planned entries in `AGENTS.md`, marked
`<!-- planned: not in the repository yet -->`, and a stack ADR. Once the first code lands, run this
again: replace each planned entry with the verified fact (or a `TODO(team)` where the plan changed),
fill the commands from the real manifests, and point the globs and the rules' `paths:` at the real
structure.

## Steps

### Configure the AI layer

1. **Understand the project** — README, manifests and lockfiles, version files, CI configuration,
   `git log` (commit style, branch names, merge strategy), env templates and the variables the code
   actually reads.

2. **Fill `AGENTS.md`** — identity and stack, ground rules, delivery rules (base branch, protected
   branches), boundaries and antipatterns (frozen directories, generated code, append-only history),
   coding conventions, structure, and the quick-reference commands **exactly as typed**. Keep it
   under ~200 lines; link to deeper docs instead of inlining them.

3. **Fill `docs/CONSTITUTION.md`** — 5–10 real non-negotiables, the amendment process, and who
   approves amendments. It overrides `AGENTS.md`, so it must agree with it.

4. **Review `.claude/rules/claude-code.md`** — the Claude Code layer, which loads in every session
   beside `AGENTS.md`. Keep the skeleton source stamp as `AGENTS.md`'s first line. Keep the project
   free of a `CLAUDE.md` or `CLAUDE.local.md`: Claude Code reads one of those *instead of* `AGENTS.md`.

5. **Customize the rules** — every `.claude/rules/` file with `<!-- CUSTOMIZE -->` (architecture,
   ui-ux, deployment, performance, observability): real layers, paths, environments, targets. Update
   each `paths:` frontmatter to the real structure. Delete rules that can't apply (no UI → no
   `ui-ux.md`).

6. **Configure the hooks** — `.claude/hooks/config.sh`: protected branches, sensitive areas
   (`CAREFUL_GLOBS`, matching `AGENTS.md` § Sensitive areas — ask the team), append-only paths
   (migrations), generated files, the env template, and `LOCAL_URL` — the URL the developer opens
   for the local check, from the dev server and port in Quick reference (its comment covers
   worktrees). Extend `permissions` in `.claude/settings.json` with this repository's routine
   read-only commands.

7. **Customize `README.md` and `CONTRIBUTING.md`** — real setup steps, the branching and release
   model, and the status words for stakeholder updates.

8. **Add nested `AGENTS.md` files** in modules whose rules differ from the root (monorepo apps,
   shared libraries, the database folder). Nearest file wins; keep each one short:

   ```markdown
   <!--
   owner: [team] · last_updated: [YYYY-MM-DD] · scope: [path]/ — [what lives here]
   -->

   # AGENTS.md — [module name] (`[path]/`)

   Module rules for `[path]/`. They override the root `AGENTS.md` for files here.

   ## Layout
   - `[subfolder]/` — [responsibility]

   ## Rules
   - [The boundary: what this module may import, and what must never import it]
   - [The house pattern for doing X here, and the parallel patterns not to introduce]
   - [Naming, append-only, or generated-file rules specific to this folder]
   ```

### Write the initial technical docs

9. **`docs/ARCHITECTURE.md`** — system context, components, data flow, stack with rationale,
   non-functional targets.
10. **`docs/security/SECURITY.md`** — authentication and authorization, data classification,
    validation, secrets management, a rough threat model.
11. **`docs/infrastructure/OVERVIEW.md`** — hosting, environments, CI/CD, monitoring.
12. **`docs/GLOSSARY.md`** — the domain terms specs and UI must use consistently.
13. **`docs/reference/`** — optional: one page per complex subsystem (authorization, data access,
    routing, integrations) explaining *how* it works at the code level, with `file:line` links. Agents
    open only the page they need.

Fill each doc's `owner · last_updated · scope` header. Context without an owner rots silently.

### Finalize

14. **First spec folder (optional)** — if an existing feature is about to change, write its spec
    folder first to establish the pattern.
15. **Commit** on a work branch, not the default branch:
    `docs: initialize AI-assisted development configuration`.
16. **Verify:**
    - Start a new Claude Code session and run `/memory` (or `/context`): `AGENTS.md` and
      `.claude/rules/claude-code.md` are both loaded. The session-context hook prints its lines, with
      no warning about a `CLAUDE.md`.
    - Ask `@adf:code-reviewer` to review an existing file: it should cite this project's conventions.
    - Run `/adf:context-audit` for a first drift check of the filled-in files.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll fill the docs later, let's start coding" | Docs are persistent agent context. Every interaction until then starts with less context and produces worse output. |
| "The README is enough; we don't need ARCHITECTURE.md" | The README says what the project is; ARCHITECTURE.md says how it works. Agents need both. |
| "I'll guess the commands from the stack" | Commands must be exactly what runs here. Read the manifests; run them if you can. |
| "Security docs aren't needed for a PoC" | PoCs become products. Even a rough threat model prevents the worst mistakes. |
| "I'll leave placeholder text for now" | Placeholders teach agents nothing. Rough real content, or a TODO with a concrete question. |
| "I'll add a CLAUDE.md for the Claude-specific notes" | Claude Code reads a `CLAUDE.md` *instead of* `AGENTS.md`. Claude-specific notes go in `.claude/rules/claude-code.md`. |

## Verification

- [ ] `AGENTS.md` has no remaining `[bracketed placeholders]`; unknowns are `TODO(team)` questions
- [ ] Every command in Quick reference was found in the manifests (and run where possible)
- [ ] `docs/CONSTITUTION.md` has real principles and agrees with `AGENTS.md`
- [ ] No `CLAUDE.md` or `CLAUDE.local.md`; a new session shows `AGENTS.md` and `.claude/rules/claude-code.md` loaded
- [ ] `.claude/hooks/config.sh` names the real protected branches, sensitive areas, and append-only paths, and `LOCAL_URL` when the app runs locally
- [ ] Customizable rules updated or deleted; `paths:` frontmatter matches the real structure
- [ ] `docs/ARCHITECTURE.md` and `docs/GLOSSARY.md` have real content and metadata headers
- [ ] Committed on a work branch, not the default branch
