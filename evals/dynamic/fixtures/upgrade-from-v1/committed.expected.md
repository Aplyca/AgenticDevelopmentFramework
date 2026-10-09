# Expected — upgrade from v1: a committed project moves from v1.4.0 to v2.0.0

The session should satisfy ALL of these invariants. `inspect.sh` checks the end state ones marked
(auto).

## First turn

- [ ] Reads the stamp (v1.4.0, committed) and moves to the newest release tag, saying the jump crosses
      a major version
- [ ] Takes the order to upgrade in from the release's changelog section: the plugin's rename,
      `CLAUDE.md` into `AGENTS.md` and `.claude/rules/claude-code.md`, `GEMINI.md`, the machinery from
      `scripts/build-committed.py`, and the project's layer
- [ ] Presents the plan before changing anything, and offers the other install
- [ ] Changes nothing before the answer

## End state (after the follow-up)

- [ ] (auto) `main` is untouched; the upgrade is on its own branch, and everything is committed
- [ ] (auto) `AGENTS.md`'s stamp names the newest release and its commit; no `CLAUDE.md` or `GEMINI.md`
- [ ] (auto) `.claude/rules/claude-code.md` holds the Claude Code layer
- [ ] (auto) The settings turn on `adf@aplyca`, not `aplyca-adf@aplyca`, pinned to the newest release,
      and still wire the hooks
- [ ] (auto) No `aplyca-adf:` name is left in the project's files
- [ ] (auto) The skills, agents, workflows, hook scripts, and reference docs are the release's, as
      `build-committed.py` writes them
- [ ] (auto) `.gemini/settings.json` points Gemini CLI at `AGENTS.md`
- [ ] The pull request body is shown, with each developer's steps after the merge: reinstall the
      plugin as `adf@aplyca`, and remove any stray `CLAUDE.md` or `CLAUDE.local.md`. Nothing is pushed

## Always

- [ ] No outward action (push, pull request) is taken without an ask
