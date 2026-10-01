---
name: cost-report
description: Report what Claude Code sessions on a project cost — calls, active time, context size, tokens, and estimated cost per session from Claude Code's local transcripts — and flag the patterns that make sessions expensive (long context, pauses past the cache lifetime, browser loops, spec-heavy small changes). Use when asked how much agent work costs, why a session was expensive, or whether a change to the lanes or habits paid off.
argument-hint: "[project path — default: this repository] [--days N] [--siblings]"
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

2. **Present the result:** totals, the most expensive sessions, the size bands, and the flags.

3. **Explain the drivers** with `docs/COST-MODEL.md` (in the project, or the framework's skeleton):
   - **Calls × context** — cost grows with the number of steps and with how much each step re-reads.
   - **`long-context`** — one task per session, `/clear` between tasks; a 1M-context model lets
     routine sessions grow far past what they need.
   - **`pauses`** — each wait longer than the cache lifetime wrote the whole context again; batch
     questions into one message.
   - **`browser`** — agent browser loops; prefer tests and leave visual QC to the human check.
   - **`spec-heavy`** — a small change with more spec edits than code edits: was the full lane
     needed, or was it a fast-lane change with a light change request?

4. **Suggest one or two concrete changes** — the ones the numbers point at — not a list of everything.

## Rules

- **Estimates, not invoices.** Prices are list prices in the script; subscriptions, discounts, and
  provider pricing differ. Say so.
- **Session titles can contain client or task details.** Keep the report in the conversation; don't
  paste titles into commits, pull requests, or shared documents without the developer's say-so.
- Read-only: the skill never edits transcripts or settings.

## Verification

- [ ] The report ran on the intended project folder (the "Folders" line says which)
- [ ] Numbers are presented as estimates at list prices
- [ ] Each suggestion is tied to a number in the report
