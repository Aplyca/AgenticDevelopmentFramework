---
name: open-pr
description: Push the current work branch and open a DRAFT pull request that names its spec folder, links its tracker task, and states what was verified and what was not. Never marks the pull request ready on its own, and never opens it before the developer approved a change they can see or use in a local check. Use only when the developer asks to push or open a pull request.
argument-hint: "[base branch — defaults to the one in CONTRIBUTING.md]"
disable-model-invocation: true
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/open-pr/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Open a Draft Pull Request

Pushing and opening a pull request leave this machine, so this skill runs only when the developer
asks for it — and Claude Code still asks you to confirm the push and the `gh pr create` call.

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

   Then the **local check** (`AGENTS.md` § Delivery rules). When the change alters something a person
   can see or use, the developer must have tested it by hand on the local environment and approved it.
   If they haven't, stop before pushing and offer it: start the environment, give the local URL and
   what to try — the acceptance criteria, or the fast lane's "done when" — and continue only after
   their OK. Docs-only, CI-only, and answer-only work has nothing to run and skips it.

3. **Verify the pull request, not just the diff.**
   - `git log --oneline <base>..HEAD` and `git diff --stat <base>...HEAD`: no unrelated files, no
     debug leftovers, no generated files or secrets.
   - Every changed file is inside the plan's change surface — or the plan was updated and
     re-confirmed. Say which in the description.
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
   <careful: the checklist applied · lowered by the developer: <their reason>>

   ## What changed and why
   <the change and its reasoning — a reviewer should not have to reconstruct intent from the diff>

   ## How to verify
   1. <concrete step a reviewer can follow>
   **Tests:** <which tests cover this — added or extended>

   ## Verified / not verified
   - Verified: <commands run, counts — from tasks.md § Gate results>
   - Local check: <what the developer tried on the local environment, and their OK — or "nothing to run">
   - Not verified: <what you could not check, and why — e.g. "UI on the preview deployment">

   ## Merge danger
   **Reversible:** yes — reverting the merge undoes it | no — <what a revert leaves changed>
   **Blast radius:** <who or what is affected if this is wrong — one page, every form, an API's callers>

   ## Screenshots
   <before / after for UI changes; delete otherwise>
   ```

   Fill checklists honestly: leave a box unchecked and say why, rather than checking something you
   didn't do or deleting the line. **Merge danger** is the reviewer's first read on risk: a
   migration that drops or rewrites data, a sent email, a published URL or API contract, or a
   changed external integration is not undone by a revert — say what isn't.

5. **Show the title and body to the developer**, then push and open the draft:
   ```bash
   git push -u origin <type>/<slug>
   gh pr create --draft --base <base> --title "<title>" --body-file <file>
   ```
   (`glab mr create --draft --target-branch <base> …` on GitLab.)

6. **Record the link** when there's a spec folder — full lane or a light change request. Add the
   pull request URL to `pull-requests:` in `spec.md` (`· CR N` for a change request) and commit it
   (`spec: link <slug> pull request`); it goes up with the next push the developer asks for.

7. **Offer — don't do — the tracker link-back.** Adding the pull request link to the tracker task is
   a write the requester can see: show the exact text and post it only on the developer's yes.

8. **Report:** the pull request URL, that it is a **draft**, what you verified, what you could not,
   and what the developer should QC before marking it ready (`gh pr ready`). If, after their QC, they
   ask you to promote it, run `gh pr ready` then — never before, and never on your own initiative.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "CI is green, so I'll mark it ready" | CI is a signal, not the gate. Ready means a person exercised the change; green tests aren't that. |
| "I'll open it ready so the reviewer saves a click" | A ready pull request asks for attention now. Reviewers would spend it on a first QC pass the author should have done. |
| "Reviewers can read the diff — a short description is fine" | A reviewer shouldn't reconstruct intent. Agent pull requests whose description doesn't match the diff are a known failure. |
| "I'll tick every checklist box" | Ticking what you didn't verify is false certification. Unchecked with a reason is honest. |
| "They asked me to commit, so pushing is implied" | Commit is local; push is outward. Each needs its own ask. |
| "The tests pass, and the preview will show it" | The developer approves the change on the local environment before the pull request exists. The preview check comes later, before ready. |
| "I'll post the link on the tracker task while I'm here" | That's a write the requester sees. Confirm the exact text first, every time. |

## Red flags (stop and reassess)

- The branch is protected, or the diff contains files outside the change surface the plan didn't record.
- The gate hasn't run since the last commit and you were about to describe it as passing.
- The diff includes `.env` files, credentials, lockfile churn unrelated to the change, or debug code.
- The tasks in `tasks.md` aren't all ticked and the description doesn't say why.
- The change alters something a person can see or use, and the developer hasn't approved it locally.

## Verification

- [ ] The developer asked for the push / pull request in this conversation
- [ ] The developer approved the change after testing it by hand on the local environment — or it has nothing to run
- [ ] Opened as a **draft**; not marked ready
- [ ] The body names the spec folder and links the tracker task
- [ ] "Verified / not verified" matches `tasks.md` § Gate results
- [ ] The description matches the diff — no phantom or missing changes
- [ ] Merge danger says whether a revert undoes the change and what it affects if wrong
- [ ] The pull request URL is recorded in `spec.md` `pull-requests:`
- [ ] No tracker write was made without the developer's explicit yes on the exact text

## Principles

- Outward actions happen only when asked.
- Draft until a human has exercised it; the developer promotes it.
- Say what you verified and what you could not — evidence, not confidence.
- The description must be true to the diff.
