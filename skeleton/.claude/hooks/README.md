# Claude Code hooks

Instructions in `AGENTS.md` are context: an agent reads them and usually follows them. These
hooks are the rules that must hold **every** time, so they run as code at fixed points instead of
depending on what the model decides. They are wired in `../settings.json`.

| Hook | Event | What it does |
|---|---|---|
| `session-context.sh` | SessionStart | Adds a few lines to the session: main checkout or worktree, branch, uncommitted changes, the spec folder for the branch and its status, and — with the parallel-agents module — whether this session is a dispatcher or a worker |
| `guard-git.sh` | PreToolUse · Bash | Blocks `--no-verify` (and `git commit -n`), commits on protected branches, and pushes, force-pushes, or deletes targeting protected branches |
| `protect-paths.sh` | PreToolUse · Edit/Write | Blocks hand-edits to generated files (lockfiles, generated types) and modifications to existing files in append-only history (migrations) |
| `careful-paths.sh` | PreToolUse · Edit/Write | The first edit in each sensitive area (`CAREFUL_GLOBS`) is stopped once per session, so the agent confirms the change is in the careful or full lane before going on. Empty `CAREFUL_GLOBS` turns it off |
| `check-env-declared.sh` | PostToolUse · Edit/Write | After an edit, reports environment variables the file reads that the env template (`.env.example` or similar) doesn't declare, so Claude declares them. With no env template in the repository it does nothing — add one, or set `ENV_TEMPLATE` |

Pushing to a non-protected branch, opening or readying a pull request, and other outward actions
aren't blocked here — `permissions.ask` in `../settings.json` makes a human confirm each one.

## Configure

Edit **`config.sh`** — protected branches, append-only and generated paths, sensitive paths, the
env template, ignored variables. The scripts read it on every run; you don't edit the scripts (they are
framework-owned and replaced on upgrade).

## Requirements and behavior

- `bash`, `git`, and `jq` (or `python3` as a fallback) on the PATH. If neither JSON parser is
  available, a hook prints a notice and lets the action through rather than blocking everything.
- Exit code 2 blocks a PreToolUse call and shows the reason to Claude; for PostToolUse the edit has
  already happened and the message goes to Claude to act on.
- The git guard matches the command text an agent writes. A deliberately disguised command can get
  past it — it is a guardrail against mistakes, not a security boundary. The real boundaries are
  branch protection on the Git host and human review.
- Hooks in project settings run only after you trust the folder.

## Disable or extend

- Turn one off by removing its entry from `../settings.json` (`/hooks` shows what is active).
- Add a project-specific hook as a new script here, wired the same way. Read the event JSON from
  stdin (`tool_input.command`, `tool_input.file_path`, `cwd`), and source `_lib.sh` for the
  helpers. Keep hooks fast — they run on every matching tool call.
