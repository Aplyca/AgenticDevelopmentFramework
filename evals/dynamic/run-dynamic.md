# Running dynamic evals

Patterns for executing the dynamic eval suite. Pick one based on your team's stack.

## Pattern 1 — Manual (zero setup, recommended for starting)

Best for: small teams, occasional eval runs, no CI integration yet.

```
1. Pick a fixture: e.g. fixtures/write-spec/simple-feature.input.md
2. Open your AI tool (Claude Code, Cursor, etc.) with the framework loaded
3. Paste the input prompt
4. Run the skill: /write-spec [the prompt content]
5. Save the AI's output as <case-name>.actual.md (gitignored)
6. Open <case-name>.expected.md and check each invariant against the actual output
7. Record pass/fail for each invariant in a results log
```

Pros: no setup, no API key management, works in any AI tool.
Cons: slow, manual, doesn't scale past ~5 cases.

## Pattern 2 — Anthropic SDK direct (Python)

Best for: teams already using the Anthropic SDK, full control over the runner.

Sketch (not a full implementation — adapt to your project):

```python
# evals/dynamic/runner.py (illustrative)
import anthropic
import re
from pathlib import Path

client = anthropic.Anthropic()

def load_fixture(skill: str, case: str):
    input_path = Path(f"fixtures/{skill}/{case}.input.md")
    expected_path = Path(f"fixtures/{skill}/{case}.expected.md")
    return input_path.read_text(), expected_path.read_text()

def load_skill_prompt(skill: str):
    # Load the SKILL.md as system prompt
    return Path(f"../../.claude/skills/{skill}/SKILL.md").read_text()

def run_case(skill: str, case: str):
    input_text, expected_text = load_fixture(skill, case)
    skill_prompt = load_skill_prompt(skill)

    # The Messages API needs a full model ID; Claude Code aliases like `sonnet` don't work here.
    response = client.messages.create(
        model="claude-sonnet-5-5",
        max_tokens=16000,  # headroom: adaptive thinking is on by default and counts toward max_tokens
        system=skill_prompt,
        messages=[{"role": "user", "content": input_text}],
    )
    # Thinking blocks may precede the answer, so take the first text block, not content[0]
    actual = next((b.text for b in response.content if b.type == "text"), "")

    invariants = parse_invariants(expected_text)
    results = [(inv, check_invariant(actual, inv)) for inv in invariants]
    return actual, results

# parse_invariants: extract the bullet list from expected.md
# check_invariant: regex / contains / structure check based on invariant type
```

Pros: full control, integrates with anything.
Cons: you maintain the runner, the grader, the report.

## Pattern 3 — Braintrust (eval-as-code)

Best for: teams that want a managed dashboard, regression tracking, run history.

```python
# Sketch — see braintrust.dev for current API
import braintrust
from anthropic import Anthropic

eval_dataset = [
    {
        "input": "draft a spec for a newsletter signup form...",
        "expected": ["frontmatter has feature-type: ui", "Functional has ≥3 ACs", ...],
    },
    # ...
]

def task(input):
    return client.messages.create(...).content[0].text

def scorer(output, expected):
    # Score each invariant in expected against output
    return sum(check(output, inv) for inv in expected) / len(expected)

braintrust.Eval("write-spec-evals", dataset=eval_dataset, task=task, scores=[scorer])
```

Pros: dashboard, regression tracking, run history, CI integration out of the box.
Cons: SaaS dependency, vendor lock-in.

## Pattern 4 — DeepEval (Python, open-source)

Best for: teams that want open-source eval tooling with the most popular metrics.

See [deepeval.com](https://deepeval.com) — supports custom metrics, regression suites, CI integration.

## Pattern 5 — Hybrid (recommended for growing teams)

1. **Static evals** in CI on every PR (`./evals/static/check-skills.sh`).
2. **Dynamic evals manually** when touching a skill (developer's responsibility).
3. **Dynamic evals automated nightly** via Braintrust or custom runner — alerts on regression.
4. **Full suite + manual review** before publishing a framework version update.

## Grader strategies

**Deterministic graders** (preferred when possible):
- Regex matches: `output contains 'feature-type: ui'`
- Structural checks: `parse output as YAML and check section headers`
- Count checks: `Functional section has ≥3 numbered items`

**LLM-as-judge graders** (use sparingly — expensive, less reproducible):
- "Does the output follow the multi-perspective spec model? Score 0-5."
- Best for invariants that resist deterministic checks ("the spec doesn't mix WHAT with HOW")
- Use a weaker model (Haiku) for grading to keep costs down

## Reporting

Each run should produce:
- Per-fixture pass/fail
- Per-invariant pass/fail within each fixture
- Total pass rate
- Trends over time (if using Braintrust / similar)

Example output:
```
Dynamic evals — write-spec
  ✓ simple-feature: 8/8 invariants
  ✓ personal-data-feature: 9/9 invariants (Privacy section correctly flagged)
  ✘ ambiguous-requirement: 5/7 invariants
      ✘ AI asked clarifying questions before drafting (expected)
      ✘ Status was set to draft (got 'approved' — REGRESSION)
  Total: 22/24 (91%)
```

## Adding a fixture from a real regression

1. Reproduce the failure in your AI tool.
2. Save the input prompt as `fixtures/<skill>/<case>.input.md`.
3. Save the desired-output invariants as `fixtures/<skill>/<case>.expected.md`.
4. Confirm the eval fails on the current code (the regression is captured).
5. Fix the skill.
6. Re-run; confirm the eval now passes.
7. Commit fix + fixture together. The commit message should reference the regression.
