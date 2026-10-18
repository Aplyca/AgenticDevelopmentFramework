# Framework decision records

Why the framework works the way it does. Each record follows the PDR shape the framework teaches
adopting teams (`skeleton/docs/process/`): context with evidence, the decision, its consequences
including the cost, and the alternatives that were rejected. Records are append-only: a decision
that changes is superseded by a new record.

Most of these decisions came from running the framework — and practices that grew alongside it — in
real client projects, then generalizing what held up. The evidence is described without naming the
projects.

| # | Decision | Status |
|---|---|---|
| [0001](0001-spec-folders-as-record-of-intent.md) | Spec folders are the record of intent; trackers are linked, never copied | accepted |
| [0002](0002-one-approval-gate-on-the-change-surface.md) | One approval gate, after the plan, on the change surface | accepted |
| [0003](0003-tdd-at-task-granularity.md) | TDD at task granularity: one task, one red → green cycle, one commit | accepted |
| [0004](0004-triage-before-setup.md) | Triage a task before setting anything up | accepted |
| [0005](0005-outward-actions-and-draft-prs.md) | Outward actions only on request; pull requests stay drafts until a human QCs them | accepted; amended by 0022, 0033 |
| [0006](0006-guardrails-as-configuration.md) | Guardrails that must hold are configuration and code, not prose | accepted; amended by 0022 |
| [0007](0007-process-decision-records.md) | Process decisions are recorded as PDRs; the constitution is amended through them | accepted |
| [0008](0008-dispatcher-and-worker-worktrees.md) | The main checkout dispatches; worktrees do the work (optional module) | accepted; amended by 0015, 0020, 0032, 0042, 0044 |
| [0009](0009-optional-modules.md) | Host- and team-specific harness ships as optional modules | accepted; amended by 0016, 0023 |
| [0010](0010-model-aliases.md) | Configure models with version-less aliases | accepted |
| [0011](0011-lanes-ceremony-follows-risk.md) | Three lanes — ceremony follows risk and uncertainty, not size | accepted; partly superseded by 0014 |
| [0012](0012-choose-the-model-by-the-work.md) | Choose the model by the work — Sonnet for well-specified work, Opus for judgment | accepted |
| [0013](0013-adapt-practices-not-a-second-workflow.md) | Adapt practices from other skill collections into our skills — never a second workflow | accepted |
| [0014](0014-test-first-in-every-lane.md) | Test first in every lane | accepted |
| [0015](0015-tool-worktrees-are-workers.md) | Worktrees that Claude Code creates are workers too (parallel-agents module) | accepted; amended by 0020, 0040 |
| [0016](0016-packaged-install.md) | A packaged install — the framework's machinery from its pinned plugin, `aplyca-adf` (opt-in, Claude Code only) | accepted; amended by 0018, 0019, 0020, 0023 (renamed `adf` in v2.0.0), 0024, 0027, 0028, 0041 |
| [0017](0017-semantic-versioning.md) | Releases follow semantic versioning | accepted; amended by 0023 |
| [0018](0018-packaged-by-default.md) | The packaged install is the default | accepted |
| [0019](0019-reference-docs-in-the-plugin.md) | A packaged project reads the framework's reference docs from the plugin | accepted; amended by 0028, 0044 |
| [0020](0020-every-task-through-dispatch.md) | Every task goes through `/dispatch` in the main checkout (parallel-agents module) | accepted; amended by 0021, 0023, 0042 |
| [0021](0021-sibling-worktree-and-chip.md) | `/dispatch` hands every task to a new session that creates its worktree beside the main checkout and moves into it (parallel-agents module) | accepted; amended 2026-10-07, by 0035; amended by 0040, 0042 |
| [0022](0022-local-check-before-the-pull-request.md) | The developer approves a change on the local environment, and the approval opens its draft pull request | accepted; amended by 0033, 0039 |
| [0023](0023-plugins-by-concern.md) | One plugin per concern — the process, development, connections — and modules as each project's switches | accepted; amended by 0027, 0028 |
| [0024](0024-agents-md-only.md) | No `CLAUDE.md` — Claude Code reads `AGENTS.md`, and its own layer is a rule | accepted |
| [0025](0025-no-gemini-md.md) | No `GEMINI.md` — Antigravity reads `AGENTS.md`, and Gemini CLI is pointed at it | accepted |
| [0026](0026-display-only-mods.md) | The framework's mods are display-only — the first shows the local environment's URL | accepted; amended by 0032 |
| [0027](0027-worktree-scripts-as-plugin-commands.md) | The worktree scripts are the plugin's commands — `adf-worktree-new`, `-ls`, `-rm` (parallel-agents module) | accepted; amended by 0032, 0045 |
| [0028](0028-plugins-are-the-source.md) | The plugins are the machinery's source, and a committed install is written from them | accepted; amended by 0029, 0045 |
| [0029](0029-workflows-carry-agent-checklists.md) | A workflow carries the agent checklists its lenses follow | accepted; amended by 0030 |
| [0030](0030-workflows-carry-skill-steps.md) | A workflow carries the skill steps its agents follow | accepted |
| [0031](0031-agent-model-overrides-in-the-project-rule.md) | A project changes an agent's model in its own rule, which the session passes when it spawns the agent | accepted |
| [0032](0032-local-environment-layout.md) | A project's local environment: `compose.yaml` and a `Makefile` at the root, operations in `ops/`, ports Docker picks | accepted; amended by 0034, 0038 |
| [0033](0033-pull-request-upkeep-without-prompts.md) | An agent pushes, opens, edits, and comments on its draft pull request without a prompt | accepted; amended by 0038 |
| [0034](0034-local-environment-modes.md) | The local environment runs in Docker or natively, and `ops/` has one folder per target | accepted; amended 2026-10-15, 2026-10-16 |
| [0035](0035-move-into-the-worktree-without-a-prompt.md) | A dispatched session moves into its task's worktree without a prompt | accepted |
| [0036](0036-wrap-up-after-the-merge.md) | After the merge, a task's session wraps itself up with one yes | accepted |
| [0037](0037-end-to-end-tests.md) | End-to-end tests follow a specification: Playwright in `e2e/`, against the checkout's own stack | accepted; amended 2026-10-16 |
| [0038](0038-fewer-prompts-for-tasks-and-local-git.md) | Allow broadly, ask by name: make, docker, git, and gh | accepted |
| [0039](0039-check-locally-then-on-the-preview.md) | An agent checks a change locally first, then on the pull request's preview | accepted |
| [0040](0040-workers-move-out-of-the-apps-worktree.md) | A worker that starts in the desktop app's worktree moves to the task's worktree beside the main checkout | accepted; amended by 0042 |
| [0041](0041-the-pin-updates-every-machine.md) | The pinned marketplace auto-updates, and an upgrade names the commands for each machine | accepted |
| [0042](0042-each-session-moves-to-its-task-worktree.md) | Each task's session moves to its own worktree; the main checkout hands nothing out (parallel-agents module) | accepted |
| [0043](0043-track-time-in-the-tracker.md) | A task's time goes to the tracker as two numbers, and the developer picks one per entry (time-tracking module) | accepted |
| [0044](0044-parallel-agents-guide-in-the-plugin.md) | The parallel-agents guide ships in the plugin; the project keeps only its shared services (parallel-agents module) | accepted |
| [0045](0045-a-scripted-upgrade-from-the-new-release.md) | An upgrade runs a script from the new release, and the developer approves only what needs a person | accepted |

Changes that follow from these records are listed, with their upgrade impact, in
[`CHANGELOG.md`](../../CHANGELOG.md).
