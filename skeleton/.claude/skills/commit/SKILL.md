---
name: commit
description: Review the working tree and create one clean, well-prefixed commit — an approved spec folder, a docs-first doc, one TDD task (its test and code together), or a standalone change — staging files by name and never bypassing hooks. Commits locally only; pushing is a separate, explicitly requested action. Use when work is ready to commit.
---

# Commit

Create one commit that captures one logical step. In spec-driven work that step is one of: the
approved spec folder, a docs-first doc, or one task from `tasks.md` (its test and code together).

## Steps

1. **See everything that changed:** `git status` and `git diff` (staged and unstaged). Understand
   every file before it goes in. Make sure you're on a work branch (`<type>/<slug>`), not a protected
   one — the git guard hook will refuse otherwise.

2. **Decide what this commit is** (phase order in `.claude/rules/git-workflow.md`):

   | Commit | Prefix | Must be true first |
   |---|---|---|
   | Approved spec folder (or an amendment: CR, plan correction) | `spec:` | `status: approved` with an `approvals:` line; required sections filled. Exception: a draft saved before the gate at the developer's request — `spec: draft <slug>`, status still `draft` |
   | Docs-first doc | `docs:` | It's in the plan's documentation plan; claims trace to ACs and planned tests |
   | One task | `feat:` / `fix:` / `refactor:` | Its test went red, then green; the task is ticked in `tasks.md` |
   | Contract-first acceptance tests, or characterization tests | `test:` | Acceptance tests fail for the right reason (red — pending implementation); characterization tests pass and were each seen failing once against a deliberately broken copy |
   | Doc reconciliation, backfill, ADR/PDR, gate results | `docs:` | Claims match what was built |
   | Tooling, dependencies, CI | `chore:` | Nothing to decide, no behavior change |
   | A fast- or careful-lane change | `feat:` / `fix:` / `chore:` | A test proves it (a bug's regression test failed first); the diff stays within the files stated at triage — or the lane moved up; on delivered work, the light `CR N` entry is in this commit; careful lane: the area's checklist is done and the developer confirmed the risky part |

   ```
   spec: approve newsletter-signup scope and plan
   docs: add admin guide for newsletter signup
   feat: reject invalid emails with an inline error
   test: add newsletter-signup acceptance tests (red — pending implementation)
   docs: record newsletter-signup gate results
   ```

3. **Check before committing:**
   - One logical step? If not, split it.
   - Nothing that shouldn't be committed: `.env` or credentials, generated files and build output,
     test artifacts, debug code, commented-out blocks.
   - **Spec commits:** approved, required sections filled.
   - **Task commits:** the test and the code for exactly one task; the test failed before the code
     and passes now; the task is ticked; committed docs still true (or the doc fix is in this commit,
     called out in the body).
   - **Fast- and careful-lane commits:** the triage's "done when" holds; the files match the ones it
     stated; the lane and any assumption go in the body when they aren't obvious.

4. **Stage files by name** — never `git add .` or `git add -A`.

5. **Write the message:** the prefix, then an imperative summary under 72 characters. Add a body when
   the *why* isn't obvious, when a small doc fix is folded in, or to reference the spec folder or task.

6. **Commit.** Hooks run — never `--no-verify` or `-n`. If a hook fails, fix what it reports. Don't
   amend an earlier commit unless asked.

7. **Confirm:** `git log -1 --stat` and `git status` — the commit holds what you meant; the tree is
   clean or shows only unrelated work.

Pushing is **not** part of committing. It happens only when the developer asks (`/open-pr`).

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll use `git add .` to save time" | It stages secrets, build output, and unrelated work. Stage by name. |
| "I'll commit three tasks together — they're related" | One task, one commit keeps history reviewable and each step revertible. |
| "I'll commit the spec and the code together" | Intent and execution are reviewed separately: the spec folder commits at the gate, code commits per task. |
| "The hook is slow / flaky — `--no-verify` just this once" | Hooks catch real mistakes, and the git guard blocks it anyway. Fix the cause. |
| "I'll amend the previous commit to keep history tidy" | Amending rewrites history and can destroy work. New commit, unless asked. |
| "I'll leave the debug log in and remove it later" | Debug code doesn't belong in commits. Remove it now. |
| "Committed — I'll push too, it's the next step" | Push is outward. Only when asked. |

## Red flags (stop and reassess)

- `.env`, credentials, or keys among the staged files.
- More than ~10 files for one task — the task may really be two.
- A task commit without its test, or a test that was never seen failing.
- Untracked files that weren't part of the task.
- You're on a protected branch.

## Verification

- [ ] Only the intended files are staged, by name
- [ ] The prefix matches the step, per the phase order
- [ ] No secrets, generated files, or debug code
- [ ] For a task: the test went red then green, and the task is ticked in `tasks.md`
- [ ] Hooks ran; nothing was bypassed
- [ ] `git log -1 --stat` confirms the commit; nothing was pushed

## Principles

- One logical step per commit; one task per commit in spec-driven work.
- The subject says what, the body says why; the diff shows how.
- Never commit secrets; never bypass hooks.
- Committing is local. Pushing is a separate decision.
