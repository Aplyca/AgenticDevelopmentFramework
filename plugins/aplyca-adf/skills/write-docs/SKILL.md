---
name: write-docs
description: Write the pre-implementable user-facing docs an approved spec folder's plan lists (admin guides, API contracts, end-user copy) BEFORE implementation — docs-first — and update them later when implementation shows reality differs. Skips cleanly when the plan lists none. Use after the approval gate, before /aplyca-adf:implement.
argument-hint: "[spec folder, e.g. specs/007-newsletter-signup — or 'update' for update mode]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/write-docs/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Write Docs (Docs-First)

Write the user-facing documentation the plan calls for **before** the code exists. Writing docs first
forces the team to articulate how the feature will be used while that conversation is still cheap.
Docs are **living artifacts**, not frozen contracts: when implementation reveals reality differs,
they are updated deliberately (small fixes by `/aplyca-adf:implement`, larger rewrites by this skill's update mode).

Two modes:
- **First pass (default)** — the Phase 1 doc tasks in `tasks.md`, after the approval gate and before
  any implementation task.
- **Update mode** — re-run during or after implementation when a doc needs a real revision.

## Prerequisites

- The spec folder is approved (`status: approved`) and committed (`spec:`). The documentation plan was
  approved with it — there is no separate doc-plan approval.

## When to skip cleanly

If `plan.md` § Documentation plan lists no pre-implementable docs (or spec § Documentation marks
Pre-implementable as Not applicable), say so, confirm the post-implementable docs are listed for
later, and hand off to `/aplyca-adf:implement`. Don't manufacture docs a feature doesn't need.

Pre-implementable docs typically include admin or operator guides, API contracts (OpenAPI, GraphQL
schemas), end-user help and copy defaults seeded into a CMS, public READMEs or SDK docs, and
architecture sketches for non-trivial features. Post-implementable docs — runbooks with real
metrics, tutorials with real screenshots, troubleshooting from real failures — are not this phase's
job; they're Phase 5 tasks.

## Steps (first pass)

1. **Read the doc plan and its sources:** `plan.md` § Documentation plan (which docs, which audience,
   where they live), the spec — Functional, Design, Documentation, and the sections each doc draws
   on — and `plan.md` § Test strategy: the tests are the precise statement of behavior the docs
   must match. For a change request, focus on the `CR N` section and leave docs for unchanged
   behavior alone.

2. **Read the existing docs** in the same area and match their tone, structure, and depth. Use
   `docs/GLOSSARY.md` terms.

3. **Write each doc** in its planned location:
   - describe behavior using the ACs and the planned tests as the source of truth;
   - for UI or code that doesn't exist yet, describe the expected behavior — never fabricate
     screenshots, sample output, or anything you'd have had to run;
   - cross-reference the spec folder, related ADRs, and related docs.

4. **Validate** — every claim backed by an AC, an edge case, or a planned test; nothing contradicts
   the spec; no implementation details that aren't defined yet; glossary terms used.

5. **Tick the Phase 1 tasks and commit:** `docs: add <audience> docs for <slug>`. Hand off to `/aplyca-adf:implement`.

## Update mode

Use it when implementation has surfaced a meaningful revision — a new section, a substantial
behavior change. For a one-line fix (a renamed field), `/aplyca-adf:implement` folds it into the task's commit.

1. Read the committed docs and what has actually been built (the implementation commits).
2. List what is wrong, missing, or misleading, and present a short **doc-update plan** — which
   sections of which files change, and what gets removed. Wait for approval.
3. Write the updates; commit `docs: update <doc> for <what changed>`.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll write the docs after implementation — it's easier with the code" | Then they describe what was built, not what should be — and they're the first thing skipped. Docs-first is the point. |
| "I'll add sample output and screenshots to make it better" | Fabricated examples are wrong the moment implementation differs. Describe behavior; real examples come in the backfill. |
| "The spec lists an admin guide, but I'll also write a runbook" | Runbooks need production reality — they're post-implementable. Stick to the plan. |
| "This feature is small, I'll skip the docs" | The plan decides, not the skill. If it lists pre-implementable docs, write them; if not, skip cleanly. |
| "I'll keep the docs vague — implementation will fill in the details" | Docs drive implementation thinking; vagueness defeats that. Match the tests' precision. |
| "The spec is missing an audience — I'll add the doc anyway" | Scope changes go through the spec and plan first. Don't extend scope silently. |

## Red flags (stop and reassess)

- The plan lists no pre-implementable docs but you're about to write one.
- A doc describes internal architecture or code paths — that belongs in `plan.md`, an ADR, or `docs/reference/`.
- A doc describes a UI element or behavior no AC or planned test covers — the spec is missing an AC, or you're speculating.
- More than ~3 doc files for one feature.

## Verification

- [ ] Every pre-implementable doc in the plan exists in its planned location
- [ ] Every claim is backed by an AC, an edge case, or a planned test
- [ ] Nothing describes implementation details that don't exist yet; nothing is fabricated
- [ ] Terminology matches `docs/GLOSSARY.md`; tone and structure match existing docs
- [ ] Phase 1 tasks are ticked and the docs are committed with `docs:` before any implementation commit

## Principles

- Docs drive implementation thinking; write them before the code.
- Docs are living artifacts; update them when reality moves — never let them go stale.
- Source every claim from the spec and the planned tests, not imagination.
- Skip cleanly when there's nothing to write.
