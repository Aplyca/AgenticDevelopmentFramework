---
name: open-pr
description: Push the work branch, open a draft pull request, and mark it ready once your own tests pass — locally, on the preview, and CI — then update the tracker task. Use once your own local check passes — for docs or CI, once the gate and /adf:review pass — or when the developer asks. `refresh` updates the draft's description after a later push; `sync` brings the base branch in.
argument-hint: "[base branch — defaults to the one in CONTRIBUTING.md] | refresh | sync"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/open-pr/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Open a Pull Request, and Mark It Ready

Pushing and opening a pull request leave this machine. Your own local check is what lets them:
once the changed flow works on this checkout's environment, open the draft without asking, in
every lane: it's the team's standing go-ahead. In the full lane, it's the end of the run the
approval gate authorized (`/adf:implement`): go on to ready with no stop but for a decision. Work
with nothing to run — docs, CI — opens it once the full gate and `/adf:review` pass. The git guard hook refuses a `gh pr create` without `--draft`.

The pull request opens as a **draft** — the window where the preview deploys and CI runs before
anyone is asked to look — and you **mark it ready** once your own tests pass: every criterion worked
locally, and on the preview when there is one, and CI is green. Ready means *"the agent's tests
passed; a person's review is next"*, not that a person has exercised it (decision 0070).

**Agents implement and review; humans decide** (decision 0072). The local environment is
yours, to build, test, and review the change; the preview is yours to test and review it, when
there is one, and the developer's to review, approve, and merge it. Marking it ready hands it over:
you request the project's reviewers then.

**The pull request is for technical communication with the developer; the ticket is for business
communication with stakeholders** (decision 0073).
How to review and test it, and what you tested, go in the description; what changes for the people
who use the system goes on the tracker task (step 9).

**GitHub or GitLab.** The steps name each action with its `gh` command. When the remote is on GitLab
(`git remote -v`), read `<this skill's base directory>/gitlab.md` first: it gives the `glab` command
for each step, and what differs.

**`refresh` and `sync` have steps of their own:** with either argument, read
`<this skill's base directory>/refresh.md` or `<this skill's base directory>/sync.md`, follow it,
and skip the steps below.

**In a compacted conversation, re-read this `SKILL.md` before going on:** the summary keeps where
the run stood, not these steps.

## Steps

1. **Check the branch.** It must be a work branch (`<type>/<slug>`), never a protected one.
   `git status` is clean; every commit belongs to this change. Find the base branch in
   `CONTRIBUTING.md` (or use the argument).

2. **Check the evidence and the record.** Read `tasks.md` § Gate results in the spec folder. If the
   full gate hasn't run since the last commit that changed app files — source, tests, package
   manifests, the app framework's configuration — run it now (commands in `AGENTS.md` § Quick
   reference) and update the gate results. A commit that only records gate results, ticks tasks,
   links the pull request, or edits the spec folder or docs doesn't count, so recording the gate
   never calls for another run; a merge from the base follows `/adf:open-pr sync`'s rule. Anything you can't run — needs a preview, needs a shared service — is
   listed as *not verified*, with the reason.

   Then the record, when there's a spec folder: every task in `tasks.md` ticked, or struck through as a follow-up with why (it
   goes under Follow-ups), and `spec.md` at `status: implemented` — a light change request leaves it
   as it was. Fix what's missing and commit it before the push.

   Then the **local check** (`AGENTS.md` § Delivery rules) — the gate for the push. When the change
   alters something a person can see or use, start it on this checkout's own environment — local
   first, even with a preview — and walk the changed flow yourself: every acceptance criterion, or
   the fast lane's "done when". Note what you tried and what you saw.
   - **A step fails:** fix it, rerun the gate, and walk the flow again. Nothing is pushed until it
     works.
   - **The environment won't start:** stop before pushing and tell the developer what blocks it. A
     push to see it on the preview skips the gate.
   - **A criterion needs something only a shared service has** — a payment sandbox, a CMS webhook:
     walk every other criterion here, push, and walk that one on the preview (step 7) before the
     pull request is ready; a walk there that writes beyond a test sandbox waits for the developer's
     yes. With no preview, stop before pushing and say what blocks it.
   - **Keep the environment running until the pull request is ready** (step 8): the preview walk or
     CI can still send you back to fix the change.

   Docs-only and CI-only work has nothing to run: the full gate and a clean `/adf:review` stand in for
   the local check.

   **Careful lane: no stop before the push.** It pushes once the local check passes, like every
   lane; the risky part goes in the description's Lane line (step 4) and leads the report, so the
   developer's test starts there.

3. **Review it, then verify the pull request.**
   - **Run `/adf:review`, in every lane** — it reads in proportion to the lane — and fix what it
     finds before the push, walking the flow again when a fix touches it. A finding you leave goes
     under *Not verified*, with why.
   - `git log --oneline <base>..HEAD` and `git diff --stat <base>...HEAD`: no unrelated files, no
     debug leftovers, no generated files or secrets.
   - Every changed file is inside the plan's change surface — or the plan was updated, and
     re-confirmed when the growth reached a risk. Say which in the description.
   - The description you're about to write claims nothing the diff doesn't do, and omits nothing it
     does.

4. **Write the title and body.** Title: a commit-style subject under 72 characters. Body: follow
   `.github/pull_request_template.md` when it exists; with none, read
   `<this skill's base directory>/body.md` — the same sections: *Traceability*, *What changed and
   why*, *How to review and test*, *Verified / not verified*, *Merge danger*, *Follow-ups*. A
   requester's issue is `Refs #N`, never `Closes`, since the merge isn't live; `Closes #N` only for
   an engineering issue this resolves.

   Keep the `adf:` markers, the repository template's included: they mark the sections you own,
   which `refresh` rebuilds later; everything outside them is the people's. Fill checklists
   honestly: leave a box unchecked and say why, rather than checking something you
   didn't do or deleting the line. **Follow-ups** lists every bug or improvement this session found
   outside the task (`specs/README.md` § Found along the way) — gathered from your reports, not from
   memory of the last one; on the open draft, add a line when you find one, and never tick or remove
   one: the developer does. One the developer had filed as an issue is written ticked, with its link
   (`→ #<n>`). **Merge danger** is the reviewer's first read on risk: a
   migration that drops or rewrites data, a sent email, a published URL or API contract, or a
   changed external integration is not undone by a revert — say what isn't.

5. **Push and open the draft.** Don't report yet — the developer hears from you once, in step 10:
   ```bash
   git push -u origin <type>/<slug>
   gh pr create --draft --base <base> --title "<title>" --body-file <file>
   ```
   On GitLab, the commands in `<this skill's base directory>/gitlab.md`.

6. **Record the link** when there's a spec folder — full lane or a light change request. Add the
   pull request URL to `pull-requests:` in `spec.md` (`· CR N` for a change request) and commit it
   (`spec: link <slug> pull request`), and push it to the same branch.

7. **Check the preview — test and review it** when the project has previews (`AGENTS.md` § Quick
   reference), you can reach them, and the change alters something a person sees or uses: read
   `<this skill's base directory>/preview.md` and follow it — the deploy awaited in the background,
   the flow you checked locally walked again on the preview's URL, with any criterion only a shared
   service could run, then a review of what a person sees there, read-only, and recorded in the
   body's *Preview* line.

8. **Mark it ready once your own tests pass.** CI is awaited in the background with the preview's
   deploy — `gh pr checks <n> --watch`, run as a background command, never a polling loop; with no
   preview to check, start it right after step 6. Run it even when the host app watches the pull
   request and says not to poll CI, as the Claude desktop app's Auto-fix does: that wakes you for a
   failing check, never a green one, so only this command's exit brings you back to mark it ready. A
   failure both wake you for is one fix. Then, once all of these hold, write the review
   instructions (below) and run `gh pr ready <n>` — no prompt, no question:
   - the full gate passed, with no commit that changed app files after it (step 2);
   - every acceptance criterion, or the "done when", worked on a test environment — locally, and on
     the preview when there is one — or, with nothing to run, the full gate passed;
   - `/adf:review` came back clean, or its findings were fixed — and so did your review on the
     preview, when there was one;
   - CI finished green, or the project has none;
   - nothing a criterion depends on is listed under *Not verified*.

   Until then it stays a draft. A failing check or criterion that's yours to fix: fix it on the
   branch, walk the flow locally again, push, refresh the description (`/adf:open-pr refresh`),
   start the watch again, and check again. One you can't test or fix — a preview that won't deploy,
   a difference from local only the developer can explain — keeps it a draft, and the report says what holds it. When
   `AGENTS.md` § Delivery rules says a person marks pull requests ready, leave the draft: it's
   theirs.

   **Write the review instructions first.** The description is how you talk to the developer who
   reviews it. Just before marking it ready, rebuild two of its sections, as
   `<this skill's base directory>/refresh.md` steps 3–6 say: *How to review and test* and
   *Verified / not verified*, every line of the template (step 4) filled in. The reviewers you request
   next find them there.

   **Then request the reviewers** — the people who decide — from the **Reviewers** line in
   `CONTRIBUTING.md` § Pull requests: `gh pr edit <n> --add-reviewer <name>,<name>`, right after
   `gh pr ready`, without asking. Usernames, or a GitHub team. Never the author — the developer who
   runs this session opened it under their own name, and a self-review decides nothing. `CODEOWNERS`:
   GitHub requested them when it turned ready, so add no one. `none`, or no line: request no one, and
   the report says so. A draft requests no one.

   **Once it's ready, stop the local environment you started,** to free this machine's memory and
   CPU — stop, never down, kill, or remove (decision 0071):
   end the background commands you started (the dev server), and stop the services with the
   project's stop task (`make stop` with the docker module; `AGENTS.md` § Quick reference), so
   `make up` resumes it for the next adjustment. Never `make down`, `make reset`, the worktree's
   `STOP_CMD`, or anything that removes containers, volumes, data, dependencies, or the worktree;
   when the project's only stop command does, end just your background commands and say what still
   runs. Kill only a process you started that ignores the stop. An environment that ran before this
   session is the developer's: leave it. A draft keeps its environment running.

9. **Update the tracker task** — a ClickUp task, a GitHub or GitLab issue — once the pull request
   is ready; with none, skip this step. Read `<this skill's base directory>/tracker.md` and follow
   it. In short:
   - **The status:** move the task to the project's review status on your own — no yes needed, and
     no skill to load — forward only; the status alone, in a call of its own. The task the developer
     handed this session is theirs to move, assigned to them or not.
   - **The review update** (`/adf:stakeholder-update review`): the business outcome, for the
     requester, posted on its own; a question for the requester waits for the developer's yes.

10. **Report — once, after the preview walk and CI** (step 8). A turn that ends while the watch
   still runs isn't the report: say in a line that the pull request stays a draft until the checks
   finish and the watch's exit brings you back — never that it turns ready on its own. The report:
   the pull request URL, and that it is **ready for review** — or still a **draft**, and what holds it — in the careful lane, the risky
   part first — and who was requested to review it, or that no one was. Then where the developer
   reviews it: the preview's URL, and that the review instructions are in the description (*How to
   review and test*); don't repeat them here. The local environment is yours, stopped since ready:
   don't send them there. With no preview, they review the pull request itself — the diff and the
   evidence — so say there's none, and give the command that runs it locally if they want to
   (`make up`, which prints where). While it's a draft, give the local URL only when they must see that for
   themselves. Say in a line what you tested and reviewed, locally and on the preview, and what you
   could not. A fix they or a reviewer ask for goes on the same branch, walked locally before the
   push: follow `<this skill's base directory>/refresh.md`, which keeps the record, the description,
   and the preview current — a pull request already ready stays ready.
   Close with their next step, once: review it on the preview; approving and merging are theirs;
   you'll wrap up after the merge (`/adf:wrap-up`). Don't remind them on later turns or offer to merge it: when that happens
   is theirs. For a tracker task, the report says what step 9 did, as `tracker.md` says.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "CI is green, so I'll mark it ready" | CI is one condition, not the gate. Ready follows the walk of every criterion — locally, then on the preview — and green tests aren't a working flow. |
| "I'll `make down` to clean up properly" | Down removes the containers, and the next adjustment pays to recreate them. A stop keeps everything; down is `/adf:wrap-up`'s, after the merge. |
| "I couldn't test one criterion, but the rest works — I'll mark it ready and list the gap" | Ready says your tests passed. A criterion you couldn't test keeps it a draft; the report names it, and the developer decides. |
| "The developer should promote it, so I'll leave it a draft" | Ready is yours once your tests pass; a draft left after a clean report stalls silently. Only a rule in `AGENTS.md` § Delivery rules makes the promotion a person's. |
| "It's outward — I'll ask before I commit, push, and open the draft" | Your local check is what lets them, in every lane: it's the team's standing go-ahead. The question only delays the developer's test, which comes after your report. Review and merge are where they decide. |

## Red flags (stop and reassess)

- The branch is protected, or the diff contains files outside the change surface the plan didn't record.
- The gate hasn't run since the last commit that changed app files, and you were about to describe it as passing.
- The diff includes `.env` files, credentials, lockfile churn unrelated to the change, or debug code.
- You're about to stop the environment with `make down`, `make reset`, `STOP_CMD`, `-v`, or anything else that removes containers, volumes, or data — or to stop one this session didn't start.

## Verification

- [ ] The push followed your own local check — the changed flow walked on the local environment, or, with nothing to walk, a passing full gate — and `/adf:review`, in every lane, its findings fixed or listed — or the developer's ask
- [ ] Nothing asked the developer whether to commit, push, or open the draft, in any lane; in the careful lane, the Lane line and the report name the risky part
- [ ] Opened as a **draft**; marked ready only once the full gate, every criterion's walk — locally, then on the preview, read-only, when there is one — and CI passed, with nothing a criterion depends on unverified; otherwise left a draft, and the report says what holds it
- [ ] Just before it was marked ready, *How to review and test* and *Verified / not verified* were rebuilt: where to review, the steps and what to expect, what to look at, the tests, what was and wasn't verified
- [ ] Once it was ready, the Reviewers line was requested — never the author — or the report says no one was, and what you started was stopped — `make stop`, the background commands ended — with no down, kill, or remove; a draft requested no one
- [ ] One report, after the preview walk and CI, says whether the pull request is ready and who was requested, and sends the developer to the preview and the description's review instructions — or, with no preview, says so and how to run it locally — with no reminder or offer to review or merge it
- [ ] Before each push, the spec folder was complete in the branch: every task ticked or struck through as a follow-up, the gate results, `status: implemented`; the pull request URL is in `spec.md` `pull-requests:`
- [ ] The description matches the diff, with no phantom or missing changes, and *Verified / not verified* matches `tasks.md` § Gate results; it names the spec folder, links the tracker task, and says under Merge danger whether a revert undoes the change and what it affects if wrong
- [ ] For a tracker task, `tracker.md`'s checks hold; a requester's issue is referenced with `Refs`, not closed
