# [PROJECT NAME] — Claude Code

<!-- The Claude Code layer: no `paths:`, so it loads in every session beside AGENTS.md, which every tool reads. No CLAUDE.md or CLAUDE.local.md in the project — Claude Code would read it instead of AGENTS.md. -->

## Skills, agents, and workflows

- **Skills** (`/`) — the workflow playbooks: `/triage`, `/write-spec`, `/write-plan`, `/write-docs`, `/implement`, `/review`, `/commit`, `/open-pr`, and more. They run in this conversation — the cheapest option.
- **Agents** (`@`) — isolated specialists with their own model and context: an independent second opinion, restricted tools (reviewers can't edit), or work alongside yours. `@spec-analyzer` checks a spec folder before the approval gate.
- **Workflows** (`/deep-…`) — multi-agent fan-outs with adversarial verification: `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep`. Several times the cost of the skill they extend — for high-stakes changes and broad sweeps.
- **The local environment's URL** — `LOCAL_URL` in `.claude/hooks/config.sh`, a worktree's `READY_URL` (parallel-agents), or `make urls` (docker module); in Claude Desktop the Browser lists the running app. Give it to the developer in the local check.

## Guardrails enforced by configuration

Hooks and permissions hold whatever the instructions say; their values live in `.claude/hooks/config.sh` and `.claude/settings.json`:

- **Ask first:** readying, merging, or reviewing a pull request, releases, `push --tags`, `git config`, `gh auth`, secrets, and `gh api` writes. Commits, the work branch's push, and its draft — and keeping that draft current — need no prompt.
- **Never:** `--no-verify`; a commit, push, or force-push on a protected branch; a pull request that isn't a draft; a hand edit to generated files or append-only history; reading secret env files.
- **Stops once, as a reminder:** a session's first edit or new branch with no lane stated in your replies; the first edit in a sensitive area; with parallel-agents, any edit in the main checkout (`/dispatch` first).
- **Tells you:** the branch, worktree role, and spec folder at session start; when this branch's pull request merges or closes (offer `/wrap-up`, or ask whether the task is dropped); an environment variable missing from the env template.

Commits, the push, and the draft are a standing go-ahead: never ask for them — not in a reply, and not in the desktop app's next-step box. `/stakeholder-update` drafts the requester's update and posts nothing without the developer's yes to the exact text.

## Commands that run without a prompt

An allow rule matches a command as written; Claude Code asks about anything it can't check.
- **Use the project's tasks:** `make test t=<file>`, `make lint f=<file>`, `make logs s=web` — a
  variable goes after the task, never as a leading `VAR=value`.
- **Run them in the configured mode.** With the docker module, only the developer changes the mode:
  never set `DEV_MODE` or `SERVICES` on a command, or change them in `.env` or the `Makefile`, even
  when asked — say which setting to change. A task that can't run in this mode is a question for them.
- **Write paths out** — no `S=/path; … $S/…` — and **stay in this checkout:** `git` from the
  session's folder, not `git -C <path>`; `cd` only inside the project.
- **Read and edit with the tools,** not `for` loops or `python3 - <<EOF` / `node -e` scripts.
- **Keep output short with a pipe** (`2>&1 | tail -n 40`), not a redirect outside the project.

A read-only command that prompts every time is a gap in `.claude/settings.json`: name it to the
developer.

## Lanes — match ceremony to risk

Lane definitions are in `AGENTS.md` § How work flows; in Claude Code:

| Lane | Workflow | Model |
|---|---|---|
| Fast | `/triage` (one line) → the test first, seen failing → edit → green → `/commit`; a light `CR N` when it changes recorded behavior | `sonnet` |
| Careful | Fast, plus the area's checklist (`specs/README.md`), `@security-reviewer` for authorization, personal data, or payments, and the risky part named in the pull request | `sonnet`, high effort |
| Full | `/triage` → `/write-spec` → `/write-plan` → approval → `/write-docs` → `/implement` → `/review` | `opus`, high effort, up to the gate; a fresh `sonnet` session from `/write-docs` on |
| Bug, cause unknown | `/debug`, then the lane the fix needs | `sonnet`; `opus` after two disproven hypotheses |
| Refactor | `/refactor` → tests still green → `/commit` (full when it sets a structure others must follow) | `sonnet` |
| Answer | `/triage` → deliver the answer; no spec, no environment unless needed | `sonnet`; `opus` for architecture-level questions |

If there's nothing to decide, there's no spec folder; if a teammate could merge the diff without new
docs, there's nothing for `/write-docs`.

## Cost model

A session costs roughly *calls × context*: one task per session (`/clear` between tasks), short
output. Choose the model by the work: `sonnet` when the task has a clear spec and a way to check the
result, `opus` for judgment. Each model has its own prompt cache, so switch where it's cheap — at the
start, right after triage (in the desktop app, `/triage` switches the session's model and effort
itself), or in a fresh session after the approval gate. Agents carry their own model; the `/deep-…`
workflows pin theirs. The project default is `"model": "sonnet"`, but the desktop app's picker and
`/model` decide for a session. Keep this file, `AGENTS.md`, and the rules stable — an edit busts the
cache. Details: `docs/COST-MODEL.md`.

## Memory, rules, and MCP

Facts that change more than once a quarter stay out of the always-loaded files (`docs/MEMORY-STRATEGY.md`).
Rules in `.claude/rules/` load when a file matching their `paths:` is read; delete the ones that
can't apply to this stack. Servers in `.mcp.json` are shared with the team; a tracker server follows
`docs/TRACKER-INTEGRATION.md`.
