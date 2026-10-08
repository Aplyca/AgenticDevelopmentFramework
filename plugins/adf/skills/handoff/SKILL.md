---
name: handoff
description: Hand work in progress to someone who wasn't here — a teammate, another machine or tool, a fresh session — as a short message of pointers (task, branch, spec folder, pull request, what's done, what's next, open questions), never a copy of the spec or the process. Use when asked to hand off, pass the work on, or continue elsewhere, or before ending a session mid-task.
argument-hint: "[who or where it goes — a teammate, a fresh session, another machine]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/handoff/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

> **The reference docs this file names are the plugin's copies,** in `${CLAUDE_PLUGIN_ROOT}/docs/` — outside this project, which keeps none in its own `docs/`. Read them at the full paths given.

# Handoff

A handoff lets someone with no access to this conversation continue the work. Everything worth
keeping already has a home — the spec folder, the commits, the pull request, the tracker task — so a
handoff **points at the record; it doesn't copy it**. A copy drifts from its source, and an
incomplete handoff strands whoever receives it: they either ask, or guess.

## Steps

1. **Check that the work travels.** A handoff is for work that leaves this session: to a teammate,
   to another machine or tool, or to a fresh session after the approval gate (in the full lane, the
   spec folder already carries everything — point at it). Work that stays here needs no handoff:
   continue, or `/compact` with what the next phase needs (`${CLAUDE_PLUGIN_ROOT}/docs/COST-MODEL.md` § Between phases).
   A side task found mid-work isn't a handoff either: note it for the developer — or, with the
   parallel-agents module, `/adf:dispatch` it to its own worktree.

2. **Put the state in the record first.** Commit finished tasks (`/adf:commit`) and tick them in
   `tasks.md`. Write decisions taken in this session where they last: the spec's Clarifications or
   the plan in the full lane, the pull request body otherwise. Uncommitted work is named, with its
   files, never described as if done. Nothing is pushed unless the developer asks.

3. **Write the handoff — pointers, not copies:**

   ```
   Task: <tracker link, or one line>
   Where: <repository or worktree path> — branch <type>/<slug> @ <short SHA>; <n> uncommitted: <files>
   Record: specs/NNN-<slug>/ (status <status>; next task T<n>) · PR: <link, or "not opened">
   Lane: <fast | careful | full> — <why>; model: <sonnet | opus>
   Done: <one line per finished piece, naming its commit>
   Next: <the next step as the workflow names it, e.g. "/adf:implement from T4">
   Open: <each question waiting on someone, and who>
   Follow AGENTS.md; start by reading the record above.
   ```

   Drop a line that doesn't apply. Don't restate the workflow, the spec, or this conversation's
   reasoning: the receiver reads them in the repository, where they stay current.

4. **Read it as the receiver.** With only this message and the repository, could they continue
   without asking you? Fix a missing link, a decision that lives only in this conversation, or work
   described but not committed, before handing over.

5. **Deliver it to the developer.** Show it in your reply. Where it goes next — a chat, a pull
   request comment, the tracker — is their call: posting it anywhere leaves this machine, so it
   happens only when they ask. Don't commit it to the repository; it describes a moment and goes
   stale.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll paste the relevant spec sections so they don't have to open it" | A copy drifts from the spec, and the receiver can't tell which one is current. Point at the folder. |
| "I'll summarize our whole conversation" | Reasoning summarized is reasoning lost. The decisions belong in the spec or the pull request, where they last; the handoff points there. |
| "The change isn't committed, so I'll describe what I did" | A description isn't the work. Commit what's finished, and name what isn't, with its files. |
| "I'll list the workflow steps so they know what to do" | The receiver reads them in `AGENTS.md`. Restated steps go stale and contradict the source. |
| "I'll post it on the tracker so it's in one place" | Tracker comments and pull request comments leave this machine. Show it; the developer decides where it goes. |
| "It's the same session continuing tomorrow — a handoff can't hurt" | Continuing keeps the full conversation; a handoff is a lossy summary. Use one only when the work travels. |

## Red flags (stop and reassess)

- The handoff is longer than about fifteen lines.
- It explains *how* the work should be done rather than pointing at where that's written.
- It mentions a decision you can't find in the spec folder, the commits, or the pull request.
- The receiver would need this conversation to understand it.

## Verification

- [ ] Every pointer resolves: the path, the branch, the commit, the spec folder, the links
- [ ] Every decision it relies on is written in the spec folder or the pull request
- [ ] Uncommitted work is named with its files
- [ ] It names the next step and every open question with who answers it
- [ ] It was shown to the developer; nothing was posted or committed without their ask

## Principles

- Point at the record; never copy it.
- The repository is the handoff's backing store — put the state there first.
- Hand off only what travels.
