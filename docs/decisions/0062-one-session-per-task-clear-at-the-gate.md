# 0062: A task's phases stay in its session — after the approval gate, clear the conversation and switch to Sonnet there

- **Status:** accepted
- **Date:** 2026-11-01
- **Amends:** [0012](0012-choose-the-model-by-the-work.md) — the switch after the gate happens in the
  task's session, after a clear, not in a fresh session;
  [0013](0013-adapt-practices-not-a-second-workflow.md) — a handoff is for work that leaves the
  session, not a choice between a task's phases;
  [0055](0055-lean-context-and-acting-model-routing.md) — where the desktop app refuses a session's
  change to its own model or effort, triage names the switch for the developer

## Context

- **What happened.** A full-lane task in an adopting project (packaged install, desktop app)
  reached the approval gate, and the developer approved. `/adf:write-plan` step 12 and the lane
  table in `claude-code.md` both said to go on "in a fresh session on `sonnet`". The agent read
  that literally: it started a child session for the docs and the implementation, in the same
  worktree and branch.
- **What it cost.**
  - Two sessions shared one branch.
  - The parent, still on Opus, woke each time the child finished a turn. Each wake-up re-read the
    whole planning conversation at Opus prices, and none of them moved the task.
  - The context split. The developer didn't know which session to talk to, and the parent relayed
    and checked what the child did.
  - The developer hadn't asked for a new session, and asked why one was made.
- **The guidance named a goal, not a way.** It wanted the next phases on Sonnet with a small
  context, but it didn't say how to get there in each client. The desktop app gives an agent a tool
  that starts sessions, so "fresh session" was one call away.
- **What the goal needs.**
  - The model, the effort, and the conversation can all change inside one session. In a terminal
    that's `/model`, `/effort`, and `/clear`. The desktop app has the model menu and `/clear` in the
    prompt box.
  - Each model has its own prompt cache. A switch alone re-reads the whole conversation once,
    uncached, and every later call still carries it. Clearing or compacting is what cuts the cost
    of each call.
  - After the gate, the approved and committed spec folder holds what the next phases need.
  - In current versions of the desktop app, a session can't change its own model or effort: the
    session tools refuse it, so a session can't silently re-price its own turns. It can queue its
    own clear, but the transcript then starts over empty when the turn ends, and the agent's last
    message goes with it.
  - A subagent runs on its own model from an empty context, and only its summary comes back.

## Decision

- **One session per task, from triage to delivery.**
  - The spec, the plan, the docs, the implementation, the review, and the delivery all run in the
    task's session.
  - An agent never starts another session for a phase of its task, new or child, unless the
    developer asks.
  - Another task still gets its own session ([0042](0042-each-session-moves-to-its-task-worktree.md)).
- **After the approval gate: clear, switch to Sonnet, go on.** All three happen in the same
  session. Once the spec folder is committed, the planning conversation is dead weight on every
  later call. So the hand-off gives the developer three steps:
  1. **Clear the conversation.**
  2. **Pick Sonnet**, at default effort.
  3. **Send the next command**: `/adf:write-docs specs/<folder>/`, or `/adf:implement specs/<folder>/`
     when Phase 1 has no tasks.

  Clearing first means the switch re-reads nothing. Each client has its own way to do the steps:
  - **Terminal:** `/clear`, `/model sonnet`, then the command.
  - **Desktop app:** `/clear` in the prompt box, Sonnet in the model menu, then the command. The
    agent neither clears nor re-prices the session itself.
  - **Other tools:** the tool's way of starting the conversation over (a new chat in the same
    workspace), its model picker, then the command.

  The developer may keep the conversation instead. Then the model switches in place, with one
  uncached re-read and every later call still carrying the conversation, or the session stays on
  Opus. That's the developer's call.
- **A cleared conversation opens with where the task stands.** Started with no triage in the
  conversation, `/adf:write-docs` and `/adf:implement` open with one line: the lane, the folder,
  that it's approved, and the phase. The developer sees where things are, and the triage-first
  hook, which reads the replies, doesn't stop the first edit.
- **Triage names the switch when the app won't make it.** Where the desktop app refuses a session's
  change to its own model or effort, `/adf:triage` names the switch for the developer (the model
  and effort menus), as it does in a terminal.
- **Subagents stay for unattended steps:** reviews, analysis, and the `/adf:deep-…` workflows. The
  implementation runs in the session. It stops for the developer when the change surface grows into
  risk, and its commits and local check are the developer's to follow.
- **`/adf:handoff` is for work that leaves the session:** to a teammate, another machine or tool, or
  a session the developer opens. A task's next phase is not a handoff.

## Consequences

- **Positive:**
  - The developer has one place to talk to, and no waiting session wakes at Opus prices.
  - It's cheaper than both earlier paths. After the clear, each call carries only the session's base
    and the spec folder, on Sonnet.
  - Every client follows the same three steps, each with its own commands.
- **Negative / cost:**
  - The developer takes three actions at the gate. The old advice also left them a step: opening a
    new session.
  - The clear drops whatever the gate's discussion didn't fold into the files. `/adf:write-plan`
    already folds every change in, and the old conversation stays resumable (`/resume`, or "Resume
    previous session" in the desktop app).
  - Projects merge two lines into `claude-code.md` (the lane row and the cost paragraph) and one
    into `AGENTS.md`.

## Alternatives considered

- **Keep "fresh session".** Rejected. It was read as "start a session", and the desktop app's tools
  make that one call. A second session on the task splits it.
- **Switch the model in place, without a clear.** Rejected as the default. It re-reads the planning
  conversation once, uncached, and every implementation call still carries that conversation: the
  very cost the switch was meant to cut. It stays the developer's option.
- **`/compact` at the gate.** Rejected. It spends one call over the whole conversation, on Opus, to
  write a summary that the spec folder already is.
- **The agent clears its own session in the desktop app** (`clear_session` on `self`). Rejected. The
  transcript starts over and takes the agent's last message with it, including the command to send
  next. The model switch would still need the developer.
- **Implementation in a subagent on Sonnet.** Rejected.
  - The parent stays on Opus with the whole planning conversation, for every turn the developer
    takes.
  - Only a summary comes back, and the parent has to check it.
  - A subagent can't stop and ask when the change surface grows.
