---
name: context-audit
description: Read-only audit of the agent-instruction and process files (AGENTS.md and nested ones, rules, constitution, CONTRIBUTING, PR template, decision indexes, hook and CI configuration) against the repository and against each other — stale commands and paths, claims the code doesn't back, contradictions between files, missing metadata. Reports findings; fixes nothing. Use monthly, after process changes or framework upgrades, and before onboarding someone.
argument-hint: "[file or directory to limit the audit to — default: everything]"
---

# Context Audit (read-only)

Agent instructions drift the moment a pull request changes the repository without changing them.
Drift in these files is worse than drift in ordinary docs: agents follow them literally, and when two
files disagree an agent resolves the conflict by precedence — so a stale line in the file that wins
(the constitution) produces confidently wrong work.

This skill finds the drift and reports it. It changes nothing; fixes go in a normal `docs:` pull
request once the developer has read the report.

It complements Claude Code's built-in `/doctor prompt-audit`, which reviews the wording of Claude's
instruction files (phrasing written for older models, conflicting instructions). This audit checks
what the files **claim about the repository** and whether the files agree with each other — for every
agent tool, not only Claude Code.

## Steps

### Phase 1: Inventory

1. List what's in scope (or what the argument names):
   - `AGENTS.md` and every nested `AGENTS.md`; `GEMINI.md`, `.cursor/rules/`; a `CLAUDE.md` or
     `CLAUDE.local.md` anywhere is a finding: Claude Code reads it instead of `AGENTS.md`
   - `.claude/rules/`, project-specific skills and agents, `.claude/settings.json`, `.claude/hooks/config.sh`
   - `docs/CONSTITUTION.md`, `CONTRIBUTING.md`, `README.md`, `specs/README.md`
   - `.github/pull_request_template.md` (or the host's equivalent), CI workflows, git hooks
   - `docs/process/` and `docs/architecture/decisions/` indexes; `docs/reference/` pages

### Phase 2: Check each claim against the repository

2. **Commands** — every command in Quick reference, CONTRIBUTING, the PR template, and the
   verification checklists exists: a script in the manifest, a Makefile target, a binary on the
   path. Don't run anything destructive; to check that a command *works*, ask before running it.
3. **Paths** — every referenced file and directory exists; nested `AGENTS.md` files describe the
   folders that are really there.
4. **Behavior claims** — what the files say hooks, CI, and git hooks do matches the scripts and
   workflows themselves ("pre-push runs the unit tests" — does it?). Hook configuration
   (`PROTECTED_BRANCHES`, append-only paths) matches the documented branching and migration rules.
5. **Enforcement claims** — statements like "CI must pass before merge" or "the branch is
   protected": check what you can (with `gh`, read-only: `gh api repos/{owner}/{repo}/rulesets`). What
   you can't check from here is reported as UNVERIFIED, never assumed.
6. **Versions and environment** — runtime versions in docs match the version files and manifests;
   environment variables in docs match the env template.

### Phase 3: Check the files against each other

7. **Contradictions** — the branching model, base branch, merge method, release process, review
   rules, and commit conventions must agree across the constitution, `AGENTS.md`, `CONTRIBUTING.md`,
   the PR template, decision records, CI, and hook configuration. For each disagreement, say which
   file wins by precedence (the constitution overrides `AGENTS.md`; nested `AGENTS.md` overrides the
   root for its folder) and what an agent following that precedence would wrongly do.
8. **Decision records vs instructions** — accepted ADRs and PDRs are reflected in the instruction
   files; superseded ones are not still described as current.

### Phase 4: Hygiene

9. **Freshness** — each context file has its `owner · last_updated · scope` header, and
   `last_updated` isn't older than the file's last meaningful change (`git log -1 --format=%cs -- <file>`).
10. **Coverage** — modules with their own conventions but no nested `AGENTS.md`; reference pages
    whose linked code has moved.
11. **Bloat** — always-loaded files over ~200 lines; the same rule stated in several files (each copy
    drifts separately); generic advice ("follow best practices") that guides nothing; leftover
    template placeholders (`[...]`, `TODO(team)`). Also:
    - **No-ops** — an instruction the agent already follows by default. The test is whether
      behavior would change without it; a sentence that fails is deleted, not trimmed.
    - **Copies of the repository** — a list of scripts, a directory tree, versions, or config values
      that one command or one file already shows. They go stale; keep only what can't be looked up
      (an unwritten convention, the reason behind a choice, a gotcha no config admits).
    - **In the wrong tier** — material in an always-loaded file that only some tasks need belongs in
      a doc read on demand, behind a pointer that says *when* to read it ("Read `docs/X.md` before
      changing the payment flow"), not a bare "see X".
    - **Prohibitions without the target** — "don't do X" with no statement of what to do instead.

### Phase 5: Report

12. Group findings by severity, each with `file:line`, the evidence, and a recommended fix:

    ```
    CONTRADICTION  docs/CONSTITUTION.md:14 vs AGENTS.md:62 — merge target: constitution says
                   feature PRs target main, AGENTS.md says staging. Constitution wins, so an agent
                   would open feature PRs into main. Fix: amend the constitution (PDR).
    FALSE CLAIM    AGENTS.md:58 — "pre-push runs typecheck"; the hook runs lint only.
    STALE          CONTRIBUTING.md:40 — `npm run e2e` no longer exists (now `npm run test:e2e`).
    UNVERIFIED     CONTRIBUTING.md:88 — "approvals are required"; host rulesets not readable here.
    HYGIENE        src/lib/AGENTS.md — no metadata header; lists folders that moved.

    Summary: 1 contradiction, 1 false claim, 1 stale, 1 unverified, 1 hygiene.
    ```

13. **Offer the fix** as one `docs:` pull request — and a PDR when the fix changes a rule rather than
    restating it. Don't start until the developer says so.

For a parallel sweep across many files, the user can run the `/deep-context-audit` workflow.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll fix the small ones as I go" | The audit is read-only. Mixed audit-and-fix runs hide what was found and skip review. |
| "The constitution must be right — it's the constitution" | It wins conflicts, which is exactly why a stale line there is the most dangerous finding. |
| "I can't check the branch ruleset, so I'll assume the docs are right" | Report it as UNVERIFIED. An unverifiable enforcement claim is a finding, not a pass. |
| "These two files say almost the same thing — close enough" | "Almost" is where agents diverge. Report the difference precisely. |
| "No findings — the docs look fine" | Every claim either checked out or didn't; say what you checked, with counts, so "no findings" means something. |

## Red flags (stop and reassess)

- More than ~20 findings: the files may need restructuring, not patching — say so.
- A rule appears in three or more files: recommend one home plus links.
- You're about to run a command that writes, deploys, or migrates to "test" a claim.

## Verification

- [ ] Every file in scope was read; nested `AGENTS.md` files were included
- [ ] Commands, paths, behavior claims, enforcement claims, and versions were checked against the repository
- [ ] Cross-file contradictions name the winning file and the wrong action it would cause
- [ ] Claims that couldn't be checked are listed as UNVERIFIED
- [ ] No file was modified
- [ ] The report ends with counts per severity and a recommended next step

## Principles

- Read-only: report, then let the developer decide.
- Check claims against the repository, not against other docs alone.
- Contradictions matter most where precedence turns them into wrong actions.
- Unverifiable is a finding, never a pass.
