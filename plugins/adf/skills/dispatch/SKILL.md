---
name: dispatch
description: With the parallel-agents module: move a triaged task — a change, or anything that runs the app, the tests, or the database — to its own worktree and branch under .claude/worktrees/; a session that already has a task offers another one a new session. Use right after triage, in the main checkout or Claude Code's own worktree, and when a session is handed an unrelated task or finds one along the way.
argument-hint: "[<type>/<slug>, or the other task]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/dispatch/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Dispatch

**Every task gets its own session, worktree, folder, branch, and pull request.** A developer starts
a new session for each new task, in the main checkout or wherever the desktop app opens it, and that
session becomes the task's. Once triage says the task needs a worktree, this skill creates it under
the main checkout's `.claude/worktrees/` and moves the session there. The main checkout takes no edits (the protect-hub
hook stops them), so nothing lands on the base branch, and no session sits in it handing tasks out.

This skill needs the `parallel-agents` module: without `ops/agent/worktree.conf` in this
repository (or `scripts/agent/worktree.conf`, where it was before the module moved), say the module
isn't installed and stop.

## Which route

| This session | The task | Route |
|---|---|---|
| Has no task yet: in the main checkout, or in Claude Code's own worktree on a generated branch or a detached HEAD | A change, in any lane, or an answer whose triage needs an environment | **Move here** |
| The same | An answer that only reads — code, docs, the tracker | None. Answer from where you are, and edit nothing. A change the answer recommends moves once the developer approves it |
| Has a task: in a worktree on a task branch, or one already done in this conversation | Another task — one the developer brings, or one found along the way | **A new session** — except a finding, when the stamp on `AGENTS.md`'s first line names `github` or `gitlab`: it's a follow-up the close-up files as an issue, and gets a session only when the developer wants it now |

A session on a task branch that wasn't created by the scripts (an old Claude Code worktree) has its
task: it stays a worker, and the session-context hook names what it lacks.

Neither route asks first. The triage is on the page, and the developer redirects it; the chip is
where they choose whether the other task starts.

## Steps

### Move here

1. **After the triage,** which names the branch: `<type>/<slug>`, where `<type>` is the commit
   type (`feat`, `fix`, `chore`, `docs`, `refactor`; `hotfix` where the branching model uses it).
   A change request starts the slug with the delivered feature's spec-folder slug and adds the
   change (`feat/newsletter-signup-topics`). If the session context says the base branch is behind
   origin's, run `git pull --ff-only` in the main checkout first.
2. **Create the worktree:** `adf-worktree-new <type>/<slug> --no-start` (a hotfix from a release tag
   adds `--from <tag>`). It's under the main checkout's `.claude/worktrees/`, named after the branch
   (`.claude/worktrees/feat-newsletter-signup-topics`), on a new branch from `BASE_BRANCH`, with the
   env file seeded from the main checkout's and, when worktrees run a server, a port reserved.
   Nothing starts.
3. **Move this session into it** with `EnterWorktree`, `path` set to the path the script printed,
   in the desktop app and in a terminal alike. The approve-worktree-move hook approves a worktree of
   this repository, so Claude Code's permission check doesn't ask. Not `change_directory`: the app
   refuses it for a session in its own worktree, which every chip's is, or in a folder another
   session shares.

   If the move is refused, give the developer the path and stop: they open a session on that folder.
4. **Confirm with `pwd`, and carry on with the task** where the triage left it. The triage stands;
   don't repeat it. Session-start hooks don't run again after the move, so look for the branch's
   spec folder yourself (`ls specs/`). The desktop app keeps showing this session in the folder it
   started in; the pull request still reaches its PR bar when `/adf:open-pr` opens it.

Until the move, run nothing but the script, and edit and commit nothing. In Claude Code's own
worktree, never rename its generated branch: the app reuses that folder for a later session once
this one is archived (`/adf:wrap-up`).

A command that stops in the main checkout and hands itself here moves the same way, on the branch
it names, and then runs in the worktree as the developer typed it.

### A new session

1. **Name the task in one line.** Don't read into it: its own session triages it.
2. **Write its prompt** — the task, and the process to follow:
   ```
   Task: <tracker link or one-line description>
   Follow AGENTS.md end to end, starting with triage.
   ```
   If the developer set a lane or asked for more effort, pass it on in their words
   (`Developer: full lane — the billing rules are fragile`), since triage honors it. Don't restate
   the workflow: the session reads it in `AGENTS.md`.

   **One part of a split feature** — a provider and its consumers, in separate spec folders: the
   contract is written into both specs before the split (`specs/README.md` § Granularity), and the
   prompt carries it — the provider's folder and the shared interface (parameter names, accepted
   values, field IDs, endpoints) — and says how a change to it is recorded:
   ```
   Contract: specs/012-topic-catalog/ § Constraints — GET /api/topics?state=active|archived → { id, label }.
   Any change to it is recorded in the consumer's spec and pull request.
   ```
3. **Offer it:**
   - **Desktop app:** a task chip for this repository, with the prompt, titled with the task's title
     alone (`Show the chosen topics after signup`). The new session's triage moves it to its own
     worktree, and the app then shows that folder, named after the branch.
   - **Terminal:** one command to run in a new terminal, in the main checkout: `claude "<prompt>"`.
4. **Carry on with this session's own task.** The other one needs nothing more from this
   conversation. One found along the way is also a line in this pull request's `## Follow-ups`
   (`specs/README.md` § Found along the way), so it survives a chip nobody started.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "It's a one-line fix — I'll just do it here" | The main checkout is shared, and its base branch takes no commits. A change in any lane gets its worktree first. |
| "I'll make the worktree before triage, to save time" | The triage names the branch, and an answer that only reads needs no worktree at all. |
| "The app refused `change_directory`, so I'll give the developer the path" | The app refuses it from its own worktree, whatever the folder. `EnterWorktree` reaches the task's worktree from there: stop only if that's refused too. |
| "The app already gave this session a worktree, so it can work there" | The app's worktree is on a generated branch, without the env file, the setup, or a name after the branch, and the app reuses its folder for a later session — with whatever this task left in it, its stack included. Create the task's worktree, and move. |
| "This session is free now — I'll take the next task here" | One task per session, worktree, branch, and pull request. Another task in this session mixes their context and their history. Offer it a new session. |
| "The plan is approved — I'll start a fresh session for the docs and implementation" | That's a phase of this task, not another task: it stays in this session. Two sessions on one branch split the context, and the waiting one wakes on every turn the other ends. Compact and switch the model here (`/adf:write-plan` step 12). |
| "I'll ask whether to open a new session for it" | The chip is that question. Asking first makes the developer answer twice. |
| "I found an unrelated bug, so it gets a chip now" | With the `github` or `gitlab` module, a finding is filed as an issue at the close-up, where the team decides when it's done. A session now is the developer's call. |
| "I'll triage the other task here so its session gets a head start" | Its session triages it where it can check what it reads. Analysis here drifts in the hand-off. |
| "The other part's session will work out the interface from the code" | Its branch was cut from a base without the provider's change. A contract written in both specs, and carried in the prompt, is the only one both sides read. |

## Red flags (stop and reassess)

- You're about to edit, commit, or create a branch in the main checkout, or the protect-hub hook
  stopped an edit.
- You created a worktree before the triage was on the page, and no command handed itself here with its branch.
- You renamed Claude Code's generated branch, or committed in its worktree.
- This session already has a task, and you started working on another.

## Verification

- [ ] The triage came first and named the branch — or a command that stopped in the main checkout named it
- [ ] A change — or an answer that needed an environment — got its own worktree under `.claude/worktrees/` before any edit, and `pwd` showed the session there
- [ ] An answer that only read stayed where it was and changed nothing
- [ ] Another task got a new session, as a chip titled with the task or a `claude "<prompt>"` command, and this session kept to its own — a finding, with the `github` or `gitlab` module, only when the developer wanted it now
- [ ] A part of a split feature got the contract in its prompt, and where a change to it is recorded
- [ ] Nothing was edited or committed in the main checkout or in Claude Code's own worktree

## Principles

- One task: one session, one worktree, one folder, one branch, one pull request.
- The session that takes a task moves to its worktree; nothing hands tasks out from the main checkout.
- Triage first: it names the branch, and says whether the task needs a worktree at all.
- Another task, another session.
