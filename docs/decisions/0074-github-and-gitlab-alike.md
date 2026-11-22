# 0074: GitHub and GitLab alike

- **Status:** accepted
- **Date:** 2026-11-12
- **Amends:** [0072](0072-agents-implement-and-review-humans-decide.md) — it made `/adf:open-pr`
  and the draft guard host-agnostic and left the rest for this change; [0038](0038-fewer-prompts-for-tasks-and-local-git.md)
  — the skeleton's settings ask GitLab's outward actions by name too, where `/adf:adopt` used to add them

## Context

- **After 0072, the rest of the framework still spoke `gh`.** The `pr-state.sh` hook asked only `gh`,
  so a GitLab session never heard that its merge request merged, and `/adf:wrap-up` wasn't offered.
  `/adf:wrap-up`, `/adf:track-time`, `/adf:end-user-docs`, and `/adf:context-audit` each named a `gh`
  command with no `glab` one, or half of one.
- **The `glab` permission rules lived in `/adf:adopt`'s prose.** A GitLab project got them only if
  the agent adopting it added them by hand; no check read them, and an upgrade never brought them to
  a project adopted before they were written.
- **Nothing kept the two hosts in step.** A new step naming `gh` would pass every check.

## Decision

- **The `pr-state.sh` hook asks the host's CLI.** `glab` first when `origin`'s URL names GitLab, `gh`
  first otherwise; when the first can't answer, the other one, if installed — which covers a
  self-managed GitLab whose host name doesn't say so. `glab mr view <branch> --output json` gives
  `state` (`opened`, `merged`, `closed`) and `web_url`, read through the hooks' own JSON reader:
  `glab`'s `--jq` arrived in 2026, and older installs lack it. The hook names a merge request
  `!<n>`, as GitLab does.
- **A skill with a command or two carries the `glab` one beside the `gh` one,** in the same step:
  `/adf:wrap-up`, `/adf:track-time`, `/adf:end-user-docs`, `/adf:context-audit`. A skill with a
  host procedure — `/adf:open-pr`'s draft, CI wait, ready, and reviewers — keeps it in `gitlab.md`
  beside its steps. The line is 0063's: every project is on one host, so a reference file costs a
  GitLab run a read to save a GitHub run a few dozen words.
- **The skeleton's settings ship the `glab` rules beside the `gh` ones.** `Bash(glab *)` is allowed,
  and asked by name, as `gh`'s are: merging (`mr merge`, its alias `mr accept`), a reviewer's voice
  (`mr approve`, `mr revoke`, `mr unapprove`), `release`, `repo delete`, secrets (`variable`, `var`,
  `securefile`), auth (`auth`, `token`), and `glab api` writes (`-X`, `--method`, `-f`, `-F`,
  `--field`, `--raw-field`, `--form`, `--input`). `/adf:adopt` keeps them on either host. The
  permission check tests their verdicts beside `gh`'s.
- **A static check keeps the hosts in step:** every skill folder, agent, workflow, hook script, and
  skeleton file that names a `gh` command names a `glab` one. The `github` module is GitHub's own.

## Consequences

- **Positive:**
  - A GitLab session hears when its merge request merged or closed, and every skill's step has a
    command that works there.
  - A GitLab project needs nothing added to its settings at adoption, and an upgrade brings the
    rules to one adopted earlier. A project that moves hosts keeps its guardrails.
  - A new `gh`-only step fails the static checks.
- **Negative / cost:**
  - **A GitHub project's settings carry about twenty `glab` rules it never uses,** and a GitLab
    project's the `gh` ones, as it already did.
  - **Two CLI calls in the worst case.** With both CLIs installed, a GitHub branch with no pull
    request yet also asks `glab`, which fails fast on a remote it doesn't know; each call is still
    bounded at five seconds where `timeout` is installed.
  - **The check is a word match:** it proves a `glab` command is near, not that it is the right
    one. The commands come from `glab`'s documentation, and `glab` isn't exercised by the session
    evals, which simulate `gh`; the hook's GitLab path is tested against a fake `glab`.
  - **`glab` admin commands run** — runners, OpenTofu state, packages — as `gh`'s rarer commands do;
    the agent has no reason to reach for them, and a project that uses them adds its own `ask` rules.

## Alternatives considered

- **A `gitlab.md` beside every skill that names `gh`.** Declined for one-command skills: a read on
  every GitLab run for a line of text (0063's own line, as for desktop app vs terminal).
- **Keep the `glab` rules in `/adf:adopt`.** Declined: prose no check reads, and an upgrade never
  reaches a project adopted before it.
- **Choose the hook's CLI by remote URL alone.** Declined: a self-managed GitLab at a host without
  "gitlab" in its name would go silent whenever `gh` is installed.
- **Use `glab`'s `--jq`, as the `gh` call does.** Declined for now: `glab` versions before mid-2026
  lack it, and the hook would go silent on them.
