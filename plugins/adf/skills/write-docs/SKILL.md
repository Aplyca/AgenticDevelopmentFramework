---
name: write-docs
description: Write the pre-implementable user-facing docs an approved spec folder's plan lists (admin guides, API contracts, end-user copy) BEFORE implementation — docs-first — and update them later when implementation shows reality differs. Skips cleanly when the plan lists none. Use after the approval gate, before /adf:implement. Its external mode writes or updates a guide that lives outside the repository — the tracker's docs, a shared document, an editor guide — from verified facts, in the destination's own voice, and returns it for review.
argument-hint: "[spec folder, e.g. specs/007-newsletter-signup — or 'update' for update mode — or 'external <what> [destination]']"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/write-docs/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Write Docs (Docs-First)

Write the user-facing documentation the plan calls for **before** the code exists. Writing docs first
forces the team to articulate how the feature will be used while that conversation is still cheap.
Docs are **living artifacts**, not frozen contracts: when implementation reveals reality differs,
they are updated deliberately (small fixes by `/adf:implement`, larger rewrites by this skill's update mode).

Three modes:
- **First pass (default)** — the Phase 1 doc tasks in `tasks.md`, after the approval gate and before
  any implementation task.
- **Update mode** — re-run during or after implementation when a doc needs a real revision.
- **External mode** — a guide or page that lives outside the repository, asked for directly. It
  needs no spec folder, and it never publishes.

## Prerequisites

- The spec folder is approved (`status: approved`) and committed (`spec:`). The documentation plan was
  approved with it — there is no separate doc-plan approval.

## When to skip cleanly

If `plan.md` § Documentation plan lists no pre-implementable docs (or spec § Documentation marks
Pre-implementable as Not applicable), say so, confirm the post-implementable docs are listed for
later, and hand off to `/adf:implement`. Don't manufacture docs a feature doesn't need.

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

5. **Tick the Phase 1 tasks and commit:** `docs: add <audience> docs for <slug>`. Hand off to `/adf:implement`.

## Update mode

Use it when implementation has surfaced a meaningful revision — a new section, a substantial
behavior change. For a one-line fix (a renamed field), `/adf:implement` folds it into the task's commit.

1. Read the committed docs and what has actually been built (the implementation commits).
2. List what is wrong, missing, or misleading, and present a short **doc-update plan** — which
   sections of which files change, and what gets removed. Wait for approval.
3. Write the updates; commit `docs: update <doc> for <what changed>`.

## External mode

For a page the repository doesn't hold: an editor guide in the tracker's docs, a client document, a
page in a shared drive. A client message about a delivered task is `/adf:stakeholder-update`'s.

1. **The brief, before anything else:** who reads it (editors in the CMS, client stakeholders,
   developers), what they must be able to do afterwards, and where it lives. The reader sets the
   register: editors get exact on-screen labels and one action per step, no code or internals;
   stakeholders get outcomes and decisions; developers get commands, paths, and constraints. If the
   reader is unclear, ask one question; otherwise state the assumption in one line.
2. **Read the destination as it is** — the whole page and one or two siblings — through the
   project's connected server (`docs/TRACKER-INTEGRATION.md`), or ask the developer to paste it.
   Copy its headings, step style, label formatting, person, and length. Update, don't rewrite:
   keep what is correct, in its order.
3. **List the facts, each with its source:** on-screen labels from the config or content type that
   defines them, numbers and examples from real data, behavior from the code path — confirmed on the
   local environment or preview when it can be. Every existing statement the facts contradict is a
   fix to report.
4. **Write it, then strip the slop** (below).
5. **Return, in this order:** the complete page in the destination's syntax, ready to paste (one
   line per paragraph where the destination turns line breaks into breaks); what changed — added,
   fixed with old and new statement and source, removed with a reason; open questions. Writing to
   the destination needs the developer's yes for that exact page and text.

### Strip the slop

Before returning any doc, in any mode, cut or rewrite:
- throat-clearing and wrap-ups ("This section explains", "In short", "Overall");
- reassurance and selling ("simply", "easily", "seamlessly", "robust", "ensures", "Nothing to
  worry about");
- "not X but Y" contrasts that answer a question nobody asked;
- a bold lead-in on every bullet, groups of three for rhythm, a table for one or two rows, the same
  thing said twice;
- hedges ("may", "might", "generally") on behavior that is known, and mechanism the reader doesn't
  need.

Then read it as its reader: if a sentence can go without them losing anything, delete it.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll write the docs after implementation — it's easier with the code" | Then they describe what was built, not what should be — and they're the first thing skipped. Docs-first is the point. |
| "I'll add sample output and screenshots to make it better" | Fabricated examples are wrong the moment implementation differs. Describe behavior; real examples come in the backfill. |
| "The spec lists an admin guide, but I'll also write a runbook" | Runbooks need production reality — they're post-implementable. Stick to the plan. |
| "This feature is small, I'll skip the docs" | The plan decides, not the skill. If it lists pre-implementable docs, write them; if not, skip cleanly. |
| "I'll keep the docs vague — implementation will fill in the details" | Docs drive implementation thinking; vagueness defeats that. Match the tests' precision. |
| "The spec is missing an audience — I'll add the doc anyway" | Scope changes go through the spec and plan first. Don't extend scope silently. |
| "The guide reads better if I restructure it" (external mode) | The page has readers who know where things are. Fix what's wrong and add what changed; keep the rest. |
| "I know what that button is called" (external mode) | Labels come from the config or content type that defines them. A label from memory sends the editor looking for a button that isn't there. |

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
- [ ] External mode: every fact has its source, the page keeps the destination's structure and voice, and nothing was published without the developer's yes
- [ ] The slop pass ran on every doc

## Principles

- Docs drive implementation thinking; write them before the code.
- Docs are living artifacts; update them when reality moves — never let them go stale.
- Source every claim from the spec and the planned tests, not imagination.
- Skip cleanly when there's nothing to write.
