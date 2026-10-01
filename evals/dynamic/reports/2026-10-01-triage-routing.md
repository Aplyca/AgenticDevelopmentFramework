# Triage routing evals — 2026-10-01

The eight `fixtures/triage/` cases, run against real headless Claude Code sessions (v2.1.284) on
`sonnet` (Sonnet 5.5) and `opus` (Opus 5.5) with `run-triage-evals.sh`: 58 sessions in four runs,
about $17 API-equivalent in total. Graded by reading each transcript against its `.expected.md`.

| Run | Setup | Sessions |
|---|---|---|
| 1 | Read-only (edits denied), the lanes as first written | 16 |
| 2 | Read-only, after fixes A–C below | 16 |
| 3 | Edits allowed in each throwaway copy, with the new `triage-first` hook (one reminder) | 16 |
| 4 | Edits allowed; hook trying two reminders — then reverted (finding E) | 10 (five small-change cases) |

## Routing — runs 1 and 2 (fully graded)

| Case | Expected | Sonnet | Opus |
|---|---|---|---|
| `fast-copy-change` | fast + light `CR` | ✓ ✓ | ✓ ✓ |
| `fast-bug-clear-cause` | fast, no `CR` | ✓ (run 1 hesitated on a `CR` — fix B) ✓ | ✓ ✓ |
| `careful-migration` | careful, new migration, checklist, your yes | ✓ ✓ | ✓ ✓ |
| `careful-sensitive-area` | careful from the sensitive area | ✓ ✓ | ✓ (named only in the closing summary) ✓ |
| `full-unclear-request` | full, questions about *what* | ✓ ✓ | ✓ ✓ |
| `developer-raises-lane` | full, from the developer | ✓ ✓ (run 2 on the corrected fixture — fix C) | ✓ ✓ |
| `developer-lowers-risk` | checklist kept unless the risk is accepted | ✓ ✓ | ✓ ✓ |
| `answer-only` | an answer, no lane, no environment | ✓ ✓ | ✓ ✓ |

**The lane was right in all 32 graded sessions**, including both developer overrides: raising was
honored without argument; lowering dropped the spec, plan, and gate but kept the migration checklist
and offered to record an explicit risk acceptance in the pull request.

## What differed by model

| | Sonnet | Opus |
|---|---|---|
| Triage written as visible text before the first change (runs 1–2) | 16 of 16 | 6 of 16 — in the small-change cases it usually read, branched, and attempted the edit first, stating the triage only in its closing summary |
| Names the model that fits the lane (run 2) | 8 of 8 — and suggests `/model opus` for full-lane planning | 3 of 5 small-change cases suggest `sonnet`; none when the triage wasn't written out (runs 3–4) |
| Average cost and time per session | about $0.20 · 22 s | about $0.38 · 32 s |
| Judgment worth noting | Read the code more reliably (the answer-only estimate cites the files) | Sharper edge cases: a `varchar` overflow should be rejected, not truncated, so the writer is elsewhere; `create index concurrently` vs. transactional migration runners |

On the evidence, small and careful work loses nothing on Sonnet and costs about half — the
guidance in decision 0012 holds. Full-lane triage was solid on both.

## Findings and fixes

- **A — Triage after acting.** Opus routinely acted before writing its triage. `/triage` now says to
  state it in reply text before creating a branch or file; that alone didn't change Opus (run 2).
- **B — Light change request on a restoring bug fix.** The fast lane said "on delivered work, add a
  light change request", so a fix that restores documented behavior looked like it needed one.
  Reworded everywhere: a light `CR` records a *change* to recorded behavior; a fix that restores it
  needs none. Run 2: both models got it right.
- **C — Fixture flaw.** `developer-raises-lane` named a field the fixture repository doesn't have;
  both models correctly refused to invent it. The fixture now targets real copy.
- **D — `triage-first` hook (run 3).** Stops the first edit once when no lane is stated. It worked
  as a nudge: one Opus run wrote a proper `Careful lane — …` line after the reminder. More often the
  model replied "the triage is stated above" and retried — it had decided the triage in its thinking,
  which nobody sees. The reminder now says so explicitly.
- **E — No second reminder (run 4).** A second reminder converted no runs, and one Opus session read
  the hook's source and waited out the cap. Reverted to a single reminder: the hook is a cheap nudge,
  not enforcement, and is documented that way.
- **F — Light change request shape (run 3).** With edits allowed, both models recorded the label
  change against the spec, but neither used the template's shape — it lived only in a comment at the
  end of the spec template. `specs/README.md` now shows the light entry inline.

## Caveats

- **Headless sessions.** `claude -p` returns the final message at the end, which may encourage
  acting before narrating; interactive sessions usually write text between tool calls. The
  ordering numbers are the least portable result here — spot-check interactively.
- **A fictional project** with stub code and no installed dependencies: tests couldn't run, so the
  red-then-green parts of each lane weren't exercised.
- **Grading by hand,** one grader. Transcripts aren't committed (they include machine paths); rerun
  the harness to reproduce.
