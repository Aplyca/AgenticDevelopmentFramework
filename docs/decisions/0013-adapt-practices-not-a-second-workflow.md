# 0013: Adapt practices from other skill collections into our skills — never a second workflow

- **Status:** accepted
- **Date:** 2026-10-01
- **Builds on:** [0004](0004-triage-before-setup.md) (triage), [0011](0011-lanes-ceremony-follows-risk.md) (lanes), [0012](0012-choose-the-model-by-the-work.md) (model choice)

## Context

Public collections of agent skills keep appearing, and some carry practices this framework lacks.
The one reviewed here is [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), widely
used and actively maintained. Several of its practices are sharper than ours:

- **Debugging** starts by building a command that fails on the bug, then ranks hypotheses. Our
  `/debug` went from the symptom straight to tracing code.
- **Interviews** ask questions in rounds, each with a recommended answer, and look facts up instead
  of asking.
- **A glossary** is opinionated (one term per concept, the words to avoid) and updated while
  clarifying, where ours was a passive list.
- **Pull requests** state whether a revert undoes the change and what it affects.
- **Tests** guard against expected values recomputed the way the code computes them, and against
  mocking your own modules.
- **Decision records** have a threshold — hard to reverse, surprising, a real trade-off.
- **Phases** of a session end with an ordered choice: continue, clear, hand off, or compact.

The collection is also a complete workflow of its own. Its `triage` is a label state machine for
issue trackers, its `implement` and spec flow differ from ours, and its plugin is a read-only bundle
that updates whenever its author ships. Installed beside this framework, an agent would see two
triages and two implements with conflicting instructions. Updates would also reach adopting
repositories without a changelog entry or an upgrade impact.

## Decision

- **Adapt practices into the skills we already have**, rewritten in this framework's voice, terms,
  and paths. Don't install or vendor another collection's skills, and don't add a skill that
  duplicates one of ours.
- **The practices adopted in this change:**
  - `/debug` and `@debugger`: a failing signal first, a shrunk reproduction, 3–5 ranked falsifiable
    hypotheses tested one at a time, tagged debug logs, cleanup.
  - `AGENTS.md`, `/triage`, `/write-spec`, `/write-plan`: question rounds with recommended answers.
  - `docs/GLOSSARY.md`, `/write-spec`, the naming rule: an opinionated glossary, used and updated as
    terms settle.
  - `/open-pr`, the github module's template, `/review`: merge danger.
  - `.claude/rules/testing.md`: tests that can fail.
  - `/record-decision`: the ADR threshold.
  - `/triage`: "already built?" and "declined before?" checks.
  - `COST-MODEL.md`: between phases.
  - `/context-audit`: no-ops, copies of the repository, material in the wrong tier, prohibitions
    without a target.
- **Credit the source** in this record and the changelog. The adapted text is our own; the ideas
  are theirs.
- **Claims are tested before they change our style.** The collection argues that prohibitions make
  the forbidden behavior more likely, and that naming the Skill tool fires skills more reliably than
  a `/name` mention. Our skills rely on "do not accept these" tables and `/name` mentions; both
  claims go through the session evals before anything is restyled.

## Consequences

- **Positive:** the practices arrive inside the lanes, the spec folder, and the cost model, with
  upgrade notes. There is still one triage and one implement. Debugging gets a check that's
  measured: `run-session-evals.sh --suite debug`.
- **Negative / cost:** the skills that changed are longer when they load. `/debug` roughly doubles,
  which matters only when it runs. Keeping up with another collection is manual: someone reads its
  changes and decides what to adapt.

## Alternatives considered

- **Install the collection's plugin beside ours.** Rejected: conflicting skills with the same names
  and jobs, and updates outside our changelog.
- **Vendor selected skills verbatim.** Rejected: their paths, tracker setup, and terms (issue labels,
  `docs/adr/`, a root glossary) don't match ours, and each copy would drift from its source.
- **Leave the framework as it is.** Rejected: the debugging, interviewing, and test-quality
  practices close real gaps at little cost.
