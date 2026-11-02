# 0062: A task's phases stay in its session — after the approval gate, compact the conversation and switch to Sonnet there

- **Status:** accepted
- **Date:** 2026-11-01
- **Amends:** [0012](0012-choose-the-model-by-the-work.md) — the switch after the gate happens in the
  task's session, after a compaction, not in a fresh session;
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
- **What the developer needs:** one session per task, from triage to delivery, with cost and
  context kept small.
- **The guidance named a goal, not a way.** It wanted the next phases on Sonnet with a small
  context, but it didn't say how to get there in each client. The desktop app gives an agent a tool
  that starts sessions, so "fresh session" was one call away.
- **What the goal needs.**
  - The model and the conversation can both change inside one session: `/model` and `/compact` in
    a terminal; the model menu and `/compact` in the desktop app's prompt box.
  - Each model has its own prompt cache. A switch alone re-reads the whole conversation once,
    uncached, and every later call still carries it. Shrinking the conversation is what cuts the
    cost of each call.
  - `/compact` replaces the conversation with a summary in the same session. The summary costs one
    call over the conversation, and soon after the last call most of that is read from the cache.
  - `/clear` starts the conversation over. In a terminal, that begins a new transcript, so the
    task's history ends up in two places.
  - After the gate, the approved and committed spec folder holds the detail the next phases need.
  - In current versions of the desktop app, a session can't change its own model or effort: the
    session tools refuse it, so a session can't silently re-price its own turns. No tool lets a
    session compact itself.
  - A subagent runs on its own model from an empty context, and only its summary comes back.

## Decision

- **One session per task, from triage to delivery.**
  - The spec, the plan, the docs, the implementation, the review, and the delivery all run in the
    task's session.
  - An agent never starts another session for a phase of its task, new or child, unless the
    developer asks.
  - Another task still gets its own session ([0042](0042-each-session-moves-to-its-task-worktree.md)).
- **After the approval gate: compact, switch to Sonnet, go on.** All three happen in the same
  session. The hand-off gives the developer three steps:
  1. **Compact right away,** with what the next phases need: the lane, the spec folder, the gate's
     decisions, and the next step.
  2. **Pick Sonnet**, at default effort.
  3. **Send the next command**: `/adf:write-docs specs/<folder>/`, or `/adf:implement specs/<folder>/`
     when Phase 1 has no tasks.

  Compacting first means the switch re-reads only the summary. Each client has its own way to do
  the steps:
  - **Terminal:** `/compact <instruction>`, `/model sonnet`, then the command.
  - **Desktop app:** the same `/compact` in the prompt box, Sonnet in the model menu, then the
    command.
  - **Other tools:** the tool's compaction and model picker. A tool with no compaction starts the
    conversation over instead; the folder carries the task.

  The developer may keep the whole conversation instead. Then the model switches in place, with
  one uncached re-read and every later call still carrying the conversation, or the session stays
  on Opus. That's the developer's call.
- **The spec folder stays the source of truth.** `/adf:write-docs` and `/adf:implement` read the
  folder, not the summary. In a conversation that doesn't show where the task stands, whether
  compacted or started anew, they open with one line: the lane, the folder, that it's approved, and
  the phase.
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
  - The developer has one place to talk to, and one history to read, from triage to delivery. No
    waiting session wakes at Opus prices.
  - The agent keeps the thread of the gate's discussion, in summary.
  - After the compaction, each call carries the session's base and a summary, on Sonnet. That's
    close to a cleared conversation and far below the whole planning conversation.
  - Every client follows the same three steps, each with its own commands.
- **Negative / cost:**
  - The developer takes three actions at the gate. The old advice also left them a step: opening a
    new session.
  - The summary costs one call over the conversation, on the session's model. It costs least right
    after approval, while the cache is warm. A long wait at the gate makes it one uncached read,
    once.
  - A summary can drop or blur a detail. The folder is the record, and the next phases read it.
  - Projects merge two lines into `claude-code.md` (the lane row and the cost paragraph) and one
    into `AGENTS.md`.

## Alternatives considered

- **Keep "fresh session".** Rejected. It was read as "start a session", and the desktop app's tools
  make that one call. A second session on the task splits it.
- **`/clear` at the gate.** Rejected. It's the cheapest move, but it drops the thread the developer
  and the agent share, and in a terminal it starts a new transcript: one task, two histories. The
  per-call saving over a compaction is the summary, a few thousand tokens. In the desktop app, a
  clear the agent queues for itself (`clear_session` on `self`) also wipes its last message, the
  command to send next. It stays the move between tasks.
- **Switch the model in place, without compacting.** Rejected as the default. It re-reads the
  planning conversation once, uncached, and every implementation call still carries that
  conversation: the very cost the switch was meant to cut. It stays the developer's option.
- **Implementation in a subagent on Sonnet.** Rejected.
  - The parent stays on Opus with the whole planning conversation, for every turn the developer
    takes.
  - Only a summary comes back, and the parent has to check it.
  - A subagent can't stop and ask when the change surface grows.
