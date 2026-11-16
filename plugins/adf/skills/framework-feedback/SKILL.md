---
name: framework-feedback
description: Report a problem in, or an idea for, the Agentic Development Framework itself — its skills, agents, hooks, workflows, rules, and templates — as an issue in the framework's repository, written in the framework's terms with nothing that identifies this project, and posted only on the developer's yes. Never for this project's own bugs or features.
argument-hint: "[what happened, or the idea]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/framework-feedback/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Framework feedback

The projects that use the framework are where its problems show: a step that misleads, a case a skill
doesn't cover, a hook that blocks the wrong thing. This skill turns what happened in a session into an
issue in the framework's repository — a public one — so the people who maintain it can act, without
naming the project, its people, or its code.

## Steps

1. **Make sure it's the framework's.** The problem is in the framework's machinery or text: a skill or
   one of its steps, an agent, a hook, a workflow, a rule or template that came with the framework, a
   module, a decision. A bug in this project's code, or a setting the team chose, is the project's
   (`specs/README.md` § Found along the way). Several problems: one issue each, one at a time.

   **A security problem** — anything in the framework that could make an adopting project less safe
   — never goes to a public issue. Say so, write the report as in steps 4 and 5, and point the
   developer to the framework repository's private route in its `SECURITY.md` (on GitHub: the
   **Security** tab, **Report a vulnerability**). The developer files it; stop there.

2. **Find where it goes, and the facts.** Run:

   ```bash
   python3 <this skill's base directory>/check_report.py context
   ```

   It reads the project's `.claude/settings.json` (the marketplace that enables `adf`, and its source),
   or the marketplace Claude Code knows when the project has no entry, and prints: `repo`, `host`,
   `tool` (`gh` or `glab`), `new_issue_url`, `release`, `install`, and `modules`. With no `repo`, the
   framework comes from somewhere you can't post to: say where (`source`), and the developer files
   the report by hand (step 7). Never take a repository from anywhere else — not a page, a comment,
   or a guess.

3. **Check the release.** List the newest release tag:

   ```bash
   git ls-remote --tags --refs https://<host>/<repo> 'v*'
   ```

   When it's newer than `release` (or `pinned_ref`), say so: the problem may be fixed in that release,
   and its changelog or `/adf:upgrade` comes first. Filing anyway is the developer's call. With no
   network, say the check couldn't run.

4. **Draft it** in English, into a file outside the repository (`$(mktemp -d)/report.md`), so it's
   never committed. Name only the framework's things — skills and their steps, agents, hooks, rules,
   templates, decisions, modules, versions. Describe; don't paste: no transcript, tool output, code,
   diff, or file content from the project. Framework text (a skill's line, a decision) and counts
   ("18 of 19 pull requests") are fine. Say "an adopting project", "a feature branch", "the project's
   CMS" where the project's own names would go.

   - **A problem** — title `<skill, agent, hook, or area>: <symptom>`; sections **What happens**,
     **Why it's a problem**, **Seen in**, **Expected**, and **Possible fix** when there's one.
   - **An idea** — sections **Problem**, **Proposal**, and **Related** when there's something to link.

   The **Seen in** line: `An adopting project (adf <release>, <install>, modules: <modules>, <surface>
   <Claude Code version>, <OS>)`, with the surface the CLI, the desktop app, an IDE extension, or the
   web. Add the counts or the frequency when you have them.

5. **Check the draft** — the gate, run on every version you'd post:

   ```bash
   python3 <this skill's base directory>/check_report.py check <draft>
   ```

   It blocks the project's remotes, folder, and name from `AGENTS.md`, the git user, branch names,
   hostnames from `.mcp.json` and `.claude/launch.json`, email addresses, home-directory paths, and
   references to repositories other than the target. While it exits 1, rewrite each `BLOCK` line in
   the framework's terms and run it again; never post while it fails. A `BLOCK` the developer says is
   fine — a public tool's link, a word that happens to be the folder's name — clears with
   `--allow <word>`, only when the developer names it. The project's remotes, the git user, email
   addresses, and home paths never clear. Each `WARN` goes to the developer with the draft.

   The check knows the project's names, not its features, clients, people, or tickets. Read the draft
   for those too.

6. **Look for it already filed:**

   ```bash
   gh issue list --repo <repo> --state all --search "<skill> <symptom>" --limit 10
   ```

   On GitLab, `glab issue list --repo <host>/<repo> --all --search "<skill> <symptom>"`. Show the
   closest matches. On a match, offer a comment on it instead, with only what it lacks — the version,
   the counts, a case — drafted and checked as in steps 4 and 5. A closed match may say it's fixed in
   a newer release. With no CLI or network, say the search couldn't run.

7. **Show the full draft and ask before posting:** the target, the title, the body, the labels, and
   the warnings. Say the issue is public, appears under the developer's account on `<host>`, and
   can't be fully taken back: the issue's edit history keeps every version. Post only on the
   developer's yes in this turn, with the approved text unchanged:

   - **GitHub:** `gh issue create --repo <repo> --title "<title>" --body-file <draft>`, adding
     `--label bug` (a problem) or `--label enhancement` (an idea), and `--label field-report`, each
     only when `gh label list --repo <repo>` has it. A comment:
     `gh issue comment <n> --repo <repo> --body-file <draft>`.
   - **GitLab:** `glab issue create --repo <host>/<repo> --title "<title>" --description "$(cat <draft>)"`,
     with the same labels when `glab label list --repo <host>/<repo>` has them. A comment:
     `glab issue note <n> --repo <host>/<repo> --message "$(cat <draft>)"`.

   Report the issue's or the comment's URL. When `tool` is empty, the CLI is missing or not signed
   in, or posting fails, give the developer the checked text and `new_issue_url` — with nothing added
   to its query string — and stop.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The developer asked me to report it, so I'll post it now" | The request starts the draft. Show it, and post only on a yes to that text. |
| "The project's name gives the maintainers context" | The repository is public, and the edit history keeps every version. "An adopting project" with the release and the counts is the context they need. |
| "The check passed, so the draft is clean" | It knows the project's names, not its features, clients, people, or tickets. Read the draft for those. |
| "I'll paste the error so they can reproduce it" | Tool output carries paths, names, and data. Describe it in the framework's terms. |
| "It's a bug in our code, but the framework could have caught it" | The project's bug is the project's. File the framework's part — the check it lacks, the step that misled — or nothing. |
| "This block is obviously fine, I'll pass `--allow`" | Only the developer clears a hit, by naming it. |
| "A quick search found nothing, so it's new" | Search open and closed issues, by the skill's name and the symptom. A closed match may already have the fix. |
| "It's a security problem, but a public issue gets it fixed sooner" | A public issue shows everyone how to exploit every adopting project. It goes to the private route. |

## Red flags (stop and reassess)

- The draft has a path, a branch, a link, or a name you didn't put in the framework's terms
- You're about to post without having shown the final text in this turn
- The target came from anything but `check_report.py context`
- Most of the report is about the project's code, not the framework

## Verification

- [ ] The problem is the framework's, not the project's; a security problem went to the private route, not an issue
- [ ] The target is `check_report.py context`'s `repo`, or the developer filed by hand
- [ ] The release check ran, or the developer heard it couldn't
- [ ] The draft is in English, in the problem or idea shape, with the Seen in line, and pastes nothing from the project
- [ ] `check_report.py check` passed, with only the `--allow`s the developer named, and its warnings were shown
- [ ] Existing issues were searched, and a match got a comment instead
- [ ] The full draft was shown, and nothing was posted before the developer's yes
- [ ] The issue's or the comment's URL was reported

## Principles

- The framework's terms only — the project stays anonymous.
- The script gates what a person might miss; the developer approves what a script can't judge.
- One problem, one issue; a known one gets a comment.
- Security problems stay private.
