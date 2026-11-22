# Framework decision records

Why the framework works the way it does. Each record follows the PDR shape the framework teaches
adopting teams (`skeleton/docs/process/`): context with evidence, the decision, its consequences
including the cost, and — where the record weighed any — the alternatives that were rejected. Records are append-only: a decision
that changes is superseded or amended by a new record. The one line that changes is the old
record's status, which names each later record that amends, refines, or supersedes it and how.

Most of these decisions came from running the framework — and practices that grew alongside it — in
real client projects, then generalizing what held up. The evidence is described without naming the
projects.

| # | Decision | Status |
|---|---|---|
| [0001](0001-spec-folders-as-record-of-intent.md) | Spec folders are the record of intent; trackers are linked, never copied | accepted; refined by 0011, 0050 |
| [0002](0002-one-approval-gate-on-the-change-surface.md) | One approval gate, after the plan, on the change surface | accepted; refined by 0011 |
| [0003](0003-tdd-at-task-granularity.md) | TDD at task granularity: one task, one red → green cycle, one commit | accepted |
| [0004](0004-triage-before-setup.md) | Triage a task before setting anything up | accepted |
| [0005](0005-outward-actions-and-draft-prs.md) | Outward actions only on request; pull requests stay drafts until a human QCs them | accepted; amended by 0022, 0033, 0070 |
| [0006](0006-guardrails-as-configuration.md) | Guardrails that must hold are configuration and code, not prose | accepted; amended by 0022 |
| [0007](0007-process-decision-records.md) | Process decisions are recorded as PDRs; the constitution is amended through them | accepted |
| [0008](0008-dispatcher-and-worker-worktrees.md) | The main checkout dispatches; worktrees do the work (optional module) | accepted; amended by 0015, 0020, 0032, 0042, 0044 |
| [0009](0009-optional-modules.md) | Host- and team-specific harness ships as optional modules | accepted; amended by 0016, 0023 |
| [0010](0010-model-aliases.md) | Configure models with version-less aliases | accepted |
| [0011](0011-lanes-ceremony-follows-risk.md) | Three lanes — ceremony follows risk and uncertainty, not size | accepted; partly superseded by 0014; refined by 0050; amended by 0047, 0079 |
| [0012](0012-choose-the-model-by-the-work.md) | Choose the model by the work — Sonnet for well-specified work, Opus for judgment | accepted; amended by 0062 |
| [0013](0013-adapt-practices-not-a-second-workflow.md) | Adapt practices from other skill collections into our skills — never a second workflow | accepted; amended by 0062 |
| [0014](0014-test-first-in-every-lane.md) | Test first in every lane | accepted |
| [0015](0015-tool-worktrees-are-workers.md) | Worktrees that Claude Code creates are workers too (parallel-agents module) | accepted; amended by 0020, 0040 |
| [0016](0016-packaged-install.md) | A packaged install — the framework's machinery from its pinned plugin, `aplyca-adf` (opt-in, Claude Code only) | accepted; amended by 0018, 0019, 0020, 0023 (renamed `adf` in v2.0.0), 0024, 0027, 0028, 0041 |
| [0017](0017-semantic-versioning.md) | Releases follow semantic versioning | accepted; amended by 0023 |
| [0018](0018-packaged-by-default.md) | The packaged install is the default | accepted |
| [0019](0019-reference-docs-in-the-plugin.md) | A packaged project reads the framework's reference docs from the plugin | accepted; amended by 0028, 0044 |
| [0020](0020-every-task-through-dispatch.md) | Every task goes through `/dispatch` in the main checkout (parallel-agents module) | accepted; amended by 0021, 0023, 0042 |
| [0021](0021-sibling-worktree-and-chip.md) | `/dispatch` hands every task to a new session that creates its worktree beside the main checkout and moves into it (parallel-agents module) | accepted; amended 2026-10-07, by 0035; amended by 0040, 0042, 0083 |
| [0022](0022-local-check-before-the-pull-request.md) | The developer approves a change on the local environment, and the approval opens its draft pull request | accepted; amended by 0033, 0039, 0045 |
| [0023](0023-plugins-by-concern.md) | One plugin per concern — the process, development, connections — and modules as each project's switches | accepted; amended by 0027, 0028; refined by 0057 |
| [0024](0024-agents-md-only.md) | No `CLAUDE.md` — Claude Code reads `AGENTS.md`, and its own layer is a rule | accepted |
| [0025](0025-no-gemini-md.md) | No `GEMINI.md` — Antigravity reads `AGENTS.md`, and Gemini CLI is pointed at it | accepted |
| [0026](0026-display-only-mods.md) | The framework's mods are display-only — the first shows the local environment's URL | superseded by 0060 |
| [0027](0027-worktree-scripts-as-plugin-commands.md) | The worktree scripts are the plugin's commands — `adf-worktree-new`, `-ls`, `-rm` (parallel-agents module) | accepted; amended by 0032, 0046 |
| [0028](0028-plugins-are-the-source.md) | The plugins are the machinery's source, and a committed install is written from them | accepted; amended by 0029, 0046 |
| [0029](0029-workflows-carry-agent-checklists.md) | A workflow carries the agent checklists its lenses follow | accepted; amended by 0030 |
| [0030](0030-workflows-carry-skill-steps.md) | A workflow carries the skill steps its agents follow | accepted |
| [0031](0031-agent-model-overrides-in-the-project-rule.md) | A project changes an agent's model in its own rule, which the session passes when it spawns the agent | accepted |
| [0032](0032-local-environment-layout.md) | A project's local environment: `compose.yaml` and a `Makefile` at the root, operations in `ops/`, ports Docker picks | accepted; amended by 0034, 0038, 0056, 0060, 0071, 0077, 0078 |
| [0033](0033-pull-request-upkeep-without-prompts.md) | An agent pushes, opens, edits, and comments on its draft pull request without a prompt | accepted; amended by 0038, 0053, 0070 |
| [0034](0034-local-environment-modes.md) | The local environment runs in Docker or natively, and `ops/` has one folder per target | accepted; amended 2026-10-15, 2026-10-16, and by 0084; point 8 superseded by 0060 |
| [0035](0035-move-into-the-worktree-without-a-prompt.md) | A dispatched session moves into its task's worktree without a prompt | accepted; amended by 0085 |
| [0036](0036-wrap-up-after-the-merge.md) | After the merge, a task's session wraps itself up with one yes | accepted; amended by 0055, 0061, 0067 |
| [0037](0037-end-to-end-tests.md) | End-to-end tests follow a specification: Playwright in `e2e/`, against the checkout's own stack | accepted; amended 2026-10-16 |
| [0038](0038-fewer-prompts-for-tasks-and-local-git.md) | Allow broadly, ask by name: make, docker, git, and gh | accepted; amended by 0074, 0077, 0078, 0088 |
| [0039](0039-check-locally-then-on-the-preview.md) | An agent checks a change locally first, then on the pull request's preview | accepted; amended by 0045, 0047, 0070, 0072 |
| [0040](0040-workers-move-out-of-the-apps-worktree.md) | A worker that starts in the desktop app's worktree moves to the task's worktree beside the main checkout | accepted; amended by 0042, 0083, 0085 |
| [0041](0041-the-pin-updates-every-machine.md) | The pinned marketplace auto-updates, and an upgrade names the commands for each machine | accepted; amended by 0090 |
| [0042](0042-each-session-moves-to-its-task-worktree.md) | Each task's session moves to its own worktree; the main checkout hands nothing out (parallel-agents module) | accepted; amended by 0083, 0085 |
| [0043](0043-track-time-in-the-tracker.md) | A task's time goes to the tracker as two numbers, and the developer picks one per entry (time-tracking module) | accepted; amended by 0061, 0064, 0066, 0092, 0094 |
| [0044](0044-parallel-agents-guide-in-the-plugin.md) | The parallel-agents guide ships in the plugin; the project keeps only its shared services (parallel-agents module) | accepted |
| [0045](0045-agent-local-check-opens-the-draft.md) | The agent's own local check opens the draft, and the developer tests after it, locally and on the preview | accepted; amended by 0047, 0070, 0071, 0072 |
| [0046](0046-a-scripted-upgrade-from-the-new-release.md) | An upgrade runs a script from the new release, and the developer approves only what needs a person | accepted |
| [0047](0047-sessions-move-to-done.md) | Sessions move to done: each turn ends with what's next, fewer stops, and a close-up for every ending | accepted; amended by 0049, 0070, 0072, 0081 |
| [0048](0048-end-user-docs-in-the-doc-tool.md) | End-user docs live in the doc tool end users read, drafted before the code and published once it ships (end-user-docs module) | accepted; scope clarified in 0059; amended by 0064 |
| [0049](0049-every-lane-pushes-without-asking.md) | Every lane commits, pushes, and opens its draft without asking — a standing go-ahead | accepted; amended by 0070 |
| [0050](0050-spec-records-name-roles-and-contracts.md) | Spec folders name roles, a change request can ride the open pull request, and a split feature shares one written contract | accepted; refined by 0054 |
| [0051](0051-agent-owned-sections-of-the-pull-request.md) | The agent owns marked sections of its pull request's description and refreshes them from the record | accepted; amended by 0055 |
| [0052](0052-production-build-in-the-configured-mode.md) | A production-like run is the optional `make prod` task, in the configured mode (docker module) | accepted |
| [0053](0053-stakeholder-updates-at-three-moments.md) | The requester hears at three moments — started, in review, delivered — on the tracker task, on a yes, never on the pull request | accepted; amended by 0059, 0064, 0073 |
| [0054](0054-found-along-the-way.md) | What an agent finds along the way is reported and routed — never dropped, never fixed in passing | accepted; refined by 0080; amended by 0082 |
| [0055](0055-lean-context-and-acting-model-routing.md) | The always-loaded files carry rules, not procedures; triage fits the session's model; the developer's "merged" closes up | accepted; amended by 0062, 0065 |
| [0056](0056-the-running-app-in-claude-desktops-browser.md) | Claude Desktop's Browser lists each checkout's running web services — those `compose.yaml` labels — from an untracked `.claude/launch.json` that `make up` and `adf-worktree-new` keep | accepted; point 9 superseded by 0060 |
| [0057](0057-read-only-profiles-for-connected-services.md) | `/connect` carries fixed read-only profiles for Vercel and Contentful, denies reads that return secrets, and leaves GitHub to `gh` | accepted; refined by 0068 |
| [0058](0058-test-tiers-and-feature-suites-with-vitest.md) | Tests run by tier and by feature suite; Vitest is the preferred engine for unit and integration tests | accepted; amended by 0069 |
| [0059](0059-task-status-follows-the-work-and-stakeholder-guides.md) | A task's status follows the work on its own, every session is named after its task, and end-user docs are stakeholder guides | accepted; amended by 0063, 0070, 0073, 0076 |
| [0060](0060-retire-the-local-environment-band.md) | The local-environment band is retired — Desktop's Browser lists the running app | accepted |
| [0061](0061-wrap-up-starts-follow-ups-first-and-asks-about-time.md) | The wrap-up starts the follow-ups before the worktree goes, and asks about the time before the close-up | accepted; amended by 0082 |
| [0062](0062-one-session-per-task-compact-at-the-gate.md) | A task's phases stay in its session — after the approval gate, compact the conversation and switch to Sonnet there | accepted |
| [0063](0063-reference-files-and-status-moves-in-the-calling-skill.md) | A skill's case-only steps load from reference files beside its `SKILL.md`, and the skill that reaches a moment moves the task's status itself | accepted; amended by 0073 |
| [0064](0064-tracker-writes-through-the-projects-server.md) | Tracker writes go through the project's server as the developer, and a correction an edit would damage is the developer's | accepted; amended by 0073 |
| [0065](0065-always-loaded-text-says-each-rule-once.md) | The always-loaded text says each rule once, and a phase's procedure stays in its skill | accepted |
| [0066](0066-time-entries-describe-outcomes.md) | A time entry's description says what the day delivered, in business terms | accepted; amended by 0092 |
| [0067](0067-the-task-record-merges-with-its-pull-request.md) | A task's pull request carries its whole record, and a gap after the merge is a miss | accepted |
| [0068](0068-a-contentful-server-is-named-after-its-project.md) | A Contentful server is named after its project, so each project has its own sign-in and space | accepted |
| [0069](0069-a-run-is-as-small-as-the-question.md) | A test run is as small as its question, and each behavior is tested once at its cheapest layer | accepted |
| [0070](0070-the-agent-marks-its-pull-request-ready.md) | The agent marks its pull request ready once its own tests pass — locally first, on the preview for what only a shared service has, and CI green | accepted; amended by 0072 |
| [0071](0071-stop-the-local-environment-once-ready.md) | The agent stops the local environment once its pull request is ready — stop, which keeps containers and data; never down, kill, or remove | accepted |
| [0072](0072-agents-implement-and-review-humans-decide.md) | Agents implement and review; humans decide: `/review` in every lane, the agent tests and reviews on the preview, and requests the project's reviewers at ready, on GitHub and GitLab | accepted; amended by 0073, 0074 |
| [0073](0073-the-ticket-for-stakeholders-the-pull-request-for-the-developer.md) | The ticket is for business communication with stakeholders, the pull request for technical communication with the developer: outcome updates post on their own, delivered means live, and GitHub and GitLab issues are trackers too | accepted; amended by 0076 |
| [0074](0074-github-and-gitlab-alike.md) | GitHub and GitLab alike: the PR-state hook asks `glab` on GitLab, every skill's `gh` command has its `glab` one, and the skeleton's settings ship the `glab` rules | accepted |
| [0075](0075-the-gitlab-module.md) | The `gitlab` module: GitHub's harness in GitLab's terms — a `Default.md` merge request template, the tracker redirect in the default issue template, and the gates as one framework-owned CI include with the team's settings in `.gitlab-ci.yml` | accepted |
| [0076](0076-a-status-only-tracker-update-needs-no-prompt.md) | A tracker update that changes only the task's status needs no prompt: a hook approves that call and leaves every post, and any other edit, to the prompt | accepted |
| [0077](0077-the-container-is-the-boundary-for-make-run.md) | In Docker mode the container is the boundary: `make run` runs any command in the app's container without a prompt, a hook asks wherever it would run on the host, and the specification says what the container doesn't protect | accepted; amended by 0078, 0084, 0089 |
| [0078](0078-docker-and-make-run-without-a-prompt.md) | Docker and make commands run without a prompt: the docker module adds no ask rule, `make reset` included, and the developer's yes in chat is what protects local data | accepted |
| [0079](0079-no-file-count-in-the-lanes.md) | No file count in the lanes: the fast lane is a precise request in one layer however many files it touches, and "more than ~3 files" no longer sends a change to the full lane | accepted |
| [0080](0080-framework-feedback-from-adopting-projects.md) | Adopting projects report the framework's problems as issues with `/framework-feedback`: in the framework's terms, checked by a script for anything naming the project, posted only on the developer's yes; a problem in the framework is a lane of its own | accepted |
| [0081](0081-answers-in-the-main-checkout-close-up-there.md) | Answers in the main checkout close up there: `/adf:wrap-up` checks what the session made, delivers a tracker answer, and archives it, without switching, pulling, or deleting the branch checked out there | accepted |
| [0082](0082-follow-ups-found-along-the-way-are-filed-as-issues.md) | Follow-ups found along the way are filed as issues, not started as sessions: with the `github` or `gitlab` module, on the developer's yes at the close-up or as the improvement question's answer, with no chip at once | accepted |
| [0083](0083-task-worktrees-under-claude-worktrees.md) | A task's worktree sits under the main checkout's `.claude/worktrees/`, named after its branch: no worktree beside the main checkout and no `WORKTREE_PARENT`; one from an older release is reused where it is, and the parallel-agents guide names the three ways a tool in a nested worktree can reach the main checkout's files | accepted; amended by 0085 |
| [0084](0084-docker-mode-needs-nothing-on-the-host.md) | Docker mode needs nothing on the host but Docker, git, and make: a `tools` service in Compose's `tools` profile runs the checks, `make deps`, and `make run` with the stack up or not; dependencies live in volumes; a tool that needs the Docker socket gets its own service and an ask rule | accepted; amended 2026-11-16 and by 0089 |
| [0085](0085-the-session-moves-with-enterworktree.md) | A session moves to its task's worktree with `EnterWorktree`, in the desktop app too: the app refuses `change_directory` from its own worktree, and the approve-worktree-move hook answers `EnterWorktree` as well; the app keeps showing the session in the folder it started in | accepted |
| [0086](0086-one-prose-pass-for-text-people-read.md) | One prose pass for the text people read: `PROSE-PATTERNS.md`, a reference doc, lists the machine-written patterns to cut; `/stakeholder-update`, `/end-user-docs`, `/write-docs`, and `/framework-feedback`, which write for readers outside the team, run it on each draft, and the destination's own conventions win | accepted |
| [0087](0087-a-merge-wakes-an-idle-session.md) | A merge wakes an idle session: the pr-state hook also runs at Stop with `asyncRewake`, watches an open pull request every five minutes for `PR_WATCH_HOURS`, and exits 2 on a merge or close, which wakes the session to offer the wrap-up | accepted |
| [0088](0088-reads-of-git-config-releases-and-secrets-run.md) | Reading `git config`, a release, or the secrets' names runs without a prompt: the git guard hook asks before a `git config` change in place of an ask rule, and the `gh release` and `gh secret` rules name their write subcommands | accepted |
| [0089](0089-no-hook-decides-make-run.md) | No hook decides `make run`: the approve-container-run hook goes, `Bash(make *)` and the session's permission mode decide it in both modes, and native mode, where it runs on the host, is documented — a project that wants a prompt adds `Bash(make run *)` to `permissions.ask` | accepted |
| [0090](0090-each-machine-re-adds-the-marketplace-at-the-pin.md) | Each machine adds the marketplace again at the new pin: Claude Code keeps it at the ref it was first added with, so the upgrade's commands for each machine add it at the moved pin, restore the settings they rewrite, and show the installed versions | accepted |
| [0091](0091-the-install-adds-the-marketplace-at-the-newest-release.md) | The install adds the marketplace at the newest release: added without a ref, a machine's copy follows the default branch and the pin `/adf:adopt` writes doesn't move it, so the install finds the newest tag with `git ls-remote` and adds at it, and `/adf:adopt` checks the machine's ref against the pin | accepted |
| [0092](0092-time-entries-are-outcomes-with-a-midpoint.md) | A time entry is an outcome, with a midpoint: one entry per milestone, completed task, or value delivered — not per session or day — ending at its delivery, and a third number between the AI-assisted time and the manual estimate, set activity by activity | accepted |
| [0094](0094-the-time-unit-is-one-hour.md) | The time unit is one hour, in every project: `docs/TIME-TRACKING.md` has no Unit setting, and every number `/track-time` shows or writes is a whole number of hours, rounded up | accepted |

Changes that follow from these records are listed, with their upgrade impact, in
[`CHANGELOG.md`](../../CHANGELOG.md).
