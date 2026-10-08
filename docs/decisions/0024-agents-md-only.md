# 0024: No `CLAUDE.md` — Claude Code reads `AGENTS.md`, and its own layer is a rule

- **Status:** accepted
- **Date:** 2026-10-08
- **Amends:** [0016](0016-packaged-install.md) — where the stamp and the packaged names note live

## Context

**Until now, the skeleton's `CLAUDE.md` did four jobs:**

1. **It loaded `AGENTS.md`** through `@AGENTS.md` on its first line. Claude Code used to read only
   `CLAUDE.md`, so the import was what made it see `AGENTS.md`.
2. **It carried the Claude Code layer:** skills, agents, workflows, enforced guardrails, lanes, cost,
   and memory. That's about 85 lines no other tool can use.
3. **Its first line was the stamp** (`Skeleton source: … · modules: … · install: packaged`), read by:
   - the plugin's hooks, to decide whether to act;
   - `/upgrade`, for its baseline;
   - `/dev-env`, for the module list;
   - `/adopt` and the evals.
4. **It held the packaged names note** ("This project uses the packaged install"). Step 0 of every
   plugin skill and agent checks for it.

**Claude Code now reads `AGENTS.md` itself** (code.claude.com/docs/en/memory, checked 2026-10-08):

- **When it reads it:** with no `CLAUDE.md` or `CLAUDE.local.md` in the working directory or any folder
  above it, from v2.1.277, and in every kind of session from v2.1.281.
- **When one exists:** it reads the `CLAUDE.md` files *instead*, and keeping the import never loads
  `AGENTS.md` twice.
- **Nested files:** a subdirectory's `AGENTS.md` loads when Claude opens a file there, unless that
  subdirectory has its own `CLAUDE.md`.
- **Rules:** a `.claude/rules/` file without `paths:` loads in every session, beside `AGENTS.md`.

**This exposed a gap.** The framework tells monorepos to add a nested `AGENTS.md` per module
(`/init-project`). While the root `CLAUDE.md` exists, Claude Code reads only `CLAUDE.md` files, so
by the documentation those nested files never reached Claude Code.

## Decision

1. **No `CLAUDE.md` in the skeleton, and none in an adopted project.** Claude Code reads `AGENTS.md`
   natively.
2. **The Claude Code layer is `.claude/rules/claude-code.md`,** a rule without `paths:`. It loads in
   every Claude Code session, and other tools never read it. The packaged names note goes there too.
3. **The stamp is `AGENTS.md`'s first line,** an HTML comment other tools ignore.
4. **Everything that reads the stamp reads `AGENTS.md` first and `CLAUDE.md` second:** the hooks'
   `_lib.sh`, `/upgrade`, `/dev-env`, `/adopt`, and the install prompt. A project adopted before this
   change keeps working until `/upgrade` moves it.
5. **Step 0 checks "this project's instructions"** for the packaged note, not a named file.
6. **The session-context hook warns** when a `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md`
   sits in the project or a folder above it, since it would silently replace `AGENTS.md`. The warning
   tells the agent to read `AGENTS.md` and the developer what to do. It stays quiet:
   - when a `CLAUDE.md` at the project root still imports `AGENTS.md` (a project not yet migrated);
   - when the developer's user settings load both kinds of file (`claude-md-and-agents-md`).
7. **Claude Code v2.1.281 or later** is the documented minimum.
8. **It ships in v2.0.0,** beside the plugin's rename (0023), so teams migrate once. `/upgrade` moves:
   - the stamp, to `AGENTS.md`;
   - the layer and the team's customizations, to the rule;
   - anything else the team added to `CLAUDE.md`, to the file it belongs in.

   Then it deletes `CLAUDE.md`.

## Consequences

- **Positive:**
  - One instruction file at the root, and no import line whose removal silently drops `AGENTS.md`.
  - Nested `AGENTS.md` files reach Claude Code.
  - The same text loads as before, from two files instead of one, so context cost doesn't change.
- **Negative / cost:**
  - **A stray `CLAUDE.md` or `CLAUDE.local.md` replaces the project's instructions without an error.**
    That covers a developer's own file, a monorepo root's, or one in a parent folder. The fix is a
    user setting a project can't commit; the session-context hook only warns.
  - **The version floor:** a machine or CI image older than v2.1.281 reads no instructions at all.
  - **Every adopted project migrates once,** in v2.0.0.
  - **Not verified at runtime yet:** these follow the documentation and weren't observed in a live
    session.
    - That Claude Code strips HTML comments from an `AGENTS.md` it reads directly, as it does for a
      `CLAUDE.md`; if it doesn't, the stamp and the `CUSTOMIZE` notes cost a little context.
    - That nested `AGENTS.md` files load as described.

## Alternatives considered

- **Keep `CLAUDE.md` with its import** (until now). It works on every version, but the nested
  `AGENTS.md` files don't reach Claude Code, and the import is one line from silently dropping
  `AGENTS.md`. Fixing nested files alone would add a `CLAUDE.md` beside each one.
- **Move the Claude layer into `AGENTS.md`.** Every tool would read instructions only Claude Code can
  follow (`/skills`, `@agents`, hooks, model aliases), and `AGENTS.md` can't take 85 more lines under
  its 200-line limit.
- **Keep a one-line `CLAUDE.md` (`@AGENTS.md`) as a fallback for old versions.** It keeps the
  `CLAUDE.md` mode, and with it the nested-file gap.
- **Ship it in a later major release.** Teams would migrate twice in a row.
