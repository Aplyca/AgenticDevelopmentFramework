---
name: write-docs
description: Plan and write user-facing documentation BEFORE implementation (docs-first). Use after spec and tests are committed, before /implement. Skips cleanly when the spec has no pre-implementable docs.
user_invocable: true
argument-hint: "[spec name or feature area]"
---

# Write Docs (Docs-First — Plan Then Execute)

Write user-facing documentation from a committed spec's Documentation section. Docs are written first to **drive implementation thinking** — they force the team to articulate how the feature will be used before code starts. They are **living artifacts**, not immutable contracts: when implementation reveals reality differs, docs get updated deliberately (handled by `/implement`).

This skill follows a plan-then-execute pattern: first present a doc plan for approval, then write the docs. The skill has two modes:

- **First-pass (default)** — initial docs written from the spec and committed tests, before implementation
- **Update mode** — re-invoke this skill mid- or post-implementation to refresh docs when reality has moved (use when the change is large enough to deserve a planning step; for small adjustments, the `/implement` skill handles doc reconciliation inline)

## Prerequisites

Before running this skill, both the spec and the tests should already be committed:
- **Spec commit** (`spec:` prefix) — defines what to build, including the Documentation section's pre-implementable doc list
- **Test commit** (`test:` prefix) — defines how to verify it (tests should currently be failing)

## When to skip cleanly

If the spec's Documentation section has no entries under **Pre-implementable docs** (or the only entries are Not applicable / Standard applies), this skill skips with a short message and tells the user to proceed directly to `/implement`. Don't manufacture docs for features that don't need them.

Pre-implementable docs typically include:
- Admin / operator guides (how site administrators use the feature)
- API contracts (OpenAPI, GraphQL schemas, type signatures of public surfaces)
- End-user help / microcopy defaults (often seeded into a CMS)
- Public-facing READMEs / SDK documentation
- Architecture sketches for non-trivial features

Post-implementable docs (NOT this skill's job — backfilled after code):
- Code-level JSDoc / inline comments (come with the code)
- Runbooks with real metrics, dashboards, log examples
- Tutorials with screenshots / exact UI
- Troubleshooting guides built from real failure modes

## Phase 1: Plan

1. **Read the spec — Documentation section + supporting context** — Find the relevant spec in `specs/`. Focus on the Documentation section, but also read Functional, Design (if present), and Technical to understand what each doc audience needs to know.

2. **Read the spec diff** — Run `git diff HEAD~2 HEAD~1 -- specs/` to see what changed since the previous spec commit. For modifications, focus new docs on new/changed behavior. Don't rewrite docs for unchanged behavior.

3. **Read the committed tests** — The tests describe exact, observable behavior. Use them as the ground truth for what the docs need to describe. Tests + spec together define the contract docs must match.

4. **Read existing docs** — Look in `docs/` for existing documentation in the same area. Match the patterns (tone, structure, level of detail). Don't duplicate.

5. **Check if there's anything to do** — If the Documentation section's Pre-implementable subsection is empty or contains only Not applicable / Standard applies, **skip cleanly**:
   - Tell the user there are no pre-implementable docs in this spec.
   - Confirm post-implementable docs are listed (so they're backfilled later).
   - Recommend proceeding to `/implement`.
   - Exit.

6. **Present the doc plan** — Show the user a mapping from doc entries to artifacts:
   ```
   FROM Pre-implementable docs:

   - Admin guide → docs/admin/[feature].md
     Audience: site administrator
     Length: ~300 lines
     Sections: overview, where to edit, field reference, common tasks, troubleshooting
     References: spec ACs 1-3, edge cases for missing fields, security AC for rate limit

   - End-user copy defaults → docs/copy/[feature]-defaults.md
     Audience: end user (via marketing-managed CMS)
     Length: ~50 lines (short copy snippets)
     Note: these are seed values; marketing customizes in Contentful
   ```
   Include: which doc files will be created or modified, audience for each, length estimate, which spec sections / tests each draws from.

7. **Get approval** — Wait for the user to approve the doc plan before writing. Iterate if they want changes.

## Phase 2: Execute

8. **Write the docs** — Follow the approved plan. For each doc:
   - Match the project's existing doc tone and structure
   - Describe behavior using the spec ACs and tests as the source of truth
   - For UI / code that doesn't exist yet, describe expected behavior — don't fabricate screenshots or pretend to have run anything
   - Use the project glossary (see `docs/GLOSSARY.md`) for consistent terminology
   - Cross-reference the spec, related ADRs, related docs

9. **Validate consistency** — After writing, verify:
   - Every claim in the docs is backed by an AC, an edge case, or a test
   - No claim contradicts the spec
   - No claim references implementation details that aren't yet defined (mention behavior, not code paths)
   - Terminology matches the project glossary

10. **Report results** — Show the user: docs written, lengths, ready to commit.

## After docs are committed

The implementation phase (`/implement`) reads the committed docs as additional context — they drive implementation thinking. As implementation proceeds, doc claims that turn out inaccurate (UX changed, edge case surfaced, requirement shifted) get updated deliberately. Updates can land as a separate `docs:` commit before the `feat:` commit (preferred for meaningful changes) or folded into the `feat:` commit body (acceptable for small fixes). The `/implement` skill handles small reconciliations inline; re-invoke this skill (`/write-docs`) when the doc revision is large enough to deserve its own planning pass.

## Update mode (re-invoking after implementation)

When implementation has surfaced a meaningful doc revision (whole new section needed, substantial behavior change to document, etc.), re-invoke this skill. In update mode:

1. Read the existing committed docs for this feature
2. Read the implementation diff (what's actually been built)
3. Identify what's wrong, missing, or misleading in the current docs
4. Present a **doc-update plan**: which sections of which doc files change, what the diff will be, what gets removed
5. Get approval, write the updates, commit with `docs:` prefix referring to the implementation context

For small one-line adjustments (e.g., a renamed field), don't bother with this skill — `/implement` will handle them inline as part of the feat commit.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll write the docs after implementation — it's easier with the code in front of me" | That's not docs-first. Docs written after code describe what was built, not what should be built. They miss the docs-as-contract value, and they often get skipped entirely. |
| "I'll skip the plan and just write the docs" | The plan is the contract. Skipping approval means the user can't catch missing doc audiences or scope mismatches before the docs are drafted. |
| "I'll fabricate screenshots / sample outputs since they make the doc better" | Don't. Fabricated examples become wrong the moment implementation differs. Describe behavior; let the post-impl backfill add real examples. |
| "The spec says 'admin guide' but I'll also write a runbook while I'm here" | Runbooks need real production data — they're post-impl. Stick to what the Pre-implementable section lists. |
| "I'll skip docs for this feature, it's small" | The spec's Documentation section is the source of truth. If it lists pre-impl docs, write them. If it doesn't, skip cleanly per the skip condition above. The skill doesn't decide; the spec does. |
| "I'll write the docs more loosely than the tests describe — the user can read between the lines" | Docs drive implementation thinking. Looseness defeats the point. Match the tests' precision. (Docs can evolve later — but they should start sharp.) |
| "I notice the spec is missing a doc audience that should be there — I'll add it to the docs anyway" | Update the spec first, get approval, then write the doc. Don't extend scope silently. |

## Red flags (stop and reassess)

- Documentation section's Pre-implementable subsection is empty but you're tempted to write docs anyway → skip cleanly. The spec is the contract.
- A doc would describe internal architecture / implementation details → that belongs in the Technical section of the spec or an ADR, not in user-facing docs.
- A doc references a UI element / code path that the tests don't assert on → either the spec is missing an AC, or you're documenting something speculative. Stop and clarify.
- More than ~3 doc files for a single feature → either the feature is genuinely large (verify against spec scope), or you're over-documenting.

## Verification

- [ ] Every entry in the spec's Pre-implementable docs has a corresponding written doc
- [ ] Every claim in each doc is backed by an AC, edge case, or test
- [ ] No doc references implementation details that don't yet exist
- [ ] Terminology matches `docs/GLOSSARY.md`
- [ ] Docs follow existing patterns in `docs/` (tone, structure, length)
- [ ] Cross-references to the spec and related artifacts are present

## Principles

- **Docs drive implementation thinking.** Writing them first forces the team to articulate how the feature will be used before code constrains the conversation.
- **Docs are living artifacts.** Updated when implementation reveals reality differs — never let them go stale.
- **Plan first, then execute** — present the doc plan for approval before writing.
- **Source from spec + tests, not imagination.** If a claim isn't grounded in either, it shouldn't be in the doc.
- **Skip cleanly when there's nothing to do.** Empty Pre-implementable section → no docs to write at this phase.
- **Match the project's voice.** Read existing docs to match tone, structure, and depth.
- For modifications: only write/update docs for new/changed behavior. Existing docs for unchanged behavior stay as-is.
