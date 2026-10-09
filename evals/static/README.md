# Static evals

Deterministic checks of the framework's own files — zero AI invocation, seconds to run, run in CI on
every pull request (`.github/workflows/evals.yml`). Four suites, all run by `../run-evals.sh`:

| Suite | What it does |
|---|---|
| `check-skills.sh` | **Structure** — skills, agents, workflows, settings and hook wiring, instruction files, spec templates, links, modules |
| `test-hooks.sh` | **Behavior of the guardrail hooks** — feeds real tool events (JSON on stdin, exactly as Claude Code sends them) into a committed project's hooks — the copies `scripts/build-committed.py` writes from the `adf` plugin — and into the plugin's own, against a throwaway repository and checks block / allow |
| `test-modules.sh` | **Behavior of the module scripts** — the `git-hooks` `pre-push` against a bare remote, and the `parallel-agents` worktree scripts (create, idempotent rerun, env seeding, port reservation under a lock, setup/start, removal), the `clickup` installer (merges into existing `.mcp.json` and settings, idempotent, keeps customizations, refuses invalid JSON), the `docker` installer (merges its permission rules, idempotent, refuses invalid JSON) with a simulation of which docker and `make` commands ask, run, or prompt, and the stack `/dev-env` writes from its templates (`make env`, `help`, `reset`, `logs`, and `ops/scripts/ports.sh` against a stub `docker`: the ports Docker picked, the native app's ports, the copied-`.env` guard, no secret printed), in throwaway repositories |
| `test-plugin.sh` | **Behavior of the plugin's scripts** — `/cost-report`'s `session_cost.py` against synthetic transcripts: which folders count, the cost arithmetic, the model tier, and each flag (long context, pauses, browser loops, spec-heavy) |

## What `check-skills.sh` checks

| Check | Why it matters |
|---|---|
| Every skill has frontmatter with `name` (matching its directory) and a meaningful `description` | Required to load; the description routes invocation |
| Frontmatter keys are hyphenated (`argument-hint`, `disable-model-invocation`, `user-invocable`) — never `user_invocable` and the like | Unknown keys are silently ignored; this defect shipped once |
| `/open-pr` sets `disable-model-invocation: true`; `/stakeholder-update`, which can start from a plain request, shows its draft and asks before posting when nobody asked for it | Nothing leaves the machine unless a human asked for it |
| Every skill has `## Steps`, `## Phase`, or `## Workflow` sections; discipline skills have a Rationalizations table (≥4 rows) and a Verification checklist (≥4 items) | Explicit steps and anti-rationalization are the main defenses against agent drift |
| Agents: `name` matches the directory, a meaningful description, `model` is an alias, `inherit`, or a full ID | Loadable, routable, and future-proof |
| Workflows: `meta` is a pure literal with a matching name and a description, phase titles match, no `Date.now()` / `Math.random()`, the script parses | Workflows fail at load or break resume otherwise |
| `settings.json`: valid JSON, alias model, every hook entry nests a `hooks` array, no `$CLAUDE_FILE_PATH`, referenced scripts exist and are executable, outward actions are in `permissions.ask` | The flat hook schema silently never ran; outward actions must need a human |
| Hook scripts pass `bash -n` | Syntax errors would turn a guardrail into a notice |
| The skeleton has no `CLAUDE.md`; `AGENTS.md`'s first line is the stamp; `.claude/rules/claude-code.md` has no `paths:` | Claude Code reads a `CLAUDE.md` instead of `AGENTS.md`; `/upgrade` and the plugin's hooks read the stamp; the Claude layer must load in every session (decision 0024) |
| `AGENTS.md` covers triage with the lane, the three lanes, the approval gate, the change surface, docs first, red before green, change requests, sensitive areas, working economically, boundaries — in ≤200 lines | The always-loaded contract must be complete and lean |
| The git-workflow rule lists the commit prefixes and the draft / outward-action rules | Workflow integrity |
| Workflow-integrity phrases in `/write-spec`, `/write-plan`, `/implement`, `/write-docs`, `/open-pr` | Removing them silently removes a gate |
| Spec scaffold: `specs/README.md`, `_templates/{spec,plan,tasks}.md` exist, the legacy template is gone, required frontmatter and sections, the plan's change surface / constitution check / test strategy / documentation plan / assumptions, the tasks' TDD loop and gate results | The templates are the contract every skill reads |
| Every relative link in `skeleton/`, the committed machinery, and `modules/*/files/` resolves inside an adopting repository | Framework-only links shipped once and broke in every adopted repo |
| A module's `settings-fragment.json` pre-approves only MCP tools and `Bash` commands that read — no command that changes state or prints secrets, no whole program — and its `.mcp.json` carries no credentials | A write tool on the allowlist would post to the client without a prompt; a destructive command would run without one |
| Lanes: `specs/README.md` defines them (triggers, checklists, the developer's call, light change requests); `/triage` decides them; `/review` checks them; `CAREFUL_GLOBS` and the `careful-paths` hook are wired; the spec template has the light form | Ceremony follows risk only while every piece of the routing is in place |
| Plugin skills have valid frontmatter; plugin scripts compile; skill and agent names are unique across plugins | The plugins ship to every machine that installs them, and a bare name must reach one skill |
| `plugins/`' generated parts (`bin/`, the spec model, the agents' checklists, and the skills' steps in the workflows, the versions) match a fresh `scripts/build-plugins.sh`; every file a committed install carries comes back unchanged from its committed form (`build-committed.py --check`); the marketplace lists every plugin folder, `adf` first; every plugin's version equals the newest release | A source change that wasn't rebuilt would ship old machinery; one release pins every plugin (decisions 0016, 0017, 0023) |
| A plugin's mods are display-only — they hook only session, turn, command, and drawing events, and never call a prompt, a tool, a process, a model, or a file write; the one exception is the `adf-dev` band's `docker compose port <service> <port>`, with that argument vector — `hooks.json` names a file beside it, and each mod has tests (`run-evals.sh` runs them with `claude plugin test` where the CLI is installed) | A mod runs with the developer's permissions inside Claude Code; the framework's act only through skills, hooks, and permissions every install shares (decisions 0026, 0032) |
| `/dev-env`'s templates keep the local-environment conventions: `compose.yaml` has no `env_file:`, `container_name:`, or top-level `name:`, publishes every port as `"127.0.0.1:${<NAME>_PORT:-}:<port>"`, declares each `${VAR}` in `.env.example`, pins images, and waits only on healthchecks; the `Makefile` has every task, help as the default, no follow in `logs`, and nothing GNU make 3.81 lacks; `.env.example` leaves the ports empty; every shipped `.sh` runs on bash 3.2 | Every stack `/dev-env` writes starts from these files, and macOS ships bash 3.2 and make 3.81 (decision 0032) |
| No plugin workflow names a `.claude/agents/` or `.claude/skills/` path a packaged project lacks; a lens that follows an agent's checklist carries it (`const <AGENT>_CHECKLIST`), and an agent that follows a skill's steps carries them (`const <SKILL>_STEPS`) | A packaged project has no `.claude/agents/` or `.claude/skills/`, and a workflow can't reach the plugin's, so its agents would look for a file that isn't there (decisions 0029, 0030) |
| The skills a committed install carries, the agents, the reference docs, and the hooks name no `.claude/agents/`, `.claude/workflows/`, `.claude/skills/`, `agent.md`, or hook script in `.claude/hooks/` outside the Step 0 and a paragraph (in a script, a line) about a committed install; a glob over the project's own passes | A packaged project, the default install, runs the plugin's copies and has none of these: text that names one sends it to a file that isn't there. Four pull requests fixed such mentions one file at a time before this check |
| Each plugin carries the skills of the modules whose `module.json` names it; every skill but the installer's and `/connect` has a Step 0, so a committed install carries it | A module's skills reach the plugin of its concern and no other (decision 0023) |
| Every module has `MODULE.md` and a `files/` tree, no `files/README.md`; module skills pass the skill checks; a module that ships skills has a `module.json` naming a plugin in `plugins/`, and `moved_from`, when it has one, is the one folder its commands' scripts lived in before | Modules install with `cp -R`; a README would overwrite the target's |

## Running

From the framework repo root:

```bash
./evals/run-evals.sh             # all three suites
./evals/static/check-skills.sh   # one suite
```

Each prints `✓` / `✘` per check and exits non-zero on any failure. Requirements: `bash`, `git`,
`python3`; `node` for the workflow syntax check; `jq` or `python3` for the hooks.

## Adding a check

- **Structure:** add a function to `check-skills.sh` that calls `pass` / `fail`, and call it from the
  main section. One assertion per check.
- **Hook behavior:** add a `run <hook> <expected-exit> <event-json> <description>` line to
  `test-hooks.sh`.
- **Module behavior:** add a `check <description> <condition>` to `test-modules.sh`.

Follow [STRATEGY.md](../STRATEGY.md): add a check when a real regression surfaces, keep each one
atomic and fast. If a check fails, fix the file, not the check — unless the framework genuinely
changed, in which case update the check and say why in the commit message.

## What this catches vs. doesn't catch

**Catches:** a deleted rationalization table or gate phrase; broken template structure; configuration
that loads but silently does nothing (flat hooks, underscore keys, a missing import); hooks that stop
blocking what they should; module scripts that regress; links that break in adopting repos.

**Doesn't catch:** whether a skill, invoked, produces good output; whether an agent rationalizes past a
table; whether instructions agree semantically. That's what the dynamic fixtures in `../dynamic/` are for.
