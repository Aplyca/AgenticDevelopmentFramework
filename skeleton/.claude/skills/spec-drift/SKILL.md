---
name: spec-drift
description: Detect drift between a committed spec folder (spec, plan, tasks) and the current code, tests, and docs. Reports divergences without fixing them. Run periodically (e.g., monthly per spec area) to catch silent decay after a spec has aged through many pull requests.
argument-hint: "[spec folder | --all | --area <path>]"
---

# Spec Drift Detection (Read-Only Audit)

Compare a committed spec folder against the current state of the code, tests, and committed user-facing docs. Report divergences. Do NOT fix them — drift detection is an audit; remediation goes through the change-request workflow (`specs/README.md` § Change requests).

This workflow enforces consistency at *write time* (spec and plan before docs before code). But code evolves through dozens of PRs. Six months later, the spec may no longer accurately describe what ships. This skill catches that decay.

## When to use

- **Periodic audit** — monthly per spec area, or before a significant new feature touches an old spec
- **Before refactoring** — confirm the spec you're working from is current
- **After incident** — if a bug surfaced because the spec was wrong, audit nearby specs for similar drift
- **Onboarding a new team member** — when they ask "is this spec still accurate?"

## When NOT to use

- **During active feature development** — the change-request workflow already amends the spec as part of the change
- **When the change is in flight** — drift detection is for stable code, not work-in-progress
- **For trivial copy changes** — cost-of-audit exceeds the value

## Modes

| Argument | Behavior |
|---|---|
| `<spec folder>` | Audit a single spec folder (or a legacy single-file spec) |
| `--all` | Audit every spec under `specs/`. Slow — for a parallel sweep, the user can run the `/deep-drift-sweep` workflow. |
| `--area <path>` | Audit specs in a path. Useful when you've reorganized one part of the codebase. |
| (no argument) | Ask the user which spec(s) to audit. |

## Steps

### Phase 1: Read the spec and identify the surface

1. **Read the committed spec folder.** `spec.md` — every section, not just Functional, including every `CR N` section (the latest change request is the current requirement). Pay attention to:
   - Functional ACs (what should be observable), including those tagged `(CR N)` and those struck through
   - Edge cases (what failure modes were promised)
   - Security / Privacy / Accessibility / Performance (testable requirements that may have eroded)
   - Documentation (which doc files were committed)
   - Constraints & prior decisions, and References (ADRs, PDRs, designs)

   Then `plan.md` (architecture, change surface, contracts) and `tasks.md` (the test each task named, and the gate results). A legacy single-file spec has no plan or tasks — rely on its Technical section and the heuristics below.

2. **Identify the implementation surface.** Use these signals:
   - The change surface table in `plan.md` — the files the feature was built in
   - The tests named on each task in `tasks.md`
   - Doc file paths from the Documentation section
   - For legacy specs: the Technical section, and test files added near the spec's commit date (`git log --diff-filter=A -- e2e/ tests/ '**/*.test.*' '**/*.spec.*'`)
   - Heuristics: the slug or feature name in file, component, and route names

3. **Read the current state of those files.** Use the smallest set that gives you the picture.

4. **Read the related tests and docs.** Same surface as above.

### Phase 2: Compare and report

5. **Walk the spec against reality.** For each filled section:
   - **Functional ACs**: does each AC have a corresponding test? Does the test still assert what the AC says? Does the code make the test pass in the way the AC describes?
   - **Edge cases**: are they all still tested?
   - **Security / Privacy / Accessibility / Performance**: are the testable requirements still enforced? Is the rate limit still 10/min, or did someone change it without updating the spec?
   - **Documentation**: do the committed admin guides still describe what the code actually does? Has marketing copy in CMS diverged from documented defaults?
   - **Plan** (`plan.md`): are the architecture, integrations, and contracts still as described? Did someone swap the rate-limit store for an in-memory cache without updating the plan? Has the feature spread far beyond its change surface?
   - **Out of scope**: did anything from the out-of-scope list get implemented anyway? (Scope creep that bypassed spec update.)

6. **Categorize each divergence:**
   - **CONTRADICTION** — code does something the spec explicitly forbids or contradicts (highest severity)
   - **DRIFT** — code does something the spec doesn't address; spec is silent on real behavior (needs spec update)
   - **MISSING** — spec promises something but the code/test no longer implements/verifies it (regression risk)
   - **STALE REFERENCE** — spec references a file / module / integration that no longer exists or has been renamed
   - **DOC MISMATCH** — committed docs describe behavior that doesn't match current implementation

7. **Present the drift report.** Structured format:
   ```
   Spec: specs/007-newsletter-signup/ (last spec commit: 2025-11-12, 7 PRs since)

   ✓ AC1 (form renders with Contentful copy) — code matches, test in place
   ✓ AC2 (success message after valid submission) — matches
   ✘ AC3 (inline error for invalid email) — DRIFT
       Spec says: "focus moves to the input"
       Code: focus does not move (commit a1b2c3d removed the focus management
             "for accessibility refactor"; spec was not updated)
       Recommendation: update spec to reflect new behavior, OR restore focus management
   ✘ Edge case "Mailchimp 5xx → retry-able error" — MISSING
       Test was removed in commit d4e5f6g; code still has the path but no test
       Recommendation: restore the test (it's a real edge case)
   ✘ Security: "Rate limit 10 req/IP/min" — CONTRADICTION
       Code: lib/newsletter/rate-limit.ts now uses 30 req/IP/min
       (changed in commit a7b8c9d "increase rate limit per marketing request",
       no spec update)
       Recommendation: spec update required — this is a deliberate change that
       bypassed the change-request workflow

   Summary: 1 CONTRADICTION, 1 DRIFT, 1 MISSING — spec is meaningfully out of date.
   Recommended action: open a spec update PR addressing the three findings.
   ```

8. **Do NOT auto-fix.** This skill reports; it does not modify. The fix goes through the change-request workflow (`specs/README.md` § Change requests): a `CR N` amendment of the spec folder, test changes, and doc updates as needed.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll fix the drift while I'm here" | Drift detection is read-only. Fixing without going through the change-request workflow bypasses the team's review process. Report only. |
| "This drift is minor, I won't report it" | Categorize and report everything. The user decides what's worth acting on. Suppressing findings undermines the audit's purpose. |
| "The spec is wrong, the code is right — I'll mark it 'spec needs update' and move on" | Both possibilities matter. Sometimes the code drifted; sometimes the spec was always aspirational. Surface the divergence; let the user decide which side is "right". |
| "I can't find the implementation surface, I'll skip the audit" | If you can't identify what implements the spec, that's itself a signal — the spec may be too abstract or the code may have moved without updating references. Report THAT as a finding. |
| "I'll batch-audit all specs at once" | `--all` is supported but slow and noisy. Default to one spec at a time so each report is reviewable. |
| "The spec was written by someone else, I'll be deferential and assume the code is the source of truth" | The spec is the source of truth for intent. Code is the source of truth for current behavior. The audit's job is to surface where they disagree, not to take a side. |

## Red flags (stop and reassess)

- More than 10 divergences in one spec → the spec is stale enough that "drift detection" isn't the right tool. Recommend a full change request on the folder instead (`specs/README.md` § Change requests).
- The implementation surface is unclear → spec is too abstract OR code has moved significantly. Surface this as a finding.
- You find yourself wanting to make changes → stop. This skill is read-only. Hand off to `/write-spec` for spec updates.

## Verification

- [ ] Every filled spec section was checked against reality (not just Functional)
- [ ] Findings are categorized (CONTRADICTION / DRIFT / MISSING / STALE / DOC MISMATCH)
- [ ] Each finding includes: spec reference, observed behavior, recommended action
- [ ] No code, tests, or docs were modified
- [ ] Report includes a summary count and a recommended next action

## Principles

- **Read-only.** This skill audits; it does not fix.
- **Source from spec + code + tests + docs.** All four are inputs; divergences between them are the signal.
- **Categorize, don't suppress.** Every divergence is a data point. The user decides what to act on.
- **One spec at a time by default.** Batch mode (`--all`) exists but is slow and noisy.
- **Recommend, don't prescribe.** Each finding has a "recommendation" but the team makes the call (update spec, restore behavior, change tests, etc.).
- **Hand off to the change-request workflow** when the user wants to act on findings — don't try to fix things here.
