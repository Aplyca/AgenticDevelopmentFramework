# Framework evals

This directory holds evals for the **AI-Assisted Development Framework itself** — fixtures and checkers that verify the framework's skills, agents, rules, and spec template still produce the right behavior.

This is "eating our own dogfood": if the framework promotes evals as a discipline, the framework's own files have to pass them. A skill that loses its anti-rationalization table, a spec template that drops its `feature-type` frontmatter, or an agent description that regresses to the old "use after implementation" wording — these are silent failures that code-style tests can't catch. Evals catch them.

## Why evals exist

The framework's primary artifacts are prompts and instructions (SKILL.md files, rules, the spec template, agent definitions). Editing a single line in `write-spec/SKILL.md` changes how every adopting team's AI behaves. Without evals, regressions are silent:

- Someone removes the mandatory-section enforcement, thinking it's redundant — every spec downstream loses its safety net.
- The spec template loses its `feature-type` field — conditional Accessibility/Privacy logic silently breaks.
- A skill's anti-rationalization table gets weakened — the AI starts rationalizing again.
- Cross-skill references drift (e.g., `/implement` no longer reads committed docs) — the docs-first phase becomes write-only.

**Stanford's 2026 AI Index found 89% of AI agent projects never reach production**, primarily because most teams have no structured testing for agent behavior. Evals are how this framework avoids that fate for itself.

## Two tiers

### Static evals — fast, deterministic, free

Structural checks of skills, agents, workflows, rules, settings, hooks, templates, links, and modules, plus functional tests that feed real tool events into the hooks and run the module scripts in throwaway repositories. Zero AI invocation. Run in seconds. Suitable for CI on every PR.

```bash
./evals/run-evals.sh
```

Every check must pass against the framework, and CI enforces it on every pull request (`.github/workflows/evals.yml`). Any failure is a regression.

See [`static/README.md`](static/README.md) for the full check list.

### Dynamic evals — slow, non-deterministic, real

Fixture-based evals that actually invoke an AI with a prompt and grade the output against invariants. Catches behavior regressions that structure can't catch — like whether the AI rationalizes past the anti-rationalization table, or fills all required spec sections.

Run manually (paste fixture into your AI tool, compare output) or via SDK (Anthropic SDK, Braintrust, DeepEval).

See [`dynamic/README.md`](dynamic/README.md) and [`dynamic/run-dynamic.md`](dynamic/run-dynamic.md).

## CI integration

```yaml
# .github/workflows/evals.yml
name: Framework evals
on: [pull_request, push]
jobs:
  static:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./evals/run-evals.sh
```

If anyone modifies a skill, agent, workflow, rule, hook, template, or module in a way that breaks the structural contract — or a hook stops blocking what it should — the PR fails CI. The discipline is enforced, not just documented.

## When to add a new eval

When a real regression surfaces. **Don't write evals speculatively** — bloated suites get ignored. See [`STRATEGY.md`](STRATEGY.md) for the full discipline.

The growth pattern matches TDD for application code:

1. A regression surfaces (e.g., `/write-spec` skipped the Privacy section despite `personal-data: yes`).
2. Reproduce as a fixture (input + expected invariants).
3. Confirm the eval fails on current code.
4. Fix the skill.
5. Confirm the eval now passes.
6. Commit fix and fixture together.

## Project-side evals (for adopting teams)

These evals are framework-level — they test what *this* framework's files do. Adopting projects don't get evals copied in; they have no fixtures of their own to run.

If your team adopts the framework and wants to add evals for **your own** customizations (project-specific rules, custom skills you wrote, your project's spec patterns), use the patterns documented here as a starting point. The discipline transfers directly: prefer structural checks where possible, write dynamic fixtures only when real regressions surface, keep the suite focused.

## Layout

```
evals/
  README.md            ← this file
  STRATEGY.md          ← when to write static vs dynamic; how to write fixtures
  run-evals.sh         ← top-level runner
  static/
    README.md          ← what each static check covers
    check-skills.sh    ← structural checks (skills, agents, workflows, settings, hooks, templates, links, modules)
    test-hooks.sh      ← functional tests of the guardrail hooks
    test-modules.sh    ← functional tests of the module scripts
    skills.checklist.md ← human / AI-readable checklist (same checks, prose form)
  dynamic/
    README.md
    run-dynamic.md     ← manual + SDK execution patterns
    fixtures/
      write-spec/
      write-tests/
      write-docs/
      implement/
  results/             ← gitignored, where eval run outputs land
```
