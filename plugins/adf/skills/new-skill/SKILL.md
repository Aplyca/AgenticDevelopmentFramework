---
name: new-skill
description: Turn a task this project repeats — add a redirect, scaffold a content block, add an environment variable — into a project skill in .claude/skills/, written from the commits and sessions where the task was done before, with the commands that check it and, when an invariant can be checked by a script, that script. Use when the developer asks for a skill for a recurring task, or says "we keep doing this by hand".
argument-hint: "<the recurring task, in a few words> [examples: commit SHAs or task links]"
---

# New project skill

The framework's skills carry the process; a project's own tasks — where its redirects live, how a
content block is wired, which file declares an environment variable — stay in people's heads until
someone writes them down. This skill writes one of them as a project skill, from evidence, in the
shape the framework's skills use, so the next agent does it right the first time.

The skill lives in the project, at `.claude/skills/<name>/SKILL.md`, committed and shared with the
team. It is the project's own layer: upgrades never touch it.

## Steps

1. **Find the evidence.** At least two past occurrences of the task: commits
   (`git log --oneline -i --grep=<word>`), merged pull requests, or the developer's examples. Read
   their diffs. With fewer than two, say the task isn't recurring yet and stop — a skill written
   from one example encodes that example's accidents.

2. **Check it isn't covered.** Read `.claude/skills/` and the framework's catalog. Never write a
   skill that repeats or shadows a framework one — no project `/commit`, `/review`, or a `/verify`
   that restates the Quick reference: the project's check command belongs in `AGENTS.md`
   § Quick reference, where every skill already finds it. Pick a name no framework skill uses: in
   a committed install they share `.claude/skills/`.

3. **Collect the facts,** each from a file you read:
   - **Where it lives:** the files the past diffs touched, and the format each one uses.
   - **The check:** the commands from `AGENTS.md` § Quick reference that prove the result, and how
     to see it on the local environment.
   - **The lane:** fast, or careful when the files match a sensitive area (`AGENTS.md` § Sensitive
     areas, `CAREFUL_GLOBS` in `.claude/hooks/config.sh`). Name it in the skill.
   - **The mistakes:** what the past diffs had to fix in review or in a follow-up commit.

4. **Present the outline and wait for a yes:** the name, the trigger description, the steps, and
   whether a check script is worth adding (step 6).

5. **Write `.claude/skills/<name>/SKILL.md`,** under ~120 lines:
   - **Frontmatter:** `name` (the folder name), a `description` that says what it does and when to
     use it in the words a request would use, and `argument-hint`. Documented keys only, hyphenated.
   - **Where it lives** — a short table of the files and their format.
   - **Steps** — the order the past diffs followed, each with the exact command or snippet, ending
     with the check and a `/adf:commit` in the skill's lane.
   - **Rationalizations (do not accept these)** — at least four rows, from the mistakes in step 3.
   - **Red flags** — when to stop and ask.
   - **Verification** — checkboxes the agent ticks before it commits.

6. **Add a check script only for an invariant a script can decide** — no duplicates, no redirect
   chains, a schema that parses — in the project's language and where it keeps its scripts
   (`AGENTS.md` § Quick reference or the repository layout; ask if neither says). It exits non-zero
   with a one-line reason per problem, and the skill's steps run it. No script for what a test or
   the linter already checks.

7. **Prove it on a past occurrence:** walk the skill's steps against the oldest example's diff. If
   following them wouldn't produce that diff, or would repeat its mistake, fix the skill.

8. **Commit** on a work branch with `/adf:commit`: `chore: add /<name> skill` — with the script in the
   same commit when there is one.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "One example is enough to see the pattern" | One diff can't tell the rule from its accidents. Two occurrences, or no skill yet. |
| "I'll add a `/verify` skill so the checks are easy to find" | The checks belong in `AGENTS.md` § Quick reference, where every skill reads them. A second copy drifts. |
| "I'll also cover the rare variants, to be complete" | A skill for the common case, with a red flag for the rest. Variants nobody has done are invented requirements. |
| "A script will make it robust" | Only for an invariant a script can decide. A script that restates the steps is code to maintain and tells nobody anything. |
| "I'll describe the files in general terms so the skill ages well" | Vague steps send the next agent searching. Name the files and formats; `/adf:context-audit` flags them when they move. |

## Red flags (stop and reassess)

- The task touches a sensitive area, and the skill would make it look routine — keep the careful lane.
- The past occurrences disagree on where or how — ask which one is right before writing either.
- The skill passes 150 lines, or covers more than one task — split it, or it isn't one task.
- The name matches a framework skill.

## Verification

- [ ] Two or more past occurrences were read, and the steps reproduce the oldest one
- [ ] No framework skill covers or shares the name; the checks point at `AGENTS.md` § Quick reference
- [ ] Every file, format, and command in the skill came from a file or diff that was read
- [ ] The lane is named, and a sensitive area keeps the careful lane
- [ ] Frontmatter uses documented, hyphenated keys; the description says when to use it
- [ ] A check script, if any, decides one invariant and exits non-zero on failure
