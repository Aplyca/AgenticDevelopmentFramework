# 0019: A packaged project reads the framework's reference docs from the plugin

- **Status:** accepted; amended by [0028](0028-plugins-are-the-source.md) (the plugin's copies are the docs' source, and a committed project's are written from them)
- **Date:** 2026-10-05
- **Amends:** [0016](0016-packaged-install.md) — what a packaged project commits

## Context

Decision 0016 split the skeleton into the project's own files and generic machinery, and counted
every doc as the project's own. Four of them aren't: `COST-MODEL.md`, `MEMORY-STRATEGY.md`,
`SPEC-MODEL.md`, and `MCP-INTEGRATION.md`, about 950 lines. They have no `<!-- CUSTOMIZE -->`
markers, and `/upgrade` already overwrites them verbatim, as "framework reference docs" in its
safe-to-overwrite bucket. A team adopting the packaged install asked why a project copies them at
all. Two other docs, `TRACKER-INTEGRATION.md` and the parallel-agents module's `PARALLEL-AGENTS.md`,
hold the project's settings: which tracker it uses, with its tools and statuses, and what its
worktrees share. They stay in the project.

These readers use the four docs:

- **Skills and agents.** The spec-writer and spec-analyzer agents read the spec model. `/handoff`,
  `/orchestrate`, `/spec-workflow`, and `/cost-report` cite the cost model.
- **The deep-spec-analysis workflow.** Each of its lenses reads the spec model.
- **Claude in a session.** `AGENTS.md`'s "when to read what" table names the docs.
- **People.** `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `specs/README.md`, and the
  spec template link them.

Sessions run headless on 2026-10-05 (Claude Code 2.1.286, Haiku, default permission mode, no user
settings) showed four things about a plugin's own files:

1. **`${CLAUDE_PLUGIN_ROOT}` is filled in for skills and agents.** A plugin skill and a plugin agent
   each opened the path it named in the plugin.
2. **It isn't filled in for workflows.** A workflow's agent got the literal `${CLAUDE_PLUGIN_ROOT}`
   and found the path only by loading one of the plugin's skills. A template literal that named it
   threw, because the variable is undefined.
3. **Reading any file outside the project asks first.** This held for the plugin's `docs/` folder,
   for a skill's own folder, and for the installed copy under `~/.claude/plugins/cache/`. Headless,
   every one of these reads was denied.
4. **A read rule removes the prompt.** With `Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)`
   allowed, the session and a plugin agent both read the installed copy without asking.
5. **A model can take the plugin's path for a project path.** The spec-analyzer agent, on Haiku, was
   told to read four files, three of them in the project. It read `docs/SPEC-MODEL.md` in the project
   instead of the plugin's copy, although its instructions gave the full path. One line at the top of
   its instructions fixed it: the reference docs it names are the plugin's copies, outside the
   project.

## Decision

- **The plugin carries the four reference docs** in its `docs/` folder. `scripts/build-aplyca-adf.sh`
  generates them from `skeleton/docs/`. A packaged project commits none of them.
- **Each component reaches the docs its own way:**
  - **Skills and agents** name the plugin's copy, `${CLAUDE_PLUGIN_ROOT}/docs/<doc>.md`, and open
    with a line that says those copies are outside the project.
  - **The deep-spec-analysis workflow** carries the spec model's text, because Claude Code doesn't
    fill in the path in a workflow script.
  - **A session** gets one line from the plugin's SessionStart hook that names the plugin's docs
    folder.
- **A packaged project commits the read rule**, `Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)`,
  in `permissions.allow`, so the docs open without asking.
- **The project's files link the docs on GitHub, at the release the project pins.** People read
  them there. `scripts/link-reference-docs.py` rewrites the links:
  - `/aplyca-adf:adopt` runs it at adoption.
  - `/aplyca-adf:upgrade` runs it to move the links with the pin, and runs it in reverse on a switch
    to the committed install.
- **The committed install is unchanged.** It keeps the four docs in `docs/`.
- **Customizing the spec model takes the committed install.** It already meant editing
  `/write-spec`, which a packaged project can't do.

## Consequences

- **Positive:**
  - A packaged project commits four fewer files, about 950 lines, and its upgrades skip them.
  - Each release has one copy of each doc, which moves with the pin.
- **Negative / cost:**
  - **A permission rule in every packaged project's settings.** It names Claude Code's cache layout,
    `cache/<marketplace>/<plugin>/<version>/`, which the plugin loading reference documents. When
    `CLAUDE_CODE_PLUGIN_CACHE_DIR` moves the cache, or a session loads the plugin with
    `--plugin-dir`, the rule misses, and Claude asks before reading.
  - **Headless runs need the rule passed in.** A headless run (`claude -p`, CI) never applies the
    project's allow rules, so it passes the rule with `--allowedTools`.
  - **People read the docs on GitHub,** not in their repository.
  - **The workflow's prompts grow.** The plugin's copy of deep-spec-analysis carries about 10 KB of
    spec model. Each lens gets it in its prompt, the same text each lens read before.
  - **One more upgrade step.** A packaged project's upgrades run the link script.

## Alternatives considered

- **Keep the four docs in packaged projects.** Declined: they're generic, never edited, and
  overwritten by every upgrade, the same cost 0016 removed for the machinery.
- **Put each doc's text into every skill and agent that names it**, so nothing is read at runtime.
  Declined for skills and agents: the spec model would be copied into several files, and the three
  docs that are only cited would stay reachable only through the web, which asks too. Kept for the
  workflow, the one place the path can't reach.
- **Ship the docs as a skill's supporting files.** Declined: reading a skill's own folder asks too
  (finding 3).
- **Link the docs on GitHub only,** for Claude as well as people. Declined: Claude would fetch each
  doc through the web, which also asks first and returns a summary of the page.
- **Move `TRACKER-INTEGRATION.md` and `PARALLEL-AGENTS.md` too.** Declined: they hold the project's
  settings. Moving the generic half of `TRACKER-INTEGRATION.md` into the plugin is a separate change.
