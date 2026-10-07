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
| [0005](0005-outward-actions-and-draft-prs.md) | Outward actions only on request; pull requests stay drafts until a human QCs them | accepted; amended by 0022 |
| [0006](0006-guardrails-as-configuration.md) | Guardrails that must hold are configuration and code, not prose | accepted; amended by 0022 |
| [0007](0007-process-decision-records.md) | Process decisions are recorded as PDRs; the constitution is amended through them | accepted |
| [0008](0008-dispatcher-and-worker-worktrees.md) | The main checkout dispatches; worktrees do the work (optional module) | accepted; amended by 0015, 0020 |
| [0009](0009-optional-modules.md) | Host- and team-specific harness ships as optional modules | accepted; amended by 0016 |
| [0010](0010-model-aliases.md) | Configure models with version-less aliases | accepted |
| [0011](0011-lanes-ceremony-follows-risk.md) | Three lanes — ceremony follows risk and uncertainty, not size | accepted; partly superseded by 0014 |
| [0012](0012-choose-the-model-by-the-work.md) | Choose the model by the work — Sonnet for well-specified work, Opus for judgment | accepted |
| [0013](0013-adapt-practices-not-a-second-workflow.md) | Adapt practices from other skill collections into our skills — never a second workflow | accepted |
| [0014](0014-test-first-in-every-lane.md) | Test first in every lane | accepted |
| [0015](0015-tool-worktrees-are-workers.md) | Worktrees that Claude Code creates are workers too (parallel-agents module) | accepted; amended by 0020 |
| [0016](0016-packaged-install.md) | A packaged install — the framework's machinery from its pinned plugin, `aplyca-adf` (opt-in, Claude Code only) | accepted; amended by 0018, 0019, 0020 |
| [0017](0017-semantic-versioning.md) | Releases follow semantic versioning | accepted |
| [0018](0018-packaged-by-default.md) | The packaged install is the default | accepted |
| [0019](0019-reference-docs-in-the-plugin.md) | A packaged project reads the framework's reference docs from the plugin | accepted |
| [0020](0020-every-task-through-dispatch.md) | Every task goes through `/dispatch` in the main checkout (parallel-agents module) | accepted; amended by 0021 |
| [0021](0021-sibling-worktree-and-chip.md) | `/dispatch` hands every task to a new session that creates its worktree beside the main checkout and moves into it (parallel-agents module) | accepted |
| [0022](0022-local-check-before-the-pull-request.md) | The developer approves a change on the local environment, and the approval opens its draft pull request | accepted |

Changes that follow from these records are listed, with their upgrade impact, in
[`CHANGELOG.md`](../../CHANGELOG.md).
