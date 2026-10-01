# 0012: Choose the model by the work — Sonnet for well-specified work, Opus for judgment

- **Status:** accepted
- **Date:** 2026-10-01
- **Builds on:** [0010](0010-model-aliases.md) (version-less aliases) and [0011](0011-lanes-ceremony-follows-risk.md) (lanes)

## Context

Record 0010 made the project default the `sonnet` alias, but in practice sessions ran on whatever
the developer's tool defaulted to: in the measured sessions behind 0011, every session ran on Opus,
including one-line fixes, and some on a 1M-context variant. Claude Code's own `default` is Opus, and
the desktop app's model picker overrides the project setting.

Anthropic's guidance for the current models draws the line by the shape of the task, not its size:
Sonnet 5.5 for well-scoped work such as fixing bugs and iterating on features, and for well-defined
agent tasks run repeatedly (investigation, review, drafting); Opus 5.5 for complex work that needs
careful judgment and for long-horizon agentic coding. Its test: whether the task has a clear spec
and a way to check the result. For effort, start at `medium` for well-specified tasks and move to
`high` for harder or longer ones; `xhigh` and `max` make Sonnet think longer and cost more.
([Building with Claude Sonnet 5.5](https://claude.dev/blog/building-with-claude-sonnet-5-5/))

That line falls almost exactly on the lanes: the fast and careful lanes, and the full lane after
its gate, are a clear spec with a test that checks it; the full lane's spec and plan are judgment.

One constraint shapes *when* to switch: each model has its own prompt cache, so after a switch the
next call re-reads the whole conversation uncached.

## Decision

- **The model follows the work**, named with version-less aliases only (`sonnet`, `opus`):
  `sonnet` for the fast and careful lanes, bug fixes, investigations, reviews, and implementing an
  approved plan; `opus` for the full lane's spec and plan, ambiguous or long-horizon work,
  architecture, and bugs that resist two hypotheses. The table lives in `COST-MODEL.md` § Choosing
  between Sonnet and Opus, and a Model column in `CLAUDE.md`'s lanes table.
- **Switch only where it's cheap:** at session start; right after triage, while the context is small
  (`/triage` names the model when the session's doesn't fit the lane); or in a fresh session after
  the approval gate — the spec folder is the handoff and the cache has usually expired during the
  review. `/write-plan` suggests that fresh Sonnet session for `/write-docs` and `/implement`.
- **Effort before model:** default effort for well-specified work, `high` for harder or longer; no
  `xhigh` / `max` on Sonnet by default.
- **Subagents carry their own model** — they run in their own context, so it costs no switch:
  reviewers (`@code-reviewer`, `@security-reviewer`, `@ux-reviewer`) move from `haiku` to `sonnet`;
  `@spec-analyzer` and `@architect` move to `opus`.
- **Skills don't pin a model.** A skill's `model` key would switch the session in and out on every
  invocation — two cache misses — and override a developer's deliberate choice. Guidance and triage
  do the routing instead.

## Consequences

- **Positive:** quick work runs on the cheaper, faster model by default; the judgment that decides
  a feature's shape gets Opus; reviews no longer run on the smallest model; nothing pins a version.
- **Negative / cost:** routing depends on developers acting on the triage's suggestion — the measured
  default was Opus. Reviews cost about twice what they did on Haiku (cents per review); spec analysis
  costs more on Opus, once per full-lane folder.

## Alternatives considered

- **Pin models in skills** (`/write-plan` on Opus, `/implement` on Sonnet). Rejected: two cache
  misses per invocation and an override of the developer's choice.
- **`opusplan` as the project default.** It switches on plan mode, which the full lane doesn't use
  for writing spec files; documented as an option for developers who plan in plan mode.
- **Opus everywhere "to be safe".** Rejected for the same reason the full lane isn't the default:
  it pays for judgment where the task has none to exercise.
