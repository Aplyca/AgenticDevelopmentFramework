# 0055: The always-loaded files carry rules, not procedures; triage fits the model; the developer's "merged" closes up

- **Status:** accepted; corrected before release: `/adf:adopt` and `/adf:init-project` stay model-invocable, and the shortened skill descriptions keep their trigger phrases — a description decides whether a skill loads at all (CHANGELOG, Unreleased)
- **Date:** 2026-10-23
- **Amends:** [0036](0036-wrap-up-after-the-merge.md) (the close-up needs no second yes when the
  developer's own word ended the task) and [0051](0051-agent-owned-sections-of-the-pull-request.md)
  (the sync procedure moves from the git rules to `/adf:open-pr sync`)

## Context

An audit of 41 sessions in an adopting project measured what a session pays for. The project had
2,544 model calls, about $200 at list prices.

- **The instructions loaded in every session came to about 14k tokens.** That is `AGENTS.md`,
  `claude-code.md`, `git-workflow.md` (its `paths: "**/*"` loads it at the first file read), and the
  plugins' skill and agent listings. About 15–18% of those words restated each other. The longest
  restatements were procedures: the eight sync steps, the guardrail table, and the pull-request
  rules that `/adf:open-pr` already carries.
- **Skill descriptions alone came to about 14k characters.** They were in the listing of every
  session, though 20 of the skills were never used in those sessions. The installer's `/adf:adopt`
  and `/adf:init-project` sat there too.
- **94% of the calls ran on Opus.** That included fast-lane bug fixes the lane table puts on Sonnet,
  where the same tokens cost about 28% less. Triage named the model that fits, but switching was left
  to the developer, and almost never happened.
- **The close-up took a turn of its own.** "Merged" started the check, then a second question waited
  for "yes, close up": 16 times in the audited sessions. After a pause, that turn re-wrote the whole
  context into the cache at twice the input price.

## Decision

- **The always-loaded files state rules; procedures live in the skills that run them.**
  - The sync procedure moves to `/adf:open-pr sync`. `git-workflow.md` keeps its rules: sync only
    for a reason, merge and never rebase, never push to a merged or closed pull request's branch.
  - `claude-code.md`'s guardrail table becomes four lines of what is asked, refused, stopped once,
    and announced. Its lane table drops the definitions `AGENTS.md` already holds.
  - `AGENTS.md` keeps every rule, in fewer words.
- **Skill descriptions say what a skill does and when, in about 250 characters.**
  - `/adf:adopt` and `/adf:init-project` are user-invoked only (`disable-model-invocation`), so
    their descriptions leave the listing.
  - The read-only reports run in a forked subagent on Sonnet (`context: fork`, `model: sonnet`):
    `/adf:context-audit`, `/adf:spec-drift`, and `/adf:cost-report`. Their reading never enters the
    session's context, and they don't run on the session's model.
- **Triage fits the session to the lane.**
  - In the desktop app, right after stating the triage, `/adf:triage` reads the session's model and
    effort. When either doesn't fit the lane, it sets them itself (`set_session_model`,
    `set_session_effort`): Sonnet with medium effort for the fast lane, high for careful, Opus with
    high effort for the full lane's spec and plan.
  - A model or effort the developer chose for the task stays. A task a few calls from done keeps its
    model, because a switch re-reads the conversation uncached once. An effort change keeps the
    cache on the current models.
  - In a terminal, the triage line still names the switch.
- **The developer's own word closes up a merged task.**
  - When the developer says in the session that the task ended ("merged", "it's in", "close up"),
    `/adf:wrap-up` checks as before. If the pull request merged by the host's state, nothing is
    left, and there's nothing to choose, it closes up in the same turn. The list it would have
    asked about opens its report.
  - A merge reported by the hook or the app, an abandoned task, an answer, or anything to choose
    still gets the one question.
  - Wrap-up now also offers the **delivered** stakeholder update, which no skill owned before.

## Consequences

- **Positive:**
  - The three always-loaded files go from about 7.3k words to about 5k, and the skill listing loses
    about 6.6k characters: every call of every session re-reads less.
  - Fewer, shorter copies of each rule leave fewer places for them to disagree.
  - Fast- and careful-lane sessions in the desktop app run on Sonnet without the developer having to
    remember.
  - A merged task closes up in the turn that reports it.
- **Negative / cost:**
  - **Projects merge their `AGENTS.md` and `claude-code.md`.** The changes are wording, but they
    touch most sections. `git-workflow.md` is overwritten.
  - **The sync steps load only with `/adf:open-pr`.** Tools that read only `AGENTS.md` and the rules
    keep the rules of a sync but not its steps.
  - **The model switch spends one uncached read** of the conversation at the triage. It pays back
    within a few dozen calls, and the skill skips it for tasks that are nearly done.
  - **The close-up removes the worktree without a second look at the list.** The check is what
    protects the work: it lists anything uncommitted, unpushed, stashed, open, or promised, and
    stops. The deleted files are a clean worktree whose branch is merged, and the archive can be
    undone.
  - **A forked report runs in the background** and arrives when it's done, rather than in the turn
    that asked for it.

## Alternatives considered

- **Leave the model to the developer.** Declined: the audit shows the advice isn't followed. A
  developer who wants Opus says so in the task, and triage keeps it.
- **Scope `git-workflow.md` to fewer paths.** Declined: commits touch every kind of file. Making it
  shorter works on every path.
- **Trim the skill bodies in this change.** Deferred. About 22% of skill text is rationalization
  tables, red flags, checklists, and principles that restate the steps. Trimming them changes how
  every skill behaves, so it needs the session evals, which run at release time.
