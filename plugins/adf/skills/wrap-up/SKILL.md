---
name: wrap-up
description: When a task ends — its pull request merged, its answer delivered, or its pull request closed and the developer drops the task — check that nothing is left (no uncommitted or unpushed work, no stash, no open task or promised follow-up), then ask once to close up: stop what the task started, remove its worktree and branch, update the base branch, and archive the session. Use when the developer says the pull request merged ("merged", "it's in"), when the app or the pr-state hook reports the merge or the close, when an answer task is done, or when asked to wrap up, close up, or clean up a finished or abandoned task. Not for a task on hold.
argument-hint: "[pull request, when it isn't this branch's]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/wrap-up/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Wrap up

A task ends one of three ways: its pull request **merged**, its **answer delivered** (no pull
request), or its pull request **closed** and the developer drops the task (**abandoned**). Each leaves
things behind:
- its branch, locally and on the host;
- its worktree, beside the main checkout;
- whatever it started: containers, a server on the host, a background command;
- its session in the app's sidebar;
- a base branch in the main checkout that is now behind origin's.

Each one costs a little: memory, a port, a stale folder, a sidebar the developer has to read past.
Over a week of parallel tasks they pile up.

Wrapping up clears them, **with one yes and only when nothing is left**. Unfinished work is never
cleared: the check comes first, and anything it finds is the developer's to decide.

A task the developer puts **on hold** isn't ending: don't wrap it up. Record why, and what resumes
it, where its record is — an `On hold:` line under § Gate results in `tasks.md`, or in the pull
request's description; for an answer, in the session itself — and close the turn with that. Offer
the close-up only once it resumes and ends.

## Steps

1. **Check where you are.**
   - **The main checkout, with the parallel-agents module** (`ops/agent/worktree.conf` or
     `scripts/agent/worktree.conf` exists, and `git rev-parse --git-dir` equals
     `git rev-parse --git-common-dir`): a session here has no worktree or branch to wrap up — its task,
     if any, moved to a worktree, or was an answer. Say so in a line and stop. A worktree whose session is
     gone is removed from here with `adf-worktree-rm <branch>`, only when the developer asks.
   - **Anywhere else** — a task worktree, Claude Code's own worktree, or the main checkout of a
     project without the module — go on.

2. **Read the state.** Run the reads together:
   - **The pull request:** `gh pr view --json number,url,state,mergedAt,headRefName,headRefOid` for
     this branch, or the one the developer named (`glab mr view` on GitLab). Its state names the
     ending:
     - **Merged** — go on.
     - **Closed without merging** — its work isn't upstream. Go on only once the developer says the
       task is dropped (**abandoned**); otherwise ask, and stop.
     - **Still open** — the task isn't over: say what it waits on (the developer's test, ready, the
       merge) and stop.
     - **None, on a branch with no commits past the base** — an **answer**: go on when it was
       delivered where the task asked. With commits and no pull request, the work isn't delivered:
       say so and stop.
   - **The follow-ups,** for a merged pull request: its body (`gh pr view --json body`), from the line
     `## Follow-ups` to the next heading. Each unchecked line, `- [ ] \`<command>\` — <why> (<source>)`,
     is work the merge made necessary — `/adf:upgrade` writes them (issue #89). `- none`, a checked
     line, or no section: nothing to offer.
   - **The working tree:**
     - `git status --porcelain` — uncommitted changes, including untracked files;
     - `git stash list` — stashes from this branch;
     - `git log --oneline <headRefOid>..HEAD` — commits made after the pull request's last one,
       which the merge doesn't have (for an answer, `git log --oneline <base>..HEAD`).
   - **The record:** in the spec folder, the unchecked tasks in `tasks.md`, the spec's open questions,
     and its `status:`. Then this session's own promises: a follow-up you said you'd do, a `/adf:handoff`
     not yet given, a side task you noted for later.
   - **What's running:** what this worktree started — `make ps` with the docker module's
     conventions, in either mode — and the background commands this session started. Running
     things aren't work left over: they go in the close-up.

3. **If anything is left, list it and stop.** Show each item, and what clearing it would take:
   commit and push, open a follow-up, drop the stash, give the handoff. Offer no close-up until
   the developer settles them. Nothing is deleted or archived in this case.

   Time not yet logged isn't work left over. Only when the stamp on `AGENTS.md`'s first line names
   the `time-tracking` module, offer `/adf:track-time` once, before the close-up: the task's
   worktree is still there to measure. The developer may skip it. Without the module, say nothing
   about time.

   An end-user page waiting to be published isn't work left over either. Only when the stamp names
   the `end-user-docs` module, the pull request merged, the spec lists an end-user page whose draft
   isn't retired yet, and `docs/END-USER-DOCS.md` publishes after the merge, offer
   `/adf:end-user-docs publish` once, before the close-up. The developer may skip it: a release
   publishes it later. Without the module, say nothing about end-user docs.

4. **Ask once.** Show what the close-up will do, in order, naming the real paths and branches:
   ```
   PR #<n> merged, and nothing is left in this task. Close up?
   - Stop what it started: <the containers, the app on the host, the background commands>
   - Remove the worktree <path> and its branch <type>/<slug> (here and on origin)
   - Update <base> in the main checkout to origin's
   - Start, each in its own session, once <base> is updated: <the follow-up commands, with why>
   - Archive this session
   ```
   The first line names the ending: `PR #<n> merged`, `The answer is delivered`, or `PR #<n> closed
   and the task is dropped`. An abandoned task keeps its branch **on origin** — the closed pull
   request points at it and can be reopened — so its line reads "its branch <type>/<slug> (here
   only; origin's stays)". Drop a line that doesn't apply. In a terminal, the last line is "end this session (`/exit`)".
   Follow-ups are not unfinished work, so they don't block the close-up: they ride in the same yes,
   and the developer can drop any of them from it.
   Wait for the yes. A "yes, but keep the session" or "keep the branch" changes only that line.

5. **On the yes, close up in this order.** Removing the worktree takes away this session's folder,
   so after that step, run nothing but the archive.
   1. **Stop what the task started.**
      - The background commands this session started.
      - The environment: `make down` with the docker module's conventions, or the project's stop
        command (`docs/getting-started/DEV-SETUP.md`). `adf-worktree-rm` also runs `STOP_CMD` when
        the project sets one.
   2. **Remove the branch from origin,** if the host didn't delete it on merge
      (`git ls-remote --heads origin <branch>`): `git push origin --delete <branch>`. Skip it for an
      abandoned task, and for an answer whose branch was never pushed.
   3. **Remove the worktree and update the base branch.** Which way depends on the worktree:
      - **A worktree from the scripts:** `cd <main checkout> && adf-worktree-rm <branch>`.
        - It removes the worktree, fast-forwards the base branch in the main checkout, and deletes
          the branch when git sees it as merged.
        - After a squash merge, it keeps the branch and says so. Delete it with
          `git -C <main checkout> branch -D <branch>`: the merged pull request holds its work. An
          abandoned task's branch goes the same way: the state you read showed its last commit on
          origin.
      - **Claude Code's own worktree** (under `.claude/worktrees/`): leave it. Archiving the session
        removes it. Update the base branch in the main checkout as below.
      - **No worktree** (a session in the main checkout):
        1. `git switch <base> && git pull --ff-only`;
        2. then `git branch -d <branch>`, or `-D` after a squash merge.

      The main checkout's base branch is updated only when it is checked out there and the main
      checkout has no uncommitted changes. Otherwise, say why it wasn't updated.
   4. **Start the follow-ups,** when the list had any and the developer kept them. Each one is a
      session of its own, from the updated base branch in the main checkout, because it needs the merged
      change; it changes the project's environment or tests and goes through its own review.
      - **In the desktop app:** call `start_session` once per follow-up, `"fresh"`, with the command as
        the brief and its why and source; the yes was the developer's ask. Don't run the command here.
      - **In a terminal:** print each command, for the developer to run in a new session from the main
        checkout.
      - If the base branch wasn't updated, say so: the follow-up would start without the merge.
   5. **Report, then archive.**
      - **Report:** in one short reply, say what was stopped, removed, deleted, and updated, the
        follow-ups started, and anything that didn't happen and why.
      - **Archive, in the desktop app:** in the same turn, call the app's `archive_session` with
        `"self"` and the ending as the reason: `PR #<n> merged`, `Answer delivered`, or `PR #<n>
        closed, task dropped`. The conversation ends there.
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
| "I'll wrap up the other finished worktrees while I'm at it" | Each task's session wraps up its own. Another worktree may hold work its session hasn't pushed. From the main checkout, the developer asks for each one. |
| "The pull request closed, so the task is abandoned" | Closed can mean replaced, paused, or closed by mistake. Only the developer says it's dropped, and even then origin's branch stays. |
| "It's on hold, but I'll close up the worktree to free the port" | On hold means it resumes. Stop what's running if the developer asks; the worktree, branch, and session stay. |
| "It was only an answer, nothing to check" | An answer can leave a stash, a scratch branch, a running environment, or a follow-up you promised. Check, then ask once. |
| "The upgrade's follow-ups are mine to run now" | They change the project's environment and tests: each belongs in its own session and review. Offer them; start them in their own sessions. |

## Red flags (stop and reassess)

- You're about to use `--force` with `adf-worktree-rm`, to delete origin's branch for a pull request
  that isn't merged, or to delete a local branch whose last commit isn't on origin.
- The check found uncommitted work, unpushed commits, or a stash, and you're about to close up anyway.
- You're in the main checkout of a hub.
- A command is about to run in the worktree after it was removed.

## Verification

- [ ] The ending is real, by the host's own state, not by the conversation: merged; closed and dropped in the developer's words; or an answer delivered, with no commits past the base
- [ ] No uncommitted changes, stash, or commits after the pull request's last one; nothing open in `tasks.md`; no promise left
- [ ] The developer saw the full list and said yes once, before anything was stopped or removed
- [ ] The pull request's `## Follow-ups` were offered in the same yes, and each kept one started in its own session, never run here
- [ ] What the task started was stopped before its worktree was removed
- [ ] The report says what happened, including anything that didn't; the archive came last

## Principles

- Every ending gets a close-up; a task on hold gets none.
- The check before the close-up; one yes for the close-up.
- Unfinished work is never cleared — it's listed for the developer.
- Each task's session wraps up its own task.
