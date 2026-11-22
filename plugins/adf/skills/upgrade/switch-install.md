# Switch the install — committed to packaged, or back

`/adf:upgrade` reads this once the developer accepts the other install (`SKILL.md` § *What to
offer*; decisions 0016, 0018; `docs/SETUP.md` § Packaged install).

- **Committed → packaged:** remove the skills (a module's `/dispatch` included, when the plugin
  carries it), agents, workflows, hook scripts, module scripts (`ops/agent/` but `worktree.conf`,
  when the plugin carries them as commands), and reference docs the plugin carries — only those
  unchanged since OLD_SHA;
  one the team edited stays, under a name of its own, or goes upstream — and the `hooks` block. An
  agent whose only edit is its `model:` goes too, and its model becomes a row in
  `.claude/rules/claude-code.md` § Agent model overrides
  (the `adf` plugin's `docs/COST-MODEL.md` § Per-agent recommendations, decision 0031). Add
  the pinned marketplace and `adf`, the names note in `.claude/rules/claude-code.md`, the full names in
  `DEV-SETUP.md`'s key commands and the commands' names in `AGENTS.md` § Quick reference
  (`adf-worktree-new`), and `install: packaged` in the stamp, then add the plugin's read
  rule and run `link-reference-docs.py --packaged`, both in Step 5 of
  `<this skill's base directory>/manual.md`. An installed module whose
  `module.json` names another plugin (`adf-dev`, decision 0023) switches the same way: its
  committed skills go, and that plugin is turned on with its read rule.
- **Packaged → committed:**
  write the machinery — `python3 <framework-root>/scripts/build-committed.py <repo> --modules <installed>`,
  which brings the installed modules' skills and the reference docs — copy the modules' scripts and the
  `hooks` block back, remove `install: packaged`, the
  names note, the plugin's read rule, every other `<plugin>@aplyca` (`adf-dev`) with its read rule,
  the `adf:` and `<plugin>:` prefixes in `DEV-SETUP.md`, and the commands' names in `AGENTS.md`
  § Quick reference (`ops/agent/worktree-new.sh` again), and run
  `python3 <framework-root>/scripts/link-reference-docs.py <repo> --committed`.
  Keep `adf` turned on and pinned, for `/adf:upgrade`.
- **Record the switch** — it changes how the team works — as a process decision in the same pull
  request: the next `docs/process/NNNN-<slug>.md` from `docs/process/0000-pdr-template.md`, with its
  row in `docs/process/README.md`. Say why the team switches, what changes for them (the names they
  type, Claude Code only, no cloud sessions — or the reverse), and how to switch back; ask who the
  deciders are. It amends the install chosen at adoption, so mark PDR-0001's status as amended by it.
