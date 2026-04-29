# Static evals — framework structural checks

Structural checks of the framework's own skill / agent / rule / template files (under `skeleton/`). Zero AI invocation, runs in milliseconds, suitable for CI on every PR.

## What's checked

The suite verifies that the framework's contract — the structure each skill / agent / rule / template must have — is preserved across edits.

| Check | Why it matters |
|---|---|
| All skills have YAML frontmatter with `name` and `description` | Required for AI tools to load them |
| User-invocable skills declare `user_invocable: true` | Otherwise they're not callable as `/name` |
| All workflow skills have a `## Steps` or `## Phase` section | Skills without explicit steps drift toward vague guidance |
| TDD-discipline skills (`/write-spec`, `/write-tests`, `/write-docs`, `/implement`) have a `## Rationalizations (do not accept these)` table | Anti-rationalization is the framework's primary defense against agent drift |
| `/write-spec` SKILL references mandatory section enforcement | If removed, the spec model loses its enforcement leg |
| `/implement` SKILL references reading committed docs as design context | If removed, docs-first becomes write-only |
| Spec template has `feature-type` and `personal-data` in frontmatter | These drive conditional-mandatory rules |
| Spec template has Pre-implementable and Post-implementable subsections under Documentation | Required for `/write-docs` to function |
| AGENTS.md references the full workflow including docs phase | Out-of-sync workflow descriptions confuse adopters |
| Commit-prefix table lists all four pre-impl prefixes (`spec:`, `test:`, `docs:`, `feat:`) | Workflow integrity |

## Running

From the framework repo root:

```bash
./evals/static/check-skills.sh
```

Exit 0 if all checks pass, non-zero on any failure. The script prints each check's result with a `✓` or `✘`.

For CI integration:

```yaml
# .github/workflows/evals.yml example
- name: Framework static evals
  run: ./evals/static/check-skills.sh
```

## Adding a check

Each check is a function in `check-skills.sh` that:
1. Returns 0 on pass, non-zero on fail
2. Prints `✓ <description>` on pass or `✘ <description>: <reason>` on fail
3. Is added to the `RUN_CHECKS` array in the script's main section

See the existing checks for examples. Follow the principle in [STRATEGY.md](../STRATEGY.md): one check per assertion, atomic, fast.

## What this catches vs. doesn't catch

**Catches:**
- Someone deletes the rationalization table from `/write-spec`
- Someone breaks the spec template's frontmatter schema
- Someone removes a phase from a numbered workflow list
- Someone forgets to add `/write-docs` to the skill index

**Doesn't catch:**
- Whether the skill, when invoked, actually produces a good output
- Whether the AI rationalizes past the table
- Whether the spec template's instructions match the skill's instructions semantically
- Token cost or runtime regressions

For those, use [dynamic evals](../dynamic/).

## See also

- [Manual checklist](skills.checklist.md) — same checks expressed for human or AI review (when you don't want to run a script)
