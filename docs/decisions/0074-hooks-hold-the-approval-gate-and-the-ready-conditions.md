# 0074: Hooks hold the approval gate and the ready conditions

- **Status:** accepted
- **Date:** 2026-11-12
- **Amends:** [0002](0002-one-approval-gate-on-the-change-surface.md) — in Claude Code, a hook holds
  the approval gate; [0070](0070-the-agent-marks-its-pull-request-ready.md) — two of ready's
  conditions are checked before the command runs

## Context

- **The process's gates were held unevenly.** Guardrails that must hold are configuration and code,
  not prose ([0006](0006-guardrails-as-configuration.md)), and the git and file rules are: protected
  branches, generated files, the draft rule. The steps of the process itself — approval before code,
  the conditions for ready — were instructions in the skills. An agent that drifts past one leaves
  no trace until a reviewer notices.
- **The approval gate said so of itself.** `specs/README.md` read: "Nothing mechanical enforces the
  gate — it is a rule an agent could skip and CI can't see." `/implement` refuses to start on a spec
  that isn't approved, but only when that skill is the one running.
- **Ready became the agent's call, and it notifies people.** Since 0070 the agent marks its own pull
  request ready, and since 0072 that requests the project's reviewers. A pull request marked ready
  with CI red, or with an empty *How to review and test*, asks people to review something they can't
  yet. 0070 noted that no hook can tell whether every criterion was walked. That holds, but two of
  its conditions are facts on the host: the description's text and CI's state.
- **Both gates are checkable where a hook can act.** A hook stops a tool call by reading state. The
  spec's status is a line in a file; the description and the checks are one read of the pull request.
- **Teams want the process followed, and the agent left free in how.** A gate that holds at two
  moments does that; a rule for every step between them wouldn't.

## Decision

- **The approval gate is a hook,** `approval-gate.sh`, before every file edit. While the spec folder
  the branch belongs to — joined by slug, as the session-context hook does — reads `status: draft` or
  `in-review`, an edit outside the specs folder is stopped. Never stopped: the specs folder itself;
  a branch with no spec folder, which is the fast and careful lanes; a spec that reads `approved` or
  `implemented`; a file git ignores; a file outside the repository.
- **The ready gate is the git guard's fifth rule.** Before `gh pr ready` or
  `glab mr update --ready`, `guard-git.sh` reads the pull request once and stops the command when:
  - the description has no review instructions — nothing between the `adf:how-to-verify` markers
    beyond the template's comments and empty labels;
  - a check is failing;
  - a check is still running.

  A project with no checks passes, and so does `--undo`, back to a draft.
- **Each gate has a mode,** in `.claude/hooks/config.sh`: `APPROVAL_GATE` and `READY_GATE`.
  - `block` stops the call every time.
  - `remind` stops it once per session and lets it through after — a nudge, like the triage-first
    hook's.
  - Empty turns it off.

  The skeleton sets both to `block`. Unset is off, so a project that upgrades gets a gate when it
  adds the line.
- **The gates are enforced, not the path between them.** The order of tasks, how a change is tested,
  which tools and agents are used stay the agent's call. The lane decides which gates apply.
- **A hook checks facts, not judgment.** The approval gate checks the status, not who set it: the
  `approvals:` line and the reviewers hold that. The ready gate doesn't know whether the criteria
  were walked: *Verified / not verified* and the reviewers hold that.
- **The way through a stop is the process, or the developer.** The gate presented and signed off;
  the instructions written and CI green. A developer who accepts a red check marks the pull request
  ready themselves, or changes the mode.
- **A pull request the hook can't read goes through** — no `gh` or `glab`, no network, no answer in
  five seconds. The guard is there for mistakes; it doesn't stop work when the host is away.

## Consequences

- **Positive:**
  - The two gates that were prose hold whichever skill is running, or none.
  - An agent that drifts hears it at that call, with what to do next, instead of from a reviewer.
  - A rule a hook holds needs saying once ([0065](0065-always-loaded-text-says-each-rule-once.md)),
    so the instructions around these two gates can get shorter.
  - A team picks how firm each gate is.
- **Negative / cost:**
  - **A status the agent sets itself passes.** The hook turns a silent skip into a false record in
    the diff, where reviewers look. It isn't a lock.
  - **Some stops will be wrong.** A fix to the branch's own work is stopped while a full change
    request on that branch is in review. A project whose pull request template lacks the markers has
    every ready stopped until it adds them or turns the gate off. `remind` exists for both.
  - **Every check counts, required or not.** A flaky optional check holds ready.
  - **One read of the host per ready,** five seconds at most.
  - **Claude Code only.** Other tools still have the instructions alone.
  - **The GitLab path is tested against a stand-in for `glab`,** not a live GitLab. It reads the
    merge request's `description` and `head_pipeline.status`; a pipeline it can't find passes.
  - **A committed install merges its settings** to wire the new hook, and the always-loaded Claude
    Code rule gains a clause.

## Alternatives considered

- **A machine-readable file describing the whole process** — stages, actors, gates, and states in
  YAML, TOML, JSON, or BPMN, with tables and checks built from it. Declined for now. An agent reads
  it no better than a table; a process change stays the same size, since the prose stays; and these
  two gates need two facts, not a map, so nothing would read it at runtime. Worth another look when
  a hook needs to know the stage, or a project needs process values a script reads.
- **Block only, with no reminder mode.** Declined: the triage and sensitive-area hooks already nudge,
  and a team that finds a gate stops honest work needs something between on and off.
- **Check ready's other conditions** — gate results recorded, every criterion walked. Declined: a
  hook can read that a line exists, not that the walk happened.
- **Required checks only.** Declined: a project with no branch protection has none, and would pass
  with CI red.
- **Read the developer's approval from the transcript.** Declined: a hook can't judge prose (0047).
  The status in the file is the record.
- **A CI check for the approval gate.** Declined as the mechanism: it runs after the code is written,
  where the hook stops the first edit. It could be added beside it.
- **The ready gate as its own script.** Declined: the git guard already parses the command and holds
  the draft rule, and a second script would need its own wiring in every committed install.
