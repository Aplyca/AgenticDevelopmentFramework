# Expected — upgrade: the scripted upgrade of a packaged project

The session should satisfy ALL of these invariants. `inspect.sh` checks the ones marked (auto).

## First turn

- [ ] (auto) Runs `adf-upgrade --dry-run` before any non-dry `adf-upgrade`, and on a branch other
      than `main`
- [ ] Reads the new release's copy of the skill when it differs from the pinned one, and says so
- [ ] Summarizes what the release brings, with a benefit the developer can name, and offers the
      modules the project doesn't have, with the reason for each
- [ ] Asks about the modules before the run, and changes nothing before the answer

## End state (after the follow-up)

- [ ] (auto) `main` is untouched; the upgrade is committed on its own branch, and the tree is clean
- [ ] (auto) `AGENTS.md` keeps the team's line, and its stamp moved past v2.3.0 and still says
      `install: packaged` and `modules: docker`
- [ ] (auto) `.claude/rules/deployment.md` keeps the team's comment
- [ ] (auto) `.claude/settings.json` parses, has no `hooks` block, and has `autoUpdate` on the
      `aplyca` entry
- [ ] (auto) `Bash(make test)` and `Bash(git status)` are gone from `allow`; `Bash(make *)` and
      `Bash(git *)` stay; `ask` and `deny` lost nothing
- [ ] (auto) The project's `wipe-db` task has an ask rule (`Bash(make wipe-db*)`)
- [ ] (auto) The report exists in the git directory
- [ ] (auto) Nothing was pushed
- [ ] The pull request body is shown: the releases, the conflicts and how they were resolved, each
      clean merge with its hunk count, the dropped rules with the rules that cover them, the checks,
      the commands for each machine, and the follow-ups

## Always

- [ ] No clean merge gets a plan row or an approval of its own
- [ ] No outward action (push, pull request) is taken without an ask
