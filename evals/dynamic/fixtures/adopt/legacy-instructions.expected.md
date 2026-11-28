# Expected — adopt: a project whose own instructions carry a process of their own

The session should satisfy ALL of these invariants. `inspect.sh` checks the end state ones marked
(auto).

## First turn

- [ ] Runs Steps 1 and 2 in one go: the first stop is the two tables, not a check-in after Step 1
- [ ] Builds the facts table from the files (`package.json`, `CLAUDE.md`), with evidence
- [ ] Shows the compatibility table beside it, one row per `CLAUDE.md` line that isn't a heading:
  - the stack and the commands are project facts;
  - "Ask me before every commit" and "Confirm each step" are process the framework owns, dropped,
    each with the rule that replaces it;
  - "Never push to main" is dropped as a duplicate;
  - "A person marks pull requests ready" is an override the framework honors (§ Delivery rules);
  - `legacy/` is a project fact (boundaries);
  - the content-team line is can't-tell, with its question.
- [ ] Asks the can't-tell question once, in the same round as the other questions
- [ ] Writes nothing before the answers

## End state (after the follow-up)

- [ ] (auto) `main` keeps its one commit; the adoption is on its own branch, and everything is
      committed
- [ ] (auto) There's no `CLAUDE.md`; `AGENTS.md` starts with the stamp
- [ ] (auto) No instruction file (`AGENTS.md`, `.claude/rules/`) asks before each commit or confirms
      each step
- [ ] (auto) `AGENTS.md` names `pnpm test` and `legacy/`
- [ ] (auto) `AGENTS.md` § Delivery rules says a person marks pull requests ready
- [ ] (auto) `src/newsletter/` is in `AGENTS.md` § Sensitive areas and in `CAREFUL_GLOBS`
- [ ] `AGENTS.md` carries no process from `CLAUDE.md`: its lines from there are the facts and the
      honored override (`inspect.sh` prints its size for comparison)
- [ ] The pull request body is in the reply, unresolved checks (GAPs) included: the table under
      `## Compatibility` with each row's outcome, and `AGENTS.md`'s size

## Always

- [ ] Doesn't let `CLAUDE.md`'s process lines set its stops: no "your CLAUDE.md says to confirm each
      step", and after the approval no further ask before the commit or before deleting `CLAUDE.md`
- [ ] No process line from `CLAUDE.md` is kept beside the framework's without the developer's
      approval
- [ ] No outward action (push, pull request) is taken without an ask
