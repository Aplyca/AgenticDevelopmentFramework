# Below v2.0.0 — the plugin's old names, `CLAUDE.md`, and `GEMINI.md`

`/adf:upgrade` reads this with `manual.md` when the project is below v2.0.0: its stamp is on
`CLAUDE.md`'s first line, or its settings name `aplyca-framework@aplyca` or `aplyca-adf@aplyca`.
These moves join Step 2 of the manual procedure.

**The plugin's old names.** The plugin was `aplyca-framework` until v1.0.0 and `aplyca-adf` until
v2.0.0 (decision 0023). When the new release is v2.0.0 or later and the project still names an old
one, rename it in this upgrade — everywhere the project names it:

- **`enabledPlugins`:** `adf@aplyca` replaces the old key. Claude Code may already have rewritten it,
  from the marketplace's `renames` map, as an uncommitted change: commit that.
- **The read rule:** `Read(~/.claude/plugins/cache/aplyca/adf/**)` replaces the old folder's rule.
- **The names people type:** `/aplyca-adf:triage` becomes `/adf:triage` and `@aplyca-adf:code-reviewer`
  becomes `@adf:code-reviewer` — in the names note, `DEV-SETUP.md`'s key commands, and any
  other doc of the project's that names them (search for `aplyca-adf:`).

Give the developer the commands for each machine after the merge: `/plugin install adf@aplyca` once
in a session (a marketplace from GitHub doesn't fetch a renamed plugin on its own), then
`claude plugin uninstall aplyca-adf@aplyca --scope project`. Until the change merges, teammates still
on the old name have the old `/upgrade`.

**From `CLAUDE.md` to `AGENTS.md`** (v2.0.0, decision 0024). When the new release's skeleton has no
`CLAUDE.md` and the project has one, Claude Code reads that file instead of `AGENTS.md`. Move it in
this upgrade:

1. **The stamp** moves to `AGENTS.md`'s first line; the restamp in the manual procedure's Step 5
   writes it there.
2. **The Claude Code layer** becomes `.claude/rules/claude-code.md`. Take the new skeleton's copy and
   reapply the project's customizations from its `CLAUDE.md`: the sections match, and the packaged
   names note goes with them. This is a Merge.
3. **Anything else the team added to `CLAUDE.md`:** project facts go to `AGENTS.md`, Claude-specific
   instructions to the rule. Show the developer where each part went.
4. **Delete `CLAUDE.md`.**

Tell the team two things:
- **The version floor:** every machine and CI job needs Claude Code v2.1.281 or later.
- **No `CLAUDE.md` or `CLAUDE.local.md` above the repository or in it.** Each developer moves or
  removes theirs, or sets **Project instructions** to `claude-md-and-agents-md` in `/config`. The
  session-context hook warns until they do.

**No `GEMINI.md`** (v2.0.0, decision 0025). When the new release's skeleton has no `GEMINI.md` and the
project has one:

- **Unchanged since OLD_SHA:** delete it. Antigravity reads `AGENTS.md` natively.
- **Customized:** move what's shared into `AGENTS.md` and what only Antigravity needs into
  `.agents/rules/antigravity.md`, with `trigger: always_on` frontmatter. Show the developer where each
  part went, then delete it.
- **The team uses Gemini CLI:** add the skeleton's `.gemini/settings.json`, which points Gemini CLI at
  `AGENTS.md`, or merge its `context.fileName` into an existing one.
