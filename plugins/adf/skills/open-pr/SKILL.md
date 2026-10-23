---
name: open-pr
description: Push the current work branch and open a DRAFT pull request that names its spec folder, links its tracker task, and states what was verified and what was not. Use as soon as your own local check passes — the changed flow walked on this checkout's environment — or, for work with nothing to run, once the full gate and /adf:review pass — or when the developer asks. Never before the local check, and never marks the pull request ready. With `refresh`, rebuilds your open draft's description after a later push changed what it says.
argument-hint: "[base branch — defaults to the one in CONTRIBUTING.md] | refresh"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/open-pr/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Open a Draft Pull Request

Pushing and opening a pull request leave this machine. Your own local check is what lets them:
once the changed flow works on this checkout's environment, open the draft without asking, in
every lane: it's the team's standing go-ahead. Work
with nothing to run — docs, CI — opens it once the full gate and `/adf:review` pass. The developer
tests the change after the draft opens, locally and on the preview. The git guard hook
refuses a `gh pr create` without `--draft`.

The pull request opens as a **draft** and stays one. Marking it ready is a claim — *"a person has
exercised this"* — that an agent can't make: it hasn't opened the preview, clicked through the flow,
or seen the result. The developer QCs the change and promotes it.

Use the repository host's CLI: `gh` for GitHub, `glab` (merge requests) for GitLab.

## Steps

1. **Check the branch.** It must be a work branch (`<type>/<slug>`), never a protected one.
   `git status` is clean; every commit belongs to this change. Find the base branch in
   `CONTRIBUTING.md` (or use the argument).

2. **Check the evidence.** Read `tasks.md` § Gate results in the spec folder. If the full gate
   hasn't run since the last commit, run it now (commands in `AGENTS.md` § Quick reference) and
   update the gate results. Anything you can't run — needs a preview, needs a shared service — is
   listed as *not verified*, with the reason.

   Then the **local check** (`AGENTS.md` § Delivery rules) — the gate for the push. When the change
   alters something a person can see or use, start it on this checkout's own environment and walk
   the changed flow yourself: every acceptance criterion, or the fast lane's "done when". Note what
   you tried and what you saw.
   - **A step fails:** fix it, rerun the gate, and walk the flow again. Nothing is pushed until it
     works.
   - **It can't run here** — the environment won't start, or a criterion needs something only a
     shared service has: stop before pushing and tell the developer what blocks it. A push to see
     it on the preview skips the gate.
   - **Leave the environment running.** The developer tests the change there after the draft opens.

   Docs-only and CI-only work has nothing to run: the full gate and a clean `/adf:review` stand in for
   the local check.

   **Careful lane: no stop before the push.** It pushes once the local check passes, like every
   lane. The risky part — the area, what the checklist found, what you walked — goes in the
   description's Lane line and leads the report, so the developer's test starts there.

3. **Verify the pull request, not just the diff.**
   - `git log --oneline <base>..HEAD` and `git diff --stat <base>...HEAD`: no unrelated files, no
     debug leftovers, no generated files or secrets.
   - Every changed file is inside the plan's change surface — or the plan was updated, and
     re-confirmed when the growth reached a risk. Say which in the description.
   - The description you're about to write claims nothing the diff doesn't do, and omits nothing it
     does.

4. **Write the title and body.** Title: a commit-style subject under 70 characters. Body: follow
   `.github/pull_request_template.md` when it exists; otherwise:

   ```markdown
   ## Traceability
   **Spec:** `specs/NNN-<slug>/` (CR N, when amending — "light" for a fast- or careful-lane
   adjustment) — or "none: fast lane" for work with nothing to record
   **Tracker task:** <link>  ·  `Closes #N` only for an engineering issue this resolves
   **Lane:** fast | careful | full — <reason>; set by <the triggers | a sensitive area | the developer>
   <careful: the checklist applied; the risky part — the area, what the checklist found, what you
   walked · lowered by the developer: <their reason>>

   ## What changed and why
   <!-- adf:what-changed -->
   <the change and its reasoning — a reviewer should not have to reconstruct intent from the diff>
   <!-- /adf:what-changed -->

   ## How to verify
   <!-- adf:how-to-verify -->
   1. <concrete step a reviewer can follow>
   **Tests:** <which tests cover this — added or extended>
   <!-- /adf:how-to-verify -->

   ## Verified / not verified
   <!-- adf:verified -->
   - Verified: <commands run, counts — from tasks.md § Gate results>
   - Local check: <the flow you walked on the local environment, and what you saw — or "nothing to run">
   - Preview: <the flow you walked on the preview, and what you saw — or "pending: deploying", "no preview", "nothing a person sees">
   - Not verified: <what you could not check, and why>
   <!-- /adf:verified -->

   ## Merge danger
   **Reversible:** yes — reverting the merge undoes it | no — <what a revert leaves changed>
   **Blast radius:** <who or what is affected if this is wrong — one page, every form, an API's callers>

   ## Screenshots
   <before / after for UI changes; delete otherwise>
   ```

   Keep the `adf:` markers, the repository template's included: they mark the sections you own,
   which § Refresh rebuilds later; everything outside them is the people's. Fill checklists
   honestly: leave a box unchecked and say why, rather than checking something you
   didn't do or deleting the line. **Merge danger** is the reviewer's first read on risk: a
   migration that drops or rewrites data, a sent email, a published URL or API contract, or a
   changed external integration is not undone by a revert — say what isn't.

5. **Push and open the draft.** Don't report yet — the developer hears from you once, in step 9:
   ```bash
   git push -u origin <type>/<slug>
   gh pr create --draft --base <base> --title "<title>" --body-file <file>
   ```
   (`glab mr create --draft --target-branch <base> …` on GitLab.)

6. **Record the link** when there's a spec folder — full lane or a light change request. Add the
   pull request URL to `pull-requests:` in `spec.md` (`· CR N` for a change request) and commit it
   (`spec: link <slug> pull request`), and push it to the same branch.

7. **Check the preview** when the project has previews (`AGENTS.md` § Quick reference) and the change
   alters something a person sees or uses. Wait for its deploy in the background — the host's check
   for it, `gh pr checks <n> --watch`, run as a background command, never a polling loop — then walk
   the same flow you checked locally, on the preview's URL:
   - **Read-only.** The preview is shared and may reach real services: don't submit what reaches a
     person or shared data unless the developer asks. Use a browser, not the end-to-end suite, which
     creates data and runs only against the local stack.
   - **Record it** in the body's *Preview* line (`gh pr edit <n> --body-file <file>`, from the
     current body — § Refresh).
   - **A difference from local** — it works here, not there — goes to the developer with what
     differs: configuration, data, the platform. It's not fixed by retrying the deploy.
   - **The deploy fails:** the *Preview* line says so, naming the failing check. Don't retry it on
     your own; the report says the preview couldn't be checked, and why.

   The developer's QC on the preview still decides ready; yours is evidence for it.

8. **Draft the review update** for a tracker task (`/adf:stakeholder-update review`): the task's move
   to the project's review status, and a business-focused report for the requester — what changes
   for them, the preview and what to test there, and the pull request link, which is the tracker
   link-back. It ends the report in step 9. Post it only on the developer's yes to the exact text,
   the status, and the assignee — often after their own test.

9. **Report — once, after the preview walk** (or right after step 6 when there's no preview to
   check): the pull request URL, and that it is a **draft** — in the careful lane, the risky part
   first. Then where the developer can test it:
   the local URL — the environment you left running — and the preview's, with what to try on each (the acceptance criteria, or the "done when"). Say what you verified on each,
   and what you could not. A fix they ask for goes on the same branch: walk it locally again, push,
   refresh the description (§ Refresh), and recheck the preview. Close with their next step, once: test it; ready and merge are theirs;
   you'll wrap up after the merge (`/adf:wrap-up`). Don't remind them on later turns or offer to
   promote it: when those happen is theirs. Never request reviewers. If, after their QC, they ask you to promote it, run `gh pr ready` then — never before,
   and never on your own initiative. For a tracker task, the review update's draft and its one
   question come last (step 8).

## Refresh — keep your draft's description current

`/adf:open-pr refresh`, once a later push to your own open draft changes what its description says:
a fix or a change request the developer asked for, a sync with the base branch, new gate results.
Editing your own draft's description is upkeep: it takes no prompt.

1. **Check the pull request:** `gh pr view <n> --json state,isDraft,body`. Merged or closed: stop and
   say so — never edit it or push to its branch. No longer a draft: the developer has taken it over,
   so show the diff (step 4) and apply it only on their yes.
2. **Fetch the current body** into a file and work from that copy, never from what you wrote last:
   people edit descriptions.
3. **Rebuild only the sections you own,** the text between each `<!-- adf:<section> -->` and its
   `<!-- /adf:<section> -->`: *What changed and why*, *How to verify*, and *Verified / not verified*.
   - **From the record, not from memory:** `tasks.md` § Gate results and the spec's change requests —
     what this pull request now delivers, with what the latest `CR N` changed. In the fast and
     careful lanes, the light `CR N` and the gate you just ran.
   - **Everything outside the markers stays byte for byte:** the traceability lines, checked boxes,
     a reviewer's notes, screenshots.
   - **A body without the markers** — opened before the template had them, or rewritten by hand — is
     all the people's: show the sections you'd replace, and apply only on the developer's yes.
4. **Show the description's diff** before you apply it, old against new:
   `git diff --no-index <old> <new>`. Sum it up in your report, so the developer sees what changed.
5. **Apply it** without waiting: `gh pr edit <n> --body-file <new>`. The title changes only when the
   scope did. When the change is one a person sees, recheck the preview (step 7).

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll remind them to review and ready it each time they come back" | Their next step is named once, in the report. A reminder on every turn is noise, and an offer to promote is a question they didn't ask. Ready, review, and merge are theirs. |
| "The report says where to test it; what comes after is obvious" | A developer switching between sessions comes back to this one cold. Name the next step and who takes it: their test, then ready and merge, then your wrap-up. |
| "CI is green, so I'll mark it ready" | CI is a signal, not the gate. Ready means a person exercised the change; green tests aren't that. |
| "I'll open it ready so the reviewer saves a click" | A ready pull request asks for attention now. Reviewers would spend it on a first QC pass the author should have done. |
| "Reviewers can read the diff — a short description is fine" | A reviewer shouldn't reconstruct intent. Agent pull requests whose description doesn't match the diff are a known failure. |
| "I'll tick every checklist box" | Ticking what you didn't verify is false certification. Unchecked with a reason is honest. |
| "The tests pass, so I'll push now" | The push waits for your own local check — the changed flow walked on this checkout's environment — or, with nothing to run, for the full gate and a clean `/adf:review`. |
| "It's outward — I'll ask before I commit, push, and open the draft" | Your local check is what lets them, in every lane: it's the team's standing go-ahead. The question only delays the developer's test, which comes after the draft opens. Ready and merge are where they decide. |
| "It's the careful lane, so I'll wait for a yes on the risky part" | The careful lane adds its checklist, not a stop. Put the risky part in the Lane line and first in the report; the developer's test starts there. |
| "The environment won't start — I'll push and check it on the preview" | Then nothing has run the change. Stop and tell the developer what blocks the local run; the preview is the second check, not a substitute for the first. |
| "I'll check it on the preview instead of starting the local stack" | Local first: the preview costs a deploy round-trip, is shared, and may reach real services. Check locally, then confirm on the preview. |
| "I'll report the draft now and send the preview when it deploys" | Two reports split the developer's test in two. The deploy waits in the background, so waiting costs them nothing: report once, with both URLs. |
| "I walked it locally — the developer will find the rest" | The report tells them where and what to test: the local URL, the preview's, and the criteria. A draft with no instructions makes them reconstruct the task. |
| "I'll move the task to Review and post the link while I'm here" | Both are writes the requester sees. Draft them as the review update, at the end of the report; post on the developer's yes to the exact text. |
| "I pushed the fix; the description can stay as it was" | Then it describes code that's gone, and the reviewer reads it first. After a push that changes what it says, refresh it. |
| "I'll rewrite the whole description from what I know now" | People edit descriptions: a reviewer's note, a ticked box, a screenshot. Rebuild only the sections between the markers, from the current body. |

## Red flags (stop and reassess)

- The branch is protected, or the diff contains files outside the change surface the plan didn't record.
- The gate hasn't run since the last commit and you were about to describe it as passing.
- The diff includes `.env` files, credentials, lockfile churn unrelated to the change, or debug code.
- The tasks in `tasks.md` aren't all ticked and the description doesn't say why.
- The change alters something a person can see or use, and you haven't walked it on the local environment.

## Verification

- [ ] The push followed your own local check — or, with nothing to run, a passing full gate and a clean `/adf:review` — or the developer's ask
- [ ] Nothing asked the developer whether to commit, push, or open the draft, in any lane; in the careful lane, the Lane line and the report name the risky part
- [ ] You walked the changed flow on the local environment before the push, and left it running — or it has nothing to run
- [ ] Opened as a **draft**; not marked ready
- [ ] The report doesn't ask, remind, or offer to review, ready, or merge it, and no reviewer was requested
- [ ] The change was checked on the preview once it deployed — read-only — or the body says why not
- [ ] One report, after the preview walk, gives the developer the local URL, the preview's, and what to try on each — or says why the preview wasn't checked
- [ ] The body names the spec folder and links the tracker task
- [ ] "Verified / not verified" matches `tasks.md` § Gate results
- [ ] The description matches the diff — no phantom or missing changes
- [ ] Merge danger says whether a revert undoes the change and what it affects if wrong
- [ ] The pull request URL is recorded in `spec.md` `pull-requests:`
- [ ] For a tracker task, the report ends with the review update's draft: the review status, the preview and what to test there, and the pull request link
- [ ] No tracker write was made without the developer's explicit yes on the exact text
- [ ] After a later push that changed what it says, the description was refreshed from its current body: only the sections between the markers, with the diff shown

## Principles

- The draft opens once your own local check passes; every other outward action waits to be asked.
- The developer tests after the draft opens, locally and on the preview — tell them where and what.
- Draft until a human has exercised it; the developer promotes it.
- Say what you verified and what you could not — evidence, not confidence.
- The description must be true to the diff.
