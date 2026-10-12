---
name: wrap-up
description: After a task's pull request merges, check that nothing is left — no uncommitted or unpushed work, no stash, no open task or promised follow-up — then ask once to close up: update the base branch, stop what the task started, remove its worktree and branch, and archive the session. Use when the developer says the pull request merged ("merged", "it's in"), when the app reports the merge, or when asked to wrap up, close up, or clean up a finished task.
argument-hint: "[pull request, when it isn't this branch's]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/wrap-up/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Wrap up

A merged task leaves things behind:
- its branch, locally and on the host;
- its worktree, beside the main checkout;
- whatever it started: containers, a server on the host, a background command;
- its session in the app's sidebar;
- a base branch in the main checkout that is now behind origin's.

Each one costs a little: memory, a port, a stale folder, a sidebar the developer has to read past.
Over a week of parallel tasks they pile up.

Wrapping up clears them, **with one yes and only when nothing is left**. Unfinished work is never
cleared: the check comes first, and anything it finds is the developer's to decide.

## Steps

1. **Check where you are.**
   - **The main checkout of a hub** (`ops/agent/worktree.conf` or `scripts/agent/worktree.conf` exists,
     and `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`): the dispatcher's session
     stays open and has no task to wrap up. Say so in a line and stop. A worktree whose session is
     gone is removed from here with `adf-worktree-rm <branch>`, only when the developer asks.
   - **Anywhere else** — a task worktree, Claude Code's own worktree, or the main checkout of a
     project without the module — go on.

2. **Read the state.** Run the reads together:
   - **The pull request:** `gh pr view --json number,url,state,mergedAt,headRefName,headRefOid` for
     this branch, or the one the developer named (`glab mr view` on GitLab). It must be **merged**.
     Closed without merging, or still open: say so and stop.
   - **The working tree:**
     - `git status --porcelain` — uncommitted changes, including untracked files;
     - `git stash list` — stashes from this branch;
     - `git log --oneline <headRefOid>..HEAD` — commits made after the pull request's last one,
       which the merge doesn't have.
   - **The record:** in the spec folder, the unchecked tasks in `tasks.md`, the spec's open questions,
     and its `status:`. Then this session's own promises: a follow-up you said you'd do, a `/adf:handoff`
     not yet given, a side task you noted for later.
   - **What's running:** what this worktree started — `make ps` with the docker module's
     conventions, in either mode — and the background commands this session started. Running
     things aren't work left over: they go in the close-up.

3. **If anything is left, list it and stop.** Show each item, and what clearing it would take:
   commit and push, open a follow-up, drop the stash, give the handoff. Offer no close-up until
   the developer settles them. Nothing is deleted or archived in this case.

4. **Ask once.** Show what the close-up will do, in order, naming the real paths and branches:
   ```
   PR #<n> merged, and nothing is left in this task. Close up?
   - Stop what it started: <the containers, the app on the host, the background commands>
   - Remove the worktree <path> and its branch <type>/<slug> (here and on origin)
   - Update <base> in the main checkout to origin's
   - Archive this session
   ```
   Drop a line that doesn't apply. In a terminal, the last line is "end this session (`/exit`)".
   Wait for the yes. A "yes, but keep the session" or "keep the branch" changes only that line.

5. **On the yes, close up in this order.** Removing the worktree takes away this session's folder,
   so after that step, run nothing but the archive.
   1. **Stop what the task started.**
      - The background commands this session started.
      - The environment: `make down` with the docker module's conventions, or the project's stop
        command (`docs/getting-started/DEV-SETUP.md`). `adf-worktree-rm` also runs `STOP_CMD` when
        the project sets one.
   2. **Remove the branch from origin,** if the host didn't delete it on merge
      (`git ls-remote --heads origin <branch>`): `git push origin --delete <branch>`.
   3. **Remove the worktree and update the base branch.** Which way depends on the worktree:
      - **A worktree from the scripts:** `cd <main checkout> && adf-worktree-rm <branch>`.
        - It removes the worktree, fast-forwards the base branch in the main checkout, and deletes
          the branch when git sees it as merged.
        - After a squash merge, it keeps the branch and says so. Delete it with
          `git -C <main checkout> branch -D <branch>`: the merged pull request holds its work.
      - **Claude Code's own worktree** (under `.claude/worktrees/`): leave it. Archiving the session
        removes it. Update the base branch in the main checkout as below.
      - **No worktree** (a session in the main checkout):
        1. `git switch <base> && git pull --ff-only`;
        2. then `git branch -d <branch>`, or `-D` after a squash merge.

      The main checkout's base branch is updated only when it is checked out there and the main
      checkout has no uncommitted changes. Otherwise, say why it wasn't updated.
   4. **Report, then archive.**
      - **Report:** in one short reply, say what was stopped, removed, deleted, and updated, and
        anything that didn't happen and why.
      - **Archive, in the desktop app:** in the same turn, call the app's `archive_session` with
        `"self"` and the reason `PR #<n> merged`. The conversation ends there.
      - **If the app doesn't archive it** (the session is pinned, open on screen, or still has work
        running), say so: the developer archives it from the sidebar.
      - **In a terminal:** tell the developer the session is done, and that `/exit` ends it.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The pull request merged, so everything in the worktree is in `main`" | Not a commit made after its last push, an untracked file, or a stash. Check them, and list what you find. |
| "It's only a stash, I'll drop it with the rest" | A stash is work someone set aside on purpose. It's the developer's to drop. |
| "I'll ask for each step, to be safe" | One yes for the whole list, shown in full, is the confirmation. A prompt per step trains the developer to click through them. |
| "The developer said 'merged', so I'll clean up right away" | "Merged" starts the check, not the close-up. Removing a worktree deletes files, and archiving hides the conversation: ask first. |
| "I'll remove the worktree first, then stop its containers" | The stop command runs from the worktree, and Compose names the project after its folder. Stop first, then remove. |
| "`git branch -d` refused, so the branch isn't merged" | After a squash merge, git can't see it. The merged pull request is the proof; delete it with `-D`. |
| "I'll wrap up the other finished worktrees while I'm at it" | Each task's session wraps up its own. Another worktree may hold work its session hasn't pushed. From the hub, the developer asks for each one. |
| "The pull request closed, close enough" | Closed without merging means its work isn't upstream. Removing the branch would lose it. |

## Red flags (stop and reassess)

- You're about to use `--force` with `adf-worktree-rm`, or to delete a branch whose pull request
  isn't merged.
- The check found uncommitted work, unpushed commits, or a stash, and you're about to close up anyway.
- You're in the main checkout of a hub.
- A command is about to run in the worktree after it was removed.

## Verification

- [ ] The pull request is merged, by the host's own state, not by the conversation
- [ ] No uncommitted changes, stash, or commits after the pull request's last one; nothing open in `tasks.md`; no promise left
- [ ] The developer saw the full list and said yes once, before anything was stopped or removed
- [ ] What the task started was stopped before its worktree was removed
- [ ] The report says what happened, including anything that didn't; the archive came last

## Principles

- The check before the close-up; one yes for the close-up.
- Unfinished work is never cleared — it's listed for the developer.
- Each task's session wraps up its own task, and the hub's session stays open.
