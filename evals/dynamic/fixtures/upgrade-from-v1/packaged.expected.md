# Expected — upgrade from v1: a packaged project moves from v1.4.0 to v2.0.0

The session should satisfy ALL of these invariants. `inspect.sh` checks the end state ones marked
(auto).

## First turn

- [ ] Reads the stamp (v1.4.0, packaged) and moves to the newest release tag, saying the jump crosses
      a major version
- [ ] Takes the order to upgrade in from the release's changelog section: the plugin's rename in the
      settings, the read rule, and every name; `CLAUDE.md` and its names note into `AGENTS.md` and
      `.claude/rules/claude-code.md`; and the project's layer
- [ ] Presents the plan before changing anything. It needn't offer the committed install, which fits
      only a team that needs another AI tool or Claude Code's cloud sessions
- [ ] Changes nothing before the answer

## End state (after the follow-up)

- [ ] (auto) `main` is untouched; the upgrade is on its own branch, and everything is committed
- [ ] (auto) `AGENTS.md`'s stamp names the newest release, its commit, and `install: packaged`; no
      `CLAUDE.md` or `GEMINI.md`
- [ ] (auto) `.claude/rules/claude-code.md` holds the Claude Code layer and says the project uses the
      packaged install
- [ ] (auto) The settings: no `hooks` block, the marketplace pinned to the newest release, `adf@aplyca`
      turned on and `aplyca-adf@aplyca` gone, and the read rule for `adf`'s folder
- [ ] (auto) No framework machinery committed; `.claude/hooks/` holds only `config.sh`
- [ ] (auto) No `aplyca-adf:` name is left; `DEV-SETUP.md` names `/adf:triage`
- [ ] (auto) The reference docs are linked at the newest release, none in `docs/`
- [ ] The pull request body is shown, with each developer's steps after the merge: reinstall the
      plugin as `adf@aplyca`, and remove any stray `CLAUDE.md` or `CLAUDE.local.md`. Nothing is pushed

## Always

- [ ] No outward action (push, pull request) is taken without an ask
