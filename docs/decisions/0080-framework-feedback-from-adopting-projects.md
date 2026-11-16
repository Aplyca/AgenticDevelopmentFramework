# 0080: Adopting projects report the framework's problems as issues, in the framework's terms, checked by a script

- **Status:** accepted
- **Date:** 2026-11-15
- **Refines:** [0054](0054-found-along-the-way.md) — what an agent finds along the way gains a lane
  for a problem in the framework itself

## Context

- **The best evidence comes from adopting projects.** Field reports written in adopting projects'
  sessions are among this repository's most useful issues: the release, what happened, how often
  ("18 of 19 pull requests"), what was expected, and a proposed fix. Issue #152 asked for a route
  for them.
- **Reports named the project.** Three of them named an adopting project, and one linked one of its
  pull requests. Nothing in the drafting checked for that, and the repository is public. The names
  were edited out by hand, but each issue's edit history keeps the first version until an admin
  deletes it, and the text may already have been cached or indexed.
- **0054 had no lane for the framework.** Its lanes cover this branch's bug, an improvement to what
  it builds, anything else as a follow-up in the project's pull request, and what can't wait. A
  defect in a framework skill, agent, hook, or rule fits none: a packaged project can't change the
  plugin, and a committed one's local fix only grows the next upgrade's merge.

## Decision

- **A skill, `/adf:framework-feedback`** (`/framework-feedback` in a committed install), turns what
  happened into an issue in the framework's repository: a problem (**What happens**, **Why it's a
  problem**, **Seen in**, **Expected**, **Possible fix**) or an idea (**Problem**, **Proposal**,
  **Related**), in English, naming only framework things. It describes and never pastes: no
  transcript, tool output, code, or file content from the project. The name says whose feedback it
  is: `report` or `feedback` alone could collide with a project's own feature.
- **The target is the project's marketplace source.** The skill's script reads the marketplace that
  enables `adf` in `.claude/settings.json` (or the one Claude Code knows, with no project entry), so
  a fork's projects report to the fork. It posts with `gh` on GitHub and `glab` on GitLab; any other
  source, or no CLI, gets the checked text and the new-issue page for the developer to file by hand.
  It never takes a repository from anywhere else.
- **A script is the gate.** `check_report.py check` blocks a draft that names the project's remotes,
  folder, name from `AGENTS.md`, git user, branches, or local hosts, or has an email address, a
  home-directory path, or a reference to a repository other than the framework's. The developer can
  clear a block by naming it (`--allow`), except the remotes, the git user, emails, and home paths.
  Short or generic names (`web`, `app`), one-word branches, other links, and the project's file paths
  only warn. The script knows the project's names, not its features, clients, or people, so the
  agent reads the draft for those too.
- **A person posts.** The skill searches open and closed issues first and offers a comment on a
  match; then it shows the full text, says the issue is public and appears under the developer's
  account, and posts only on a yes. Nothing files on its own — no hook, schedule, or agent's choice.
- **A security problem never becomes an issue.** The skill points to the repository's private
  vulnerability reporting (`SECURITY.md`) and gives the text for it there.
- **0054 gains a lane** (`specs/README.md` § Found along the way): a problem in the framework itself
  goes to `/framework-feedback`, offered and never run unasked. A change to the project's own copy of
  the file stays the developer's call, and the report says it was made.
- **This repository** takes the same shapes as issue templates (`field-report.md`, `proposal.md`),
  sends security reports to the private route from the template chooser, has a `field-report` label,
  and says in its rules that issues, like files and pull requests, never name a client or project.

## Consequences

- Field reports keep coming from where the evidence is, without naming the projects they come from.
- One more skill description in every session's list; the shapes and the check live in the skill and
  its script, so nothing is added to the always-loaded files beyond a clause in `AGENTS.md`'s line on
  findings.
- The check can't see everything that identifies a project — a feature's name, a client, a ticket. The
  developer's review of the full text is still the last gate, and the skill says so.
- An issue posted from a project appears under the developer's own account.
- A report from an older release may already be fixed; the skill checks the newest tag first.

## Alternatives considered

- **The issue templates alone.** They give the shape, but nothing checks what goes into them, and
  the reports that named projects were written by agents that didn't use one.
- **Automatic reporting** — a hook or a schedule that files what agents find. Rejected: posting to a
  public repository can't be fully taken back, and it would file without a person reading it.
- **A name check in the agent's instructions only.** An instruction is a step an agent can skip; the
  names it must not write are facts a script can read from the repository (0006).
- **Filing in the project's tracker for someone to forward.** It keeps the report private but adds a
  hand-off nobody owns, and the forwarding person anonymizes by hand — the step that failed.
