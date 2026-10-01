# Session evals — sharper process (decision 0013) — 2026-10-01

The new `debug` suite and three triage cases, run against real headless Claude Code sessions on
`sonnet` (Sonnet 5.5) and `opus` (Opus 5.5) with `run-session-evals.sh`. There were 10 sessions,
about $3.20 API-equivalent, with edits allowed in each throwaway copy, and 8 more to test fix B,
about $2.80. Each transcript was
graded by reading it against its `.expected.md`.

| Run | Cases | Sessions | Cost |
|---|---|---|---|
| `--suite debug` | `debug-clear-cause`, `debug-unclear-cause` | 4 | $1.47 |
| triage | `declined-before` (new), `full-unclear-request`, `fast-bug-clear-cause` | 6 | $1.69 |

## Debug — a failing signal first

| Case | Expected | Sonnet | Opus |
|---|---|---|---|
| `debug-clear-cause` | cause from the code; the regression test is the signal; fast lane, no `CR` | ✓ cause, lane, no `CR` — signal was a throwaway one-liner and the regression test was proposed, not written · 7 turns, $0.18 | ✓ the regression test was the signal: written, run red, then fixed and green · 16 turns, $0.48 |
| `debug-unclear-cause` | a signal before a theory; ranked hypotheses; asks for what the repo can't show; no change to the keying | ✓ all — a scratch harness for three header shapes; asks for a captured request; careful lane and `@security-reviewer` | ✓ all — the same signal with five ranked hypotheses, each with what confirms or rules it out; asks for the load balancer's settings |

- **Signal first held on both models.** Both models built the unclear-cause signal outside the
  repository: a scratch test that sends eleven readers through `clientKey` and `hit` under several
  header shapes. Both showed it failing before naming a cause, and both left the repository
  untouched.
- **Effort matched the bug.** The clear-cause case took about a third of the turns of the
  unclear-cause case on Sonnet. Opus spent more turns there only because it went on to the fix.
- **Both found real drift.** The example plan puts the rate-limit counters in Redis, while the
  fixture's code keeps them in memory. Both models reported the mismatch while explaining "not
  always". The mismatch is a fixture artifact, but it's the behavior the step "check the decision
  records for the area" asks for, so it stays.

## Triage

| Case | Expected | Sonnet | Opus |
|---|---|---|---|
| `declined-before` (new) | surfaces the earlier decision and its reason; full-lane change request; asks whether the reason still holds | ✓ all — checked "already built? declined before?" first, by name | ✓ all |
| `full-unclear-request` | full; questions about *what* | ✓ — one round, each question with a recommended answer | ✓ — one round, each with a recommended answer |
| `fast-bug-clear-cause` | fast, regression test first, no `CR` | ✓ routing — ✗ triage written before acting | ✓ routing — ✗ triage written before acting |

- **Question rounds were adopted at once.** Every full-lane triage asked one numbered round, with a
  recommended answer on each question, and invited "as recommended".
- **"Declined before?" works.** Both models quoted the *Out of scope* line and the Clarifications
  answer, with who decided and when, and stopped before planning. Opus also named the acceptance
  criterion the change would retire.
- **Triage before acting is still unreliable when edits are allowed.** In `fast-bug-clear-cause`,
  both models branched and edited before writing the triage. After the `triage-first` reminder, Opus
  replied "the triage is stated above" — it wasn't. This is finding D of the
  [routing report](2026-10-01-triage-routing.md), unchanged by this work: `/triage` step 4 wasn't
  touched. The hook gated edits, not `git switch -c`, so a branch could come first — see fix B.

## Fixes made from these runs

- **A — The glossary example contradicted the example spec.** The template's *Subscriber* was
  "someone who has confirmed", but the example spec is single opt-in, and a session cited the
  glossary as evidence for double opt-in. The example no longer mentions confirmation.
- **B — `triage-first` now catches a new branch.** The hook also runs on Bash and stops a session's
  first `git switch -c`, `git checkout -b`, `git branch <name>`, or `git worktree add` once when no
  lane is stated. Two reruns of `fast-bug-clear-cause` and `fast-copy-change` on both models
  (8 sessions, about $2.80) tested it:

  | Rerun | Reminder | Stopped at the branch | Wrote the triage after the reminder |
  |---|---|---|---|
  | 1 | "write the triage … nothing above states one" | 4 of 4 | 0 of 4 — "the triage is stated above", then a retry |
  | 2 | says what it saw: "you haven't written any reply text yet" or "none of your replies names a lane" | 3 of 3 (Sonnet stated the triage first on its own in the fourth) | 0 of 3 |

  The hook now fires at the right moment, and its message is accurate. It still doesn't change what
  a headless model does next, which agrees with findings D and E of the routing report. It stays a
  one-time nudge, which the developer sees in an interactive session. Routing was right in all 8
  sessions, including the light `CR` for the copy change.

## Caveats

- **Headless sessions** (`claude -p`) may act before narrating more than interactive ones do.
- **`pnpm test` wasn't allowed in the triage suite**, so both fast-bug sessions stopped before
  seeing red. The debug suite allows `node` and `pnpm test`.
- **One run per case and model**, graded by one reader.
