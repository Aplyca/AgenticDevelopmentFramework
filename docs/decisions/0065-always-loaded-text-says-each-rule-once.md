# 0065: The always-loaded text says each rule once, and a phase's procedure stays in its skill

- **Status:** accepted
- **Date:** 2026-11-02
- **Amends:** [0055](0055-lean-context-and-acting-model-routing.md) — the same principle, applied
  again to the text added since

## Context

[0063](0063-reference-files-and-status-moves-in-the-calling-skill.md) cut the text a task loads and
left the text every call re-reads for a change of its own. That text is about 43.7k characters,
about 11k tokens: `AGENTS.md`, `claude-code.md`, `git-workflow.md` (loaded from the first file
read), and the plugins' skill and agent descriptions.

- **0055 already made these files state rules, not procedures.** Later decisions have added to them,
  and some rules came to be said two or three times:
  - a change request's branch after the merge, in `AGENTS.md` and `git-workflow.md`;
  - the pull-request rules, in `AGENTS.md`, `git-workflow.md`, and `/adf:open-pr`;
  - the commit prefixes, in a section of `AGENTS.md` and the table in `git-workflow.md`;
  - the developer's yes for a stakeholder update, and one task per session, in `AGENTS.md` and
    `claude-code.md`;
  - the browser check on the preview, twice in `AGENTS.md`;
  - "never do silently" beside the boundaries it restates.
- **Some text serves one phase, and its skill says it at the step that needs it:** what to do when
  implementation departs from the plan (`/adf:implement`), the sections of `plan.md`
  (`/adf:write-plan` and the template), and which docs a diff needs.
- **A packaged install pays twice for a reference doc named twice.** Each mention of
  `docs/SPEC-MODEL.md` or `docs/COST-MODEL.md` becomes a link of about 110 characters to the pinned
  release.
- **The text is a small share of the cost.** On adopting projects, the framework's text came to about
  7–10% of the cost, and the median call read about 154k tokens of context. Session length and the
  model are the bigger levers.

## Decision

- **Each rule is said once in the always-loaded text,** in the file whose readers need it:
  `AGENTS.md` for every tool, `claude-code.md` for Claude Code alone, `git-workflow.md` for the git
  detail `AGENTS.md` points to.

  | Rule | Was in | Now in |
  |---|---|---|
  | A change request after the merge gets a fresh branch | `AGENTS.md`, `git-workflow.md` | `AGENTS.md` § Change request |
  | Branch from an up-to-date base; never commit to a protected branch | `AGENTS.md`, `git-workflow.md` | `AGENTS.md` § Delivery rules |
  | Don't amend or rewrite pushed history | `AGENTS.md`, `git-workflow.md` | `AGENTS.md` § Delivery rules |
  | The pull request's body, readiness, and reviewers | `AGENTS.md`, `git-workflow.md` | `AGENTS.md` § Delivery rules; `git-workflow.md` keeps the title and the template |
  | CI is a signal; env variables declared in the template | `AGENTS.md`, `git-workflow.md` | `AGENTS.md` § Ground rules |
  | The commit prefixes in phase order | Their own section of `AGENTS.md`, `git-workflow.md` | `AGENTS.md`'s Commits line, with the table in `git-workflow.md` |
  | A stakeholder update posts only on the developer's yes | `AGENTS.md`, `claude-code.md` | `AGENTS.md` § Requirements & traceability |
  | One task per session; a phase stays in its session | `AGENTS.md`, `claude-code.md` | `AGENTS.md` § Working economically |
  | Check on the preview after the local check | Twice in `AGENTS.md` | `AGENTS.md` § Delivery rules |
  | An open requirement is a question; a minor choice is an assumption | Three places in `AGENTS.md` | § Ground rules and the question rounds |
  | Never do silently | `AGENTS.md` § AI interaction rules | `AGENTS.md` § Boundaries, folded into its neighbors |

- **A phase's procedure stays in its skill.** `AGENTS.md`'s full lane keeps its seven steps and the
  gate in full, and points to `/adf:implement` for a plan that departs from reality. The sections of
  `plan.md` and the lane table's per-lane details give way to the skills and `AGENTS.md`. The rule
  that a diff a teammate could merge without new docs needs none moves from `claude-code.md` to
  `/adf:write-plan`'s documentation plan. Removing rules that can't apply is `/adf:init-project`'s.
- **Fewer mentions of the reference docs:** `AGENTS.md` names `SPEC-MODEL.md` once, in its docs
  table, and leaves `COST-MODEL.md` to `claude-code.md`, which is about Claude's models.
- **Descriptions in fewer words, every trigger kept.** The longest skill and agent descriptions lose
  wording, never a "Use when" phrase: a description decides whether a skill loads at all (0055's
  correction).
- **What stays as it was:**
  - The skills' rationalizations, red flags, and principles: 0055 and 0063 declined trimming them,
    because only the session evals can measure it.
  - The session name in `AGENTS.md`'s triage, for the tasks `/adf:triage` doesn't run on.
  - The tracker sentences in `AGENTS.md` § Requirements & traceability, word for word. They still
    ask for the developer's yes before a status change, which 0059 made automatic in the skills and
    `docs/TRACKER-INTEGRATION.md`. Reconciling them changes behavior, so it's a change of its own.

## Consequences

- **Positive:**
  - Characters every call re-reads, before → after:

    | File | Before | After | Change |
    |---|---|---|---|
    | `AGENTS.md` | 20,020 | 18,525 | −7.5% |
    | `AGENTS.md`, packaged (reference docs linked) | 20,578 | 18,720 | −9.0% |
    | `.claude/rules/claude-code.md` | 6,046 | 5,294 | −12.4% |
    | `.claude/rules/git-workflow.md` | 5,205 | 4,226 | −18.8% |
    | Skill descriptions, `adf` | 8,781 | 8,521 | −3.0% |
    | Agent descriptions, `adf` | 1,788 | 1,677 | −6.2% |
    | Skill descriptions, `adf-dev` and `adf-connect` | 1,895 | 1,895 | 0 |
    | **Total, committed** | 43,735 | 40,138 | −8.2% |
    | **Total, packaged** | 44,488 | 40,528 | −8.9% |

  - **In dollars, under one percent.** About 900–1,000 tokens fewer on every call, of the ~154k a
    median call reads. The framework's text is about 7–10% of an adopting project's cost; this trims
    8–9% of the part every call re-reads.
  - Each rule has one copy in the always-loaded text, so there are fewer places for them to disagree.
- **Negative / cost:**
  - **Projects merge `AGENTS.md` and `claude-code.md`.** The changes are wording in most sections,
    one section removed, and one table row. `git-workflow.md` is overwritten.
  - **A tool that reads only `AGENTS.md` loses two details:** what to do when implementation departs
    from the plan, and the list of `plan.md`'s sections. Both are in `/adf:implement`,
    `/adf:write-plan`, and the plan template.
  - **The session evals should cover it at the next release:**
    - the triage fixtures, to check every lane and the session name in the desktop app;
    - a full-lane task whose implementation grows the change surface into risk, re-confirmed from
      `/adf:implement`;
    - a change request after the merge, on a fresh branch;
    - a full lane whose plan lists no docs, skipped by `/adf:write-docs`;
    - `/adf:open-pr`'s title and body without `git-workflow.md`'s body line;
    - a tracker task's started update, posted only on a yes;
    - the shortened descriptions still loading their skills: "it's merged" (`/adf:wrap-up`),
      "update the client" (`/adf:stakeholder-update`), a passed local check (`/adf:open-pr`), and an
      ADR-worthy choice (`/adf:record-decision`).

## Alternatives considered

- **Move the full lane's steps to `specs/README.md`.** Declined: tools that don't run skills follow
  `AGENTS.md`'s map, and the gate must be read before any code is written.
- **Cut every description to about 250 characters.** Declined: most of what remains is trigger
  phrases.
- **A static check on the files' length.** Declined: a guard nobody asked for. `AGENTS.md`'s
  200-line check stays, and the checks pin each rule's text.
- **Fix the tracker sentences here.** Declined: it changes what the agent asks before, which this
  cleanup doesn't.
