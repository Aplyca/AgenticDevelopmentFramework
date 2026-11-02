# 0063: A skill's case-only steps load from reference files, and the skill that reaches a moment moves the task's status itself

- **Status:** accepted
- **Date:** 2026-11-01
- **Amends:** [0059](0059-task-status-follows-the-work-and-stakeholder-guides.md) — the status moves
  stay where they are, but `/adf:triage`, `/adf:open-pr`, and `/adf:wrap-up` make them in a step of
  their own instead of loading `/adf:stakeholder-update status <moment>`

## Context

A developer worried that the framework's prompting makes sessions slow and costly. We measured the
text it loads, in characters (about four to a token).

- **Every call** re-reads about 43.6k characters, or about 11k tokens: `AGENTS.md` (20.1k),
  `claude-code.md` (6.0k), `git-workflow.md` (5.2k, from the first file read), the skill
  descriptions (10.8k), and the agent descriptions (1.8k).
- **Every task** loads the skills every lane runs: `/adf:triage` (17.2k), `/adf:open-pr` (19.7k),
  `/adf:wrap-up` (16.5k), `/adf:commit` (6.3k), and on a tracker task `/adf:stakeholder-update`
  (18.2k). The full lane adds about 105.7k more: `/adf:write-spec`, `/adf:write-plan`, the spec
  model, `specs/README.md`, the templates, `/adf:write-docs`, `/adf:implement`, and `/adf:review`.
- **A loaded skill stays in the conversation.** Every later call re-reads it, and a second
  invocation adds a second copy.
- **`/adf:stakeholder-update` could load six times on one tracker task.** Since 0059, each of the
  three moments moves the status with `/adf:stakeholder-update status <moment>`, then drafts the
  message with the same skill. That's up to 110k characters, about 27k tokens, for three status
  changes and three drafts.
- **Much of each skill serves a case most runs never reach.** Examples: `/adf:open-pr`'s `refresh`
  and `sync` and its preview walk; `/adf:stakeholder-update`'s screenshots and three templates;
  `/adf:wrap-up`'s follow-ups and its module steps; and `/adf:triage`'s ambiguous stakeholder reply.
  No skill had reference files. Only scripts and the `adf-dev` specifications lived beside a
  `SKILL.md`.
- **Adopting projects' transcripts:** three projects, 166 sessions in 30 days. The median session
  made 64 calls, and its median call read 154k tokens of context. Text loaded early is re-read by
  every call that follows. Most of these sessions predate 0059's status moves: none loaded
  `/adf:stakeholder-update` more than once.
- **Speed follows the number of calls more than the size of the text.** A cache read is cheap, but
  each call is a round trip, and every skill invocation is one.

## Decision

- **What every run needs stays in `SKILL.md`; a case only some runs reach moves to a reference
  file beside it.**
  - `SKILL.md` keeps the steps and decisions, the rationalizations, the red flags, the verification,
    and the principles.
  - A case's text moves word for word into `<file>.md` in the skill's folder. The step that needs it
    names it as `<this skill's base directory>/<file>.md`, the convention `/adf:cost-report` and the
    `adf-dev` skills already use. The step also says in a line what the case requires.
  - The rationalization rows and red flags that concern only that case move with it. Every
    verification item stays in `SKILL.md`, so the final check still covers every case.
  - When the case is known from the start — an argument, a module the stamp names, the moment —
    the file is read with the step's first reads, so it adds no round trip.
- **The files:**

  | Skill | Reference file | Read when |
  |---|---|---|
  | `/adf:triage` | `reply.md` | The task is a stakeholder's reply that can be read more than one way |
  | `/adf:open-pr` | `refresh.md`, `sync.md` | The argument `refresh` or `sync` |
  | `/adf:open-pr` | `preview.md` | The project has previews and the change is one a person sees |
  | `/adf:wrap-up` | `follow-ups.md` | The pull request's `## Follow-ups` has an unchecked line, or an answer listed follow-ups |
  | `/adf:wrap-up` | `modules.md` | The stamp names `end-user-docs` or `time-tracking` |
  | `/adf:stakeholder-update` | `started.md`, `review.md`, `delivered.md` | The moment's template, read with step 1's reads |
  | `/adf:stakeholder-update` | `screenshots.md` | A picture shows the client something words can't |
  | `/adf:stakeholder-update` | `status.md` | A move it makes itself: the argument `status`, or a move missed at its moment |

- **The skill that reaches a moment moves the status itself.**
  - `/adf:triage`, `/adf:open-pr`, and `/adf:wrap-up` each carry the move as a step of their own,
    with the rules in a few lines. The status comes from the task's own statuses, as
    `docs/TRACKER-INTEGRATION.md` § Stakeholder updates maps the moment, and one the task lacks is
    a question. Forward only; the status alone; only a task the developer is assigned to; one line
    to say so.
  - `/adf:stakeholder-update` loads only to draft a message. Its `status` argument still works, from
    `status.md`.
- **The machinery stays as it is.**
  - `scripts/build-committed.py` already carries every file in a skill's folder. A reference file
    gets the same name conversion as the rest (`/adf:open-pr` → `/open-pr`). It names no
    `${CLAUDE_PLUGIN_ROOT}` path, because nothing fills one in for a file the agent reads.
  - The upgrade's overwrite bucket, `.claude/skills/*`, covers the new files.
  - A static check requires every reference file to be named by a step of its `SKILL.md`, every file
    a `SKILL.md` names in its base directory to exist, and none to use `${CLAUDE_PLUGIN_ROOT}`.

**What stays in place:**
- **Desktop app vs terminal:** every session is one or the other, so a split would cost a read on
  every run to save a few hundred characters.
- **`/adf:triage`'s steps 4 and 5** (the triage line, the session name, the model fit): every task
  runs them.
- **`/adf:commit`:** it has no case-only text.
- **The always-loaded files.**

## Consequences

- **Positive:**
  - The characters a task loads, before → after:

    | Task | Before | After | Change |
    |---|---|---|---|
    | Answer, no tracker | 33,662 | 32,067 | −5% |
    | Answer, tracker task | 88,409 | 46,483 | −47% |
    | Fast or careful lane, no tracker | 59,661 | 53,093 | −11% |
    | Fast or careful lane, tracker task | 150,906 | 82,033 | −46% |
    | … with a started message too | 169,155 | 96,196 | −43% |
    | Full lane, tracker task (plus 105.7k, unchanged) | 256,620 | 187,747 | −27% |

    "Before" counts a skill load for each status move, as the skills' text asked. A reference file
    adds its size only on the runs that reach its case.
  - **In dollars, a few percent.** On one adopting project, the framework's text came to about 7–10%
    of the cost: 5–7% in cache reads, plus its share of each cache rewrite. Cutting part of that text
    saves part of that share. Session length and the model are the bigger levers: there, sessions
    of 100+ calls made 80% of the cost, and the same tokens on Sonnet would have cost 23% less.
  - A tracker task makes three fewer skill calls.
  - The case-only text is in one place per case.
- **Negative / cost:**
  - **An agent that skips the read misses that case's steps.** The pointer sits in the step that
    needs it and says in a line what the case requires, and the static check keeps every pointer
    and file paired. The session evals at the next release should exercise `/adf:open-pr refresh`
    and `sync`, a wrap-up with follow-ups and with the `time-tracking` module, and a tracker task's
    three moments.
  - **A case read when its trigger shows up mid-step** — an ambiguous reply, the follow-ups, a
    screenshot, the preview — costs one more call.
  - **The status rules live in four places:** the three calling skills and `status.md`, with
    `docs/TRACKER-INTEGRATION.md` § Rules for agents as the project's own copy. The static checks
    require each calling skill to carry them.
  - **A committed install overwrites four skill folders**, which now hold more than one file.

## Alternatives considered

- **Trim the rationalizations, red flags, and principles.** Declined. 0055 deferred it, and a review
  restored rows it had cut: they change how a skill behaves, which only the session evals can
  measure.
- **A script for the status moves.** Declined: the tracker is reached through its MCP server, which a
  script can't call.
- **One shared status file that the three calling skills read.** Declined: it adds a read at every
  moment to save four lines.
- **All three templates in one file.** Declined: every draft would read the templates it doesn't use.
