---
name: dispatch
description: In the main checkout, hand every task to a new session in a worktree of its own — name the task, create its worktree beside the main checkout with scripts/agent/worktree-new.sh --no-start, and hand it over with a task chip pointed at that folder (or a command, or a prompt to paste), pointing the worker at the process. Does no analysis and edits nothing. Use for every task that arrives in the main checkout of a project with the parallel-agents module.
argument-hint: "[tracker link or task description]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/dispatch/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Dispatch

The main checkout is the shared hub where every developer and agent session starts. **In the main
checkout you dispatch every task; you never work.** Editing there blocks every other session, and
analysis done there is wasted: the dispatcher can't run the app or the tests, its conclusions are
unverified, and the worker in the worktree has to redo the reading anyway — now with tools that can
check it. The dispatcher's context stays cheap: a branch name, not a plan.

A dispatcher **writes nothing outside this machine** and takes no outward-facing action. Its only
network calls are reads: the task in step 1, and the `git fetch` inside the worktree script.

This skill needs the `parallel-agents` module: without `scripts/agent/worktree-new.sh` in this
repository, say the module isn't installed and stop.

Every task takes the same route (decision 0021): the scripts create its worktree beside the main
checkout, and a new session opens there. Whether the task will run the app is its triage's question,
after the hand-off; the worktree can, because the scripts gave it the env file and, where the project
uses them, a port.

## Steps

1. **Name the task — nothing more.** Read only enough of the task to know its title and type
   (`feat`, `fix`, `chore`, `docs`, `refactor` — `hotfix` where the branching model uses it). No code
   reading, no requirement analysis, no planning. Choose a short kebab-case slug. If the task names
   a delivered feature, start the slug with that feature's spec-folder slug and add the change
   (`feat/newsletter-signup-topics`) — a directory listing (`ls specs/`) is enough; don't open the
   files. Whether it really is a change request is the worker's triage to decide.

2. **Create the worktree:**
   ```bash
   scripts/agent/worktree-new.sh <type>/<slug> --no-start
   ```
   It creates a sibling of the main checkout named after the branch (`feat/newsletter-signup-topics`
   → `../feat-newsletter-signup-topics`), on a new branch from the base branch, with the env file
   seeded from the main checkout's and, when the project's worktrees run a server, a port reserved —
   or it reports the existing worktree unchanged. `--no-start` is deliberate: the environment belongs
   to the worker, which starts it only if its triage says a step needs it
   (`scripts/agent/worktree-new.sh <branch>` from the worktree). A hotfix from a release tag adds
   `--from <tag>`.

3. **Hand it over.**
   - **Desktop app:** offer the task as a task chip whose folder is the worktree's absolute path. Title
     it with the branch and the task's title — `feat/newsletter-signup-topics · Show the chosen topics
     after signup` — because the app shows that title, not the folder or the branch, for a session
     started this way. Its prompt is the worker prompt (step 4). Tell the developer to start it in that
     folder, not in a new worktree: the card's worktree option would make a second worktree under
     `.claude/worktrees/`, without this one's env file, port, or setup.
   - **Terminal:** give the developer one command to run in a new terminal:
     `cd <worktree path> && claude "<worker prompt>"`.
   - **Check the first lines.** The new session's session-context lines say `Role: WORKER` and name
     this worktree. If they say DISPATCHER, the session opened in the main checkout: the developer
     closes it and opens a new session with the worktree as its folder, then pastes the prompt. So
     give the worktree's path on a line of its own and the prompt in a code block.

4. **Write the worker's prompt** — pointers, not instructions:
   ```
   Task: <tracker link or one-line description>
   Worktree: <absolute path> — branch <type>/<slug>
   Follow AGENTS.md end to end, starting with triage.
   ```
   Don't restate the workflow: the worker reads it in `AGENTS.md`, and a copy in a handoff message is
   one more thing that drifts. If the developer set a lane or asked for more effort, pass it on in
   their words — `Developer: full lane — the billing rules are fragile` — since triage honors it.

The hand-off ends the task's time here. The next task needs nothing from this conversation, so
clearing it (`/clear`) between dispatches keeps the hub's session cheap.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll read the task properly first so the worker gets a head start" | The worker redoes the reading where it can verify it. Analysis here is unverified, burns the hub's context, and drifts in the handoff. |
| "It's a one-line fix — I'll just do it here" | The main checkout is shared. A stray edit or a running server here collides with every other session. |
| "The chip can make the worktree itself" | Its worktree lands under `.claude/worktrees/`, inside the main checkout, on a generated branch, without the env file, port, or setup. Create the worktree with the script and point the chip at it. |
| "I'll start the environment so it's ready" | The worker may not need one (an answer-only task). It decides after triage. |
| "I'll open a placeholder issue or take the next spec number for the branch" | That's an outward-facing write, and numbers collide between parallel dispatchers. The slug is the join. |
| "I'll put the full workflow in the handoff to be safe" | Restated steps drift from `AGENTS.md`. Point at the process; don't copy it. |

## Red flags (stop and reassess)

- You've opened source files, specs, or tests in the main checkout.
- `git status` in the main checkout shows changes you made — or the protect-hub hook stopped an edit:
  you were about to work in the hub.
- The handoff prompt contains analysis, a plan, or a list of files to change.
- The chip has no folder, or a folder other than the worktree the script created.

## Verification

- [ ] Only the task's title and type were read
- [ ] The worktree was created (or reported) by `worktree-new.sh --no-start` beside the main checkout — never by raw `git worktree add`, and never left to the chip
- [ ] The chip points at that worktree and its title carries the branch — or the developer has the command, or the path and prompt to paste
- [ ] Nothing was edited, committed, or posted from the main checkout
- [ ] The worker prompt has the task link, worktree path, branch, and "follow AGENTS.md, starting with triage" — nothing else

## Principles

- The hub dispatches every task; worktrees beside it do the work.
- One route: the script creates the worktree; a chip, a command, or a pasted prompt hands it over.
- Reads only, no writes, no analysis.
- Point at the process; never restate it.
