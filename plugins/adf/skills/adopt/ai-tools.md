# The AI tools' own files

`/adf:adopt` reads this at Step 3 when the target already has a `CLAUDE.md` or a `GEMINI.md`, or
the team uses Antigravity.

**An existing `CLAUDE.md`** (decision 0024): Claude Code reads it *instead of* `AGENTS.md`. Sort it by
the compatibility table: its project facts into `AGENTS.md` and its Claude-specific instructions
into `.claude/rules/claude-code.md`, show the developer where each part went, and delete it once they
agree. A team that keeps one makes `@AGENTS.md` its first line.

**An existing `GEMINI.md`** (decision 0025): Antigravity loads it beside `AGENTS.md`. Sort it by the
compatibility table: what's shared into `AGENTS.md` and what only Antigravity needs into
`.agents/rules/antigravity.md` (with `trigger: always_on` frontmatter), show the developer where each
part went, and delete it once they agree.

**Antigravity** reads `AGENTS.md` natively, so there's no `GEMINI.md` (decision 0025). Link its
skills folder to Claude Code's — the framework ships no symlinks:
`mkdir -p .agents && ln -s ../.claude/skills .agents/skills`.
