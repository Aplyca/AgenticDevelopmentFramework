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
passed; a person's review is next"*, not that a person has exercised it ([decision 0070](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0070-the-agent-marks-its-pull-request-ready.md)).

**Agents implement and review; humans decide** ([decision 0072](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0072-agents-implement-and-review-humans-decide.md)). The local environment is
yours, to build, test, and review the change; the preview is yours to test and review it, when
there is one, and the developer's to review, approve, and merge it. Marking it ready hands it over:
you request the project's reviewers then.

**The pull request is for technical communication with the developer; the ticket is for business
communication with stakeholders** ([decision 0073](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0073-the-ticket-for-stakeholders-the-pull-request-for-the-developer.md)).
How to review and test it, and what you tested, go in the description; what changes for the people
who use the system goes on the tracker task (step 9).

**GitHub or GitLab.** The steps name each action with its `gh` command. When the remote is on GitLab
(`git remote -v`), read `<this skill's base directory>/gitlab.md` first: it gives the `glab` command
for each step, and what differs.

**`refresh` and `sync` have steps of their own:** with either argument, read
`<this skill's base directory>/refresh.md` or `<this skill's base directory>/sync.md`, follow it,
and skip the steps below.

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
   as it was. Fix what's missing and commit it before the push. Everything the task changes in the
   repository merges with this pull request; after the merge, a missing line needs one of its own.

   Then the **local check** (`AGENTS.md` § Delivery rules) — the gate for the push. When the change
   alters something a person can see or use, start it on this checkout's own environment and walk
   the changed flow yourself: every acceptance criterion, or the fast lane's "done when". Note what
   you tried and what you saw.
   - **A step fails:** fix it, rerun the gate, and walk the flow again. Nothing is pushed until it
     works.
   - **The environment won't start:** stop before pushing and tell the developer what blocks it. A
     push to see it on the preview skips the gate.
   - **A criterion needs something only a shared service has** — a payment sandbox, a CMS webhook:
     walk every other criterion here, then push, and walk that one on the preview (step 7) before
     the pull request is ready. With no preview, stop before pushing and say what blocks it. A walk
     that writes beyond a test sandbox — it reaches a person or real shared data — waits for the
     developer's yes (`<this skill's base directory>/preview.md`, *A criterion only a shared service
     can run, whose walk writes*).
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
   `.github/pull_request_template.md` when it exists; otherwise:

   ```markdown
   ## Traceability
   **Spec:** `specs/NNN-<slug>/` (CR N, when amending — "light" for a fast- or careful-lane
   adjustment) — or "none: fast lane" for work with nothing to record
   **Tracker task:** <link> — a requester's issue: `Refs #N`, never `Closes`, since the merge isn't live  ·  `Closes #N` only for an engineering issue this resolves
   **Lane:** fast | careful | full — <reason>; set by <the triggers | a sensitive area | the developer>
   <careful: the checklist applied; the risky part — the area, what the checklist found, what you
   walked · lowered by the developer: <their reason>>

   ## What changed and why
   <!-- adf:what-changed -->
   <the change and its reasoning — a reviewer should not have to reconstruct intent from the diff>
   <!-- /adf:what-changed -->

   ## How to review and test
   <!-- adf:how-to-verify -->
   **Where:** <the preview's URL — "pending" until it deploys; or "no preview: `make up`, which prints where">
   1. <a step the reviewer follows there, in order> — <what they should see>
   **Look at:** <what deserves the reviewer's attention — the risky part, a decision, the files that carry the change>
   **Tests:** <which tests cover this — added or extended>
   <!-- /adf:how-to-verify -->

   ## Verified / not verified
   <!-- adf:verified -->
   - Verified: <commands run, counts — from tasks.md § Gate results; `/adf:review`: clean, or what it found and you fixed>
   - Local check: <the flow you walked on the local environment, and what you saw — or "nothing to run">
   - Preview: <the flow you walked and what you reviewed on the preview — layout, copy, console, accessibility — and what you saw; or "pending: deploying", "no preview", "can't reach it", "nothing a person sees">
   - Not verified: <what you could not check, and why>
   <!-- /adf:verified -->

   ## Merge danger
   **Reversible:** yes — reverting the merge undoes it | no — <what a revert leaves changed>
   **Blast radius:** <who or what is affected if this is wrong — one page, every form, an API's callers>

   ## Follow-ups
   - [ ] <a task found along the way, in one line> — <why it matters> (found in <file:line>)
   <or "- none">

   ## Screenshots
   <before / after for UI changes; delete otherwise>
   ```

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
   *Verified / not verified*, every line of step 4's template filled in. The reviewers you request
   next find them there.

   **Then request the reviewers** — the people who decide — from the **Reviewers** line in
   `CONTRIBUTING.md` § Pull requests: `gh pr edit <n> --add-reviewer <name>,<name>`, right after
   `gh pr ready`, without asking. Usernames, or a GitHub team. Never the author — the developer who
   runs this session opened it under their own name, and a self-review decides nothing. `CODEOWNERS`:
   GitHub requested them when it turned ready, so add no one. `none`, or no line: request no one, and
   the report says so. A draft requests no one.

   **Once it's ready, stop the local environment you started,** to free this machine's memory and
   CPU — stop, never down, kill, or remove ([decision 0071](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0071-stop-the-local-environment-once-ready.md)):
   end the background commands you started (the dev server), and stop the services with the
   project's stop task (`make stop` with the docker module; `AGENTS.md` § Quick reference), so
   `make up` resumes it for the next adjustment. Never `make down`, `make reset`, the worktree's
   `STOP_CMD`, or anything that removes containers, volumes, data, dependencies, or the worktree;
   when the project's only stop command does, end just your background commands and say what still
   runs. Kill only a process you started that ignores the stop. An environment that ran before this
   session is the developer's: leave it. A draft keeps its environment running.

9. **Update the tracker task** — a ClickUp task, a GitHub or GitLab issue — once the pull request
   is ready. A draft that stays one leaves the task where it is, with no review update.
   - **The status:** move the task to the project's review status on your own — no yes needed, and
     no skill to load — as `docs/TRACKER-INTEGRATION.md` § Rules for agents says: the task's own
     status for the moment, through the project's tracker tool, read back,
     forward only; the status alone, in a call of its own. The task the developer handed this session is theirs to move,
     assigned to them or not. One line says so.
   - **The review update** (`/adf:stakeholder-update review`): the business outcome, for the
     requester — what changes for them, the preview and what to test there — with the pull request
     link for reference, which relates the two. It posts on its own, and the report shows its text
     (step 10). Questions for the requester are a second message, a draft for the developer's yes;
     so is every message when § Stakeholder updates says *Updates post: on the developer's yes*.
   - **Can't write** — no tracker tool, or only one built into the host app: the report opens with
     the status to set and the update's text to paste.

10. **Report — once, after the preview walk and CI** (step 8). A turn that ends while the watch
   still runs isn't the report: say in a line that the pull request stays a draft until the checks
   finish and the watch's exit brings you back — never that it turns ready on its own. The report:
   the pull request URL, and that it is **ready for review** — or still a **draft**, and what holds it — in the careful lane, the risky
   part first — and who was requested to review it, or that no one was. Then where the developer
   reviews it: the preview's URL, and that the review instructions — what to try, what to look at,
   what you tested — are in the description (*How to review and test*); don't repeat them here. The
   local environment is yours, stopped since ready: don't send them there. With no
   preview, they review the pull request itself — the diff and the evidence — so say there's none,
   and give the command that runs it locally if they want to (`make up`, which prints where). While
   it's a draft, give the local URL only when they must see that for themselves. Say in a line what
   you tested and reviewed, locally and on the preview, and what you could not. A fix they or a
   reviewer ask for goes on the same branch, walked locally before the push: follow
   `<this skill's base directory>/refresh.md`, which keeps the record, the description, and the
   preview current — a pull request already ready stays ready.
   Close with their next step, once: review it on the preview; approving and merging are theirs;
   you'll wrap up after the merge (`/adf:wrap-up`). Don't remind them on later turns or offer to merge it: when that happens
   is theirs. Request no one beyond the Reviewers line. For a tracker task, say what you did on it
   (step 9): the status, and the review update's text as posted, with its link. A tracker you
   couldn't write to leads the report instead; a draft and its one question come last.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "CI is green, so I'll mark it ready" | CI is one condition, not the gate. Ready follows the walk of every criterion — locally, then on the preview — and green tests aren't a working flow. |
| "I'll `make down` to clean up properly" | Down removes the containers, and the next adjustment pays to recreate them. A stop keeps everything; down is `/adf:wrap-up`'s, after the merge. |
| "I couldn't test one criterion, but the rest works — I'll mark it ready and list the gap" | Ready says your tests passed. A criterion you couldn't test keeps it a draft; the report names it, and the developer decides. |
| "The developer should promote it, so I'll leave it a draft" | Ready is yours once your tests pass; a draft left after a clean report stalls silently. Only a rule in `AGENTS.md` § Delivery rules makes the promotion a person's. |
| "It's outward — I'll ask before I commit, push, and open the draft" | Your local check is what lets them, in every lane: it's the team's standing go-ahead. The question only delays the developer's test, which comes after your report. Review and merge are where they decide. |
| "I'll check it on the preview instead of starting the local stack" | Local first: the preview costs a deploy round-trip, is shared, and may reach real services. Check locally, then confirm on the preview. |
| "I'll report the draft now and send the preview when it deploys" | Two reports split the developer's test in two. The deploy and CI wait in the background, so waiting costs them nothing: report once, with both URLs and the pull request's state. |
| "I'll draft the review update and let the developer post it" | An outcome report posts on its own, with the pull request link, and the report shows its text. Only a question for the requester waits for a yes. |

## Red flags (stop and reassess)

- The branch is protected, or the diff contains files outside the change surface the plan didn't record.
- The gate hasn't run since the last commit that changed app files, and you were about to describe it as passing.
- The diff includes `.env` files, credentials, lockfile churn unrelated to the change, or debug code.
- You're about to stop the environment with `make down`, `make reset`, `STOP_CMD`, `-v`, or anything else that removes containers, volumes, or data — or to stop one this session didn't start.

## Verification

- [ ] The push followed your own local check — or, with nothing to walk, a passing full gate — and `/adf:review`, in every lane, its findings fixed or listed — or the developer's ask
- [ ] Nothing asked the developer whether to commit, push, or open the draft, in any lane; in the careful lane, the Lane line and the report name the risky part
- [ ] You walked the changed flow on the local environment before the push — or it has nothing to run — and once the pull request was ready, stopped what you started — `make stop`, the background commands ended — with no down, kill, or remove
- [ ] Opened as a **draft**; marked ready only once the full gate, every criterion's walk — locally, then on the preview when there is one — and CI passed, with nothing a criterion depends on unverified; otherwise left a draft, and the report says what holds it
- [ ] Once it was ready, the Reviewers line was requested — never the author — or the report says no one was; a draft requested no one
- [ ] The report doesn't remind or offer to review or merge it
- [ ] The change was tested and reviewed on the preview once it deployed — read-only — or the body says why not
- [ ] Just before it was marked ready, the description's *How to review and test* and *Verified / not verified* were rebuilt: where to review, the steps and what to expect, what to look at, the tests, what was and wasn't verified
- [ ] One report, after the preview walk and CI, says whether the pull request is ready and who was requested, and sends the developer to the preview and to the description's review instructions — or, with no preview, says so and how to run it locally
- [ ] The body names the spec folder and links the tracker task
- [ ] "Verified / not verified" matches `tasks.md` § Gate results
- [ ] Before each push, the spec folder was complete in the branch: every task ticked or struck through as a follow-up, the gate results, `status: implemented`
- [ ] The description matches the diff — no phantom or missing changes
- [ ] Merge danger says whether a revert undoes the change and what it affects if wrong
- [ ] The pull request URL is recorded in `spec.md` `pull-requests:`
- [ ] For a tracker task, once the pull request was ready: the task moved to the review status on its own, and the review update — the business outcome, the preview and what to test there, the pull request for reference — was posted and shown in the report; a requester's issue is referenced with `Refs`, not closed
- [ ] Nothing that asks the requester for something was posted without the developer's explicit yes on the exact text; with no tracker tool that can write, the report opened with the status to set and the text to paste
- [ ] After a later push that changed what it says, the description was refreshed from its current body: only the sections between the markers, with the diff shown

## Principles

- The draft opens once your own local check passes, and turns ready once your own tests and review pass — locally, on the preview, and CI. Once it's ready, the reviewer request, the task's status move, and the review update need no yes in chat. Reviewing, approving, merging, and any message that asks the requester for something wait for a person.
- Agents implement and review; humans decide. Local is yours to build, test, and review; the preview is yours to test and review, and the developer's to review, approve, and merge.
- Say what you verified and what you could not — evidence, not confidence.
- The description speaks to the developer who reviews it; the ticket speaks to the people who asked.
- The description must be true to the diff.
