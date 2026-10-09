---
name: dispatch
description: In the main checkout, hand every task to a new session — name the task and offer a task chip (or a command) whose short prompt has the new session create the task's worktree beside the main checkout, on a new branch, move into it, and follow the process. Runs nothing, analyzes nothing, edits nothing. Use for every task that arrives in the main checkout of a project with the parallel-agents module.
argument-hint: "[tracker link or task description]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/dispatch/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Dispatch

The main checkout is the shared hub where every developer and agent session starts. **In the main
checkout you dispatch every task; you never work.** Editing there blocks every other session, and
analysis done there is wasted: the dispatcher can't run the app or the tests, its conclusions are
unverified, and the worker in the worktree has to redo the reading anyway — now with tools that can
check it. The dispatcher's context stays cheap: a branch name, not a plan.

A dispatcher **writes nothing outside this machine** and takes no outward-facing action. Its only
network call is a read: the task in step 1. It runs no scripts — not even the worktree script.

This skill needs the `parallel-agents` module: without `scripts/agent/worktree-new.sh` in this
repository, say the module isn't installed and stop.

Every task takes the same route. The dispatcher names the task and hands it over. The
new session opens here, in the main checkout, and its first step is the task's worktree: the scripts
create it beside the main checkout, on a new branch from the base branch, and the session moves into
it before anything else. Whether the task will run the app is its triage's question, after that; the
worktree can, because the scripts give it the env file and, where the project uses them, a port.

## Steps

1. **Name the task — nothing more.** Read only enough of the task to know its title and type
   (`feat`, `fix`, `chore`, `docs`, `refactor` — `hotfix` where the branching model uses it). No code
   reading, no requirement analysis, no planning. Choose a short kebab-case slug. If the task names
   a delivered feature, start the slug with that feature's spec-folder slug and add the change
   (`feat/newsletter-signup-topics`) — a directory listing (`ls specs/`) is enough; don't open the
   files. Whether it really is a change request is the worker's triage to decide.

2. **Write the worker's prompt** — pointers, and the one setup step the worker takes first:
   ```
   Task: <tracker link or one-line description>
   Branch: <type>/<slug>
   First create this task's worktree — scripts/agent/worktree-new.sh <type>/<slug> --no-start — and move this session into it; then follow AGENTS.md end to end, starting with triage.
   ```
   A hotfix from a release tag adds `--from <tag>` to the script. Don't restate the workflow: the
   worker reads it in `AGENTS.md`, and a copy in a handoff message is one more thing that drifts. If
   the developer set a lane or asked for more effort, pass it on in their words —
   `Developer: full lane — the billing rules are fragile` — since triage honors it.

3. **Hand it over.**
   - **Desktop app:** offer the task as a task chip for this main checkout, with the worker prompt.
     Title it with the task's title alone — `Show the chosen topics after signup` — not the branch:
     once the session moves into the worktree, the app shows that folder as the session's, and the
     folder is named after the branch. Tell the developer to start it in this folder, not in a new worktree: the card's worktree option makes
     the app's own worktree under `.claude/worktrees/`, on a generated branch, without the env file,
     port, or setup.
   - **Terminal:** give the developer one command to run in a new terminal, in this main checkout:
     `claude "<worker prompt>"`.

   The new session starts here, so its first lines say `Role: DISPATCHER` — and that a session handed
   one task and its branch is that task's worker. It runs the script, then moves into the worktree
   (`docs/PARALLEL-AGENTS.md` § How a task gets its worktree). In the desktop app the developer
   approves the new folder once, and the session carries on there by itself.

The hand-off ends the task's time here. The next task needs nothing from this conversation, so
clearing it (`/clear`) between dispatches keeps the hub's session cheap.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll read the task properly first so the worker gets a head start" | The worker redoes the reading where it can verify it. Analysis here is unverified, burns the hub's context, and drifts in the handoff. |
| "It's a one-line fix — I'll just do it here" | The main checkout is shared. A stray edit or a running server here collides with every other session. |
| "I'll create the worktree here and point the chip at it" | Creating it is the new session's first step: it runs the script and moves in, so the app shows that session in the worktree's folder. The dispatcher runs nothing. |
| "The chip can make the worktree itself" | The card's worktree option makes the app's own worktree under `.claude/worktrees/`, inside the main checkout, on a generated branch, without the env file, port, or setup. The prompt has the session make the task's worktree with the scripts. |
| "I'll put the branch in the chip's title so the developer can see it" | The session's folder shows it. Once the session moves in, the app shows the worktree's folder, named after the branch (`../feat-newsletter-signup-topics`). The title is the task's. |
| "I'll start the environment so it's ready" | The worker may not need one (an answer-only task). It decides after triage. |
| "I'll open a placeholder issue or take the next spec number for the branch" | That's an outward-facing write, and numbers collide between parallel dispatchers. The slug is the join. |
| "I'll put the full workflow in the handoff to be safe" | Restated steps drift from `AGENTS.md`. Point at the process; don't copy it. |

## Red flags (stop and reassess)

- You've opened source files, specs, or tests in the main checkout.
- You ran a script, `git fetch`, or any command beyond listing `specs/`.
- `git status` in the main checkout shows changes you made — or the protect-hub hook stopped an edit:
  you were about to work in the hub.
- The handoff prompt contains analysis, a plan, or a list of files to change.

## Verification

- [ ] Only the task's title and type were read
- [ ] Nothing was run, edited, committed, or posted from the main checkout
- [ ] The chip is for this main checkout and its title is the task's title, without the branch — or the developer has the command
- [ ] The worker prompt has the task, the branch, the first step — create the worktree with `worktree-new.sh --no-start` and move into it — and "follow AGENTS.md, starting with triage"; nothing else

## Principles

- The hub dispatches every task; worktrees beside it do the work.
- One route: a chip or a command opens the session, and its first step creates the task's worktree and moves into it.
- Reads only — no commands, no writes, no analysis.
- Point at the process; never restate it.
