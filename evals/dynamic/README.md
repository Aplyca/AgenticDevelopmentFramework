# Dynamic evals

Fixture-based evals that **invoke an AI with an input prompt and grade the output**. Catches regressions that static checks can't — like whether the AI actually fills all required spec sections, or whether it rationalizes past the anti-rationalization table.

## Structure

```
dynamic/
  README.md                  - this file
  check-packaged.sh          - checks a project's packaged layout (adopt's and upgrade's inspect.sh use it)
  run-dynamic.md             - manual + automated execution patterns
  fixtures/
    write-spec/
      <case-name>.input.md         - what to give the AI (prompt + context)
      <case-name>.expected.md      - invariants the output must satisfy
    triage/
      ...                          - lane routing: fast, careful, full, sensitive areas, the developer's call
    debug/
      setup.sh                     - makes the fixture project runnable (Node's test runner) and plants the bugs
      ...                          - a failing signal first; effort matched to the bug
    adopt/
      project.sh                   - builds a new project (no commits, nothing built) in place of the newsletter one
      inspect.sh                   - records each run's end state: commits, stamp, planned entries, decision records
      ...                          - adopting from one line with the framework's address; /adopt in a new project; on the packaged install
    upgrade/
      project.sh                   - builds a committed adoption at v1.0.0, from that tag
      inspect.sh                   - records the end state; checks the switch to the packaged install
      ...                          - /upgrade switching a committed project to the packaged install
    plugin-hooks/
      project.sh                   - builds a project on the packaged install, with something for each hook to stop
      inspect.sh                   - checks that the case's hook fired (or stood down): ✓ or ✘ per check
      stand-down.setup.sh          - switches that case's copy to the committed install
      ...                          - each of the adf plugin's hooks, in a real session
    plugin-docs/
      project.sh                   - builds a packaged project without the reference docs, linked at the release
      inspect.sh                   - checks which reads reached the plugin's docs, asked first, or went to the web
      ...                          - an agent and a session reading the plugin's reference docs; the control without the read rule
    write-tests/
      ...
    write-docs/
      ...
    implement/
      ...
```

Each fixture has two files:
- **`.input.md`** — the prompt the AI receives, with any required context (existing spec, file paths, etc.)
- **`.expected.md`** — a list of **invariants** the output must satisfy (NOT exact text). Examples: "frontmatter contains `feature-type: ui`", "Functional section has ≥3 acceptance criteria".

## Running

### Session evals — automated (triage, debug, adopt, upgrade, plugin-hooks, plugin-docs)

`run-session-evals.sh` runs every fixture in one suite — `fixtures/triage/` by default, or
`--suite debug` — against real Claude Code sessions: it builds a fictional project in a temp
directory (the skeleton, the delivered newsletter-signup spec folder from `docs/examples/`, stub
source files matching the fixtures, plus whatever the suite's `setup.sh` adds), runs each prompt
headless with `claude -p` on each model, and writes one transcript per run to grade against the
fixture's `.expected.md`. Each run edits only its own throwaway copy — so the project's hooks take
part — and is turn- and budget-capped; `--read-only` denies edits instead. The debug suite's
project runs its tests with Node's built-in runner (Node 22.18+), so sessions can build a failing
signal without installing anything.

```bash
./run-session-evals.sh                                   # every triage case, sonnet and opus
./run-session-evals.sh --models sonnet --cases "fast-copy-change careful-migration"
./run-session-evals.sh --suite debug                     # the /debug cases
./run-session-evals.sh --suite adopt --source "$PWD/../.."   # adoption, against this checkout
./run-session-evals.sh --suite plugin-hooks              # the plugin's hooks, on Haiku
./run-session-evals.sh --suite plugin-docs               # the plugin's reference docs, on Haiku
./run-session-evals.sh --suite upgrade --models sonnet   # /upgrade, switching to the packaged install
```

The adopt suite's **packaged** case, and the **upgrade** suite's **switch-to-packaged**, check the
packaged install's two ways in: adopting on it, and switching a committed project to it. The upgrade
suite builds a committed adoption at v1.0.0 from that tag (`project.sh` gets this checkout's path), and
`/adf:upgrade` moves it to the newest release. Both cases' `inspect.sh` run
`check-packaged.sh`: the stamp naming the newest release and its commit, no framework machinery committed, the plugin pinned to that release and
turned on, no `hooks` block, the stamp, and the names people type — each marked ✓ or ✘ — plus the PDR
that records the choice. Both are long sessions; run them on one model.

The **plugin-hooks** suite checks the `adf` plugin's hooks in real sessions, which the static
hook tests can't: that Claude Code runs them from the plugin, and that what they print reaches the
session. Its project is on the packaged install, with the plugin loaded from this checkout per session.
Each case drives one hook — the session context, `--no-verify`, the triage reminder, a lockfile edit,
a sensitive area, an undeclared environment variable — and `stand-down` runs in a copy switched to
the committed install, where the plugin's hooks must do nothing. `inspect.sh` checks each run and marks
it ✓ or ✘; the summary counts them. A PostToolUse hook's message reaches Claude through the session
transcript, not the output stream, so that check reads the transcript. Seven sessions on Haiku cost
about $0.40; run it after any change to the hooks. Report: [`reports/2026-10-04-plugin-hooks.md`](reports/2026-10-04-plugin-hooks.md).

The **plugin-docs** suite checks that a packaged project reads the framework's reference docs from the
plugin ([decision 0019](../../docs/decisions/0019-reference-docs-in-the-plugin.md)). Claude Code asks
before reading any file outside the project, so its sessions run as a teammate's would: default
permission mode, no extra directory, no blanket `Read`, and only the read rule a packaged project
commits, passed with `--allowedTools` for the plugin's path in this checkout. `agent-spec-model` has
the spec-analyzer agent open the plugin's spec model. `session-docs` has Claude find a doc through the
session context. The control, `without-rule`, runs without the rule, where the same read is denied.
Agents that ask for `opus` run on Haiku (`ANTHROPIC_DEFAULT_OPUS_MODEL`). Three sessions cost about
$0.60; run it after any change to how the plugin's skills, agents, or hooks name the reference docs.
Report: [`reports/2026-10-05-plugin-docs.md`](reports/2026-10-05-plugin-docs.md).

The **adopt** suite builds its own project (`fixtures/adopt/project.sh`: a new repository with no
commits) and appends each run's end state (`inspect.sh`) to the transcript. `{{FRAMEWORK}}` in a
prompt becomes `--source`: the GitHub address by default, which tests what's published on `main`, or
a checkout's path, which tests a branch before it merges. A fixture marked `<!-- run: plugin-dir -->`
loads the installer plugin from this checkout for that session only, so nothing is installed on the
machine; no session may run `claude plugin` commands. A fixture with a `## Follow-up` section gets a
second turn in the same session — `new-project` answers `/adopt`'s questions there and adopts, which
is a long session (budget $8 per turn by default; run it on one model).

It needs a signed-in Claude Code CLI (`claude auth login`); a full triage run is 16 sessions, about
$5 API-equivalent. Graded reports of past runs: [`reports/`](reports/) (the first one ran the
script under its earlier name, `run-triage-evals.sh`).


### Manual (zero setup)

1. Open the fixture's `input.md`.
2. Paste the prompt into your AI tool (Claude Code, Cursor, etc.).
3. Run the relevant skill (`/write-spec`, etc.) on the prompt.
4. Compare the AI's output against `expected.md`'s invariants by hand.
5. Note pass/fail and which invariants were missed.

### Automated

See [`run-dynamic.md`](run-dynamic.md) for SDK-based patterns. Common stacks:
- Anthropic SDK directly
- Braintrust eval-as-code
- DeepEval (Python)
- Custom scripts hitting your AI tool's API

## Invariant style

Good invariants:
- ✓ "Frontmatter has `feature-type: ui`"
- ✓ "Section `## Security [REQUIRED]` is present and non-empty"
- ✓ "Functional section contains at least 3 numbered acceptance criteria"
- ✓ "Output does not contain code samples or file paths"
- ✓ "Status is `draft` (not `approved`)"

Bad invariants:
- ✘ "Output is good" (not measurable)
- ✘ "Output is exactly: [200 lines of expected text]" (brittle)
- ✘ "Output is in friendly tone" (subjective)

## When to add a fixture

When a real failure surfaces. See [STRATEGY.md](../STRATEGY.md) for guidance — the rule is: don't write fixtures speculatively, write them when a regression actually happens.

## Fixture naming

Use `<scenario>.input.md` / `<scenario>.expected.md` where `<scenario>` describes what's being tested:
- `simple-feature.input.md` — happy-path baseline
- `personal-data-feature.input.md` — triggers conditional Privacy requirement
- `ui-feature.input.md` — triggers conditional Accessibility requirement
- `api-only-feature.input.md` — no UI, no a11y required
- `ambiguous-requirement.input.md` — verifies the AI asks clarifying questions instead of guessing

Group by skill under `fixtures/<skill-name>/`.

## Cost considerations

Dynamic evals cost tokens. A typical `/write-spec` run consumes ~5-15k tokens (input + output). At Claude Sonnet rates that's roughly $0.05-$0.15 per case.

Recommended cadence:
- **Per PR**: skip dynamic evals (run static only). Devs run them locally when they touch a skill.
- **Nightly CI**: run the full dynamic suite. Alert on failure rate spikes.
- **Pre-release**: full suite + manual review of any new failures before publishing the framework version.

If your suite grows past ~20 fixtures, consider sampling (run a random subset per night, full suite weekly) or model-tiering (use Haiku for graders, Sonnet for the actual workflow being tested).
