# Static eval checklist (manual / AI-readable)

Same checks as `check-skills.sh`, expressed as a checklist for cases where you can't run the bash script (e.g., reviewing the framework state in conversation, or having an AI agent verify it).

Use this when:
- You're reviewing a PR and want a quick sanity check
- An AI agent needs to verify framework state without shell access
- You want to understand what the bash script enforces, expressed in prose

## Per-skill checks (run for every skill in `.claude/skills/`)

- [ ] **Has YAML frontmatter** — first line is `---`, contains `name:` and `description:`
- [ ] **Has `## Steps` or `## Phase` section** — explicit workflow, not vague guidance
- [ ] **(For TDD-discipline skills only)** Has `## Rationalizations (do not accept these)` table with at least 4 rows of content
- [ ] **(For TDD-discipline skills only)** Has `## Verification` checklist with at least 4 items

TDD-discipline skills: `write-spec`, `write-tests`, `write-docs`, `implement`, `review`, `commit`, `refactor`, `debug`.

## Workflow integrity checks

- [ ] **`/write-spec` references mandatory section enforcement** — refuses to mark approved if required sections are empty
- [ ] **`/implement` reads committed docs as design context** — the docs-first phase has downstream effect
- [ ] **`/implement` includes a doc-reconciliation step** — docs evolve with implementation
- [ ] **`/write-docs` documents the skip-clean condition** — when no pre-impl docs exist, skip cleanly

## Spec template checks

- [ ] **Frontmatter has required fields**: `feature-type`, `personal-data`, `owners`, `references`
- [ ] **All always-required sections present**: Business, Functional, Out of scope, Security, Testing, Documentation, Clarifications (each marked `[REQUIRED]`)
- [ ] **Documentation section has both subsections**: Pre-implementable docs + Post-implementable docs

## Top-level integration checks

- [ ] **`AGENTS.md` feature workflow includes the docs phase** — references `/write-docs` or `docs-first` or "Plan docs"
- [ ] **`git-workflow` rule lists all four pre-impl commit prefixes**: `` `spec:` ``, `` `test:` ``, `` `docs:` ``, `` `feat:` ``
- [ ] **`test-runner` agent description does NOT say "use after implementation"** — that's wrong for TDD; tests come BEFORE implementation

## Reporting failures

If running this manually (not via `check-skills.sh`), report results in the format:

```
✓ <description>
✘ <description>: <reason>
```

A failed check is a regression and should block merge until either the skill/agent/template is fixed OR the eval is updated with explicit reasoning ("we removed the rationalization table from /refactor because the discipline doesn't apply when there's no behavior change").

## When checks are wrong

If you find yourself wanting to delete a check because it's "annoying", first ask:
1. Is the underlying behavior still required by the framework?
2. If yes, fix the failing file, not the check.
3. If no (the framework genuinely changed), update the check AND document the reasoning in the commit message.

Eval suites that drift to match buggy code are worse than no evals.
