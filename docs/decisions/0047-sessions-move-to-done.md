# 0047: Sessions move to done — each turn ends with what's next, fewer stops, and a close-up for every ending

- **Status:** accepted; amended by [0049](0049-every-lane-pushes-without-asking.md) (the careful lane pushes without a yes)
- **Date:** 2026-10-18
- **Amends:** [0011](0011-lanes-ceremony-follows-risk.md) — when the careful lane's yes comes, and
  what moving up a lane stops for; [0039](0039-check-locally-then-on-the-preview.md) and
  [0045](0045-agent-local-check-opens-the-draft.md) — the report names the developer's next step once

## Context

A developer running several sessions comes back to one and can't tell what it's waiting for. The
agent reported what it did, but not who acts next. Sometimes that was the developer: a decision
or a test. Sometimes it was nobody, because the work was done. Work stalled in sessions nobody was
going to touch again.

The framework already had most of what moves a task forward. The draft pull request opens on its
own (0045), and `/wrap-up` closes up a merged task with one yes. Five gaps were left:

- **No rule for how a turn ends.** The agent could stop on a summary, and the next step was left for
  the developer to work out.
- **The pull request report was told to stay quiet.** 0039 said to send no nudges to review, ready, or
  merge. After the draft opened, the session said where to test it, then went quiet about what came after.
- **Nothing noticed the merge.** `/wrap-up` started when the developer said "merged" or the desktop
  app reported it. A developer who merged on the host and came back later found the session as they
  left it.
- **Only a merged pull request could close up.** An answer has no pull request, and a closed one
  had no way out, so both kinds of session stayed open forever. "On hold" had no definition.
- **Some stops came earlier than the risk needed.**
  - The careful lane's yes came before the commit, which is reversible, so the session waited
    mid-task.
  - Implementation stopped for any file outside the plan's table.
  - Moving up from fast to careful stopped as well, though careful only adds checks.

The goal is the framework's own: autonomous work, with a person at the points that need one.

## Decision

- **Every turn ends with what's next** (`AGENTS.md` § AI interaction rules). The agent reports as
  usual: what it did and found, its reasoning, numbered options, and recommendations. Then it
  closes with who acts next:
  - **The agent:** it carries on, without asking for a step that's already authorized.
  - **The developer:** the decision, approval, or test the work waits on, with the agent's recommendation.
  - **Something outside:** CI, a deploy, or a reviewer, and how the agent will know.

  When the task's work is done, it offers the step that closes it. This is a closing line, not a
  template or a fixed set of states, and it doesn't limit what the agent says before it.
- **A person is asked only at a gate.** The gates are open requirements, the approval gate, the
  careful lane's yes, outward actions, readying and merging, and the close-up. Everything else
  goes ahead.
- **The careful lane's yes comes before the push, not before the commit.** The agent finishes the
  change, runs the checklist, and walks it locally. Then it asks once for a yes on the risky part,
  with everything in front of the developer. The push and the draft follow that yes. A push can
  deploy a preview against shared services, and that's what the yes guards.
- **Implementation stops only when the change surface grows into risk.** That means a new layer, a
  new dependency, or an escalation trigger: a migration, authorization, personal data, payments, a
  shared contract, shared code, infrastructure, or a sensitive area. Any other growth, such as a
  file outside the table, goes on: `plan.md` is updated in the same commit, and the pull request
  says so.
- **Moving up into careful doesn't stop. Moving up into full does.** The agent says so and applies
  careful's checklist, and the yes before the push covers it. Full stops, because its spec and
  approval gate come before more code.
- **The report names the developer's next step once.** After the preview walk, the report closes with
  where to test it. Ready and merge are the developer's. The agent wraps up after the merge.
  - No reminders on later turns.
  - No reviewers requested.
  - The agent never readies the pull request on its own (0005 stands).
- **The merge is noticed.** A new hook, `pr-state.sh`, runs at SessionStart and on each prompt. It
  asks `gh` for the branch's pull request at most once every five minutes, with a five-second limit where coreutils' `timeout` is installed.
  It says so once when the pull request merged (offer `/wrap-up`) or closed without merging (ask
  whether the task is abandoned). Without `gh`, on a protected branch, or with `PR_STATE` empty, it
  does nothing.
- **Every ending has a close-up** (`/wrap-up`), always after its check for work left over and one yes:
  - **Merged:** as before.
  - **An answer delivered:** no pull request and nothing committed. The agent offers to stop what it
    started, remove the worktree, and archive the session.
  - **Abandoned:** the pull request closed unmerged, and the developer says the task is dropped. The
    worktree and local branch go, but the branch on origin stays: the closed pull request points at
    it and can be reopened.
  - **On hold:** only the developer puts a task on hold. The reason, and what resumes it, go where the
    task's record is: `tasks.md`, the pull request, or for an answer, the session itself. `/wrap-up`
    isn't offered until it resumes.

## Consequences

- **Positive:**
  - A developer coming back to any session reads its last lines and knows what it's waiting for.
  - Fewer stops mid-task: the careful lane asks once, at the end, with the evidence.
  - Sessions end. A merged, answered, or abandoned task offers its close-up, and the sidebar
    holds only live work.
- **Negative / cost:**
  - **A careful-lane commit exists before anyone has looked at the risky part.** It stays local
    until the yes, and the developer may still ask to redo it.
  - **Growth outside the plan's table goes ahead without a person.** The pull request's note and the
    review are where it gets seen. The escalation triggers still stop everything risky.
  - **The pr-state hook adds a network call** at session start and at most every five minutes,
    and it only knows GitHub (`gh`). GitLab projects keep the manual trigger.
  - **The closing line rests on the agent following the rule.** No hook can judge prose.

## Alternatives considered

- **A fixed set of closing states** (waiting on you, waiting on CI, continuing, done, on hold).
  It's clearer to scan, but it constrains how agents communicate, and the developer wanted the
  usual reports kept. The rule asks for the content, not a format.
- **A Stop hook that checks the closing line.** A hook can't tell a clear next step from a vague
  one, and blocking a stop costs a model call each time.
- **Putting the closing rule only in the plugin, as SessionStart context.** A plugin can't carry
  instructions (0016, 0023), and other AI tools read only `AGENTS.md`. The rule lives there. The
  plugin carries the machinery: the hook and the close-ups.
- **The careful lane's yes as a note in the draft pull request.** It would remove the stop
  entirely. Declined: the push can deploy a preview with a migration in it, before anyone has
  looked.
