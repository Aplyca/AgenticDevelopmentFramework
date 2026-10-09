# 0025: No `GEMINI.md` — Antigravity reads `AGENTS.md`, and Gemini CLI is pointed at it

- **Status:** accepted
- **Date:** 2026-10-08
- **Builds on:** [0024](0024-agents-md-only.md) — one instruction file at the root

## Context

**The skeleton's `GEMINI.md`** (50 lines) had four parts:

- **An `@AGENTS.md` import** on its first line, so Gemini tools loaded `AGENTS.md`.
- **"How work flows here":** a summary of `AGENTS.md`'s workflow, written a second time. It could drift
  from the original, and it cost context in every session.
- **"Antigravity agent structure":** `.agent/rules/`, `.agent/skills/`, `.agent/workflows/`. These are
  now legacy paths: Antigravity uses `.agents/rules/`, and its workflows have moved to skills.
- **A table of docs to read,** which `AGENTS.md` already links.

**What the Gemini tools read now** (checked 2026-10-08):

- **Antigravity 2.0, IDE and CLI** ([antigravity.google/docs/rules](https://antigravity.google/docs/rules)):
  - At each directory level from the file it works on up to the workspace root, it checks `AGENTS.md`,
    `GEMINI.md`, `.agents/AGENTS.md`, `.agents/GEMINI.md`, and `.agents/rules/*.md`.
  - `AGENTS.md` and `GEMINI.md` are always on. Rules are cumulative, so when both exist both seem to
    load.
- **Gemini CLI** ([geminicli.com/docs/cli/gemini-md](https://geminicli.com/docs/cli/gemini-md/)):
  - It reads `GEMINI.md` by default.
  - `context.fileName` in a project's `.gemini/settings.json` names other files to read instead, and
    takes a list.
  - Its docs say Antigravity CLI replaced it for unpaid-tier and Google One users on 2026-06-18.

## Decision

1. **No `GEMINI.md` in the skeleton, and none in an adopted project.** Antigravity reads `AGENTS.md`
   natively, and `GEMINI.md` added nothing `AGENTS.md` lacks.
2. **The skeleton ships `.gemini/settings.json`** with `"context": {"fileName": ["AGENTS.md"]}`, so
   Gemini CLI reads `AGENTS.md` directly. Like `.cursor/`, `/adopt` deletes it when the team doesn't
   use that tool.
3. **Antigravity keeps its skills link.** `.agents/skills` links to `.claude/skills`, created by
   `/adopt`.
4. **What a team wrote only for Antigravity** goes in `.agents/rules/antigravity.md` with
   `trigger: always_on` frontmatter. Antigravity discards a rule there that has no frontmatter.
5. **Migration:**
   - `/adopt` and `/upgrade` move a customized `GEMINI.md` into `AGENTS.md` or that rule, and delete
     it.
   - `/upgrade` deletes an unchanged one.
   - `context-audit` and `deep-context-audit` report one as a finding.
6. **It ships in v2.0.0,** beside 0023 and 0024, so teams migrate once.

## Consequences

- **Positive:**
  - Every tool reads the same one file at the root.
  - The workflow summary can't drift from `AGENTS.md` any more.
  - Antigravity no longer loads a near-copy of `AGENTS.md` beside it.
- **Negative / cost:**
  - **Antigravity still doesn't read `.claude/rules/`,** as before. Its rules need `trigger` and
    `globs` frontmatter, so the path-scoped engineering rules don't reach it.
  - **A team on Gemini CLI has to keep `.gemini/settings.json`.** Delete it and Gemini CLI reads no
    instructions.
  - **Not verified at runtime yet:**
    - Whether Antigravity expanded the old `@AGENTS.md` import, and so loaded `AGENTS.md` twice.
    - Whether a project's `.gemini/settings.json` needs a trusted folder in Gemini CLI.

## Alternatives considered

- **Keep `GEMINI.md`** as an import plus Antigravity notes. Antigravity already reads `AGENTS.md`, so
  the file only repeats it, and its paths had gone stale.
- **A one-line `GEMINI.md` (`@AGENTS.md`) for Gemini CLI.** Antigravity loads it beside `AGENTS.md`
  too, and the settings file reaches Gemini CLI without touching Antigravity.
- **Point Antigravity at `.claude/rules/`.** Its rules need different frontmatter (`trigger`,
  `globs`); a second copy of every rule would drift. Worth its own decision if a team needs it.
