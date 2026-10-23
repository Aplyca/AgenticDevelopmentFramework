# 0049: Every lane commits, pushes, and opens its draft without asking — a standing go-ahead

- **Status:** accepted
- **Date:** 2026-10-22
- **Amends:** [0047](0047-sessions-move-to-done.md) — the careful lane's yes before the push is
  dropped, and is no longer one of the gates

## Context

Since 0045, the agent's own local check opens the draft: once the changed flow works on its
environment, it pushes and opens the pull request without asking. The developer tests after it,
locally and on the preview, from one report with both URLs. In practice, sessions still stopped
to ask before the push, for two reasons:

- **The careful lane kept one yes before the push** (0047). The agent finished the change, walked it,
  and then waited for the developer to look at the risky part before pushing. The developer was
  going to test the change anyway, after the draft opened, so the stop added a round trip and
  bought little more than that test does.
- **The tools' own defaults ask.** Claude Code commits and pushes "only when the user asks" unless it
  is durably authorized, and the desktop app's next-step box suggests a go-ahead button for a
  commit or a push. The framework allowed the push but never said the permission was standing, and
  `.claude/rules/claude-code.md` even said the push followed "your approval in the local check". So
  agents ended turns with "Commit and open the draft?" in every lane.

The developer's own check decides ready and merge, and that check runs on the draft. A question
before the push only moves it later.

## Decision

- **Commits, the work branch's push, and its draft pull request are the team's standing go-ahead,
  in every lane.** Once the local check passes — or, with nothing to run, the full gate and a clean
  `/review` — the agent commits what's left, pushes, and opens the draft without asking.
  `AGENTS.md` § Delivery rules says so for every tool, and `.claude/rules/claude-code.md` adds that
  the agent doesn't ask for them, in a reply or in the desktop app's next-step box.
- **The careful lane adds its checklist, not a stop.** The risky part — the area, what the checklist
  found, what the agent walked — goes in the pull request's Lane line and leads the report, so the
  developer's test starts there. Moving up into careful never stopped; now the careful lane ends
  without a stop as well.
- **Everything else stands.** The draft stays a draft until the developer has tested it and asks
  for ready (0005). Readying, merging, reviewing, releases, pushes to any other branch, and writes
  the requester can see still wait for a person. Moving up into full still stops for the spec and
  the approval gate, and growth of the change surface into risk still stops implementation.

## Consequences

- **Positive:**
  - No session waits on a question whose answer is the developer's test anyway. The developer
    finds a draft ready to test, with the local and preview URLs and the risky part first.
  - One rule for every lane, and one sentence agents can point to when a tool's default would ask.
- **Negative / cost:**
  - **A careful-lane change reaches the preview before anyone has looked at it.** A preview can
    run a migration against a shared database or reach a shared service. This is the risk 0047
    declined to take. What's left to guard it is the area's checklist, the local walk, and the
    pull request's Merge danger section. A team whose previews share data that a migration can
    damage should give the preview its own database. If it can't, it can ask for careful-lane
    changes to stop before the push in its own `AGENTS.md`.
  - **The rule rests on the agent following it.** No hook can tell a question about a push from
    any other question.

## Alternatives considered

- **Keep the careful lane's yes** (0047). Declined: the developer tests every draft, careful ones
  included, and a yes before the push repeats that check with less to look at.
- **Stop only when the push changes shared data**, such as a preview that runs a migration against
  a shared database. It's the narrowest guard, but it needs the agent to know how each project's
  previews deploy, which the framework can't tell it. A team that needs it writes it into its own
  `AGENTS.md`.
- **An allow rule or hook in place of the instruction.** The push already runs without a permission
  prompt (`Bash(git *)`, `Bash(gh *)`, decisions 0033 and 0038). The stops came from the agent
  asking, which only an instruction changes.
