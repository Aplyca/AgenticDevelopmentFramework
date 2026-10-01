# Static eval checklist (manual / AI-readable)

The same checks as `check-skills.sh`, expressed as a checklist for when you can't run the scripts —
reviewing the framework in conversation, or having an AI agent verify it without shell access. The
behavioral suites (`test-hooks.sh`, `test-modules.sh`) need a shell; there is no checklist substitute.

## Per skill (every `skeleton/.claude/skills/*` and module skill)

- [ ] YAML frontmatter with `name:` equal to the directory name and a meaningful `description:`
- [ ] Frontmatter keys are hyphenated — no `user_invocable`, `disable_model_invocation`, `allowed_tools`, `argument_hint`
- [ ] Has `## Steps`, `## Phase …`, or `## Workflow …` sections
- [ ] Discipline skills have `## Rationalizations (do not accept these)` with ≥4 rows and `## Verification` with ≥4 checkboxes

Discipline skills: `triage`, `write-spec`, `write-plan`, `write-tests`, `write-docs`, `implement`,
`review`, `commit`, `refactor`, `debug`, `spec-drift`, `orchestrate`, `open-pr`, `stakeholder-update`,
`record-decision`, `context-audit`, `dispatch`.

- [ ] `/open-pr` and `/stakeholder-update` set `disable-model-invocation: true`

## Agents and workflows

- [ ] Each agent's `name:` matches its directory; `model:` is `haiku`, `sonnet`, `opus`, `fable`, `inherit`, or a full ID
- [ ] Each workflow starts with a pure-literal `export const meta = {…}` whose `name` matches the file and that has a `description`; phase titles in `meta` match the `phase` names used; no `Date.now()`, `Math.random()`, or argless `new Date()`

## Settings, hooks, instruction files

- [ ] `settings.json` is valid JSON; `model` is an alias; every hook entry nests `{"type": "command", "command": …}` inside a `hooks` array; no `$CLAUDE_FILE_PATH`; every referenced `.claude/hooks/*.sh` exists and is executable
- [ ] `permissions.ask` covers `git push`, `gh pr create`, `gh pr ready`, `gh pr merge`
- [ ] `CLAUDE.md` has a line that is exactly `@AGENTS.md`, and the `Skeleton source:` stamp
- [ ] `AGENTS.md` covers triage, the approval gate, the change surface, docs first, "watch it fail", change requests, "don't invent requirements", and a Boundaries section — in ≤200 lines
- [ ] `git-workflow.md` lists `spec:`, `test:`, `docs:`, `feat:`, `fix:`, `refactor:`, `chore:`, plus the draft and "only when asked" rules

## Workflow integrity

- [ ] `/write-spec` enforces mandatory sections and has a change-request (`CR N`) mode
- [ ] `/write-plan` holds the approval gate on the change surface
- [ ] `/implement` requires `status: approved`, watches each test fail, reconciles docs, records gate results
- [ ] `/write-docs` documents the skip-cleanly condition
- [ ] `/open-pr` opens drafts and never marks them ready

## Spec scaffold

- [ ] `specs/README.md` and `specs/_templates/{spec,plan,tasks}.md` exist; `specs/_template.md` does not
- [ ] `spec.md` frontmatter has `status`, `feature-type`, `personal-data`, `tracker`, `approvals`, `owners`, `references`
- [ ] `spec.md` has Business, Functional, Out of scope, Security, Testing, Documentation `[REQUIRED]` and Clarifications `[REQUIRED…`; Documentation has Pre- and Post-implementable subsections
- [ ] `plan.md` has Constitution check, Change surface, Test strategy, Documentation plan, Assumptions
- [ ] `tasks.md` describes the red-then-green loop ("watch it fail") and has a Gate results section

## Links and modules

- [ ] Every relative link in `skeleton/` and `modules/*/files/` resolves inside an adopting repo (nothing points at `docs/ONBOARDING.md`, `docs/scenarios/`, `evals/`, or other framework-only paths)
- [ ] Every module has `MODULE.md` and `files/`, and no `files/README.md`

## Reporting

```
✓ <description>
✘ <description>: <reason>
```

A failed check is a regression and blocks merge until the file is fixed — or the check is updated with
explicit reasoning in the commit message because the framework genuinely changed. Eval suites that
drift to match buggy files are worse than none.
