# 0099: A compatibility pass for the project's own instructions

- **Status:** accepted
- **Date:** 2026-11-28
- **Amends:** [0024](0024-agents-md-only.md) and [0025](0025-no-gemini-md.md) — an existing `CLAUDE.md`
  or `GEMINI.md` is sorted line by line before it's moved, not moved whole

## Context

In adopting projects, agents didn't follow the framework's process. The cause was the project's own
instructions, written before the adoption: an `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or Cursor rules
that kept process rules of their own.

- **The lines contradicted the framework.** "Ask before each commit", "confirm every step", "wait for
  my OK before each task", a different approval or pull-request flow. `AGENTS.md` § Delivery rules
  makes commits, the work branch's push, and its draft the standing go-ahead.
- **Agents followed the stricter or more specific line, or stalled between the two.** A rule against
  asking and a rule to ask both read as instructions. The agent asked at every commit, or stopped and
  asked which rule held.
- **Adoption merged them in.** `/adf:adopt` merged a collision by keeping the project's content and
  adding the skeleton's missing sections, and moved an existing `CLAUDE.md`'s facts and instructions
  into `AGENTS.md` and the Claude Code rule, process lines included.
- **Upgrades never looked.** `/adf:upgrade` merges each changed file three ways. A project line that
  merged cleanly stayed, even when the new release added a rule it now contradicted.
- **`/adf:context-audit` didn't catch it.** It found contradictions between the project's files, but
  never compared a project line with the framework's process. It's also read-only and optional.

## Decision

- **A compatibility pass** sorts each project line of `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
  `.cursor/rules/`, `.claude/rules/`, and `.agents/rules/` that the skeleton doesn't have into one of
  four classes:
  - **Project fact** (the stack, commands, paths, conventions): moves into its skeleton section, once.
  - **Process the framework owns** (when to ask or stop, approvals, the commit, branch, and
    pull-request flow, the testing process, review, model and session handling): dropped, with the
    line and the rule that replaces it shown.
  - **Deliberate override:** kept where the framework honors one, such as the CUSTOMIZE note in
    `AGENTS.md` § Delivery rules for a person marking pull requests ready. Otherwise it's recorded as
    a PDR with its reason. A process line nobody can give a reason for is the framework's.
  - **Can't tell:** asked once.
- **The developer approves the table before anything is written.** It goes in the pull request's
  body under `## Compatibility`.
- **The pass lives in one reference file,** `plugins/adf/skills/adopt/compatibility.md`, beside
  `/adf:adopt` (decision 0063). `/adf:adopt` runs it where it merges an existing `AGENTS.md`,
  `CLAUDE.md`, `GEMINI.md`, or rule. `/adf:upgrade` runs it on every upgrade, on the merged files,
  against the new release's rules. A line an earlier pass settled stays out of the table until the
  rule it overrides changes.
- **It never grows the always-loaded text.** A dropped line leaves nothing, an override is the honored
  sentence or one line pointing to its PDR, and a fact goes in once. The pass gives `AGENTS.md`'s size
  before and after.
- **`/adf:context-audit` reports a PROCESS finding:** a project line that asks for a stop, an
  approval, or a flow the framework's process doesn't have, or that contradicts it. The same goes for
  `/adf:deep-context-audit`.

## Consequences

- **Positive:**
  - An adopted project's instructions carry one process, so agents follow it.
  - A team's real exceptions survive, with a reason others can read.
  - An upgrade catches a new rule that collides with an old line, in the pull request that brings it.
  - `AGENTS.md` doesn't grow with a second copy of the process.
- **Negative / cost:**
  - **Adoption and every upgrade read the project's instruction files line by line,** and show one more
    table to approve.
  - **The classification is judgment.** The can't-tell class and the developer's approval are the
    guard against a wrong drop.
  - **A team that wants a stop the framework doesn't make writes a PDR for it,** which is the point:
    the next reader learns why.

## Alternatives considered

- **Keep merging and rely on `/adf:context-audit`.** Declined. It's optional and read-only, and the
  adoption had already merged the contradiction by the time anyone ran it.
- **Overwrite the project's instructions with the skeleton's.** Declined. It loses the project's facts
  and its real exceptions.
- **A precedence line in `AGENTS.md` ("the framework's process wins over older lines").** Declined. It
  adds always-loaded text, and an agent still reads two instructions that disagree and has to pick.
- **Run the pass at adoption only.** Declined. A new release's rule can collide with a line that was
  compatible when the project adopted.
