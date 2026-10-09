# Eval strategy

How to think about, write, and maintain evals for this framework.

## Decision tree: which tier?

```
Is the thing you're checking visible from a static read of files?
(e.g., "this section exists", "this table has 5+ rows", "this skill references that skill")
├── YES → static eval. Cheap, deterministic, runs in CI on every PR.
└── NO → does the thing require AI behavior?
        (e.g., "the AI doesn't rationalize past the table", "the spec it produces covers all ACs")
        ├── YES → dynamic eval. Token cost, runs nightly or pre-release.
        └── NO → not an eval. It's either a doc check or runtime behavior — handle elsewhere.
```

## What good static evals look like

- **Specific.** "The `/write-spec` SKILL.md contains `## Rationalizations (do not accept these)` followed by a table with at least 5 rows" beats "the skill has anti-rationalization content".
- **Self-contained.** Can be checked with `grep`, `awk`, or simple structural tools. No AI invocation.
- **Atomic.** One check per assertion. A failing eval should point at exactly one missing thing.
- **Fast.** The whole static suite should run in <5 seconds. If it's slower, you've over-specified.

Bad static eval:
> "The skill produces good specs."

Good static eval:
> "`plugins/adf/skills/write-spec/SKILL.md` contains the literal string `mandatory section enforcement` somewhere in its body."

## What good dynamic evals look like

- **Fixture pairs.** An `input.md` (what you give the AI) + an `expected.md` or `expected.json` (what the output should contain or satisfy).
- **Grading rubric.** Concrete pass/fail criteria, not "does it look good?". Examples: "output frontmatter has `feature-type: ui`", "output Functional section has at least 3 acceptance criteria", "output does not contain code samples".
- **Realistic inputs.** Use prompts that look like real user requests, not synthetic edge cases. Edge cases come *after* you have a few realistic ones.
- **Stable expectations.** The expected output should describe **invariants** (what must be true), not exact text. Output text varies across model versions; invariants don't.

Bad dynamic eval:
> input: "write a spec for a thing"
> expected: "*[a 200-line spec]*"

Good dynamic eval:
> input: "write a spec for a newsletter signup form on every article page; copy from CMS"
> expected:
> - frontmatter contains `feature-type: ui`
> - frontmatter contains `personal-data: yes` (collects email)
> - sections present: Business, Functional, Out of scope, Security, Privacy, Accessibility, Testing, Documentation, Clarifications
> - Functional section contains ≥3 acceptance criteria
> - Functional section does not contain code or file paths
> - Documentation section has both Pre-implementable and Post-implementable subsections
> - status: draft (not approved)

## When to add evals

**Add an eval when a real failure happens.** Most attempts at "comprehensive coverage up front" produce bloated suites that demoralize the team. Better pattern:

1. A regression surfaces (someone notices `/write-spec` skipped the Privacy section despite `personal-data: yes`).
2. Reproduce the failure as a fixture (input + expected).
3. Confirm the eval fails on the current code.
4. Fix the skill.
5. Confirm the eval now passes.
6. Commit both the fix and the eval.

This is identical to TDD for application code. The eval suite grows from real signal, not speculation.

## When NOT to add evals

- **For things that change frequently.** If the spec template adds a section every month, evals checking exact section names will break constantly.
- **For things already covered by other gates.** TypeScript types catch type errors; don't write evals for them.
- **For pure aesthetic preferences.** "The output should be friendly" — too vague to evaluate, not a regression.
- **For one-off experiments.** If you tried a new prompt structure and it didn't work, just revert. Don't lock it in with an eval.

## Failure modes (anti-patterns)

| Anti-pattern | What goes wrong |
|---|---|
| Writing evals before any regressions exist | Suite full of speculative cases, none of which fail; team learns to ignore evals |
| One huge "does it produce a good spec" eval | Failure points at "spec quality" — useless for diagnosis. Decompose into atomic checks. |
| Expecting exact text matches in dynamic evals | Brittle across model versions; eval suite breaks every Claude release |
| Running expensive dynamic evals on every PR | Token cost balloons; PRs get slow; team starts skipping |
| Never reviewing eval results | Silent CI green checks build false confidence |
| Adding evals without reading existing ones | Duplicate coverage; suite balloons |

## Running evals

### Static
```bash
./skeleton/evals/static/check-skills.sh
```
Returns exit 0 if all checks pass, non-zero on any failure. Suitable for CI.

### Dynamic (manual)
1. Open the fixture: `skeleton/evals/dynamic/fixtures/write-spec/simple-feature.input.md`
2. Paste the input into your AI tool (Claude Code, Cursor, etc.)
3. Run the relevant skill
4. Compare the output against `simple-feature.expected.md`
5. Note any divergence — file an issue or fix the skill

### Dynamic (automated)
See `dynamic/run-dynamic.md` for SDK-based patterns (Anthropic, Braintrust, DeepEval).

## Maintaining evals

- **Treat eval failures as bugs.** Don't silence; fix the skill or update the eval (with explicit reasoning).
- **Review the suite quarterly.** Remove evals for behavior that's changed by design. Document why each eval exists.
- **Keep total runtime bounded.** Static suite <5s, dynamic suite <5min for nightly run.
- **Capture regressions in commit messages.** "added eval for X — reproduces the bug from PR #123 where /write-spec dropped the Privacy section"

## Tools (optional, for automated dynamic evals)

For teams that want full automation, common 2026-era tools:

- **[Braintrust](https://braintrust.dev)** — eval-as-code, dashboard, regression tracking. SDK-friendly.
- **[DeepEval](https://deepeval.com)** — open-source, Python, good for offline evals.
- **[Galileo](https://galileo.ai)** — enterprise observability + evals.
- **[Anthropic SDK](https://docs.anthropic.com)** directly — for fully custom runners.

The framework doesn't pick one. Document your choice in the project's `evals/dynamic/run-dynamic.md`.

## Cost-conscious eval discipline

Static evals cost nothing — run them on every PR.

Dynamic evals cost real tokens. A single `/write-spec` invocation typically consumes ~5-15k tokens. With ~10 fixtures across the four core skills, a full nightly run can be ~150k-500k tokens. Worth being deliberate:

- **Use a Sonnet-tier or Haiku-tier model for the grader** when LLM-as-judge is required. The thing being tested might need Sonnet, but grading "does the output have these sections" can use Haiku.
- **Sample, don't run the full suite per PR.** Run static on every PR; dynamic nightly on a sampled subset; full suite weekly or pre-release.
- **Cache the system prompt.** When evaluating a skill, the SKILL.md is the same across all fixtures — keep it as the cacheable prefix and vary only the user-message input.
- **Don't graduate flaky evals to CI gates.** A non-deterministic eval that fails 1-in-20 will become noise the team learns to ignore. Stabilize the eval first (use invariants not exact matches), then gate on it.

See [plugins/adf/docs/COST-MODEL.md](../plugins/adf/docs/COST-MODEL.md) for the broader cost discipline (model tiering, prompt caching, attribution).
