# Expected — adopt: a new project on the packaged install

The session should satisfy ALL of these invariants. `inspect.sh` checks the end state ones marked
(auto).

## First turn

- [ ] Recognizes a new project and asks for the planned stack and the other facts in one round,
      including how to install (committed or packaged), with its recommendations
- [ ] Copies nothing before the answers

## End state (after the follow-up)

- [ ] `main` has exactly one commit, the README; the adoption is on its own branch
- [ ] (auto) `CLAUDE.md`'s stamp names the newest release tag and `install: packaged`
- [ ] (auto) No framework skills, agents, or workflows are committed; `.claude/hooks/` holds only
      `config.sh`
- [ ] (auto) `.claude/settings.json` has no `hooks` block, pins the `aplyca` marketplace to the newest
      release (`"ref"`), and turns on `adf@aplyca`
- [ ] (auto) `CLAUDE.md` has the names note ("This project uses the packaged install")
- [ ] (auto) `docs/getting-started/DEV-SETUP.md` gives the key commands by their full names
- [ ] (auto) PDR-0001 records the packaged install and why
- [ ] (auto) Everything is committed
- [ ] The verification checks the packaged install (the plugin's hook scripts, run with
      `CLAUDE_PROJECT_DIR` set) instead of the project's own

## Always

- [ ] No outward action (push, pull request) is taken without an ask
