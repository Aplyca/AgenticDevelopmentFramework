---
name: dispatch
description: From the main checkout, hand a task to its own worktree — name the task, create the worktree and branch with scripts/agent/worktree-new.sh --no-start, and start (or hand the developer) a worker session there with a short prompt that points at the process. Does no analysis and edits nothing. Use when a task arrives in the main checkout and needs the scripts' worktree (a port, setup or start commands, a base branch other than the default) — or when the developer asks for it.
argument-hint: "[tracker link or task description]"
---

# Dispatch

The main checkout is the shared hub where every developer and agent session starts. **In the main
checkout you dispatch; you never work.** Editing there blocks every other session, and analysis done
there is wasted: the dispatcher can't run the app or the tests, its conclusions are unverified, and
the worker in the worktree has to redo the reading anyway — now with tools that can check it. The
dispatcher's context stays cheap: a branch name, not a plan.

A dispatcher **writes nothing outside this machine** and takes no outward-facing action. Its only
network calls are reads: the task in step 1, and the `git fetch` inside the worktree script.

## Which route

A task gets its worktree one of two ways (decision 0015):

- **Claude Code's worktree** — a new session with the worktree option: the desktop app's worktree
  toggle, or `claude --worktree <slug>`. No dispatcher needed: the worker renames the branch to
  `<type>/<slug>` after triage, and `.worktreeinclude` copies the env file. The default when the
  project's worktrees run no server and tasks start from the default branch.
- **The scripts — this skill** — when the worktree needs what only they set up: a port, setup or
  start commands, or a base branch other than the default branch (`scripts/agent/worktree.conf`).
  The session-context hook says which applies when this session starts.

When a task arrives here and Claude Code's worktree fits, say so and stop: the developer starts a new
session with the worktree option and gives it the task. Otherwise, follow the steps.

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
   It creates a sibling worktree named after the branch (`../feat-newsletter-signup-topics`) on a
   new branch from the base branch — or reports the existing worktree unchanged. `--no-start` is
   deliberate: the environment belongs to the worker, which starts it only if its triage says a step
   needs it (`scripts/agent/worktree-new.sh <branch>` from the worktree). A hotfix from a release
   tag adds `--from <tag>`.

3. **Start the worker session in the worktree.**
   - Terminal: `cd <worktree path> && claude`, then paste the prompt from step 4.
   - Desktop app: a new session with the worktree as its folder — not the worktree option, which
     would create a second worktree without this one's port and setup. Give the developer the prompt
     from step 4.

4. **Write the worker's prompt** — pointers, not instructions:
   ```
   Task: <tracker link or one-line description>
   Worktree: <absolute path> — branch <type>/<slug>
   Follow AGENTS.md end to end, starting with triage.
   ```
   Don't restate the workflow: the worker reads it in `AGENTS.md`, and a copy in a handoff message is
   one more thing that drifts. If the developer set a lane or asked for more effort, pass it on in
   their words — `Developer: full lane — the billing rules are fragile` — since triage honors it.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll read the task properly first so the worker gets a head start" | The worker redoes the reading where it can verify it. Analysis here is unverified, burns the hub's context, and drifts in the handoff. |
| "It's a one-line fix — I'll just do it here" | The main checkout is shared. A stray edit or a running server here collides with every other session. |
| "I'll start the environment so it's ready" | The worker may not need one (an answer-only task). It decides after triage. |
| "I'll open a placeholder issue or take the next spec number for the branch" | That's an outward-facing write, and numbers collide between parallel dispatchers. The slug is the join. |
| "I'll put the full workflow in the handoff to be safe" | Restated steps drift from `AGENTS.md`. Point at the process; don't copy it. |

## Red flags (stop and reassess)

- You've opened source files, specs, or tests in the main checkout.
- `git status` in the main checkout shows changes you made — or the protect-hub hook stopped an edit:
  you were about to work in the hub.
- The handoff prompt contains analysis, a plan, or a list of files to change.

## Verification

- [ ] Only the task's title and type were read
- [ ] The route fits: the scripts only when the task needs their setup, or the developer asked for them
- [ ] The worktree was created (or reported) by `worktree-new.sh --no-start` — never by raw `git worktree add`
- [ ] Nothing was edited, committed, or posted from the main checkout
- [ ] The worker prompt has the task link, worktree path, branch, and "follow AGENTS.md, starting with triage" — nothing else

## Principles

- The hub dispatches; worktrees work.
- Reads only, no writes, no analysis.
- Point at the process; never restate it.
