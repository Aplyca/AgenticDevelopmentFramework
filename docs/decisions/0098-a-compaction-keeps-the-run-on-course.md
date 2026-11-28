# 0098: After a compaction, the run goes on as the framework says — the session-context hook says where it stands, and every skill comes back whole

- **Status:** accepted
- **Date:** 2026-11-28
- **Refines:** [0097](0097-the-agent-goes-on-after-the-gate.md) — the run the approval authorizes
  goes through Claude Code's automatic compaction, and comes out of it on course
- **Refines:** [0063](0063-reference-files-and-status-moves-in-the-calling-skill.md) — a skill
  moves a case into a reference file to stay small enough that a compaction keeps it whole, too

## Context

- **What happened.** In adopting projects, agents stopped following the framework's instructions
  after Claude Code compacted the conversation in the middle of a task. They asked whether to go
  on, skipped `/adf:open-pr`'s last steps, or picked up a task with no red test first.
- **It's where the run goes.** [0097](0097-the-agent-goes-on-after-the-gate.md) has the approval
  authorize the whole run, from the first task to a pull request ready for review. The project caps
  the conversation at 300k tokens ([0062](0062-one-session-per-task-compact-at-the-gate.md)), so a
  long run meets an automatic compaction, often in `/adf:implement` or while `/adf:open-pr` waits
  for CI.
- **What a compaction keeps.** Claude Code's docs ("What survives compaction") and its code
  (v2.1.330) agree:
  - `AGENTS.md` and the unscoped rules, re-read from disk; the five most recently changed files.
  - The session-start hooks' output: `SessionStart` runs again, with `"source": "compact"` in its
    input. The framework's session-context hook has no matcher, so it already runs there.
  - Each skill the session ran, the most recent first, within 25,000 tokens in all. One is kept
    whole while Claude Code's estimate of it — its characters divided by four — is 5,000 tokens or
    less: 20,000 characters. A longer one is cut at 20,000 characters, with a note to read the rest.
- **What it loses.**
  - The end of a long skill. `/adf:open-pr` (24.6k bytes), `/adf:adopt` (25.4k), and `/adf:wrap-up`
    (20.7k) lost their last steps, rationalizations, and verification: for `/adf:open-pr`, the
    tracker step, the report, and every check on marking the pull request ready.
  - Skills past the 25,000-token budget; path-scoped rules, until a matching file is read again.
  - Anything agreed only in chat, and which phase or skill was running: the summary may say it, or
    not.
- **The estimate isn't the model's count.** `/adf:open-pr`'s `SKILL.md`, 24.4k bytes, took about
  8,200 tokens in a session's usage — about three bytes a token. The cut goes by characters, so the
  limit that matters is in characters, not in the model's tokens.

## Decision

- **After a compaction, the session-context hook says where the run stands.** With
  `"source": "compact"` and the branch's spec folder found, it adds to its usual lines:
  - the next unticked task in `tasks.md`, its ID and title (`T021 — Subscribe endpoint`);
  - or, with every task ticked, that the run goes on with the reconcile, the full gate, the local
    check, and `/adf:open-pr` — whichever hasn't happened yet;
  - and, with `status: approved`, that the approval authorizes the run to a pull request ready for
    review: re-read the running skill's `SKILL.md`, continue, and stop only for a decision.

  Three lines at most, since Claude Code carries them on every later call. A struck-through task
  counts as neither ticked nor next. What the hook can't read — no spec folder, no `tasks.md`, no
  task lines, another status — it doesn't mention ([0096](0096-hooks-stay-silent-on-what-they-cannot-read.md)).
  Other sources (`startup`, `resume`, `clear`) print nothing more.
- **Every skill's `SKILL.md` stays within 19,000 bytes,** so a compaction keeps it whole. A static
  check holds it. Claude Code attaches the body without the frontmatter, after a
  `Base directory for this skill:` line (about 150 characters), with `${CLAUDE_PLUGIN_ROOT}` spelled
  out as the plugin's path (about 50 more characters each). A byte count never undercounts those
  characters: it counts the frontmatter, and three bytes for each em dash. The 1,000 left under
  20,000 covers the line and the paths, with room to spare.
- **Four skills move cases into reference files,** by [0063](0063-reference-files-and-status-moves-in-the-calling-skill.md):
  - `/adf:open-pr`: the description's template for a repository with none (`body.md`), the tracker
    task's update (`tracker.md`), and two rationalizations about the preview (`preview.md`). Its
    Principles repeated its opening, and go; its verification list merges items without dropping a
    check.
  - `/adf:adopt`: a new project, a project already adopted and the modules' install and settings, an
    existing `CLAUDE.md` or `GEMINI.md`, the committed install, and a plugin outside the documented
    install.
  - `/adf:wrap-up`: the main checkout's, the time-tracking module's, and the follow-ups' rows,
    checks, and red flag, into the files that already hold those cases. Its Principles go too.
  - `/adf:stakeholder-update`: the rationalizations of one moment, into that moment's file.
- **`/adf:implement` and `/adf:open-pr` say to re-read themselves.** One line each: in a compacted
  conversation, re-read this `SKILL.md` before going on. A static check holds both.

## Consequences

- **Positive:**
  - After an automatic compaction, the run picks up at the next task, from the folder rather than
    the summary, with what the approval authorized said again.
  - A skill the session ran comes back whole, its verification included.
  - The case that left a skill is read fresh from disk at the step that needs it, compaction or
    not.
- **Negative / cost:**
  - The hook's lines ride on every call after a compaction: about 100 tokens.
  - With `status: implemented` — `/adf:implement` sets it before the local check — the hook names
    the remaining steps but not the authorization. `/adf:open-pr` says to go on to ready itself, and
    now comes back whole.
  - A skill that grows past 19,000 bytes fails the static checks; the fix is a reference file.
    Several skills sit within a few hundred bytes of the limit.
  - The 25,000-token budget still drops the oldest skills once about five whole ones are attached.
    The hook's line names no skill: the agent finds the one that was running in the summary.
  - Claude Code's numbers can change. The check's comment says where they come from.

## Alternatives considered

- **A `PreCompact` hook that steers the summary:** the summary is still the model's. A line read
  from the folder doesn't depend on what it chose to keep.
- **A new hook on another event:** `SessionStart` already runs after a compaction, and its output is
  what Claude Code keeps. The session-context hook already finds the spec folder.
- **A limit in the model's tokens:** Claude Code cuts by characters, and a byte count needs no
  tokenizer, so the check runs anywhere.
- **Splitting the long skills into one per phase:** more names in the skill listing, which loads in
  every session, and the 25,000-token budget fills sooner.
- **Only the re-read line in each skill:** an agent that lost track of which skill was running has
  no skill to re-read. The hook says it from the folder.
