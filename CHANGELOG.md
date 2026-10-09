# Changelog

All notable changes to the Agentic Development Framework. From v1.0.0, releases follow semantic versioning and are tagged `vX.Y.Z` ([decision 0017](docs/decisions/0017-semantic-versioning.md)); earlier releases are referenced by **commit SHA + date**.

Adopting projects: see [`docs/UPGRADING.md`](docs/UPGRADING.md) for the procedure to pull these changes into a project that already adopted an earlier skeleton version.

For each entry, **Upgrade impact** classifies the change against the [three-bucket file taxonomy](docs/UPGRADING.md#file-taxonomy-three-buckets):
- **Overwrite** — file is safe to copy verbatim from the new skeleton
- **Merge** — file has customization expectations; reapply your customizations on top
- **Additive** — new file, no existing project version to merge against

## Unreleased

**Upgrading from v1:** this is a major release. The framework's plugin is renamed, and `CLAUDE.md` and
`GEMINI.md` go away, and every project acts once. Run `/aplyca-adf:upgrade`, which carries out the
migrations below.
Then each developer installs `adf@aplyca` once, and every machine and CI job runs Claude Code v2.1.281
or later.

### `/orchestrate` names the `/deep-*` workflows without their folder

`/orchestrate`'s "Not a dynamic workflow" note placed the `/deep-*` workflows "in `.claude/workflows/`",
a folder a packaged project doesn't have: in the default install, the workflows are the `adf` plugin's.
The note already names each one (`/adf:deep-review`, `/adf:deep-spec-analysis`,
`/adf:deep-context-audit`, `/adf:deep-drift-sweep`), so it now drops the folder.

**Upgrade impact:**

- **Overwrite** `.claude/skills/orchestrate/SKILL.md` in a committed install: one line, no guidance
  changed.
- **A packaged project:** nothing to do.

### The cost model names agents, workflows, and skills, not the folders a committed install keeps them in

`docs/COST-MODEL.md` pointed at three folders a packaged project doesn't have: the agents' defaults were
"in `.claude/agents/`", the `/deep-*` workflows "in `.claude/workflows/`", and a loaded skill was
`.claude/skills/<name>/SKILL.md` in the prompt-caching table. In the default install, the agents are
the `adf` plugin's, the workflows too, and a skill's `SKILL.md` is the plugin's copy.

- **Per-agent recommendations** introduces its table as the current defaults by agent. The table already
  names each one: `@adf:code-reviewer` and the rest, which a committed project's copy reads as
  `@code-reviewer`.
- **Dynamic workflows** names the `/deep-*` workflows without their folder.
- **The prompt-caching table** lists a loaded skill as "its `SKILL.md`".

**Upgrade impact:**

- **Overwrite** `docs/COST-MODEL.md` in a committed install, a framework reference doc: three lines,
  none of them guidance that changed.
- **A packaged project:** nothing to do.

### `deep-drift-sweep` carries the steps its auditors follow

([0030](docs/decisions/0030-workflows-carry-skill-steps.md))

Each auditor was told to follow the method in `.claude/skills/spec-drift/SKILL.md`. A packaged project
has no such file, and a workflow can't reach the plugin's skills. So in the default install, the
auditors worked from the prompt's one-paragraph summary.

- **The plugin's `deep-drift-sweep` carries the skill's steps:** `const SPEC_DRIFT_STEPS` holds the
  `## Steps` section of `spec-drift`'s `SKILL.md`, and each auditor's prompt ends with it.
- **A committed project's copy points at its own skill,** so a team that edits its `/spec-drift` still
  gets the edit in its sweeps.
- **`scripts/build-plugins.sh` keeps the text equal to the skill's,** as it does for the agents'
  checklists (0029). A `const <SKILL>_STEPS` line carries the `## Steps` section of one of `adf`'s
  own skills.
- **The static check covers `.claude/skills/` paths too.** It fails when a plugin workflow names a
  `.claude/agents/` or `.claude/skills/` path that a packaged project lacks.
- **The spec model names the playbooks by skill.** Its "Related" list named
  `.claude/skills/write-spec/`, `write-plan/`, and `implement/`. It now names `/adf:write-spec`,
  `/adf:write-plan`, and `/adf:implement`, which a committed project's copy reads as `/write-spec`,
  `/write-plan`, and `/implement`.

**Upgrade impact:**

- **Overwrite** `.claude/workflows/deep-drift-sweep.js` in a committed install: each auditor's prompt
  ends with "Follow the steps in `.claude/skills/spec-drift/SKILL.md`."
- **Overwrite** `docs/SPEC-MODEL.md` in a committed install, a framework reference doc: one line in
  "Related".
- **A packaged project:** nothing to do. The plugin's `deep-drift-sweep` now gives its auditors the
  steps.

### `deep-review` carries the checklists its security and UX lenses follow

([0029](docs/decisions/0029-workflows-carry-agent-checklists.md))

The security and UX lenses sent their reviewers to `.claude/agents/security-reviewer/agent.md` and
`.claude/agents/ux-reviewer/agent.md`. A packaged project has neither file, and a workflow can't reach
the plugin's agents. So in the default install, these two lenses ran without their checklists.

- **The plugin's `deep-review` carries each checklist's text:** `const SECURITY_REVIEWER_CHECKLIST`
  and `const UX_REVIEWER_CHECKLIST` hold the agent's `## … checklist` section, and the lens's prompt
  ends with it.
- **A committed project's copy points at its own agents,** so a team that edits a checklist still
  gets the edit in its deep reviews.
- **`scripts/build-plugins.sh` keeps the text equal to the agent's,** as it does for the spec model.
  The round trip fails on a stale line.
- **A static check** fails when a plugin workflow names a `.claude/agents/` path that a packaged
  project lacks.

**Upgrade impact:**

- **Overwrite** `.claude/workflows/deep-review.js` in a committed install: each of the two lenses
  ends with "Follow the checklist in `.claude/agents/<name>/agent.md`."
- **A packaged project:** nothing to do. The plugin's `deep-review` now gives these lenses the
  checklists.

### The plugins are the machinery's source; a committed install is written from them

([0028](docs/decisions/0028-plugins-are-the-source.md))

The repository kept every skill, agent, workflow, hook script, and reference doc twice: in
`skeleton/`, and generated into the plugins. Now the plugins are the only copy:

- **`plugins/adf/` and `plugins/adf-dev/` are edited by hand,** in the form a packaged project loads:
  `/adf:triage`, `@adf:code-reviewer`, `${CLAUDE_PLUGIN_ROOT}/docs/…`, a Step 0 per skill and agent.
- **`skeleton/` is the project's layer:** `AGENTS.md`, the rules, the settings, `config.sh`, the docs
  templates, `specs/`. A module's `files/` holds only what a project commits, and its `module.json`
  lists the skills its plugin carries.
- **`scripts/build-committed.py` writes a committed install:** the machinery, with the given modules'
  skills, never overwriting a file. `/adopt`, `/upgrade`, and `docs/SETUP.md` run it.
- **A round trip keeps the forms together.** Every carried file must come back unchanged from its
  committed form; `build-committed.py --check` shows what a file should read.
- **`scripts/build-plugins.sh` generates only** the module commands in `bin/`, the spec model in
  `adf`'s workflows, and the plugins' versions.
- **`link-reference-docs.py`** links the reference docs in `plugins/adf/docs/` at a pin from v2.0.0
  on, and moves an older pin's `skeleton/docs/` links there.
- **The evals** test the committed copy the script writes: the hooks run, and the skills, agents, and
  workflows are checked as a committed project keeps them.

**Upgrade impact:**

- **A committed project gets the same files.** The one change is **Overwrite**
  `.claude/skills/dispatch/SKILL.md`: its checklist names the worktree script by its path.
- **A packaged project:** nothing.
- **Upgrading a committed project by hand** writes the new release's machinery with
  `build-committed.py` into an empty folder and copies it over (`docs/UPGRADING.md` § 4);
  `/adf:upgrade` does it.

### The worktree scripts are the plugin's commands: `adf-worktree-new`, `-ls`, `-rm`

([0027](docs/decisions/0027-worktree-scripts-as-plugin-commands.md))

The parallel-agents scripts are machinery no project edits, so a packaged project stops committing
them:

- **`adf` carries them as commands** in its `bin/`, which Claude Code puts on the Bash tool's PATH:
  `adf-worktree-new`, `adf-worktree-ls`, and `adf-worktree-rm`, with the scripts' arguments. Each one
  carries the scripts' helper and reads the project's `scripts/agent/worktree.conf`, which stays.
- **They act only where they should.** Without `scripts/agent/`, a command says the project doesn't
  use the module and stops. Where a committed install keeps its script, the command runs that one.
- **The module's settings show it's installed.** The hooks, `/dispatch`, `/dev-env`, `/connect`, and
  the install prompt check for `scripts/agent/worktree.conf`, not the script, in either install.
- **The plugin's copies name the commands.** A packaged session's worker creates its worktree with
  `adf-worktree-new <branch> --no-start`.
- **The build learns module commands:** a module's `module.json` lists them under `commands`, and
  `scripts/build-plugins.sh` generates them.
- **A developer's own terminal doesn't have them** in a packaged project: go through `/adf:dispatch`,
  or ask Claude to list or remove a worktree.

**Upgrade impact:**

- **Overwrite** `.claude/hooks/protect-hub.sh` and `.claude/hooks/session-context.sh`, and, in a
  committed install, the `dispatch` and `dev-env` skills.
- **Merge** `docs/PARALLEL-AGENTS.md` (one paragraph under § The scripts).
- **Migration**, a packaged project with the parallel-agents module (`/adf:upgrade` does it):
  1. Delete `worktree-new.sh`, `worktree-ls.sh`, `worktree-rm.sh`, and `_worktree-lib.sh` from
     `scripts/agent/` when none changed since the old release; keep `worktree.conf`. If the team
     edited one, the four stay together, and the commands run them.
  2. Name the commands where the project names the scripts: `AGENTS.md` § Quick reference and any
     other doc of the project's.
  3. Add the commands' sentence of `docs/SETUP.md`'s names note to `.claude/rules/claude-code.md`.
- A committed project keeps its scripts and needs nothing else.

### Instruction text checked against the current models

A prompt audit of the skeleton against Claude Opus 5.5 and Sonnet 5.5 fixed facts the repository had
outgrown and a few lines written for older models:

- **Stale facts:** `AGENTS.md` no longer lists Gemini among the tools that read it natively — Gemini
  CLI reads it through `.gemini/settings.json`. `security.md` names the vulnerability auditors
  `pip-audit` and `govulncheck`, not `pip audit` and `go vet`. `/spec-drift` recommends a full change
  request, the workflow's current name.
- **One home for naming conventions:** `code-quality.md` points at `AGENTS.md` § Coding conventions,
  which `/init-project` customizes, instead of repeating its table.
- **`/init-project`** fills `LOCAL_URL` in `.claude/hooks/config.sh`.
- **No framework decision numbers in skill text:** `/open-pr` and `/dispatch` state their rule
  without "decision 00NN", which in an adopting project could name the project's own record.
- **`@debugger`:** no stack-specific list of common causes and no "do not skip steps" line; it
  suggests fixes for the root cause, since it fixes nothing itself.
- **`/stakeholder-update`** ends its turn with the draft: on current models, long text written just
  before a tool call can reach the developer only as a summary.

**Upgrade impact:**

- **Merge** `AGENTS.md`: one comment line, on the tools that read it natively.
- **Overwrite** `.claude/rules/code-quality.md` and `.claude/rules/security.md`. A project that
  edited the naming table in `code-quality.md` moves those conventions to `AGENTS.md` § Coding
  conventions first.
- **Overwrite** `/spec-drift`, `/stakeholder-update`, `/open-pr`, `/init-project`, `@debugger`, and
  the parallel-agents module's `/dispatch`.

### The local environment's URL above the prompt — the first mod, in `adf-dev`

([0026](docs/decisions/0026-display-only-mods.md))

With `adf-dev` turned on, a line above the prompt shows the local environment's URL — what the
developer opens for the local check before the pull request — and whether it answers (● or ○),
refreshed every 15 seconds and after each turn. `/local-url` says the same where nothing draws.

- **Where the URL comes from:** `LOCAL_URL`, a new setting in `.claude/hooks/config.sh`, or, with the
  parallel-agents module, the worktree's `READY_URL` with its own `APP_PORT`. `/adopt` and
  `/dev-env set up` fill `LOCAL_URL`.
- **Display-only:** the mod reads those files — only `APP_PORT` from the env file — and requests the
  URL; it never acts on a tool call or a prompt. A static check holds every framework mod to that and
  to having tests, which `run-evals.sh` runs with `claude plugin test` where the CLI is installed.
- **Requirements:** Claude Code v2.1.287 or later in a terminal, or the desktop app from v2.1.286. It
  works in a committed install too, with `adf-dev` turned on.
- **Framework-internal:** the hook-wiring check now reads a `hooks.json` that holds `modules`. It
  used to crash quietly on one and pass.

**Upgrade impact:**

- **Merge** `.claude/hooks/config.sh`: the new `LOCAL_URL` setting, empty by default.
- **Merge** `.claude/rules/claude-code.md`: one bullet on where the URL lives.
- **Overwrite** `/dev-env` (the docker module), which now fills `LOCAL_URL`.
- **Additive** to use it: `"adf-dev@aplyca": true` in `enabledPlugins`.

### No `GEMINI.md`: Antigravity reads `AGENTS.md`, and Gemini CLI is pointed at it

([0025](docs/decisions/0025-no-gemini-md.md))

Antigravity reads `AGENTS.md` natively, and loads a `GEMINI.md` beside it. The skeleton's `GEMINI.md`
imported `AGENTS.md`, restated its workflow, and pointed at Antigravity's legacy `.agent/` paths, so
it only repeated `AGENTS.md`. The skeleton drops it:

- **`.gemini/settings.json`** points Gemini CLI at `AGENTS.md` (`context.fileName`).
- **`.agents/skills`** still links Antigravity to Claude Code's skills.
- **`/adopt` and `/upgrade`** move a customized `GEMINI.md`: shared notes into `AGENTS.md`,
  Antigravity-only ones into `.agents/rules/antigravity.md` (`trigger: always_on`).
- **`context-audit` and `deep-context-audit`** report a `GEMINI.md` as a finding.

**Upgrade impact:**

- **Overwrite** `context-audit` and `deep-context-audit`.
- **Additive** `.gemini/settings.json`, for a team on Gemini CLI.
- **Merge** `AGENTS.md`'s header comment, and `MEMORY-STRATEGY.md` and `MCP-INTEGRATION.md` in a
  committed install.
- **Migration:** delete `GEMINI.md` when it's unchanged; otherwise move its content as above, then
  delete it.

### No `CLAUDE.md`: Claude Code reads `AGENTS.md`, and its own layer is a rule

([0024](docs/decisions/0024-agents-md-only.md))

Claude Code reads `AGENTS.md` natively, and reads a `CLAUDE.md` *instead* of it when one exists. So
the skeleton has no `CLAUDE.md` any more:

- **The Claude Code layer** — skills, agents, workflows, guardrails, lanes, cost, memory — is
  `.claude/rules/claude-code.md`. It's a rule without `paths:`, so it loads in every session, and
  other tools never read it.
- **The stamp is `AGENTS.md`'s first line.** The hooks, `/upgrade`, `/dev-env`, `/adopt`, and the
  install prompt read it there, and still read `CLAUDE.md`'s for a project not yet moved.
- **Step 0 of every plugin skill and agent** checks the project's instructions for the packaged note,
  not a named file.
- **The session-context hook warns** when a `CLAUDE.md` or `CLAUDE.local.md` in the project or a folder
  above it would replace `AGENTS.md`. It stays quiet when a `CLAUDE.md` still imports `AGENTS.md`, or
  the developer's settings load both.
- **`link-reference-docs.py`** also rewrites the committed rules, now that one of them names the
  reference docs.
- **Nested `AGENTS.md` files** — one per module in a monorepo — now reach Claude Code too.
- **This repository's own instructions** are `AGENTS.md`.

**Upgrade impact:**

- **Overwrite** `.claude/hooks/_lib.sh` and `.claude/hooks/session-context.sh`, and the skills and
  agents that named `CLAUDE.md`: `init-project`, `context-audit`, `evaluate`, `code-reviewer`, and
  `deep-context-audit`.
- **Additive** `.claude/rules/claude-code.md`.
- **Merge:** `AGENTS.md` (the stamp on its first line, and its header comment), `DEV-SETUP.md` (one
  paragraph), `README.md`, `MEMORY-STRATEGY.md`, `COST-MODEL.md`, and `MCP-INTEGRATION.md` in a
  committed install.
- **Migration**, every project:
  1. Move the stamp from `CLAUDE.md`'s first line to `AGENTS.md`'s.
  2. Take the new `.claude/rules/claude-code.md`, and reapply the customizations from the project's
     `CLAUDE.md`. Its sections match, and the packaged names note goes with them.
  3. Move anything else the team added to `CLAUDE.md`: project facts to `AGENTS.md`, Claude-specific
     instructions to the rule.
  4. Delete `CLAUDE.md`.
  5. Each developer removes a `CLAUDE.md` above the repository or a `CLAUDE.local.md` in it, or sets
     **Project instructions** to `claude-md-and-agents-md` in `/config`.


### `adf-connect`: connect a tracker or a service with `/connect`

([0023](docs/decisions/0023-plugins-by-concern.md))

The third plugin, for trackers and services. `/adf-connect:connect <service>` connects the project to
Supabase, Vercel, Contentful, GitLab, Linear, or Jira through the service's official MCP server:

- **It writes the project's own configuration:** the `.mcp.json` entry and `enabledMcpjsonServers`.
- **Safe defaults:** read-only where the server allows it, a development project rather than
  production, and OAuth or a `${VARIABLE}` instead of a committed credential.
- **Only reads are pre-approved,** taken from the server's real tool names, so every write prompts.
- **It writes it down** in `DEV-SETUP.md`, and in `TRACKER-INTEGRATION.md` for a tracker.
- **It verifies** that the server connects, that its reads run without a prompt, and that a write
  prompts.

The servers stay in the project, not the plugin. A spike found that a plugin's server whose URL a
project leaves unset reports an error in every session, instead of staying off (decision 0023).
ClickUp keeps its module, and GitHub keeps the `gh` CLI. `/adf:adopt` and `/adf:upgrade` offer the
plugin when a project has such a tracker or services.

**Upgrade impact:**

- **Additive:** turn on `"adf-connect@aplyca": true` in `enabledPlugins` to use it, committed or
  packaged. It needs no read rule.

### Everything in English

The agentic development guide the framework implements, `docs/AgenticDevelopmentGuide.md`, is now
in English; it was the repository's one Spanish file. CONTRIBUTING gains the ground rule **Write
everything in English**, and a static check fails on Spanish text.

**Upgrade impact:** none — framework-internal (`docs/`, `evals/`, `CONTRIBUTING.md`).

### The framework's plugin is `adf`

([0023](docs/decisions/0023-plugins-by-concern.md))

`aplyca-adf` is now **`adf`**, so the commands typed most are shorter: `/adf:triage`,
`@adf:code-reviewer`. It's the process plugin beside `adf-dev`. The marketplace's `renames` map
(`aplyca-framework` → `aplyca-adf` → `adf`) lets Claude Code load the plugin under its new name and
rewrite `enabledPlugins` in the user, project, and local settings. `/upgrade` does the rest.

- **The plugin** moves to `plugins/adf/`. Its skills, agents, workflows, and hooks name each other
  `/adf:<name>` and `@adf:<name>`.
- **`/adf:upgrade`** recognizes both old names, `aplyca-adf@aplyca` and `aplyca-framework@aplyca`,
  and renames them everywhere the project names them.
- **`/adf:adopt`, the install prompt, `ADOPT.md`, and the docs** install `adf@aplyca`. The install
  prompt and `ADOPT.md` stop for a project that still enables `aplyca-adf@aplyca`, and send it to
  `/aplyca-adf:upgrade`.

**Upgrade impact:**

- **Overwrite** `.claude/hooks/_lib.sh`, `.claude/hooks/session-context.sh`, and
  `.claude/workflows/deep-spec-analysis.js` (comments only).
- **Merge** `docs/getting-started/DEV-SETUP.md`: one sentence names the plugin.
- **Migration**, every project, committed or packaged — in `.claude/settings.json`:
  1. `"aplyca-adf@aplyca": true` becomes `"adf@aplyca": true` in `enabledPlugins`.
  2. Packaged: `Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)` becomes
     `Read(~/.claude/plugins/cache/aplyca/adf/**)` in `permissions.allow`.
  3. Every `/aplyca-adf:` and `@aplyca-adf:` the project's files name becomes `/adf:` and `@adf:` —
     `CLAUDE.md`'s names note, `DEV-SETUP.md`'s key commands, and any doc of the team's (search for
     `aplyca-adf:`).
  4. After the merge, each developer runs `/plugin install adf@aplyca` once, then
     `claude plugin uninstall aplyca-adf@aplyca --scope project`.

### Plugins by concern, and the `docker` module in `adf-dev`

([0023](docs/decisions/0023-plugins-by-concern.md), amending 0009, 0016, 0017, and 0020)

Integrations and specialties now have a home, sorted by one test: what a project edits is committed
in a module, and machinery no project edits is packaged — in one plugin per concern. `aplyca-adf`
carries the process, the new `adf-dev` carries development, and `adf-connect` (trackers and services)
is planned. The decision record maps the requested additions — GitLab, Supabase, Vercel, Contentful,
Ibexa, performance, frontend — onto that test, and plans the core's rename to `adf` for v2.0.0.

- **A module names the plugin that carries its skills,** in `modules/<module>/module.json`:
  `parallel-agents` → `aplyca-adf`, `docker` → `adf-dev`. A packaged project with a development
  module turns `adf-dev` on beside `aplyca-adf`; a committed one copies the module's skills as before.
  Each skill acts only where the stamp names its module.
- **The new `docker` module.** `/dev-env` (packaged: `/adf-dev:dev-env`) works on the local Docker
  Compose stack:
  - sets it up from verified facts, written to `DEV-SETUP.md` and `AGENTS.md` § Quick reference;
  - gives each worktree its own stack with `parallel-agents` (`worktree.conf`);
  - diagnoses it in `/debug`'s order;
  - resets it smallest step first, never beyond this project.

  Its permission rules, merged by `modules/docker/install.sh`, let read-only docker commands run
  and make every command that deletes containers, volumes, or images ask.
- **`/adopt` and `/upgrade`** recommend the module when the local stack runs on Compose, and in a
  packaged install turn on `adf-dev@aplyca` with `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)`.
- **Framework-internal:**
  - `scripts/build-aplyca-adf.sh` is now `scripts/build-plugins.sh`. It builds every plugin's
    generated paths and carries aplyca-adf's version into the others' manifests.
  - The static checks hold every plugin's version to the release, names unique across plugins, each
    module's skills in the plugin its `module.json` names, and `Bash` allow rules in a module to
    read-only commands.
  - CONTRIBUTING no longer says to bump the plugin's version on every change (0017).

**Upgrade impact:**

- **Additive** for a project that doesn't choose the module — `/aplyca-adf:upgrade` offers it.
- When chosen:
  - **Merge** `.claude/settings.json` through `modules/docker/install.sh`.
  - **Additive** `.claude/skills/dev-env/SKILL.md` in a committed install.
  - A packaged install commits no skill and adds two lines to `.claude/settings.json`:
    `"adf-dev@aplyca": true` and the read rule.
  - `/dev-env set up` then fills `DEV-SETUP.md`, the Quick reference, and `deployment.md`'s `paths:`
    (**Merge**).
- Nothing to migrate: `/dispatch` is still `/aplyca-adf:dispatch`.

### A dispatched session's title is the task's, without the branch

([0021](docs/decisions/0021-sibling-worktree-and-chip.md), amended)

`/dispatch` titles the task chip with the task's title alone — `Show the chosen topics after
signup`, not `feat/newsletter-signup-topics · Show the chosen topics after signup`. Once the new
session moves into its worktree, the desktop app shows that folder as the session's, and the folder
is named after the branch, so the title doesn't need to repeat it.

**Upgrade impact:**

- **Overwrite** `.claude/skills/dispatch/SKILL.md` (module; a packaged project gets it with its pin).
- **Merge** `docs/PARALLEL-AGENTS.md`: one sentence in § How a task gets its worktree.
- Nothing to migrate. Sessions already started keep their titles.

## v1.4.0 — 2026-10-06 — The developer approves a change locally, and that opens its draft pull request

A minor release with two changes:

- **Every project gets the local check**
  ([#40](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/40), decision 0022). When a change
  alters something a person can see or use, the developer tests it by hand on the local environment
  and approves it. That approval opens the draft pull request: the agent pushes and runs `/open-pr`
  without another prompt, and `guard-git.sh` refuses a pull request that isn't a draft. Marking it
  ready, merging, and every other outward action still ask.
- **Teams with the `parallel-agents` module** get a lighter hand-off
  ([#39](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/39), decision 0021). `/dispatch`
  only names the task and offers a chip. The new session creates the task's worktree beside the main
  checkout, on a new branch, and moves into it.

**Upgrading from v1.3.x:** `/aplyca-adf:upgrade` moves the pin to `v1.4.0`. It:
- overwrites the git-workflow rule. A committed project also overwrites `/open-pr`, `/implement`,
  `/commit`, `/spec-workflow`, `guard-git.sh`, `session-context.sh`, `protect-hub.sh`, the hooks
  README, and, with the module, `/dispatch`; a packaged project gets them with the pin;
- merges `AGENTS.md`, `CLAUDE.md`, `specs/README.md`, and `README.md`, and, with the module,
  `docs/PARALLEL-AGENTS.md`.

Removing the four `git push` and `gh pr create` rules from `permissions.ask` in
`.claude/settings.json` is optional. While they stay, the agent still asks before that push and that
draft.

### `/dispatch` hands every task to a new session that creates its worktree beside the main checkout

([0021](docs/decisions/0021-sibling-worktree-and-chip.md), amending [0020](docs/decisions/0020-every-task-through-dispatch.md))

v1.3.0 gave each project one of two routes. The first real dispatches showed that a task chip opens
its session in a folder and, in our probes, created no worktree even with the card's worktree option.
A team also asked for every worktree beside the main checkout, a dispatcher that only hands the task
over, and a session that creates its own worktree and branch. So there's one route now:

- **The dispatcher names the task and hands it over** — a task chip for the main checkout in the
  desktop app, titled with the branch, or `claude "<prompt>"` in a terminal. Its three-line prompt
  holds the task, the branch, and the first step. The dispatcher runs nothing.
- **The new session's first step is the worktree.** `worktree-new.sh <type>/<slug> --no-start` creates
  it beside the main checkout, named after the branch, on a new branch from the base branch, with the
  env file and, where the project uses them, a port. Then the session moves in — `change_directory`
  in the desktop app, which asks the developer to approve the folder once, `EnterWorktree` in a
  terminal — and confirms with `pwd` before triage.
- **The session-context hook** tells a session in the main checkout that, when its prompt hands it
  one task and its branch, it is that task's worker, and what its first step is. Hooks don't run again
  after the move. The protect-hub hook's message says the same.
- **The route choice by project, and the per-task override, go.**

The probes (desktop app 2.19675.0, Claude Code 2.1.286) are in the decision record.

**Upgrade impact:**

- **Overwrite** `.claude/skills/dispatch/SKILL.md` (module; a packaged project gets it with its pin)
  and, in a committed project, `.claude/hooks/session-context.sh`, `.claude/hooks/protect-hub.sh`, and
  `.claude/hooks/README.md`.
- **Merge** `docs/PARALLEL-AGENTS.md`: its roles and routes sections changed. Your § Shared services
  stays.
- Nothing to migrate. Worktrees made before stay workers. A project whose worktrees took Claude Code's
  route now gets worktrees beside the main checkout. Check `WORKTREE_PARENT` in `worktree.conf` if
  the main checkout's folder isn't one of its own.

### The developer approves a change on the local environment, and the approval opens its draft pull request

([0022](docs/decisions/0022-local-check-before-the-pull-request.md), amending [0005](docs/decisions/0005-outward-actions-and-draft-prs.md) and [0006](docs/decisions/0006-guardrails-as-configuration.md))

A new step in every lane, between the review and the pull request: **the local check**.

- **When it applies:** a change alters something a person can see or use.
- **What the agent does:** starts the change on the local environment and gives the developer the URL
  and what to try (the acceptance criteria, or the fast lane's "done when").
- **What the developer does:** tests it by hand and approves it.
- **The approval opens the draft pull request.** The agent pushes and runs `/open-pr` without waiting
  to be asked, and the pull request records what the developer tried under "Local check". Docs-only
  and CI-only work, and refactors, have nothing to try: their draft opens once the full gate and
  `/review` pass.
- **No prompt before that push and that draft.** `git push` and `gh pr create` leave
  `permissions.ask`, and `/open-pr` can start on its own. In their place, `guard-git.sh` refuses a
  `gh pr create` without `--draft`. Marking ready, merging, comments, issue and tracker writes, and
  releases still ask.
- **The preview QC before ready doesn't change.**

`/open-pr` stops without the approval and offers the check. `/implement` ends with it.

**Upgrade impact:**

- **Overwrite** `.claude/rules/git-workflow.md`, and in a committed project
  `.claude/skills/open-pr/SKILL.md`, `implement`, `commit`, and `spec-workflow`, and
  `.claude/hooks/guard-git.sh`. A packaged project gets the skills and the hook with its next pin; it
  commits the rule either way.
- **Merge** `.claude/settings.json`: remove `Bash(git push)`, `Bash(git push *)`,
  `Bash(gh pr create)`, and `Bash(gh pr create *)` from `permissions.ask`. A team that wants a click
  before each push keeps them; the rest of the change works either way.
- **Merge** `CLAUDE.md`: two rows of § Guardrails and the `/open-pr` sentence below it.
- **Merge** `AGENTS.md`:
  - the ground rule on outward actions;
  - the lanes sentence in § 2;
  - the new step 7 in § 3;
  - the new "Local check before the pull request" bullet and the "after the local check" in
    § Delivery rules.
- **Merge** `specs/README.md` (the lanes paragraph, the flow line, and the new Local check row) and
  `README.md` (step 5).
- **A project that can't run locally:** say so in `AGENTS.md` § Delivery rules, and check on the
  preview instead.
- **Several tasks under check at once** need the `parallel-agents` module's per-worktree ports, so
  their environments don't collide.

## v1.3.0 — 2026-10-06 — Every task goes through `/dispatch`

A minor release for teams with the `parallel-agents` module
([#37](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/37), decision 0020). The session in
the main checkout now takes every task and hands it to a new session in a worktree of its own, by the
route the project's `worktree.conf` gives. The plugin now carries `/dispatch`. Nothing changes for a
project without the module.

**Upgrading from v1.2.x:** `/aplyca-adf:upgrade` moves the pin to `v1.3.0`. In a project with the
module it also:
- overwrites `/dispatch` and merges `docs/PARALLEL-AGENTS.md`. A committed project also overwrites the
  hooks and `/spec-workflow` it commits;
- in a packaged project, deletes the committed `.claude/skills/dispatch/` where it's unchanged since the
  baseline. Type `/aplyca-adf:dispatch` from then on.

A project whose worktrees need a port or setup now takes every task through the scripts. Ask for a
chip for a task that won't run the app.

### Every task goes through `/dispatch` in the main checkout

([0020](docs/decisions/0020-every-task-through-dispatch.md), amending [0008](docs/decisions/0008-dispatcher-and-worker-worktrees.md) and [0015](docs/decisions/0015-tool-worktrees-are-workers.md))

With the `parallel-agents` module, the session in the main checkout now takes every task, not only the
ones whose worktree needs the project's setup. It hands each task to a new session in a worktree of
its own, and that session runs the whole process. Before, developers chose each task's route and
started the common route's session by hand. Now the project's settings in `worktree.conf` pick the
route:

- **When the project's worktrees need nothing from the scripts,** `/dispatch` takes Claude Code's
  worktree. In the desktop app it offers a task chip carrying the worker prompt, which the developer
  starts with one click. In a terminal it gives a `claude --worktree <slug> "<prompt>"` command.
- **When they need a port, setup or start commands, or tasks start from another branch,** it takes
  the scripts' worktree, created as before with `worktree-new.sh --no-start`, and gives its path and
  the prompt to paste into a session opened on it.
- **Never a chip for the scripts' worktree.** A chip always creates a worktree of its own, without the
  env file, port, or setup, even when it's given another folder. `/dispatch` and
  `PARALLEL-AGENTS.md` now say so.
- **The developer can pick the other route for one task,** for example `/dispatch <task> chip` for a
  copy change in a project whose worktrees run a server. The dispatcher never picks it on its own:
  whether a task runs the app is its triage's question.

The session-context hook tells the dispatcher to give every task to `/dispatch` and names its
project's route. `protect-hub.sh`'s message points at `/dispatch`. A session started with the worktree
option, without `/dispatch`, is still a worker.

**Upgrade impact:**

- **Overwrite** `.claude/skills/dispatch/SKILL.md` (module) and, in a committed project,
  `.claude/hooks/session-context.sh`, `.claude/hooks/protect-hub.sh`, `.claude/hooks/README.md`, and
  `.claude/skills/spec-workflow/SKILL.md`. A packaged project gets the hooks and `/spec-workflow` with
  its next pin.
- **Merge** `docs/PARALLEL-AGENTS.md`: its roles and routes sections changed, and your § Shared
  services stays as it is.
- Nothing to migrate. A project whose worktrees need the scripts now takes every task through them;
  ask for a chip when a task won't run the app.

### The plugin carries `/dispatch`

([0020](docs/decisions/0020-every-task-through-dispatch.md), amending [0016](docs/decisions/0016-packaged-install.md))

`/dispatch` was the one framework skill a packaged project still committed, because it ships in a
module, and decision 0016 keeps modules committed. It's generic machinery like the 20 skills the
plugin already carries, so the plugin now carries it too, as `/aplyca-adf:dispatch`.

- **`scripts/build-aplyca-adf.sh`** copies every module's skills into the plugin. The module stays
  their one source, so a committed install doesn't change.
- **The skill stops in a project without the `parallel-agents` module,** so the plugin can carry it
  for every project.
- **`/aplyca-adf:adopt`** leaves the skill out of a packaged project. **`/aplyca-adf:upgrade`**
  deletes a packaged project's committed copy when it's unchanged since the baseline.
- The plugin's hooks and skills name it `/aplyca-adf:dispatch`, like every other skill they name.

The module's scripts, `worktree.conf`, `.worktreeinclude`, and `PARALLEL-AGENTS.md` stay committed:
they're the project's configuration, a doc it fills in, and scripts developers run from their own
terminal.

**Upgrade impact:**

- **Packaged projects with the `parallel-agents` module:** delete `.claude/skills/dispatch/`, and type
  `/aplyca-adf:dispatch`. `/aplyca-adf:upgrade` deletes it when it's unchanged since your baseline.
  One your team edited stays under a name of its own, or goes upstream.
- **Committed projects:** nothing changes.

## v1.2.1 — 2026-10-05 — Drift the prompt audit found

A patch release: fixes to the framework's instruction files, with nothing new to adopt
([#35](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/35)). Several files had drifted
from later decisions: `/orchestrate` and the cost model gave the wrong model for some agents, and the
rules disagreed with each other. Two other habits cost tokens: every agent re-read files it already
had, and two workflows' prompts kept their agents from sharing a cache.

**Upgrading from v1.2.0:** `/aplyca-adf:upgrade` moves the pin to `v1.2.1`. A packaged project gets the
agents, `/orchestrate`, the workflows, and the cost model from it, and updates the three rule files it
commits. A committed project also overwrites its own copies of the rest. The entry below lists each
file.

### Drift the prompt audit found

A prompt audit of the framework's instruction files found nothing written for older models: no
pressure language, thinking scaffolds, word caps, or retired model names, and every command, path,
and section the files name resolves. It did find text that later decisions had left behind, and two
habits that cost tokens:

- **`/orchestrate` gave the wrong models.** It named Haiku for the reviewers and `@architect`, and its
  example plan priced a review at "~3 Haiku-tier invocations". The reviewers have run on Sonnet since
  the model-choice decision, and `@architect` and `@spec-analyzer` on Opus. The skill now states each
  agent's real model, and takes its cost estimate from the cost model.
- **`COST-MODEL.md`** recommended Haiku for "most reviews", against its own per-agent table.
- **Every agent re-read files it already had.** Each one started by reading `AGENTS.md` and
  `CLAUDE.md`, which Claude Code already loads into a subagent's context. The agents now read only
  the docs their task needs.
- **Two workflows reorder their prompts.** `/deep-spec-analysis` and `/deep-review` now put the
  context all their agents share ahead of each agent's own task, so the agents of one run can reuse
  a cached prompt prefix.
- **Two rule fixes.** `code-quality.md` said a commit message explains "why, not what", against
  `git-workflow.md` and `/commit`. It now says the subject says what changed. `deployment.md`'s caps
  "NEVER" became a plain rule with its reason.
- **Do failing tests block a merge?** `deployment.md` said "Tests must pass before merge", while
  `git-workflow.md` called red checks "information". Both now say the same thing: tests pass before
  merge, and a failure the reviewer accepts is explained in the pull request. The review stays the
  gate.

**Upgrade impact:**

- **Overwrite** the eight agents, `.claude/skills/orchestrate/SKILL.md`,
  `.claude/workflows/deep-spec-analysis.js` and `deep-review.js`, `.claude/rules/code-quality.md`, and
  `.claude/rules/git-workflow.md`.
  A committed project also overwrites `docs/COST-MODEL.md`.
- **Merge** the two changed lines in `.claude/rules/deployment.md`.
- **A packaged project** gets the agents, the skill, the workflows, and the cost model with its next
  pin. It overwrites `code-quality.md` and `git-workflow.md` and merges `deployment.md`, since a project
  commits its rules either way.

## v1.2.0 — 2026-10-05 — The reference docs come from the plugin

A minor release. A packaged project no longer commits the framework's four reference docs: it reads
them from the pinned plugin
([#33](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/33), decision 0019). Nothing changes
for a committed project but two overwritten files.

**Upgrading from v1.1.x:** `/aplyca-adf:upgrade` moves the pin to `v1.2.0`. In a packaged project it
also:
- deletes the four docs from `docs/` where they're unchanged;
- points their links at the release;
- adds the plugin's read rule to the settings;
- adds one sentence to the names note in `CLAUDE.md`.

A baseline older than v1.0.0 takes v1.0.0's order to upgrade in first.

### A packaged project reads the framework's reference docs from the plugin

([0019](docs/decisions/0019-reference-docs-in-the-plugin.md), amending [0016](docs/decisions/0016-packaged-install.md))

The four reference docs (`COST-MODEL.md`, `MCP-INTEGRATION.md`, `MEMORY-STRATEGY.md`, `SPEC-MODEL.md`)
are generic, never edited by a project, and already overwritten verbatim by every upgrade. The
`aplyca-adf` plugin now carries them in `docs/`, and a packaged project commits none of them, about 950
fewer lines.

- **Skills and agents** name the plugin's copy, `${CLAUDE_PLUGIN_ROOT}/docs/<doc>.md`, and say it's
  outside the project. Without that line, an agent on Haiku read `docs/SPEC-MODEL.md` in the project
  instead.
- **`deep-spec-analysis`** carries the spec model's text in its plugin copy, because Claude Code
  doesn't fill in `${CLAUDE_PLUGIN_ROOT}` in a workflow script.
- **The read rule.** Claude Code asks before reading any file outside the project, the plugin's own
  folder included. So a packaged project commits
  `Read(~/.claude/plugins/cache/aplyca/aplyca-adf/**)` in `permissions.allow`.
- **The session context.** The plugin's SessionStart hook tells a packaged session where the docs
  are.
- **Links on GitHub.** The project's files link the docs at the pinned release on GitHub. The new
  `scripts/link-reference-docs.py` rewrites the links: `/aplyca-adf:adopt` runs it, and
  `/aplyca-adf:upgrade` runs it to move them with each pin, and back on a switch to the committed
  install.

A new session-eval suite, `plugin-docs`, checks the reads in real sessions. The committed install is
unchanged. `TRACKER-INTEGRATION.md` and `PARALLEL-AGENTS.md` stay in the project, because they hold
its settings.

**Upgrade impact:**

- **Committed projects:** overwrite `.claude/hooks/session-context.sh` and
  `.claude/workflows/deep-spec-analysis.js`. Both behave as before in a committed project: the
  workflow's prompts name `docs/SPEC-MODEL.md` through one constant.
- **Packaged projects:** `/aplyca-adf:upgrade` does these steps after moving the pin.
  1. **Delete the four docs** from `docs/` where each is unchanged since your baseline. One your team
     edited stays under a name of its own, or the team switches to the committed install.
  2. **Rewrite the links:**
     `python3 <framework>/scripts/link-reference-docs.py . --packaged v<X.Y.Z>`.
  3. **Add the read rule** to `permissions.allow` in `.claude/settings.json`.
  4. **Add the names note's last sentence** to `CLAUDE.md`, from `docs/SETUP.md` § Packaged install.

## v1.1.0 — 2026-10-04 — The packaged install by default, checked in real sessions

A minor release: a new default for new projects, and evals for the packaged install's paths. Nothing
asks anything of an adopted team. Everything since v1.0.6: the plugin's hooks checked in real sessions
([#29](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/29)), evals for adopting on the
packaged install and switching to it, and the `/upgrade` stamp fix they found
([#30](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/30)), the packaged install as the
default ([#31](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/31), decision 0018), and
`/adopt` taking the framework at the release it pins.

**Upgrading from v1.0.x:** `/aplyca-adf:upgrade` moves the pin to `v1.1.0`; nothing else changes in
the project. For a committed project whose team works in Claude Code only, it recommends the switch to
the packaged install. A baseline older than v1.0.0 takes v1.0.0's order to upgrade in first.

### `/adopt` takes the framework at the release it pins

`/aplyca-adf:adopt` copied the skeleton from wherever the framework source was — a clone of the
default branch, or a checkout — while pinning the plugin to the newest release tag, so a project's
committed files could be newer than its pinned plugin. The packaged eval found it; the two were
identical then. It now takes the framework at the newest release tag (a shallow clone of the tag, or
a worktree of a local checkout) and stamps that tag's commit. `docs/SETUP.md`'s manual copy says the
same.
**Upgrade impact:** framework-internal — adoptions only.

### The packaged install is the default

([0018](docs/decisions/0018-packaged-by-default.md), amending [0016](docs/decisions/0016-packaged-install.md))

`/aplyca-adf:adopt` recommends the packaged install by default, and the committed install when the
team also uses another AI tool for the framework's skills or needs Claude Code's cloud sessions. It
still asks. The packaged paths have run end to end in real sessions: the plugin's hooks, adopting on
it, and switching to it. `/aplyca-adf:upgrade` recommends the switch to a committed project whose team
works in Claude Code only. The committed install stays fully supported, and the manual setup in
`docs/SETUP.md` is the committed install.
**Upgrade impact:** none — existing projects keep their install until they choose to switch.

### `/upgrade` stamps the release's commit; the packaged smoke test names the plugin

The new upgrade eval found `/aplyca-adf:upgrade` stamping `v1.0.6 · 130753a` — an annotated tag's own
ID, from `git rev-parse v1.0.6` — instead of the release's commit, `ab56cb6`, in the stamp, the branch,
and the commit message. `/upgrade` and `/adopt` now name `git rev-parse --short '<tag>^{commit}'`.
The packaged smoke test in `docs/SETUP.md` sets `CLAUDE_PLUGIN_ROOT`, which the plugin's hooks need
since v1.0.2.
**Upgrade impact:** framework-internal; a project whose stamp names a tag's ID can correct it to the
commit by hand — `/aplyca-adf:upgrade` diffs from either.

### The packaged install's two ways in, checked in real sessions

The adopt suite gains a `packaged` case — `/aplyca-adf:adopt` on a new project, choosing the packaged
install — and a new `upgrade` suite's `switch-to-packaged` case has `/aplyca-adf:upgrade` move a
committed adoption at v1.0.0 to the newest release and switch it to the packaged install. Both check
the result with `evals/dynamic/check-packaged.sh`, which also checks that the stamp names the release's
commit. The runner passes this checkout's path to a suite's `project.sh`. Report:
`evals/dynamic/reports/2026-10-04-packaged-paths.md`.
**Upgrade impact:** framework-internal.

### The plugin's hooks, checked in real sessions

A `plugin-hooks` suite for the session evals: each of the `aplyca-adf` plugin's hooks, driven in a
real Claude Code session on a project with the packaged install, and the plugin's stand-down on a committed
one — seven sessions on Haiku, checked automatically. The runner gains a per-case `setup.sh`, passes
each run's output and case to `inspect.sh`, and counts the ✓ and ✘ it marks.
**Upgrade impact:** framework-internal.

## v1.0.6 — 2026-10-04 — Closing the Claude Directory work, for now

A patch release, and the last of the Directory fixes for now. Its validator still reports one blocking
finding, `COMMAND_PATH_COMPUTED` at `.`, with no file or line. Scans of this branch showed the
reminder change below removed the `.` the validator listed after `triage-first.sh`; the other changes
showed no effect. The blocking finding's source, which v1.0.2 to v1.0.6 looked for, is still unknown.
The listing is paused. Installing from GitHub, per project, is unaffected.

#### Changed
- **`triage-first.sh`'s reminder** quotes the one-line triage with single quotes and ends it without
  a period after `>`. The text is the same.
- **`session-context.sh`**'s detached-HEAD line no longer ends `<slug>.`
- **`/aplyca-adf:adopt` and `/aplyca-adf:upgrade`** no longer name `${CLAUDE_PLUGIN_ROOT}/../..`, a
  path outside the plugin — from `plugins/aplyca-adf`, the repository root, which the validator reports
  as `.`. A development install finds the framework through the marketplace's `installLocation`,
  which is the local checkout when the marketplace was added from one.
- **The static check** refuses a `>` before a period in the plugin's hooks, and any path that climbs
  out of the plugin.

#### Upgrade impact
- **Overwrite:** `session-context.sh`, `triage-first.sh`.

## v1.0.5 — 2026-10-04 — What the Directory's validator was pointing at

A patch release. The validator lists the files it couldn't check in a fixed order — the hooks in the
order `hooks.json` wires them, each followed by what it names — and in every scan its blocking `.`
came right after `triage-first.sh`. So it was something in that hook all along, not the lines earlier
releases changed. This release removes what `triage-first.sh` did that no earlier hook does, and the
same constructs from the hooks after it, where one `.` would hide another.

#### Changed
- **`triage-first.sh`:** the lane pattern has no `{0,3}` brace pattern; the transcript reaches `jq` or
  `python3` on stdin, so they get only their own files, not a computed path; the once-per-session
  marker is made with `touch`, not a redirect to a computed path.
- **`careful-paths.sh`:** its marker is appended with `tee`, in the temporary folder chosen without a
  defaulted `${TMPDIR:-…}` path.
- **`session-context.sh` and `protect-hub.sh`:** git reports the checkout's git directories
  (`--git-dir`, `--git-common-dir`, `--absolute-git-dir`) instead of `cd "$(…)"`; spec folders and
  Claude Code's branch names are matched without wildcards; a spec's status is read with `grep`.
- **`_lib.sh`:** `read_settings` reads through `cat`; its variable is `setting`, not `key`, which the
  validator read as a credential; `path_matches` tests for a `/` without a `*/*` pattern.
- **`transcript-text.py`** reads the transcript from stdin.
- **`/debug`:** a sentence about checking the running app no longer pairs `curl` with "a script",
  which the validator matched as download-and-execute.
- **The static check** refuses each of these constructs; a negative control flags them all in v1.0.4.

#### Upgrade impact
- **Overwrite:** every hook script, `_lib.sh`, `transcript-text.py`, and `.claude/skills/debug/SKILL.md`.

## v1.0.4 — 2026-10-04 — The hooks run no project code and no inline programs

A patch release. Each fix for the Claude Directory let its validator read one file further, and each
time it refused a new line under the same rule: a file the hooks load or run by a path the shell
computes, or an inline program. v1.0.3 stopped the hooks running `config.sh`; this release removes
every remaining such line from the plugin's hooks at once, and a static check holds them out. From
v1.0.0, `/aplyca-adf:upgrade` moves the pin to `v1.0.4`.

#### Changed
- **`session-context.sh`** read the parallel-agents module's settings by running the project's
  `scripts/agent/_worktree-lib.sh` (`bash -c`). It now reads `worktree.conf` as data, with the same
  reader as `config.sh` (`read_settings` in `_lib.sh`).
- **The JSON readers are files:** `json-get.jq` and `json-get.py` for the event, `transcript-text.jq`
  and `transcript-text.py` for the transcript (`triage-first.sh`), in place of an inline `jq`
  program, `python3 -c`, and a Python heredoc. A hook test holds the two versions to the same answers.
- **`guard-git.sh`, `session-context.sh`, and `check-env-declared.sh`** do in plain bash what `sed`
  and `awk` programs did; `session-context.sh` lists the spec folders with `find`, not a wildcard.
- **The plugin's copies name their folder literally:** `HOOKS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks"` and
  every helper under it, written by the generator. The skeleton's copies find their folder as before.

#### Added
- **`.claude/hooks/json-get.jq`, `json-get.py`, `transcript-text.jq`, `transcript-text.py`.**

#### Upgrade impact
- **Overwrite:** every hook script and `_lib.sh`.
- **Additive:** the four helpers above, next to the scripts.
- **Migration**, only if the parallel-agents module's `worktree.conf` computes one of the five values
  `session-context.sh` reads (`BASE_BRANCH`, `ENV_FILE`, `PORT_SLOTS`, `SETUP_CMD`, `START_CMD`):
  write it out. The module's own scripts still run that file.

## v1.0.3 — 2026-10-04 — `config.sh` is read as data

A patch release. With `_lib.sh` named literally, the Claude Directory's validator read it and refused
the line that ran the project's `config.sh`: the plugin executed a file from outside its own folder.
From v1.0.0, `/aplyca-adf:upgrade` moves the pin to `v1.0.3` and overwrites `_lib.sh`.

### The hooks read `config.sh` as data and never run it

#### Changed
- **`.claude/hooks/_lib.sh`** reads the ten known settings from `config.sh` line by line: double-
  or single-quoted or bare values, indentation and trailing comments allowed, anything else ignored.
  Before, it sourced the file, so any code in it ran with every hook — in the packaged install, from
  the plugin. A hook test pins it: a `$(…)` in `config.sh` never runs.
- **`config.sh`'s header** says so.

#### Upgrade impact
- **Overwrite:** `.claude/hooks/_lib.sh`.
- **Merge:** `.claude/hooks/config.sh` — the header comment only; your values stay.
- **Migration**, only if your `config.sh` computes a value — `$(…)`, `$OTHER_SETTING`, or a value
  over several lines: write the value out on one line. The skeleton's file and the projects we know
  of don't.

## v1.0.2 — 2026-10-04 — The plugin's hooks pass the Claude Directory's checks

A patch release: the Directory's validator refused v1.0.1's hooks for loading `_lib.sh` from a
computed path. No workflow changes. From v1.0.0 or v1.0.1, `/aplyca-adf:upgrade` moves the pin to
`v1.0.2`; nothing in the project changes beyond v1.0.1's parts.

### The plugin's hooks load `_lib.sh` by a literal path

The Claude Directory's validator, now that it follows the plugin's hooks, refused them: each loaded
`_lib.sh` from a path the shell computes, `$(dirname "$0")`. The plugin's copies now load
`"${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh"`, which Claude Code always sets for a plugin's hooks. The
skeleton's copies are unchanged. The hook smoke test in `/aplyca-adf:adopt`, `docs/SETUP.md`, and
`docs/UPGRADING.md` passes `"cwd":"."` instead of `$PWD`, which the validator held as a possible
credential next to a GitHub URL.
**Upgrade impact:** framework-internal — the plugin's generated hooks only.

## v1.0.1 — 2026-10-04 — Ready for the Claude Directory

A patch release ([#22](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/22)): the
repository and the plugin pass the Claude Directory's checks, and the plugin has an icon. No workflow
changes. From v1.0.0, `/aplyca-adf:upgrade` moves the pin to `v1.0.1` and overwrites `_lib.sh`. A
project on `7383422` or older takes v1.0.0's order to upgrade in; `/aplyca-adf:upgrade` lands it here.

### The plugin passes the Claude Directory's checks

The Claude Directory's validator rejected the repository and held parts of the plugin for review.

#### Changed
- **No symlinks in the repository.** The skeleton's `.agents/skills`, a link to `.claude/skills` for
  Antigravity, is gone. `/aplyca-adf:adopt` creates it, `docs/SETUP.md` gives the command, and
  `/aplyca-adf:upgrade` never deletes a project's link. A static check keeps symlinks out.
- **The plugin's hooks name their scripts by one literal path,**
  `"${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh"`, the documented form, which the validator follows. They
  run the same.
- **A comment in `.claude/hooks/_lib.sh`** no longer gives a filesystem path as its example.

#### Added
- **A placeholder icon** for the plugin's listing, `.claude-plugin/icon.png`: three lanes, short to long.

#### Upgrade impact
- **Overwrite:** `.claude/hooks/_lib.sh` (a comment only).
- **None** for `.agents/skills`: keep your link. Projects adopted from now on get it from
  `/aplyca-adf:adopt`.

## v1.0.0 — 2026-10-02 — One plugin, a packaged install, and semantic versioning

Everything since `7383422`: `/upgrade` carries the plugin setting into the hub's worktree
([#17](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/17)), Claude Code's own worktrees
are workers ([#18](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/18)), `/cost-report`'s
Sonnet estimate ([#19](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/19)), and one
plugin with a packaged install, joining a project with no install, and semantic versioning
([#20](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/20)). It's the first numbered
release, and a major one: the installer plugin is renamed `aplyca-adf`.

**Upgrading a repository whose baseline is `7383422`.** In this order:

1. **Install `aplyca-adf` in the project.** Paste the install prompt from the
   [README](README.md#with-claude-code--the-installer-plugin-recommended) into a session on the
   project — from a worktree if the project uses the dispatcher hub. It refreshes the marketplace,
   installs with `--scope project`, and reports a user-scope copy to remove. Then start a new
   session.
2. **Run `/aplyca-adf:upgrade`.** It replaces `aplyca-framework@aplyca` in the committed settings,
   pins the marketplace to `v1.0.0`, applies each part's Upgrade impact below, restamps `CLAUDE.md`
   (`Skeleton source: v1.0.0 · <SHA> …`), and offers the packaged install. Stay committed unless the
   team works in Claude Code only. By hand: each part's Upgrade impact, newest first.
3. **Remove the old plugin** once the pull request merges, on each machine that installed it:
   `claude plugin uninstall aplyca-framework@aplyca --scope project`. Teammates need nothing else:
   their next session loads `aplyca-adf` at the pinned release.

A baseline older than `7383422` takes that release's order first, then this one.

### The install refreshes a marketplace added before

A machine that added the `aplyca` marketplace before the rename keeps its copy of it, which lists only
`aplyca-framework`. Running `claude plugin marketplace add` again leaves that copy alone, so the
install prompt failed with `Plugin "aplyca-adf" not found` in every project adopted before it. The
prompt, `ADOPT.md`, and the documented commands now run `claude plugin marketplace update aplyca`
between adding the marketplace and installing the plugin. Tested on a copy of the marketplace from
`7383422`.
**Upgrade impact:** framework-internal.

### One plugin, `aplyca-adf`, and semantic versioning — breaking

([0016](docs/decisions/0016-packaged-install.md), [0017](docs/decisions/0017-semantic-versioning.md))

The installer plugin `aplyca-framework` is renamed **`aplyca-adf`**. From the next release,
releases follow semantic versioning and are tagged `vX.Y.Z`, starting at **v1.0.0**: the rename is
the major change.

#### Changed
- **The plugin's name and its skills' names.** Its skills are `/aplyca-adf:adopt`,
  `/aplyca-adf:upgrade`, and `/aplyca-adf:cost-report`, and the marketplace lists only `aplyca-adf`.
  A project that turns on `aplyca-framework@aplyca` loses `/upgrade` until it switches.
- **Versions.**
  - A release is `vMAJOR.MINOR.PATCH`: MAJOR when an adopting team has to act, MINOR for additive or
    opt-in capabilities, PATCH for fixes.
  - It gets a `vX.Y.Z` tag, and the plugin's `"version"` matches. That version changes only in a
    release pull request, and a static check holds the two equal.
  - The `CLAUDE.md` stamp keeps the commit: `Skeleton source: v1.0.0 · <SHA> (<date>) · …`. Older
    stamps still work.

#### Upgrade impact
- **Merge:** `CLAUDE.md`'s first line takes the new stamp format; `/aplyca-adf:upgrade` restamps it.
- **Migration**, in each adopted project:
  1. Install `aplyca-adf` with the install prompt.
  2. Run `/aplyca-adf:upgrade`. It replaces `aplyca-framework@aplyca` with `aplyca-adf@aplyca` in the
     committed settings.
  3. Remove the old plugin: `claude plugin uninstall aplyca-framework@aplyca --scope project`.

### A packaged install: the machinery from the pinned plugin

([0016](docs/decisions/0016-packaged-install.md), amending [0009](docs/decisions/0009-optional-modules.md))

A pilot's upgrade touched 82 files, mostly generic machinery that no project edits, and its team asked
to use the framework like a package. A team that works in Claude Code only can now choose a
**packaged** install. The committed install stays the default.

#### Added
- **The machinery in `aplyca-adf`:** the 20 core skills, the 8 agents, the 4 workflows, and the hook
  scripts, wired through the plugin's own `hooks.json`.
  - They're named under the plugin and refer to each other that way: `/aplyca-adf:triage`,
    `@aplyca-adf:code-reviewer`.
  - They're generated from `skeleton/.claude/` by `scripts/build-aplyca-adf.sh`, and a static check
    fails when the two drift apart.
- **They act only in a packaged project**, whose stamp says `install: packaged`. Committed projects
  turn the plugin on too, for `/aplyca-adf:upgrade`. There the plugin's hooks stand down, so nothing
  runs twice. Its skills and agents open with a step that hands over to the committed files, and the
  pin keeps both copies at one release.
- **Every project pins its release**, `"ref": "vX.Y.Z"` on the `aplyca` marketplace in its
  `.claude/settings.json`, equal to the release in its stamp. `/aplyca-adf:upgrade` moves the pin and
  the committed files together, from release to release. In a committed project the pin keeps the
  plugin's copies at the same release as the committed files.
- **The packaged install:**
  - It commits only its own layer and its modules, about 40 fewer files.
  - `CLAUDE.md` gets a note mapping the short names the docs use to the plugin's, and
    `docs/getting-started/DEV-SETUP.md` lists the key commands by their full names.
  - `docs/SETUP.md` § Packaged install covers the steps, and `docs/UPGRADING.md` covers upgrades.
- **`/aplyca-adf:adopt` asks committed or packaged.** `/aplyca-adf:upgrade` moves a packaged project
  from release to release by bumping the pin, skips the paths the plugin carries, and offers to switch
  between the two installs. The switch is recorded as a PDR in the project, amending PDR-0001.

#### Changed
- **`.claude/hooks/_lib.sh`** reads `config.sh` from next to the scripts, as before, or else from the
  project's `.claude/hooks/config.sh` (`CLAUDE_PROJECT_DIR`). A copy of the hooks that isn't the
  project's own stands down unless the project is packaged. A committed install behaves the same.

#### Upgrade impact
- **Overwrite:** `.claude/hooks/_lib.sh`.
- **To switch to packaged:** `/aplyca-adf:upgrade` offers it from v1.0.0 (`docs/UPGRADING.md`, "We use
  the packaged install — or want to").

### Joining an adopted project: open it and trust the folder

A developer joining a project that uses the framework has nothing to install. The project's committed
`.claude/settings.json` works like a package manifest: in the first session after they trust the
folder, Claude Code fetches the marketplace at the pinned release and loads `aplyca-adf`. That was
tested on a machine that had never installed the plugin. The project's own docs didn't say so.

#### Changed
- **`docs/getting-started/DEV-SETUP.md`**, the project's setup guide, says it: open a session, trust
  the folder, and `/plugin` lists the plugin. Never install it at user scope.
- **The install prompt** stops when the project already turns the plugin on, instead of sending a
  joining developer to `/aplyca-adf:upgrade`. `ADOPT.md` asks before it treats "use the framework" in
  an adopted project as an upgrade.
- **`DEV-SETUP.md` is merge-required** in the upgrade taxonomy. It was unlisted, so upgrades left it
  alone.

#### Upgrade impact
- **Merge:** `docs/getting-started/DEV-SETUP.md` — add the paragraph to § AI-assisted development;
  `/aplyca-adf:upgrade` does it.

### `/cost-report` shows what Opus sessions would have cost on Sonnet

A pilot's report showed every session on Opus, though the project's `"model"` setting said `sonnet`:
the desktop app's model picker sets each session's model. The report now prices each Opus or Fable
session's tokens at Sonnet's prices too — an `on sonnet` column and a model line with the total and
the difference — and the skill ties it to the cost model's rule: Sonnet for work with a clear spec
and a way to check it. Cache reads cost the same on both, so the difference is in output and cache
writes; the report says so. `--json` adds `cost_on_sonnet` (`aplyca-framework` 0.2.6).
**Upgrade impact:** framework-internal; update the plugin.

### Claude Code's own worktrees are workers too (parallel-agents)

([0015](docs/decisions/0015-tool-worktrees-are-workers.md), amending
[0008](docs/decisions/0008-dispatcher-and-worker-worktrees.md))

Teams that work in the desktop app start tasks in a new session with its worktree option. Two
projects with the module had such worktrees in use while the framework treated them as foreign.

#### Changed
- **Every linked worktree is a worker.** A task gets its worktree one of two ways:
  - **Claude Code's worktree, by default:** a new session with the desktop app's worktree option,
    or `claude --worktree`.
  - **The scripts (`/dispatch`):** when the worktree needs a port, setup or start commands, or a
    base branch other than the default.
- **The session-context hook names the route and the gaps.** In the main checkout, it says which
  route this project's tasks take. In a worktree the scripts didn't set up, it says what that
  worktree lacks: a generated branch name to rename after triage, the env file, the scripts' setup,
  or the right base branch. The role no longer depends on where the worktree sits.
- **`worktree-new.sh` marks the worktrees it sets up,** with a file in the worktree's own git
  directory. Worktrees from before the marker are recognized by their folder name.
- **`worktree-ls.sh` lists Claude Code's worktrees as workers.** It flags the ones on a generated
  branch or a detached HEAD, instead of asking to move task work out of them.
- **`/dispatch`** opens with which route a task takes. `protect-hub.sh`'s message names both routes.

#### Added
- **`.worktreeinclude`** (with the module): the env file Claude Code copies from the main checkout
  into each worktree it creates.

#### Upgrade impact
- **Overwrite:**
  - Core: `.claude/hooks/session-context.sh`, `.claude/hooks/protect-hub.sh`,
    `.claude/hooks/README.md`.
  - With the module: `scripts/agent/{_worktree-lib,worktree-new,worktree-ls}.sh` and
    `.claude/skills/dispatch/SKILL.md`.
- **Merge** (with the module): `docs/PARALLEL-AGENTS.md`. Take the new § Two routes, the worker row,
  and § Claude Code's worktrees, which replaces § Claude Code's built-in worktrees. Keep your
  § Shared services.
- **Additive** (with the module): `.worktreeinclude`. List the same file as `ENV_FILE` in
  `scripts/agent/worktree.conf`; if the project already has a `.worktreeinclude`, add that line to
  it.
- **No migration:** existing script worktrees are recognized by their folder name, and rerunning
  `worktree-new.sh` on one adds the marker.

### `/upgrade` keeps the hub clean when it installs the dispatcher hub

Choosing `parallel-agents` moves the upgrade into a worktree created from the last commit, so the
plugin setting the install prompt left uncommitted in the main checkout stayed behind: the pull
request added it again, and the main checkout's copy stopped the first pull after the merge. `/upgrade`
now checks `git status` before creating the worktree, carries the setting into it, and restores the
main checkout's copy, listing both in the plan; anything else uncommitted is the developer's to
decide. The plugin-setting check now tells committed, uncommitted, and missing apart
(`aplyca-framework` 0.2.5).
**Upgrade impact:** framework-internal; update the plugin.

## 7383422 — 2026-10-01 — Parallel agents, test first in every lane, and adoption per project (`aplyca-framework` 0.2.4)

Everything since `3eb7777`: portable parallel agents and `/handoff`
([#13](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/13)), test first in every lane and
the hub enforced ([#14](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/14)), and
adoption and upgrades — the modules offered, the plugin per project, one-prompt and new-project
adoption ([#15](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/15)).

**Upgrading a repository whose baseline is `3eb7777`.** `/upgrade` does this for you, and now offers
the modules you don't have. In this order:

1. **Get the plugin into the project, at 0.2.4.** Paste the install prompt from the
   [README](README.md#with-claude-code--the-installer-plugin-recommended) into a session on the
   project: it installs with `--scope project` and reports a user-scope copy to remove. Already
   installed per project? Update from the project's folder (`claude plugin marketplace update aplyca`,
   then `claude plugin update aplyca-framework@aplyca`). Then start a new session.
2. **Run `/upgrade`** — from a worktree if the project uses the dispatcher hub. By hand: each part's
   Upgrade impact below, newest first. Where two parts touch the same file, copy the newest version
   once and apply the older parts' migration notes only.
3. **Re-stamp the baseline** at the top of `CLAUDE.md` with `7383422` and the modules you have.

A baseline older than `3eb7777` takes that release's order first — its three fixes affect every
adopted repository — then this one.

### `/upgrade` offers the modules a project doesn't have

`/upgrade` updated only the modules a project already had and never offered the others, so a project
adopted before modules existed would never be offered the dispatcher hub (`parallel-agents`), the
ClickUp integration, or the GitHub harness. It now lists the missing modules, recommends the ones
the repository's facts support (the same rules as `/adopt`), and installs the chosen ones in the same
upgrade pull request with their customize steps. Choosing `parallel-agents` moves the upgrade into a
worktree of its own, so the main checkout starts as a clean hub (`aplyca-framework` 0.2.4).
**Upgrade impact:** framework-internal; update the plugin.

### The plugin installs per project, never for the whole machine

The install docs (README, plugin README, `docs/SETUP.md`) installed the plugin at Claude Code's default
`user` scope, which turns it on in every project on the machine. They now install it with
`--scope project` from the project's folder — recorded in the committed `.claude/settings.json`, so
the team is offered it and every worktree of a hub gets it — or `--scope local` to try it alone.
Both READMEs open with an install prompt to paste into any Claude Code session — terminal, desktop
app, or IDE: it runs the two commands, skips a plugin the project already declares, stops in a hub's
main checkout, and reports a leftover user-scope copy. The plugin README adds the steps for the
desktop app's Code tab (**+ → Plugins → Add plugin**, scope "this project"). `/adopt` commits
that setting with the adoption and checks it; `/upgrade` offers to add it when the project doesn't
have it. `docs/MCP-INTEGRATION.md` pointed MCP servers at `.claude/mcp.json` or a global file; it now
uses the project's `.mcp.json`.
**Upgrade impact:** merge `docs/MCP-INTEGRATION.md` (one line, § Wiring it into AI tools).
**Migration:** if you installed the plugin at user scope, let `/upgrade` add the project setting; once
every project you use it in has it, run `claude plugin uninstall aplyca-framework@aplyca --scope user`
and `claude plugin marketplace remove aplyca --scope user`.

### Adopt in one prompt — and in a new project

A Claude Code session told "Adopt the Agentic Development Framework in this project: <repository URL>"
had nothing to follow, so it could copy the skeleton by hand and skip the fact-checking, the version
stamp, and the pull request. A new `ADOPT.md` at the repository root, pointed to from the top of the
README, is the procedure for agents: confirm with the developer, check the project (new, already
adopted, or a hub's main checkout), install the plugin with `--scope project`, then run `/adopt` — in
a new session, or in the same one by following the skill's file from the marketplace folder.
`/adopt` gains a mode for a new project with no code yet: it offers `git init` and the first commit,
asks for the planned stack instead of reading it, marks those entries
`<!-- planned: not in the repository yet -->`, records the stack as ADR-0001 (`proposed`), and
delivers without a remote. `/init-project` is the step that replaces the planned entries once the
first code lands. `/adopt` and `/upgrade` find the marketplace folder through
`claude plugin marketplace list --json` instead of assuming its path.
**Upgrade impact:** overwrite `.claude/skills/init-project/SKILL.md`; the rest is framework-internal —
update the plugin.

### Test first in every lane; the hub enforced

([0014](docs/decisions/0014-test-first-in-every-lane.md); [0008](docs/decisions/0008-dispatcher-and-worker-worktrees.md), addendum)

#### Changed
- **The fast and careful lanes are test-first.** Write or update the test that asserts the new
  behavior and watch it fail — for a bug, the regression test — then make the change until it passes.
  Before, red-first was required only for bugs, so a precise change could be tested after the fact.
  A copy-only change updates an existing assertion first rather than adding a test that restates
  the text, and a change that amends a spec updates the affected tests first. `/review` checks the
  red-then-green evidence in every lane.
- **`/adopt` recommends the parallel-agents module** to any team whose agents may work in parallel:
  each task gets its own worktree, branch, pull request, and session. It stays opt-in
  (`aplyca-framework` 0.2.3).

#### Added
- **`protect-hub.sh`** (core hook, PreToolUse on file edits). With the parallel-agents module
  installed, it stops every file edit in the main checkout — the hub, where the dispatcher edits
  nothing — and lets edits in worktrees through. Without the module it does nothing, and an empty
  `HUB_READONLY` in `config.sh` turns it off. File writes made through Bash aren't seen.
- **`/upgrade` and `/adopt` (adding modules) run from a worktree of their own** in a hub repository,
  and stop if started in the main checkout.

#### Upgrade impact
- **Overwrite:**
  - `.claude/hooks/protect-hub.sh` (new) and `.claude/hooks/README.md`.
  - `.claude/rules/testing.md`, `.cursor/rules/testing.mdc`.
  - `.claude/skills/{triage,spec-workflow,review}/SKILL.md`.
  - With the module: `.claude/skills/dispatch/SKILL.md`.
- **Merge:**
  - `.claude/settings.json` — add `protect-hub.sh` to the PreToolUse `Edit|Write|MultiEdit` hooks,
    after `protect-paths.sh`.
  - `.claude/hooks/config.sh` — add `HUB_READONLY="1"` with its comment.
  - `AGENTS.md` — the fast lane's steps (§ 2); `CLAUDE.md` — the fast lane's row and the
    `protect-hub` guardrail row; `GEMINI.md`, `CONTRIBUTING.md`, `README.md`, `specs/README.md` —
    the fast lane's wording.
  - With the module: `docs/PARALLEL-AGENTS.md` — the enforcement note under § Two roles.

### Parallel agents — portable defaults, environment info, and `/handoff`

Field findings from the project the `parallel-agents` module came from, generalized
([0008](docs/decisions/0008-dispatcher-and-worker-worktrees.md), addendum).

#### Changed
- **The `parallel-agents` defaults assume nothing about the project.**
  - Ports are off (`PORT_SLOTS=0`), and `ENV_OVERRIDES` no longer names a container project.
  - No env file is written when the project has none to seed from.
  - `worktree-new.sh` mentions the project name and the start commands only when the project uses
    them.
  - A project that runs no server gets a worktree, a branch, and a session per task, and nothing it
    has to switch off. Ports, overrides, and `READY_URL` sit in a "when each worktree runs a server"
    section of `worktree.conf` and `docs/PARALLEL-AGENTS.md`.
- **`worktree-ls.sh`** shows port and state columns only when some worktree has a port. It also flags
  task work sitting in one of Claude Code's own worktrees. `--info` runs `ENV_INFO_CMD` in each
  worktree for whatever someone needs to use it (its URLs, the accounts to sign in with), derived on
  each run.
- **`docs/PARALLEL-AGENTS.md`** leads with what every project gets. Shared services are described
  generically: a task that would change one for everyone gets its own copy through
  `START_CMD`/`STOP_CMD`.
- **The session-context hook gives a session no role in Claude Code's own worktrees**
  (`.claude/worktrees/`), which the scripts never set up. That's fine for reading; for task work it
  asks for a dispatch. Before, such a session was told it was a worker.

#### Added
- **`/handoff`** (core skill): hand work in progress to a teammate, another machine, or a fresh
  session as a short message of pointers — task, branch and commit, spec folder, pull request, done,
  next, open questions. It puts the state in the record first, never copies the spec or the process,
  and shows the message to the developer rather than posting it.

#### Fixed — framework-internal
- `CLAUDE.md` gave the framework's former name as its current one, a slip of the rename in
  [#10](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/10).
- `/adopt` offers `parallel-agents` for any project with several sessions at once, not only projects
  where each needs a running app (`aplyca-framework` 0.2.2).

#### Upgrade impact
- **Overwrite:**
  - With the module: `scripts/agent/{_worktree-lib,worktree-new,worktree-ls}.sh`.
  - Core: `.claude/hooks/session-context.sh`, `.claude/skills/spec-workflow/SKILL.md`,
    `docs/COST-MODEL.md`.
- **Merge:** `scripts/agent/worktree.conf` — keep your values. If you relied on the old defaults
  (ports on, `COMPOSE_PROJECT_NAME` in `ENV_OVERRIDES`), set them explicitly: `PORT_SLOTS=180` and
  `ENV_OVERRIDES='COMPOSE_PROJECT_NAME=${PROJECT}'`. New installs start with both off.
- **Merge:** `docs/PARALLEL-AGENTS.md` — keep your recorded shared-services decision; take the
  restructured sections.
- **Additive:** `.claude/skills/handoff/SKILL.md`.

## 3eb7777 — 2026-10-01 — Lanes, model choice, and a sharper process (`aplyca-framework` 0.2.1)

Everything since `ed3d1a1`: the field-practices reconciliation ([#9](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/9)), the rename to the
Agentic Development Framework ([#10](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/10)), practices adapted from a public skills collection
([#11](https://github.com/Aplyca/AgenticDevelopmentFramework/pull/11)), and the plugin and model-alias changes before them.

**Upgrading a repository whose baseline is older than this release.** `/upgrade` does this for you.
By hand, in this order:

1. **The three fixes first**, even if you upgrade nothing else. They affect every adopted
   repository: the `@AGENTS.md` import, the hook schema, and `user_invocable`. The steps are in
   *Field-practices reconciliation → Upgrade impact*, below.
2. **Then each part's Upgrade impact, newest first:** Sharper process, Field-practices
   reconciliation, Renamed and READMEs, then the earlier changes. Where two parts touch the same
   file, copy the newest version once and apply the older parts' migration notes only.
3. **Update the plugin to 0.2.1** (`claude plugin marketplace update aplyca && claude plugin update
   aplyca-framework@aplyca`), then restart Claude Code.
4. **Re-stamp the baseline** at the top of `CLAUDE.md` with the framework commit you upgraded to.

### Sharper process — practices adapted from a public skills collection

Practices from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), rewritten into the
skills, rules, and docs we already have rather than installed beside them
([0013](docs/decisions/0013-adapt-practices-not-a-second-workflow.md)).

#### Changed
- **`/debug` and `@debugger` start with a failing signal:**
  - One command that fails on *this* bug — run, and shown — before any theory. When the cause is
    plain from the code, the regression test is that command.
  - Then a shrunk reproduction, and 3–5 ranked hypotheses, each with what would disprove it, shown
    to the developer and tested one at a time.
  - Debug logs are tagged so one search removes them; the report adds the signal and what was ruled
    out.
  - If no correct level for the regression test exists, that's a finding for the pull request.
- **Questions come in rounds** (`AGENTS.md` § Working economically; `/triage`, `/write-spec`,
  `/write-plan`): every question that doesn't depend on another open answer, numbered, each with a
  recommended answer — so the developer can reply "as recommended". Facts are looked up, not asked.
- **An opinionated glossary:** `docs/GLOSSARY.md` holds one term per concept, the words to avoid,
  and no implementation details. `/write-spec` uses its terms and adds new ones as they settle. The
  naming rule in `code-quality.md` points at it, and `AGENTS.md` reads it whenever anything is named.
- **Merge danger** in `/open-pr` and the github module's PR template: does a revert undo the change,
  and what it affects if wrong. `/review` checks it fits the diff.
- **Tests that can fail** (`.claude/rules/testing.md`, `.cursor/rules/testing.mdc`): expected values
  from outside the code; checks through the public interface; mocks only at the system boundary.
- **`/record-decision` has a threshold:** an ADR only when the decision is hard to reverse,
  surprising without its context, and a real trade-off; every team rule still gets a PDR.
- **`/triage` checks prior decisions:** for new behavior, *already built?* (search by concept) and
  *declined before?* (the *Out of scope* sections and decision records, surfaced with their reason).
- **`COST-MODEL.md` § Between phases:** continue, `/clear`, hand off, hand to an agent, or `/compact` —
  asked in that order, at a phase boundary.
- **`/context-audit` and `/deep-context-audit`** also flag:
  - instructions that change nothing;
  - copies of what the repository already shows;
  - material only some tasks need, in an always-loaded file;
  - a "don't" with no statement of what to do instead.
- **The `triage-first` hook also catches a new branch.** It runs on Bash as well, and stops a
  session's first `git switch -c`, `git checkout -b`, `git branch <name>`, or `git worktree add` once
  when no lane is stated yet — the session evals showed models branching before triage, which the
  edit-only hook let through. Still one reminder per session; other Bash commands are never stopped.
  The reminder now says what it saw (no reply text yet, or no reply naming a lane), after models
  answered it with "the triage is stated above". In headless reruns it fired at the branch every
  time but didn't make the model write the triage — it stays a nudge, not a lock.

#### Added — framework-internal
- Evals:
  - A static check that these practices stay in place.
  - A `debug` suite for the session evals: a fixture project runnable with Node's test runner, a
    clear-cause case, and an unclear-cause case.
  - A `declined-before` triage case.
  - `evals/dynamic/run-triage-evals.sh` is now `run-session-evals.sh` (`--suite triage|debug`).
- The debugging scenario follows the new method; the catalogs and the README's bug diagram match.

#### Upgrade impact
- **Overwrite:**
  - Skills: `.claude/skills/{debug,triage,write-spec,write-plan,open-pr,review,record-decision,context-audit,spec-workflow}/SKILL.md`.
  - Agent: `.claude/agents/debugger/agent.md`.
  - Rules: `.claude/rules/{testing,code-quality}.md` and `.cursor/rules/testing.mdc`.
  - `.claude/workflows/deep-context-audit.js` and `docs/COST-MODEL.md`.
  - `.claude/hooks/triage-first.sh` and `.claude/hooks/README.md`.
- **Merge:**
  - `.claude/settings.json` — add `triage-first.sh` to the PreToolUse `Bash` matcher, after
    `guard-git.sh`.
  - `CLAUDE.md` — the `triage-first` row of the guardrails table; `.claude/hooks/config.sh` — the
    comment above `TRIAGE_FIRST`.
  - `AGENTS.md` — § Working economically gains the question-round and between-phases bullets; the
    glossary row in § Project documentation changes.
  - `GEMINI.md` — the glossary row.
  - `CONTRIBUTING.md` — the glossary and decision-record bullets.
  - `docs/GLOSSARY.md` — keep your terms; turn *Aliases* into *Avoid*, and move implementation
    details to `docs/reference/`.
  - With the github module: `.github/pull_request_template.md` gains § Merge danger.

### Field-practices reconciliation (`aplyca-framework` 0.2.0)

Practices proven in client projects — some built on this framework, some grown alongside it — reconciled into the skeleton, generalized for any stack, and tested. The rationale for each decision is in [`docs/decisions/`](docs/decisions/README.md).

#### Fixed — affects every adopting repository
- **Claude Code never loaded `AGENTS.md`.** When a repository has both files, Claude Code reads `CLAUDE.md` *instead of* `AGENTS.md`; the skeleton's `CLAUDE.md` didn't import it, so the workflow, critical rules, and conventions were invisible to Claude Code. `CLAUDE.md` now starts with `@AGENTS.md` (and `GEMINI.md` does the same).
- **Hooks never ran.** `.claude/settings.json` declared hooks as flat `{"matcher", "command"}` entries reading `$CLAUDE_FILE_PATH`; Claude Code requires a nested `hooks` array and passes tool input as JSON on stdin. Replaced with a valid schema and tested scripts.
- **Skill frontmatter `user_invocable` was ignored** (the key is `user-invocable`; unknown keys are silently dropped). Removed; `/open-pr` uses `disable-model-invocation: true`.
- **Stray test text** committed into `specs/_template.md` (commit `719f27b`) is gone with the new templates.
- **Links that break in adopting repos** — the skeleton pointed at framework-only docs (`docs/ONBOARDING.md`, `docs/scenarios/`, `evals/STRATEGY.md`) and at example files that don't exist. Fixed, and a static check now fails on any such link.
- `permissions.allow` contained `Bash(git branch:*)`, which also auto-approved `git branch -D`. Removed.
- The skeleton's `CONTRIBUTING.md` sent contributors to `CLAUDE.md` for project rules (now `AGENTS.md`); `/init-project` had duplicate step numbers.
- The reference MCP server in `docs/MCP-INTEGRATION.md` misread its own URIs (`specs` parses as the URL host, so every path segment was off by one) and cut sections with `\Z`, which JavaScript treats as a literal `Z`. Rewritten for spec folders and legacy specs, and the helpers were tested.

#### Added
- **Spec folders** — `specs/README.md` (the process: lanes, flow, granularity, status, change requests) and `specs/_templates/{spec,plan,tasks}.md`, replacing `specs/_template.md`. A change request appends a `CR N` part to each file, its tasks numbered from `T<N>00` ([0001](docs/decisions/0001-spec-folders-as-record-of-intent.md)).
- **Skills:** `/triage` ([0004](docs/decisions/0004-triage-before-setup.md)), `/write-plan` with the approval gate ([0002](docs/decisions/0002-one-approval-gate-on-the-change-surface.md)), `/open-pr` and `/stakeholder-update` (the client-facing update, generalized from a field-proven skill; it starts from a plain request such as "update the client" and posts only after showing the draft — links, CMS entries, and statuses are project settings in `docs/TRACKER-INTEGRATION.md`) ([0005](docs/decisions/0005-outward-actions-and-draft-prs.md)), `/record-decision` ([0007](docs/decisions/0007-process-decision-records.md)), `/context-audit`.
- **Agent:** `@spec-analyzer` — adversarial, read-only analysis of a spec folder before the gate.
- **Three lanes — ceremony follows risk, not size** ([0011](docs/decisions/0011-lanes-ceremony-follows-risk.md)): **fast** (a precise request, a few files, no trigger — edit, prove it with a test, commit), **careful** (the same in a risk area — plus that area's checklist and the developer's yes), **full** (something to decide — the spec-driven flow). Defined in `specs/README.md` § Lanes with escalation triggers, careful-lane checklists, and **light change requests** (a short `CR N` entry committed with the change). Triggers are rechecked while working, and `/review` checks the diff fits its lane. Measured on real sessions, small precise changes routed through the full flow cost several times more, and the extra calls went into spec files rather than tests or verification.
- **The developer's call:** raising the lane is always honored; lowering it keeps a risk area's checklist unless the developer accepts the risk, recorded in the pull request. **Sensitive areas** are configuration: `AGENTS.md` § Sensitive areas, mirrored in `CAREFUL_GLOBS` (`.claude/hooks/config.sh`), enforced by the new `careful-paths.sh` hook, which stops the first edit in each area once per session so the agent confirms the lane. A `triage-first.sh` hook (`TRIAGE_FIRST` in `config.sh`) stops a session's first file edit once when its reply text states no lane — a nudge, not a lock: the routing evals showed models acting before stating the triage, or treating a triage decided in their thinking as stated, and a second reminder changed nothing.
- **Working economically** — `AGENTS.md` gains one task per session, short tool output, targeted tests while iterating and the full gate once, agent browser checks only when asked or visual, and batched questions; `.claude/rules/testing.md` gains a verification budget.
- **Dynamic workflows** (`.claude/workflows/`): `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep` — fan-out with independent verification of every finding.
- **Guardrail hooks** (`.claude/hooks/`): `session-context.sh` (branch, worktree role, and the spec folder the branch belongs to — change-request branches included), `guard-git.sh`, `protect-paths.sh`, `check-env-declared.sh`, with project values in `config.sh` ([0006](docs/decisions/0006-guardrails-as-configuration.md)). `permissions.ask` on pushes and pull-request actions; `permissions.deny` on reading `.env` files.
- **Docs:** `docs/process/` (PDR index and template; records are named `NNNN-<slug>.md`, like ADRs), `docs/reference/` (on-demand, code-level subsystem pages), `docs/TRACKER-INTEGRATION.md` (requirements pipeline, rules for agents, MCP setup with a read-only allowlist).
- **Optional modules** (`modules/`, [0009](docs/decisions/0009-optional-modules.md)): `github` (PR template with traceability and constitution gates, issue forms, secret scan, base-branch policy, `.gitleaks.toml`), `git-hooks` (tool-agnostic `pre-push`), `clickup` (ClickUp's official MCP server in `.mcp.json` plus a read-only permission allowlist — every write prompts; `install.sh` merges into existing files and is safe to rerun), `parallel-agents` (worktree scripts — idempotent create, env seeded from the main checkout, ports reserved under a lock, `--no-start` / `--setup-only` / `--refresh-env` / `--from <tag>`, a warning when reusing a stale branch — plus `/dispatch` and `docs/PARALLEL-AGENTS.md`; [0008](docs/decisions/0008-dispatcher-and-worker-worktrees.md)).
- **Framework decision records** — `docs/decisions/0001`–`0012`.
- **Evals:** `evals/static/test-hooks.sh`, `test-modules.sh`, and `test-plugin.sh` (functional tests in throwaway repositories and synthetic transcripts); `check-skills.sh` now also checks agents, workflows, the settings and hook schema, the `@AGENTS.md` import, the spec templates, links, modules, the lanes, and the plugin. Dynamic routing evals for `/triage` (`evals/dynamic/fixtures/triage/`): fast, careful, full, a sensitive area, the developer raising and lowering the lane, and an answer-only task — run against real headless Claude Code sessions on Sonnet and Opus by `evals/dynamic/run-triage-evals.sh`, with graded reports in `evals/dynamic/reports/`.

#### Changed
- **The feature workflow:** triage → spec → plan and tasks → **one approval gate on scope, change surface, and assumptions** → `spec:` commit → docs first → **one red → green cycle and one commit per task** → gate results recorded in `tasks.md` → review → **draft** pull request only when asked ([0002](docs/decisions/0002-one-approval-gate-on-the-change-surface.md), [0003](docs/decisions/0003-tdd-at-task-granularity.md), [0005](docs/decisions/0005-outward-actions-and-draft-prs.md)). Change requests amend the same spec folder (`CR N`) on a fresh branch named after the feature and the change (`feat/newsletter-signup-topics`); hotfixes that changed behavior are backfilled the same way.
- **`AGENTS.md`** restructured: ground rules (constitution precedence, never invent requirements, nothing outward unasked), how work flows, requirements & traceability, delivery rules, boundaries & antipatterns, the comments rule. **`CLAUDE.md`** rewritten around the import, skills/agents/workflows, and the table of enforced guardrails.
- **Skills updated:** `write-spec` (folders, change-request mode; approval moved to the gate), `write-tests` (task, acceptance, and standalone modes), `write-docs` (driven by the plan's documentation plan), `implement` (per-task loop, change-surface discipline, gate results, then `status: implemented`), `review` (change surface, constitution, evidence, comments rule, PR vs diff), `refactor` (characterization tests proven able to fail, a step plan with its file list, one `refactor:` commit per green step, an ADR for lasting structural decisions), `commit`, `spec-workflow`, `spec-drift`, `orchestrate`, `init-project`, `debug`.
- **Agents updated** for spec folders; `security-reviewer` checks authorization loosening; `test-runner` requires red for the right reason and reports evidence.
- **`docs/COST-MODEL.md`** — what a session costs (calls × context, measured), the cost of each lane, the effort dials and their cost, keeping sessions cheap, measuring; the advice to run `/commit` on Haiku is withdrawn — a model switch mid-session re-reads the whole context uncached.
- **Rules:** `code-quality` gains "Comments — write almost none" and "types are load-bearing"; `git-workflow` covers per-task commits (the docs-first tasks share one; test-only tasks are proven able to fail), where the pull-request link and gate results are committed, `<type>/<slug>` branches, outward actions, drafts, "CI is a signal; review is the gate"; `testing` covers red-then-green per task and evidence.
- **Templates:** `CONSTITUTION.md` (field-proven example principles, precedence, amendment via PDR and never in the PR that benefits), `CONTRIBUTING.md` (two branching models, draft PRs, status vocabulary, what's enforced), `SPEC-MODEL.md` (folders; the Technical section moves to `plan.md`), `COST-MODEL.md` (aliases, current models and prices, workflow cost), `MEMORY-STRATEGY.md` (new layers), `DEV-SETUP.md` (one command surface), `.claudeignore` (`.claude/worktrees/`), Cursor rules, `GEMINI.md`.
- **Default model** is the alias `"sonnet"` — shipped in the model-aliases entry below; [0010](docs/decisions/0010-model-aliases.md) records why.
- **The model follows the work** ([0012](docs/decisions/0012-choose-the-model-by-the-work.md), version-less aliases only): `sonnet` for the fast and careful lanes, bug fixes, investigations, reviews, and implementing an approved plan; `opus` for the full lane's spec and plan, ambiguous or long-horizon work, and bugs that resist two hypotheses. Switch where it's cheap — session start, right after triage, or a fresh session after the gate (each model has its own prompt cache). `/triage` names the model when the session's doesn't fit the lane; `/write-plan` hands off to a fresh Sonnet session; `/debug` suggests Opus after two disproven hypotheses. `COST-MODEL.md` gains § Choosing between Sonnet and Opus (with effort guidance), `CLAUDE.md` a Model column. Agents: `@code-reviewer`, `@security-reviewer`, and `@ux-reviewer` move from `haiku` to `sonnet`; `@spec-analyzer` and `@architect` to `opus`. Skills pin no model.
- **Plugin 0.2.0:** a new `/cost-report` skill reports what agent sessions on a project cost — calls, active time, context, tokens, estimated cost — from Claude Code's local transcripts, flagging long context, pauses past the cache lifetime, browser loops, and spec-heavy small changes. `/adopt` asks for the sensitive areas and can register the marketplace for the whole team (`extraKnownMarketplaces`, in the object form Claude Code expects — a static check rejects the array form), offers modules, discovers the branching model and tracker, configures the hooks, records PDR-0001, and verifies hooks and the import; it can add modules to an adopted repo. `/upgrade` handles modules, the new buckets, and changelog migration steps.
- **Framework docs:** README (install and update steps, a workflow per situation), SETUP, UPGRADING, ONBOARDING, SKILLS-REFERENCE, AGENTS-REFERENCE, worked examples (now a spec folder and a change request), and scenarios (new: change request, answer-only task, parallel agents).

#### Removed
- `skeleton/specs/_template.md` (replaced by `specs/_templates/`).
- `docs/scenarios/modifying-existing-feature.md` (replaced by `change-request.md`); the examples' separate test, doc, and implementation plans (folded into `plan.md` and `tasks.md`).

#### Upgrade impact
- **Migration — do these even if you skip everything else:**
  1. Add `@AGENTS.md` as the first instruction of `CLAUDE.md` (below the `Skeleton source` comment). Start a new session and confirm with `/memory` that both files load.
  2. Replace any flat hook entry in `.claude/settings.json` with the nested `{"matcher": …, "hooks": [{"type": "command", "command": …}]}` form. Copy `.claude/hooks/`, set `config.sh`, and port custom hooks to read the event from stdin (`tool_input.file_path`, `tool_input.command`) and exit 2 to block or report.
  3. Remove `user_invocable:` from custom skills (use `user-invocable` / `disable-model-invocation`).
- **Overwrite:** all skills (six new), all agents (`spec-analyzer` new), `.claude/workflows/` (new), hook scripts (new), `.claude/rules/{code-quality,git-workflow,testing}.md`, `.cursor/rules/*`, `docs/SPEC-MODEL.md`, `docs/COST-MODEL.md`, `docs/MEMORY-STRATEGY.md`, `docs/process/0000-pdr-template.md`, `specs/_templates/` (new).
- **Merge:** `AGENTS.md` (restructured — move your critical rules into Ground rules, add Boundaries & antipatterns, the lanes, Sensitive areas, and Working economically; keep identity, conventions, structure, commands), `CLAUDE.md` (rewritten — keep your project name and stamp, add the import), `GEMINI.md`, `CONTRIBUTING.md` (keep the branching model you use; add the status vocabulary), `.claude/settings.json` (alias model, `ask`/`deny`, hooks — including `careful-paths.sh` under PreToolUse `Edit|Write|MultiEdit`), `.claude/hooks/config.sh` (new — set protected branches, sensitive areas in `CAREFUL_GLOBS`, append-only and generated paths), `docs/CONSTITUTION.md` (keep your principles; adopt the precedence and amendment wording), `.claudeignore`, `docs/getting-started/DEV-SETUP.md`, `README.md`.
- **Additive:** `specs/README.md`, `docs/process/README.md`, `docs/reference/README.md`, `docs/TRACKER-INTEGRATION.md`.
- **Specs:** existing single-file specs are untouched; new work uses folders; move a legacy spec into a folder the next time it changes. Delete `specs/_template.md` if you never customized it.
- **Modules:** optional — install with `/adopt` (module mode) or `cp -R modules/<name>/files/.` (`clickup`: `modules/clickup/install.sh <repo>`), and list them in the stamp.
- **Framework-internal:** `docs/decisions/`, `evals/`, the plugin, examples, scenarios, onboarding.

### Renamed to the Agentic Development Framework; READMEs

- **Renamed to the Agentic Development Framework** (formerly the AI-Assisted Development Framework), matching the repository: the READMEs, `CLAUDE.md`, `CONTRIBUTING.md`, the catalogs, the evals READMEs, the marketplace and plugin descriptions, and `/adopt` — including the commit message it suggests (`aplyca-framework` 0.2.1). Past changelog entries keep the name they were written with. **Upgrade impact:** Overwrite for `evals/README.md`, if your repository kept the evals scaffold — one sentence names the framework; nothing else lands in adopted repositories.
- **READMEs catch up with the field-practices release.** The framework README now shows each workflow as a Mermaid diagram (triage, the fast and careful lanes, the full lane, delivery, change requests, bugs and hotfixes) and covers choosing the model (a Model column in the workflow table, a "Model and cost" section, and the fresh Sonnet session after the gate), the `triage-first` and `careful-paths` hooks, agents' model tiers, the `clickup` module's sign-in, `/cost-report`, and the triage routing evals, and fixes the skill count (19, plus `/dispatch` from a module). `skeleton/README.md`: triage also names the model. **Upgrade impact:** Merge for `README.md`, and optional — the project README is yours; add the line if your README describes the workflow.

### Earlier changes since `ed3d1a1`

#### Changed
- **Version-less model aliases instead of pinned model IDs.** `skeleton/.claude/settings.json` now sets `"model": "sonnet"` (was `claude-sonnet-5`), and `skeleton/CLAUDE.md` explains that the alias follows the latest Sonnet as Claude Code updates. Pinned IDs went stale with every model release, and every adopting project inherited the outdated pin. Agent frontmatter already used `haiku` / `sonnet` and needed no change. `skeleton/docs/COST-MODEL.md`: the tier table lists aliases with their current models (Haiku 4.5, Sonnet 5.5, Opus 5.5); relative costs refreshed to current list prices (1× / 2× / 4× Haiku — previously ~3-5× / ~15×), with notes on the newer tokenizer, cache-read pricing, and `fable` above the tiers; savings claims softened to match the narrower Sonnet-vs-Opus gap; `/model` examples use aliases; `/fast` rewritten (Opus 5.5 / 5 / 4.8, premium pricing, Anthropic API or usage credits only). Framework-internal: `evals/dynamic/run-dynamic.md` keeps a full model ID (the Messages API doesn't accept Claude Code aliases), updated to `claude-sonnet-5-5`, and now reads the first text block since Sonnet 5.5 thinks by default. **Upgrade impact:** Merge for `.claude/settings.json` and `CLAUDE.md` — if your settings pin a model (e.g. `claude-sonnet-5`), switch it to the alias during this upgrade unless your team deliberately pins a version; Overwrite for `docs/COST-MODEL.md`.
- **Repo renamed: `aplyca/ai-dev-starter-kit` → `aplyca/AgenticDevelopmentFramework`** (`aplyca-framework` 0.1.3, framework-internal). GitHub redirects the old URLs (web, clone, push), so existing checkouts, marketplace installs, and adopted repos keep working — but update remotes and re-add the marketplace under the new slug at the next opportunity: `claude plugin marketplace add aplyca/AgenticDevelopmentFramework`. All live references in README, docs, and the plugin (homepage, clone fallbacks, baseline stamp) now use the new slug; historical changelog entries are left as written. Nothing lands in adopted repos — already-stamped `Skeleton source:` lines referencing the old name stay valid.
- **`/adopt` refinements from the first pilot adoption** (`aplyca-framework` 0.1.2, framework-internal): `evals/` is now opt-in — the skill asks whether the team writes custom skills/rules/spec patterns needing automated checks and deletes the scaffold otherwise (the pilot's review dropped it as unused); the skill also prunes `.claudeignore` entries that can't apply to the target stack.
- **`skeleton/.claudeignore` is now self-documenting** — explanatory header covering why the file exists (context quality, secret defense-in-depth, token cost), how it's enforced (advisory patterns; Claude Code's hard read-protection lives in `.claude/settings.json` permissions), and a CUSTOMIZE note to tailor entries per stack. Also added `.claudeignore` to UPGRADING.md's merge-required bucket — teams tailor its entries.

#### Fixed
- **Plugin skills' skeleton resolution on installed machines** (`aplyca-framework` 0.1.1) — installed plugins run from a version cache (`~/.claude/plugins/cache/…`), so `${CLAUDE_PLUGIN_ROOT}/../../skeleton` never resolves there (found during the first live `/upgrade` run). Both skills now resolve in order: repo checkout (dev installs) → marketplace checkout (`~/.claude/plugins/marketplaces/<name>/`, the normal installed case, after a `marketplace update`) → fresh clone. `/upgrade`'s clone fallback is now explicitly a full clone — the OLD_SHA → NEW_SHA diff needs history. Framework-internal; nothing lands in adopted repos.

#### Added
- **Open-source release readiness** — `LICENSE` (MIT; the README already declared it but no license file existed, so GitHub couldn't detect it), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, a Contributing section in `README.md`, and `.github/workflows/evals.yml` so the static evals actually run on every pull request as the README already claimed. Also removed the last organization-specific wording from the skeleton: `skeleton/docs/COST-MODEL.md` and `skeleton/docs/MEMORY-STRATEGY.md` no longer say "Aplyca-style consultancy". **Upgrade impact:** Overwrite for `docs/COST-MODEL.md` and `docs/MEMORY-STRATEGY.md` (wording only, safe to skip); the root community files are framework-internal and don't land in adopted repos.
- **`skeleton/docs/CONSTITUTION.md`** — non-negotiable principles template (Agentic Development Guide alignment). Short principles list + amendment process; `/write-spec` now gate-checks specs against it before approval (new step in mandatory-section enforcement + verification checklist). Referenced from `AGENTS.md` Critical rules.
- **Context metadata headers** — `<!-- owner · last_updated · scope -->` on every customizable doc template (ARCHITECTURE, GLOSSARY, SECURITY, OVERVIEW, DEV-SETUP, CONSTITUTION), with guidance in SETUP.md: context without an owner rots silently.
- **Nested `AGENTS.md` guidance** — monorepo guidance in `skeleton/AGENTS.md` (Project structure) and SETUP.md: nested files per module, nearest wins.
- **`plugins/aplyca-framework/` + `.claude-plugin/marketplace.json` — the framework repo is now its own Claude Code plugin marketplace.** The plugin carries two skills: `/adopt` (automates `docs/SETUP.md`: inspect the target repo, copy the skeleton, fill placeholders from verified repo facts only, stamp the baseline SHA, deliver an adoption PR) and `/upgrade` (automates `docs/UPGRADING.md`: OLD_SHA → NEW_SHA diff, three-bucket classification, plan-then-execute merge). Install: `claude plugin marketplace add aplyca/ai-dev-starter-kit && claude plugin install aplyca-framework@aplyca`. The plugin contains no framework content — adopted repos still get plain committed files readable by all AI tools; the plugin is installer/updater tooling only.
- `docs/UPGRADING.md` — guide for upgrading a target project to a newer skeleton version. Covers the three-bucket file taxonomy, OLD_SHA → NEW_SHA procedure, AI-assisted upgrade pattern, and four common scenarios.
- `CHANGELOG.md` (this file) — per-commit changelog so upgrade consumers don't have to read git log.
- `<!-- Skeleton source: [SHA] ([date]) -->` template line at the top of `skeleton/CLAUDE.md`. Adopting projects fill in their baseline SHA so future upgrades have a known starting point.
- `skeleton/.claude/settings.json` — wired the default model (`claude-sonnet-4-6`) and a starter `permissions.allow` list of universally-safe read-only commands (git status/diff/log, ls, rg, grep, find). Cuts permission-prompt interruptions and aligns the default with `docs/COST-MODEL.md` instead of relying on each user's tool-level setting.
- `skeleton/CLAUDE.md` — new "Lightweight mode — when to skip the full workflow" section with a per-change-type table (feature vs bug fix vs typo vs refactor vs tooling vs spike) and a perf tip about deleting unused rule files to shrink the auto-loaded prefill.
- `skeleton/docs/COST-MODEL.md` — new "Switching tiers in Claude Code" subsection documenting `/model`, agent `model:` frontmatter, and the `/fast` Opus-4.6-only output-speed toggle.
- `docs/AGENTS-REFERENCE.md` and `docs/SKILLS-REFERENCE.md` (in the framework repo, NOT in `skeleton/docs/`) — full catalogs of the seven shipped agents and thirteen shipped skills. These document framework-defined deliverables, so they live in the framework repo as the single source of truth — adopting projects don't get a local copy. Skills are grouped (workflow phase / reference + setup / quality + analysis); agents include tool access and model tier.

#### Changed
- **Model defaults updated to the Claude 5 family** — `skeleton/.claude/settings.json` and `skeleton/CLAUDE.md` now default to `claude-sonnet-5`; `docs/COST-MODEL.md` tier table updated (`claude-sonnet-5`, `claude-opus-5`; Haiku unchanged), `/model` examples updated, `/fast` description corrected (available on Opus 5 and 4.8). Agent frontmatter uses tier aliases (`haiku`/`sonnet`) and needed no change.
- `README.md` — added pointer to `docs/UPGRADING.md` in the Get started section.
- `docs/SETUP.md` — replaced the brief "Updating" paragraph with a pointer to the full upgrading guide.
- `skeleton/CLAUDE.md` cost-model paragraph now points at `.claude/settings.json` as the source of truth for the default model.
- **Scope cleanup — removed framework-author voice from skeleton-targeted files.** Target-project files should not narrate the framework that produced them; that voice belongs in framework docs only. Changes:
  - `skeleton/CLAUDE.md` perf tip — "the framework auto-loads…" → "Claude Code auto-loads…" (the original phrasing was ambiguous since "framework" reads as the project's web framework in a target context).
  - `skeleton/CLAUDE.md` Evals section — removed *"Evals test the framework that produced this skeleton, not your project"* meta-narration; rewritten in target-project voice.
  - `skeleton/evals/README.md` — full rewrite. Was written as a letter from framework authors to adopters (5 references to "the framework"); now reads like a normal target-project README with one closing reference to the source repo as a worked example.
  - `skeleton/.claude/skills/spec-drift/SKILL.md` and `skeleton/.claude/rules/git-workflow.md` — single-word swaps: "The framework uses…" / "The framework enforces…" → "This workflow uses…" / "This workflow enforces…".
- **Prefill trim — moved duplicated content out of the always-loaded files.** `AGENTS.md` and `CLAUDE.md` load on every turn for every adopting project; trimming them compounds across every conversation. Changes:
  - `skeleton/AGENTS.md` — left the full 15-step feature workflow + 4-step hotfix path **intact** (workflow detail is the framework's flagship and stays maximally visible in the always-loaded prefill). Only trimmed the duplicated 6-row commit-prefix table (~9 lines) → 1-line pointer at `.claude/rules/git-workflow.md`, which has the full 7-prefix table with phase semantics. Net: ~9 lines removed.
  - `skeleton/CLAUDE.md` — replaced the "Specialized agents" table (~14 lines) and the "Workflow skills" table (~18 lines) with a single 3-line section pointing at the framework's `AGENTS-REFERENCE.md` and `SKILLS-REFERENCE.md` catalogs. Type `@` or `/` to see the live index; the long-form catalogs live in the framework repo. Kept the "When to use skills vs agents" guidance section (load-bearing for routing). Net: ~26 lines removed.
  - `skeleton/CLAUDE.md` perf tip corrected — earlier version claimed Claude Code auto-loads `.claude/rules/`, which is false (rule bodies load on demand; only Cursor auto-loads `.cursor/rules/*.mdc` by glob). Replaced with accurate guidance that points to the highest-leverage trim targets.
  - Total per-turn skeleton-side prefill reduction: ~38 lines (~17%). No skill/agent descriptions were trimmed (preserves routing quality). The 15-step workflow in `AGENTS.md` was preserved verbatim — explicit choice to favor procedural visibility over marginal cost savings, since the workflow IS the framework's flagship.

#### Upgrade impact
- **Merge**: `.claudeignore` — reapply your pruned/extended entries under the new header (newly classified as merge-required).
- **Additive**: `skeleton/docs/CONSTITUTION.md` — drop in and customize.
- **Merge**: `skeleton/AGENTS.md` (constitution pointer + nesting guidance), `skeleton/.claude/settings.json` (model id), `skeleton/CLAUDE.md` (model id), customizable docs (metadata headers).
- **Overwrite**: `skeleton/.claude/skills/write-spec/SKILL.md`, `skeleton/docs/COST-MODEL.md`.
- **Framework-internal (not copied to adopting projects)**: `plugins/aplyca-framework/`, `.claude-plugin/marketplace.json` — installer tooling lives in the framework repo only; nothing lands in adopted repos beyond what the skeleton already defines.
- **Additive**: `docs/UPGRADING.md`, `CHANGELOG.md`. Drop in.
- **Framework-internal (not copied to adopting projects)**: `docs/AGENTS-REFERENCE.md`, `docs/SKILLS-REFERENCE.md` — these live in the framework repo and adopting projects link to them, so there is nothing to merge or copy on upgrade.
- **Merge**: `skeleton/AGENTS.md` (Development workflows + Commit prefixes sections were trimmed to pointers — if your project customized either, condense your customizations the same way and keep the pointers); `skeleton/CLAUDE.md` (new comment line near the top, updated cost-model paragraph, new Lightweight-mode section, scope-cleanup edits, perf tip rewritten, agent/skill tables replaced with pointers — keep your project name and any team-specific notes); `skeleton/.claude/settings.json` (if your project added hooks or extra permissions, merge them on top of the new model + permissions block); `skeleton/evals/README.md` (full rewrite — overwrite unless you customized it).
- **Overwrite**: `skeleton/.claude/skills/spec-drift/SKILL.md` and `skeleton/.claude/rules/git-workflow.md` (single-word phrasing fixes; safe verbatim).
- **Overwrite-with-care**: `README.md` and `docs/SETUP.md` are framework-owned and not part of the skeleton, so adopting projects don't copy these. The change is internal to the framework repo.

## ed3d1a1 — 2026-04-29 — Mermaid diagrams + MCP integration

### Added
- Mermaid subsection in `specs/_template.md` with worked examples for system context, sequence, state, and ER diagrams.
- `skeleton/docs/MCP-INTEGRATION.md` — when to set up an MCP server, what to expose, reference TypeScript implementation, wiring instructions for Claude Code / Cursor / Antigravity.

### Upgrade impact
- **Overwrite**: `skeleton/docs/MCP-INTEGRATION.md` (new file).
- **Merge**: `specs/_template.md` if your team has customized the template; otherwise overwrite.
- Existing filled-in specs are project-owned and unaffected.

## 6020538 — 2026-04-29 — `/orchestrate` skill

### Added
- `skeleton/.claude/skills/orchestrate/` — dispatches multiple specialized agents in parallel for review or investigation. Built-in task types: `review`, `investigate`, `pre-commit`, `custom`.

### Notes
- Explicitly does NOT auto-progress through workflow phases — preserves the plan-then-execute discipline.
- More expensive than `/review`; use only for high-stakes diffs or multi-angle exploration.

### Upgrade impact
- **Overwrite**: skill directory.
- **Merge**: `skeleton/CLAUDE.md` skills table — add a row for `/orchestrate`.

## 348cc2d — 2026-04-29 — Memory strategy doc

### Added
- `skeleton/docs/MEMORY-STRATEGY.md` — documents the six persistence layers (`AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, specs, ADRs, persistent memory) and a decision tree for where any given fact belongs. Includes consultancy-specific guidance for per-client vs cross-client memory.

### Upgrade impact
- **Overwrite**: new file.

## a1c5736 — 2026-04-28 — `/spec-drift` skill

### Added
- `skeleton/.claude/skills/spec-drift/` — read-only audit that detects divergences between a committed spec and the current code, tests, and docs. Reports findings categorized by severity; does not fix.
- Recommended cadence: monthly per spec area.

### Upgrade impact
- **Overwrite**: skill directory.
- **Merge**: `skeleton/CLAUDE.md` skills table — add a row for `/spec-drift`.

## 4fac0ec — 2026-04-28 — Cost model and model tiering doc

### Added
- `skeleton/docs/COST-MODEL.md` — three-tier model recommendation (Haiku / Sonnet / Opus), per-skill recommendations, per-agent recommendations, prompt-caching strategy, cost attribution patterns for consultancies, tool integrations (Anthropic Console, Helicone, LiteLLM), budget enforcement guidance.

### Changed
- Agent frontmatter `model:` fields adjusted to match recommendations:
  - Haiku: `@code-reviewer`, `@security-reviewer`, `@architect`, `@ux-reviewer`
  - Sonnet: `@spec-writer`, `@test-runner`, `@debugger`

### Upgrade impact
- **Overwrite**: `skeleton/docs/COST-MODEL.md` (new file), all `.claude/agents/*` files (the `model:` field is framework-owned; if your team intentionally overrode it, document the override and re-apply after copying).

## 23f009c — 2026-04-28 — Eval framework for the framework itself

### Added
- Top-level `evals/` directory in the framework repo with static structural checks (bash + grep) and dynamic fixture-based AI-invocation evals.
- Currently 48/48 static checks passing.

### Notes
- Adopting projects do NOT get evals copied in by default. The pattern is documented in `evals/README.md` for teams that author custom skills / rules / spec patterns and want regression coverage.

### Upgrade impact
- **N/A for adopting projects** — framework-internal change. Optionally adopt the pattern for your custom artifacts; see `evals/README.md`.

## 965d253 — 2026-04-28 — Docs-first phase coverage in onboarding, examples, Antigravity guide

### Fixed
- Onboarding, worked examples, and Antigravity (`GEMINI.md`) guidance now explicitly cover the docs-first phase between tests and implement.

### Upgrade impact
- **Merge**: `skeleton/GEMINI.md` if your team uses Antigravity.
- **Overwrite**: docs/onboarding files.

## 8277b5d — 2026-04-28 — Cursor rules and agents extended to multi-perspective + docs-first

### Changed
- `.cursor/rules/*.mdc` files updated to reflect the multi-perspective spec model and the docs-first phase.

### Upgrade impact
- **Overwrite**: all `.cursor/rules/*.mdc` files.

## 9332f73 — 2026-04-28 — Docs-first delivery as a third discipline

### Added
- `/write-docs` skill — plans and writes pre-implementable user-facing docs (admin guides, API contracts, end-user copy defaults) BEFORE implementation.
- New phase added to the workflow between tests and implement; `/write-docs` skips cleanly when the spec has no pre-implementable docs.
- `docs:` commit prefix added to `git-workflow.md` for the new phase.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/skills/write-docs/`, `skeleton/.claude/rules/git-workflow.md`.
- **Merge**: `skeleton/CLAUDE.md` skills table.

## 2b22837 — 2026-04-27 — Multi-perspective spec model + repositioning

### Added
- Multi-perspective spec model: every spec captures input from all relevant roles (business, functional, security, accessibility, privacy, design, performance, testing, documentation, deployment, etc.) in one document. Mandatory sections enforced before approval.
- `skeleton/docs/SPEC-MODEL.md` — full structure and worked examples.
- `docs/scenarios/` playbooks (modifying-existing-feature, hotfix, refactor, debugging).
- `docs/examples/newsletter-signup/` end-to-end worked example on Next.js + Contentful + Vercel.

### Changed
- Framework repositioned from "starter kit" to "AI-Assisted Development Framework" in all user-facing materials. Repo slug `ai-dev-starter-kit` preserved for URL stability.

### Upgrade impact
- **Overwrite**: `skeleton/docs/SPEC-MODEL.md`, `specs/_template.md` (if unmodified by your team).
- **Merge**: `specs/_template.md` if customized; `AGENTS.md` and `CLAUDE.md` if your team's wording referenced "starter kit".

## 466d205 — 2026-04-26 — Anti-rationalization tables, verification gates, red flags

### Added
- Skills now include explicit anti-rationalization tables (common excuses for skipping a step → why they don't apply), verification gates, and red-flag patterns.

### Upgrade impact
- **Overwrite**: all `skeleton/.claude/skills/*/SKILL.md`.

## cd04fa6 — 2026-04-26 — Explicit plan-then-execute gates

### Added
- `/write-tests` and `/implement` skills now have explicit plan-then-execute gates: the AI presents a plan and waits for approval before writing tests or code.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/skills/write-tests/`, `skeleton/.claude/skills/implement/`.

## c68e165 — 2026-04-26 — TDD by committing tests before implementation

### Changed
- Workflow enforces committing tests before implementation. Tests are the verification contract that defines "done".
- `test:` commit prefix formalized in `git-workflow.md`.

### Upgrade impact
- **Overwrite**: `skeleton/.claude/rules/git-workflow.md`, affected skills.

## e447f90 — 2026-04-26 — Initial release

### Added
- Initial skeleton with 7 specialized AI agents, 11 workflow skills, 9 engineering standards (4 universal + 5 customizable), spec template, documentation templates, AGENTS.md / CLAUDE.md / GEMINI.md, Cursor compatibility, Antigravity compatibility.

### Upgrade impact
- **N/A** — this is the baseline.

## See also

- [`docs/UPGRADING.md`](docs/UPGRADING.md) — how to apply these changes to an existing project
- [`docs/SETUP.md`](docs/SETUP.md) — initial adoption
- [`README.md`](README.md) — what's in the skeleton
