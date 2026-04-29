# Evals (pattern reference)

This directory is intentionally minimal — **the AI-Assisted Development Framework's own evals don't ship into adopting projects**. Evals test the framework itself: its skills, agents, rules, and spec template. Your project doesn't have those framework files to test (you have your project's own files).

## Want to add evals to your project?

If your team writes its own custom skills, custom rules, or has project-specific patterns it wants to verify automatically, the framework's eval pattern transfers directly. Adopt it like this:

1. **Read the framework's eval docs** — `evals/README.md` and `evals/STRATEGY.md` in the framework's source repo. They explain the two-tier model (static structural checks + dynamic AI-invocation fixtures), when to add evals, and what good fixtures look like.
2. **Start with static checks for your custom artifacts.** If you wrote a custom skill at `.claude/skills/my-skill/SKILL.md`, write a bash + grep check that verifies its structure (frontmatter, required sections). Pattern: copy the framework's `evals/static/check-skills.sh` and adapt the checks.
3. **Add dynamic fixtures only when a real regression surfaces.** Don't pre-write coverage. Bloated eval suites get ignored.
4. **Run static checks in CI**, dynamic checks nightly or pre-release.

## Why this directory is empty

If `skeleton/evals/` shipped with fixtures, adopting projects would inherit eval failures the moment the framework releases a new version that changes a skill's structure. Worse, the fixtures wouldn't actually be testing the project — they'd be testing a framework version snapshot. Confusing and unhelpful.

The right shape is: framework owns its evals, projects own theirs. The pattern is portable; the fixtures aren't.

## Reference

- Framework eval implementation: see the framework's source repository, `evals/` directory.
- Eval discipline and anti-patterns: framework's `evals/STRATEGY.md`.
- This file is the only thing that lives in your project's `evals/` directory until you add your own.
