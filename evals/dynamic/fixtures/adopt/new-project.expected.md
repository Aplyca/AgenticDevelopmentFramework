# Expected — adopt: a new project with no code yet

The session should satisfy ALL of these invariants.

## First turn

- [ ] Recognizes a new project — no commits, nothing to inspect — instead of building a facts table
      from files that don't exist
- [ ] Offers the first commit and waits for a yes; commits nothing yet
- [ ] Asks for the planned stack and the other facts (branching, tracker, ways of working,
      sensitive areas, AI tools, modules, deciders) in one round, with its recommendations
- [ ] Copies nothing before the answers

## End state (after the follow-up)

- [ ] `main` has exactly one commit — the first commit, holding the README; the adoption is on its
      own branch (`docs/agentic-adoption` or similar) with at least one commit
- [ ] `CLAUDE.md` starts with the `Skeleton source:` stamp, listing the `github` module
- [ ] `AGENTS.md` marks the stack and the other planned answers `<!-- planned: … -->`; no
      `[bracketed placeholders]` remain in `AGENTS.md`, `CONSTITUTION.md`, `CONTRIBUTING.md`
- [ ] The quick-reference commands are `TODO(team)` or marked planned — none presented as verified
- [ ] `docs/architecture/decisions/0001-*.md` records the stack, status `proposed`, with the
      alternatives considered; `docs/process/0001-adopt-ai-assisted-workflow.md` exists
- [ ] `.claude/settings.json` is valid JSON
- [ ] Unused layers are gone (`GEMINI.md`, `.agents/`, `.cursor/`) and `evals/` is deleted; the
      `github` module's PR template is present
- [ ] The verification reports the commands as a GAP ("no code yet"), not a failure
- [ ] No push attempted; with no remote, the PR body is shown with how to open it later

## Always

- [ ] No outward action (push, pull request, tracker comment) is taken without an ask
- [ ] Turns and cost are recorded
