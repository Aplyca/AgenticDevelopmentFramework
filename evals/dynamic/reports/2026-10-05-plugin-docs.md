# Session evals — the reference docs in the plugin — 2026-10-05

Decision 0019 moves the framework's four reference docs out of packaged projects and into the
`aplyca-adf` plugin. Whether a session can use them there depends on Claude Code, not on the
framework's files. So the design followed headless sessions (Claude Code v2.1.286, Haiku 4.5, default
permission mode, no user settings), run first as experiments and then as the new `plugin-docs` suite.

## Experiments: what a plugin's own files allow

These ran on a throwaway plugin with a note in `docs/`, a skill, an agent, and workflows, loaded with
`--plugin-dir`. They also used the installed copy of `aplyca-adf` v1.1.0 under
`~/.claude/plugins/cache/`.

| Question | What happened | Finding |
|---|---|---|
| Does a skill get `${CLAUDE_PLUGIN_ROOT}` filled in? | The skill read the plugin's real path | Yes |
| Does an agent? | The agent, with only the Read tool, read the real path. Asked to quote its instructions, `spec-analyzer` quoted the full path | Yes |
| Does a workflow script? | The workflow's agent got the literal `${CLAUDE_PLUGIN_ROOT}`, and found the path only by loading one of the plugin's skills. In a template literal, the script threw | No |
| Can a session read the plugin's `docs/` without asking? | Denied (headless) | No |
| A skill's own folder, or another skill's? | Denied, both | No |
| The installed copy in `~/.claude/plugins/cache/`? | Denied, with the plugin loaded from there and without | No |
| With `Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)` allowed? | The session and a plugin agent each read the installed copy, nothing asked | Yes |
| A project's allow rule, in a session that never trusted the folder? | Ignored: "this workspace has not been trusted" | Headless runs pass the rule with `--allowedTools` |

That is the design: the plugin carries the docs, skills and agents name its copy, a packaged project
commits the read rule, and the one workflow that needs the spec model carries its text.

## The suite

`run-session-evals.sh --suite plugin-docs` builds a packaged project the way `/adopt` leaves it, with
no reference docs in `docs/` and links at the release. Its sessions get no extra directory and no
blanket `Read`. The read rule is passed with `--allowedTools` for the plugin's path in the checkout,
as the project's rule applies to a teammate who trusted the folder.

| Run | Sessions | Checks | Cost |
|---|---|---|---|
| 1 | 3 | 5 passed, 1 failed | $0.54 |
| 2: `agent-spec-model` after the fix | 1 | 2 passed, 0 failed | $0.41 |
| 3: the suite on the final build | 3 | 7 passed, 0 failed | $0.58 |

| Case | What happened in the session | Checks |
|---|---|---|
| `agent-spec-model` | Run 1: the spec-analyzer agent read `docs/SPEC-MODEL.md` in the project, which doesn't exist, instead of the plugin's copy. Runs 2 and 3: it read the plugin's copy at its full path, and nothing asked | ✘ ✓ → ✓ ✓ |
| `session-docs` | The plugin's session context named its `docs/` folder. Claude read `MEMORY-STRATEGY.md` there, answered `# Memory strategy`, and fetched nothing | ✓ ✓ ✓ ✓ |
| `without-rule` | The same read was denied. Claude asked for permission to open the document instead of inventing its heading — the prompt a teammate would see | ✓ |

## What run 1 found

The agent's instructions gave the full path, which the experiment above confirmed Claude Code had
filled in. Haiku still read the doc as a project path. It was told to read four files, the other
three in the project (`AGENTS.md`, `docs/CONSTITUTION.md`, `specs/README.md`). The build now opens
every plugin skill and agent that names a reference doc with one line: those are the plugin's copies,
outside the project, so read them at the full paths given. Run 2 read the plugin's copy.

## Negative controls

Each check was fed a run where it shouldn't pass, and each marked ✘ there:

- `agent-spec-model`'s read check, on run 1's agent session.
- `session-docs`' read and no-asking checks, on the `without-rule` session.
- `without-rule`'s denial check, on the `session-docs` session.

## Not run here

- **`deep-spec-analysis`.** Its plugin copy carries the spec model's text, which the build puts in
  and the static checks parse. Running it costs a run of six or more agents for a step the build
  already guarantees.
- **The read rule against the cache path, through the suite.** The suite loads the plugin from the
  checkout, so its rule names that path. The cache path itself is covered by the experiment above.
