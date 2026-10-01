# Static evals

Deterministic checks of the framework's own files — zero AI invocation, seconds to run, run in CI on
every pull request (`.github/workflows/evals.yml`). Three suites, all run by `../run-evals.sh`:

| Suite | What it does |
|---|---|
| `check-skills.sh` | **Structure** — skills, agents, workflows, settings and hook wiring, instruction files, spec templates, links, modules |
| `test-hooks.sh` | **Behavior of the guardrail hooks** — feeds real tool events (JSON on stdin, exactly as Claude Code sends them) into `skeleton/.claude/hooks/` against a throwaway repository and checks block / allow |
| `test-modules.sh` | **Behavior of the module scripts** — the `git-hooks` `pre-push` against a bare remote, and the `parallel-agents` worktree scripts (create, idempotent rerun, env seeding, port reservation under a lock, setup/start, removal) in throwaway repositories |

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
| `CLAUDE.md` imports `AGENTS.md` and carries the stamp line | Without the import, Claude Code never reads `AGENTS.md` when a `CLAUDE.md` exists |
| `AGENTS.md` covers triage, the approval gate, the change surface, docs first, red before green, change requests, boundaries — in ≤200 lines | The always-loaded contract must be complete and lean |
| The git-workflow rule lists the commit prefixes and the draft / outward-action rules | Workflow integrity |
| Workflow-integrity phrases in `/write-spec`, `/write-plan`, `/implement`, `/write-docs`, `/open-pr` | Removing them silently removes a gate |
| Spec scaffold: `specs/README.md`, `_templates/{spec,plan,tasks}.md` exist, the legacy template is gone, required frontmatter and sections, the plan's change surface / constitution check / test strategy / documentation plan / assumptions, the tasks' TDD loop and gate results | The templates are the contract every skill reads |
| Every relative link in `skeleton/` and `modules/*/files/` resolves inside an adopting repository | Framework-only links shipped once and broke in every adopted repo |
| Every module has `MODULE.md` and a `files/` tree, no `files/README.md`; module skills pass the skill checks | Modules install with `cp -R`; a README would overwrite the target's |

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
