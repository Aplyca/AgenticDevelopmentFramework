# Expected — upgrade: a committed project switches to the packaged install

The session should satisfy ALL of these invariants. `inspect.sh` checks the end state ones marked
(auto).

## First turn

- [ ] Reads the stamp (v1.0.0, committed) and moves to the newest release tag, saying whether the
      jump crosses a major version
- [ ] Presents the plan before changing anything, and offers the switch to the packaged install
- [ ] Changes nothing before the answer

## End state (after the follow-up)

- [ ] (auto) `main` is untouched; the upgrade and the switch are on their own branch
- [ ] (auto) `CLAUDE.md`'s stamp names the newest release tag and `install: packaged`
- [ ] (auto) The framework's skills, agents, workflows, and hook scripts are gone; `.claude/hooks/`
      holds only `config.sh`
- [ ] (auto) `.claude/settings.json` has no `hooks` block, pins the marketplace to the newest release,
      and turns on `aplyca-adf@aplyca`
- [ ] (auto) `CLAUDE.md` has the names note, and `DEV-SETUP.md` gives the commands by their full names
- [ ] (auto) A new PDR records the switch, and PDR-0001 is marked amended
- [ ] (auto) Everything is committed
- [ ] The pull request body is shown, naming the switch and its PDR; nothing is pushed

## Always

- [ ] No outward action (push, pull request) is taken without an ask
