# 0097: After the approval gate, the agent runs to a pull request ready for review — the cost step moves into the gate

- **Status:** accepted; refined by [0098](0098-a-compaction-keeps-the-run-on-course.md) — the run
  goes through an automatic compaction on course
- **Date:** 2026-11-28
- **Amends:** [0062](0062-one-session-per-task-compact-at-the-gate.md) — the developer no longer
  takes three steps after approval; the compaction and the model switch become an optional step
  before approving, and the agent switches the model itself where the client lets it
- **Refines:** [0095](0095-each-step-has-one-owner.md) — the approval gate is the full lane's one
  stop, and this record says what it authorizes: the run to a pull request ready for review

## Context

- **What happened.** In adopting projects, a full-lane task reached the approval gate and the
  developer approved. The agent committed the spec folder, then stopped: it named three steps
  (compact, pick Sonnet, send the next command) and waited for them. Nothing in those steps needed
  the developer's judgment, but the task stood still until someone came back to take them.
- **It was a second stop.** [0095](0095-each-step-has-one-owner.md) made the approval gate the full
  lane's one stop, yet 0062's hand-off kept another one right after it. It stalled every run meant
  to go on unattended from the gate to the pull request.
- **Then agents asked before each task.** In other adopting projects, past the gate, the agent
  committed a task and asked whether to go on to the next, task after task. Nothing in the
  framework asks for that: `AGENTS.md` already says never to ask for a step already authorized. But
  nothing said what the approval authorizes either. Each task ends in a commit, which reads as a
  natural place to end a turn, and "end every turn with what's next" became "continue with T004?".
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
  approval, the work runs until it's done and tested — a pull request ready for review — unless
  something needs a person.

## Decision

- **The approval authorizes the whole run, to a pull request ready for review.** That's every task
  in `tasks.md`, the docs, the reconcile, the full gate, the local check, and `/adf:open-pr` through
  marking the pull request ready ([0070](0070-the-agent-marks-its-pull-request-ready.md)). Where
  `AGENTS.md` § Delivery rules has a person mark it ready, the run ends at the draft with every
  check passed. The end point is that outcome, not a skill's name: a run that stops before
  `/adf:open-pr`, or before marking ready, has stopped short.
  - **No check-ins.** The agent doesn't end its turn, report, or ask to continue between tasks or
    phases. The commits and the ticks in `tasks.md` are the progress record, and the developer can
    interrupt at any time.
  - **CI and the preview deploy are waits, not stops.** `/adf:open-pr` waits in the background, and
    a failure that's the agent's to fix, it fixes.
  - **Stops are decisions:** the change surface growing into risk; a requirement that turns out
    wrong or ambiguous; a test that passes before any code when the agent can't tell why; a shared
    contract that moved; something that can't wait, such as a security hole; an environment that
    won't start; a walk that would reach a person or real shared data; a criterion the agent
    couldn't test, which keeps the draft; a review finding that needs the developer's call rather
    than a fix. Everything else — a finding along the way, a small deviation from the plan — goes in
    the final report and the pull request.
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
- **0062 stands otherwise:** one session per task, never another session for a phase, the folder
  as the record, and the 300k cap.

## Consequences

- **Positive:**
  - The full lane has one stop. From the approval to a pull request ready for review, the run goes
    on without the developer, unless a decision needs them.
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
  - **A long run in one turn.** The automatic compaction may come in the middle of it; the folder,
    the ticks, and the commits carry it, as above.
  - Projects merge two lines into `claude-code.md` (the full lane's model cell and the cost
    paragraph) and three into `AGENTS.md`.

## Alternatives considered

- **Keep 0062's three steps.** Rejected. It's a second stop with no judgment in it, and it stalls
  unattended runs.
- **The agent compacts itself.** Not possible: no tool compacts a session from inside it, and a
  clear queued on `self` wipes the agent's last message (0062).
- **Implementation in a Sonnet subagent.** Still rejected, for 0062's reasons: the parent stays on
  Opus with the whole conversation, only a summary comes back, and a subagent can't stop and ask.
- **End the authorized run at `/adf:open-pr`.** Rejected. It names a step, and an agent can read
  it as stopping before that step. `/adf:open-pr` already runs to ready (0070), so the outcome is
  the end point.
- **A check-in at the end of each phase.** Rejected. A report with no decision in it still stops
  the run until someone answers; the commits show the progress without one.
- **A project setting to choose between stopping and going on.** Rejected. The gate's optional line
  gives the developer the same choice for each task, with no configuration.
