# 0097: After the approval gate, the agent goes on — the cost step moves into the gate

- **Status:** accepted
- **Date:** 2026-11-28
- **Amends:** [0062](0062-one-session-per-task-compact-at-the-gate.md) — the developer no longer
  takes three steps after approval; the compaction and the model switch become an optional step
  before approving, and the agent switches the model itself where the client lets it

## Context

- **What happened.** In adopting projects, a full-lane task reached the approval gate and the
  developer approved. The agent committed the spec folder, then stopped: it named three steps
  (compact, pick Sonnet, send the next command) and waited for them. Nothing in those steps needed
  the developer's judgment, but the task stood still until someone came back to take them.
- **It was a second stop.** [0095](0095-each-step-has-one-owner.md) made the approval gate the full
  lane's one stop, yet 0062's hand-off kept another one right after it. It stalled every run meant
  to go on unattended from the gate to the pull request.
- **The stop eats into its own saving.** 0062 compacts right after approval because the summary's
  read of the conversation then comes mostly from the cache. A developer who comes back after the
  cache has expired pays for that read uncached anyway.
- **What already bounds the cost.**
  - The project caps the conversation at 300k tokens (`"autoCompactWindow": 300000`, 0062), so
    Claude Code compacts it on its own when it grows. The spec folder, the ticks in `tasks.md`, and
    the commits carry the task through that compaction.
  - In the desktop app, `/adf:triage` already tries to switch the session's model itself
    (`set_session_model` on `self`) and names the switch only where the app refuses
    ([0055](0055-lean-context-and-acting-model-routing.md)). `/adf:write-plan` said the app never
    allows it, so the same switch had two rules.
- **What the developer needs:** one stop in the full lane, where the judgment is. After the
  approval, the work runs to the pull request unless something needs a person.

## Decision

- **On approval, the agent goes on.** It commits the spec folder and starts the next phase in the
  same turn: `/adf:write-docs` when Phase 1 has tasks (with `/adf:end-user-docs` and
  `/adf:stakeholder-update guide` where the spec asks for them), then `/adf:implement`, the local
  check, and `/adf:open-pr`. It doesn't wait for a command.
- **The model: switch where the client allows it, otherwise go on.** When the session is on Opus,
  dozens of calls follow, and the developer didn't choose Opus for the whole task:
  - **Desktop app:** the agent sets Sonnet itself (`set_session_model` on `self`), as triage does,
    and says so in a line.
  - **Where the app refuses, and in a terminal or another tool:** it keeps the current model, says
    so in one line, and goes on. A model switch is never a reason to stop.
- **No manual compaction after approval.** The 300k cap compacts the conversation when it grows;
  the next phases read the folder, not the conversation.
- **The saving stays the developer's choice, at the stop that already exists.** The gate's message
  ends with one optional line: to run the rest cheaper, `/compact` with what the next phases need
  and pick Sonnet, then approve. The compaction then comes at the gate's clean boundary, with the
  agreed changes already in the files (step 10), and the agent goes on from the summary. When the
  compaction can't pay back (a task or two, or a short conversation), the line names only the
  model. A plain "approve" takes the unattended path.
- **The stops that remain are the ones that need a person:** the change surface growing into risk,
  a requirement that turns out wrong or ambiguous, an environment that won't start, and the
  questions `/adf:implement` already stops for.
- **0062 stands otherwise:** one session per task, never another session for a phase, the folder
  as the record, and the 300k cap.

## Consequences

- **Positive:**
  - The full lane has one stop. From the approval to the draft pull request, the run goes on
    without the developer.
  - The model switch has one rule, in triage and at the gate.
  - A developer who wants the cheaper run takes the step while they are already at the keyboard to
    approve, when the cache is warm.
- **Negative / cost:**
  - **A plain approval costs more.** Each call carries the planning conversation until the
    automatic compaction, on the session's model: Opus wherever the app won't switch. 0062's
    estimate stands: a compaction pays back within 10–40 calls, and implementing a plan makes
    dozens. The gate's optional line is how a developer avoids this cost.
  - **The automatic compaction comes wherever the window fills,** possibly in the middle of a
    task. 0062 already accepted this: the folder, the ticks, and the commits carry the task, and a
    decision agreed only in chat may not survive.
  - **A compaction before approval summarizes a gate that is still open.** The instruction says the
    gate is awaiting approval, and every change the developer asked for is already in the files.
  - Projects merge one line into `claude-code.md` (the full lane's model cell and the cost
    paragraph) and two into `AGENTS.md`.

## Alternatives considered

- **Keep 0062's three steps.** Rejected. It's a second stop with no judgment in it, and it stalls
  unattended runs.
- **The agent compacts itself.** Not possible: no tool compacts a session from inside it, and a
  clear queued on `self` wipes the agent's last message (0062).
- **Implementation in a Sonnet subagent.** Still rejected, for 0062's reasons: the parent stays on
  Opus with the whole conversation, only a summary comes back, and a subagent can't stop and ask.
- **A project setting to choose between stopping and going on.** Rejected. The gate's optional line
  gives the developer the same choice for each task, with no configuration.
