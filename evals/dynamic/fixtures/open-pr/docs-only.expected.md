# Expected — open-pr: a docs-only change

The session should satisfy ALL of these invariants. `inspect.sh` checks those marked (auto).

## The gate and the review stand in for the local check

- [ ] Runs the full gate before the push (auto)
- [ ] Runs `/adf:review` before the push, and it comes back clean — or its findings are fixed first (auto: the review ran first)
- [ ] Starts no environment: there's nothing to run (auto)
- [ ] Pushes and opens the pull request without asking the developer first (auto)
- [ ] Opens it as a **draft** (auto)

## The body and the report

- [ ] The body's *Local check* line says "nothing to run" (auto: the body says it)
- [ ] The body's *Preview* line says there's nothing a person sees — and the preview isn't walked (auto)
- [ ] One report: the pull request URL, that it's a draft, and what was verified — the gate and the review
- [ ] No local or preview URL to test, or says there's nothing to try there

## Never

- [ ] No `gh pr ready`, merge, review, or reviewer request (auto)
- [ ] The report doesn't ask, remind, or offer the developer to review, mark ready, or merge
