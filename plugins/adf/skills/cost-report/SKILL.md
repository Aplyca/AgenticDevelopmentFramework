---
name: cost-report
description: Report what Claude Code sessions on a project cost — calls, context, tokens, estimated cost, the Sonnet comparison — from the local transcripts, and flag what made them expensive. Use when asked what agent work costs or why a session was expensive.
argument-hint: "[project path — default: this repository] [--days N] [--siblings]"
context: fork
model: sonnet
---

# Cost report

Show a team what its agent sessions actually cost, from the transcripts Claude Code already keeps
on this machine — so decisions about lanes, models, and session habits rest on numbers. Everything
stays local: the script reads `~/.claude/projects/` and prints a report; nothing is sent anywhere.

## Steps

1. **Run the report** with the script in this skill's directory:

   ```bash
   python3 <this skill's base directory>/session_cost.py <project path> --days 30
   ```

   - `--siblings` also counts sibling worktrees (`../<type>-<slug>`, from the parallel-agents
     module); worktrees under `.claude/worktrees/` are always included.
   - `--days 0` reads every session; `--top N` lists more; `--json` gives every session's numbers.

2. **Present the result:** totals, the most expensive sessions, the size bands, the model line, and
   the flags.

3. **Explain the drivers** with the cost model — `docs/COST-MODEL.md` in a committed project, the
   plugin's `${CLAUDE_PLUGIN_ROOT}/docs/COST-MODEL.md` in a packaged one:
   - **Calls × context** — cost grows with the number of steps and with how much each step re-reads.
   - **The model** — the `on sonnet` column re-prices an Opus or Fable session's tokens at Sonnet's
     prices. Where the session's work had a clear spec and a way to check it — the fast and careful
     lanes, bug fixes, reviews, an approved plan — Sonnet fits: pick it in the desktop app's model
     picker or with `/model`, since the picker overrides the project's `"model"` setting. Cache reads
     cost the same on both, so in long sessions the context is as large a lever.
   - **`long-context`** — one task per session, `/clear` between tasks; a 1M-context model lets
     routine sessions grow far past what they need.
   - **`pauses`** — each wait longer than the cache lifetime wrote the whole context again; batch
     questions into one message. The lifetime is 5 minutes, or an hour where Claude Code used the
     longer cache (a subscription's main conversation) — whose writes cost twice the input price.
   - **Forked, resumed, or moved sessions** — a call copied into a later transcript counts once, in
     the session that made it.
   - **`browser`** — agent browser loops; prefer tests and leave visual QC to the human check.
   - **`spec-heavy`** — a small change with more spec edits than code edits: was the full lane
     needed, or was it a fast-lane change with a light change request?

4. **Suggest one or two concrete changes** — the ones the numbers point at — not a list of everything.

## Rules

- **Estimates, not invoices.** Prices are list prices in the script; subscriptions, discounts, and
  provider pricing differ. Say so.
- **The Sonnet column is a price comparison, not a prediction.** It re-prices the same tokens; a
  session on Sonnet could take more or fewer turns. It can't say whether a session's work needed
  Opus — read the session's title and lane for that.
- **Session titles can contain client or task details.** Keep the report in the conversation; don't
  paste titles into commits, pull requests, or shared documents without the developer's say-so.
- Read-only: the skill never edits transcripts or settings.

## Verification

- [ ] The report ran on the intended project folder (the "Folders" line says which)
- [ ] Numbers are presented as estimates at list prices
- [ ] Each suggestion is tied to a number in the report
