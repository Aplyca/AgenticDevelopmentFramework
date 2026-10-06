---
name: dispatch
description: In the main checkout, hand every task to a new session in a worktree of its own — name the task, take the route the project's settings give (Claude Code's worktree, through a task chip in the desktop app or a claude --worktree command; or the scripts' worktree, with a prompt for the developer to paste), and point the worker at the process. Does no analysis and edits nothing. Use for every task that arrives in the main checkout of a project with the parallel-agents module.
argument-hint: "[tracker link or task description] [optional: chip | scripts]"
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

## Which route

The project picks the route, not the task (decision 0020). Whether a task will run the app is a
question for its triage, after the hand-off, and a wrong guess here costs a second dispatch. Read the
route from `scripts/agent/worktree.conf`; the session-context line at the start of this session names
it too:

| The project's worktrees need | Route |
|---|---|
| Nothing from the scripts: `PORT_SLOTS=0`, no `SETUP_CMD` or `START_CMD`, and `BASE_BRANCH` is the default branch | **Claude Code's worktree** — one click in the desktop app |
| A port, or setup or start commands | **The scripts' worktree** — a prompt the developer pastes |
| A `BASE_BRANCH` other than the default branch | **The scripts' worktree**, for every task — Claude Code's worktrees start from the default branch |

**The developer can pick the other route for one task**, in words ("use a chip for this one") or as
the argument (`chip`, `scripts`). They know the task: a copy change in a project whose worktrees run a
server never needs the server. Take their route and say what that worktree will lack — a chip's has no
port and no setup. Refuse only a chip where tasks start from another branch, and say why. Never pick
the other route on your own.

## Steps

1. **Name the task — nothing more.** Read only enough of the task to know its title and type
   (`feat`, `fix`, `chore`, `docs`, `refactor` — `hotfix` where the branching model uses it). No code
   reading, no requirement analysis, no planning. Choose a short kebab-case slug. If the task names
   a delivered feature, start the slug with that feature's spec-folder slug and add the change
   (`feat/newsletter-signup-topics`) — a directory listing (`ls specs/`) is enough; don't open the
   files. Whether it really is a change request is the worker's triage to decide.

2. **Hand it over by the route.**
   - **Claude Code's worktree.** In the desktop app, offer the task as a task chip — the app's way to
     start work in a new session with a worktree of its own. Its title is the task's; its prompt is
     the worker prompt (step 3). The developer starts it with one click, and this session carries on.
     In a terminal, give the developer one command to run in a new terminal:
     ```bash
     claude --worktree <slug> "<worker prompt>"
     ```
   - **The scripts' worktree.** Create it:
     ```bash
     scripts/agent/worktree-new.sh <type>/<slug> --no-start
     ```
     It creates a sibling worktree named after the branch (`../feat-newsletter-signup-topics`) on a
     new branch from the base branch — or reports the existing worktree unchanged. `--no-start` is
     deliberate: the environment belongs to the worker, which starts it only if its triage says a
     step needs it (`scripts/agent/worktree-new.sh <branch>` from the worktree). A hotfix from a
     release tag adds `--from <tag>`.

     Then give the developer the worktree's path on a line of its own and the worker prompt in a code
     block, to paste into a new session opened on that folder: in the desktop app, a new session with
     the worktree as its folder and the worktree option off; in a terminal,
     `cd <worktree path> && claude "<worker prompt>"`. **Never a task chip here**, nor the worktree
     option: both create a worktree of their own under `.claude/worktrees/`, without this one's env
     file, port, or setup — even when given this worktree as their folder.

3. **Write the worker's prompt** — pointers, not instructions:
   ```
   Task: <tracker link or one-line description>
   Worktree: <absolute path> — branch <type>/<slug>
   Follow AGENTS.md end to end, starting with triage.
   ```
   For Claude Code's worktree the app names the branch, so the second line is
   `Branch: <type>/<slug> — rename the generated branch to it after triage`.
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
| "This one won't run the app, so a chip will do" | Whether it runs the app is its triage's question. A wrong chip means a second dispatch and a new session; the scripts' worktree costs one paste. The developer can choose the chip — you don't. |
| "I'll offer a chip and give it the scripts' worktree as its folder" | A chip always creates a worktree of its own, without the env file, port, or setup. Hand over the prompt to paste. |
| "I'll start the environment so it's ready" | The worker may not need one (an answer-only task). It decides after triage. |
| "I'll open a placeholder issue or take the next spec number for the branch" | That's an outward-facing write, and numbers collide between parallel dispatchers. The slug is the join. |
| "I'll put the full workflow in the handoff to be safe" | Restated steps drift from `AGENTS.md`. Point at the process; don't copy it. |

## Red flags (stop and reassess)

- You've opened source files, specs, or tests in the main checkout.
- `git status` in the main checkout shows changes you made — or the protect-hub hook stopped an edit:
  you were about to work in the hub.
- The handoff prompt contains analysis, a plan, or a list of files to change.
- The route isn't the one the project's settings give, and the developer didn't ask for it.

## Verification

- [ ] Only the task's title and type were read
- [ ] The route is the project's, or the one the developer asked for — never a chip where tasks start from another branch
- [ ] The scripts' worktree was created (or reported) by `worktree-new.sh --no-start` — never by raw `git worktree add` — and handed over as a prompt to paste, never as a chip
- [ ] Nothing was edited, committed, or posted from the main checkout
- [ ] The worker prompt has the task link, the worktree path or the branch to rename to, and "follow AGENTS.md, starting with triage" — nothing else

## Principles

- The hub dispatches every task; worktrees work.
- The project picks the route; the developer can pick the other one for a task.
- Reads only, no writes, no analysis.
- Point at the process; never restate it.
