# Session evals — the plugin's hooks in real sessions — 2026-10-04

The new `plugin-hooks` suite, run with `run-session-evals.sh --suite plugin-hooks` against real
headless Claude Code sessions (v2.1.286) on `haiku` (Haiku 4.5), with the `aplyca-adf` plugin loaded from a
checkout of v1.0.6 (`--plugin-dir`). The hooks were rewritten five times between v1.0.2 and v1.0.6,
and the static hook tests run them as scripts; this suite checks that Claude Code runs them from the
plugin and that what they print reaches the session. `inspect.sh` checked each run, and each
transcript was read against its `.expected.md`.

| Run | Sessions | Checks | Cost |
|---|---|---|---|
| The suite, through the runner | 7 | 8 passed, 0 failed | $0.40 |

## Results

| Case | What happened in the session | Check |
|---|---|---|
| `session-context` | The context named `specs/007-newsletter-signup/ (status: draft)` | ✓ |
| `guard-git` | `git commit --no-verify` blocked with the guard's message | ✓ |
| `triage-first` | The first edit, with no reply text, got the reminder; Claude then stated the fast lane and made the edit | ✓ |
| `protect-paths` | The edit to `package-lock.json` blocked as a generated file | ✓ |
| `careful-paths` | The first edit in `src/billing/` stopped; having stated the fast lane, Claude stopped rather than retrying, as the message says | ✓ |
| `check-env-declared` | After the edit, `reads NEWSLETTER_LIST_ID but .env.example does not declare it` reached Claude, which declared the name | ✓ |
| `stand-down` | In the copy switched to the committed install, neither the plugin's guard nor its session context appeared | ✓ ✓ |

## What the first, manual run taught the checks

Before the suite, the same seven sessions ran from a one-off script. Two of its checks failed, and
both were wrong, not the hooks:

- **`guard-git`** required that no commit be made. The hook blocked `--no-verify`, and Claude then
  committed without it, on the work branch, which is what the message asks. The check is the block.
- **`check-env-declared`** looked for the hook's message in the output stream. A PostToolUse hook's
  message reaches Claude through the session transcript instead, where it was. `inspect.sh` reads
  the transcript.

## Negative controls

Each check was fed a run where its hook didn't act — every packaged case's check on the
`stand-down` run, and `stand-down`'s checks on the `guard-git` run — and each marked ✘. None passes
vacuously.
