# Evals

This directory is empty by design. Add evals here only if your team writes **custom skills, custom rules, or project-specific patterns** that need automated verification beyond what unit/integration tests cover.

If everything in `.claude/` is unchanged from what you adopted, there is nothing in here to test — your tests already cover your application code.

## When to add evals

Add evals when at least one of the following is true:

- You wrote a custom skill at `.claude/skills/<name>/SKILL.md` and want to verify its structure (required frontmatter, required sections).
- You wrote a custom rule at `.claude/rules/<name>.md` and want to assert it loads on the right paths.
- You changed or added a hook in `.claude/hooks/` and want a test that feeds it sample events (a tool call as JSON on stdin) and checks it blocks or allows as intended.
- You have a recurring AI-output regression (e.g. specs missing the Security section) and want a fixture that catches it.

If none of these apply, leave this directory empty. Bloated eval suites get ignored.

## Two-tier pattern

1. **Static checks** — bash + grep, run in CI on every PR. Verify that custom artifacts have the structure you expect (frontmatter keys, required headings, no forbidden phrases). Fast, deterministic, free.
2. **Dynamic fixtures** — invoke the AI with a known input and assert properties of the output. Run nightly or pre-release, not per-PR. Slower and costs tokens, so reserve for behaviors structural checks can't verify.

## Suggested layout

```
evals/
  static/
    check-skills.sh        # frontmatter + required-section checks for custom skills
    check-rules.sh         # frontmatter + scope checks for custom rules
    run.sh                 # runs all static checks; exit non-zero on failure
  dynamic/
    fixtures/              # input prompts + expected-output assertions
    run.sh                 # invokes the AI and grades outputs
  README.md                # this file
```

## Reference

The AI-Assisted Development Framework that ships this skeleton uses the same two-tier pattern internally to verify its own skills, rules, and spec template. If you want a worked example to copy from, see the `evals/` directory in that source repository.
