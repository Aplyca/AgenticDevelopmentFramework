# Setup Guide

How to adopt the framework in a repository by hand. With Claude Code, the installer plugin does all of
this for you — `/adopt` inspects the repository, copies the skeleton and the modules you choose, fills
the placeholders from verified facts, configures the hooks, and opens a draft pull request. Install it
with [the install prompt](../README.md#with-claude-code--the-installer-plugin-recommended) in any Claude
Code session, or with these commands:

```bash
cd your-project
claude plugin marketplace add aplyca/AgenticDevelopmentFramework --scope project
claude plugin marketplace update aplyca
claude plugin install adf@aplyca --scope project
# then, in the repository:  /adf:adopt
```

`--scope project` turns the plugin on in this project only, through its committed
`.claude/settings.json` — teammates get it once they trust the folder, and every worktree of a hub project gets it. Without
`--scope`, Claude Code installs it for every project on your machine. To try it alone first, use
`--scope local`. From the desktop app's Code tab:
[the plugin's README § In the desktop app](../plugins/adf/README.md#in-the-desktop-app).

`/adf:adopt` recommends the **packaged** install by default
([decision 0018](decisions/0018-packaged-by-default.md)): the skills, agents, workflows, hook
scripts, and the framework's reference docs come from the pinned plugin, and the repository commits
only its own layer —
[§ Packaged install](#packaged-install-claude-code-only) lists what changes. The manual path below is
the same procedure, step by step, for the **committed** install, which a team that also uses other AI
tools, or Claude Code's cloud sessions, chooses instead.

**A new project with no code yet:** create the repository and one first commit holding what's there
(`git init -b main`, then `git add -A && git commit -m "chore: initial commit"`, with `--allow-empty`
for an empty folder), and adopt on a branch as below. Where a
step asks for facts, write the planned ones and mark each `<!-- planned: not in the repository yet -->`;
record the stack as ADR-0001 (`docs/architecture/decisions/`, status `proposed`). Once the first code
lands, run `/init-project` to replace the planned entries with verified facts.

## 1. Copy the skeleton (on a branch)

Copy from the newest release, which the project will pin: `git ls-remote --tags
https://github.com/aplyca/AgenticDevelopmentFramework 'v*'` lists them, and
`git clone --depth 1 --branch v<X.Y.Z> https://github.com/aplyca/AgenticDevelopmentFramework` gets one.

```bash
cd your-project
git switch -c docs/agentic-adoption
cp -Rn /path/to/AgenticDevelopmentFramework/skeleton/. .
python3 /path/to/AgenticDevelopmentFramework/scripts/build-committed.py .
```

The skeleton is the layer the project owns and edits. The machinery — 20 skills, 8 agents, 4
workflows, the hook scripts, and the four reference docs in `docs/` — has its source in the framework's
plugins, and `build-committed.py` writes the committed install's copies of it
([decision 0028](decisions/0028-plugins-are-the-source.md)). Neither step overwrites a file you already
have: `-n` skips it, and the script lists the ones it kept. Merge collisions (`README.md`,
`CONTRIBUTING.md`, `.claude/settings.json`) by hand — keep your content, add the skeleton's missing
sections.

Remove the layers your team doesn't use:

| Tool | Keep | Remove if unused |
|---|---|---|
| Every tool | `AGENTS.md` | — always keep |
| Claude Code | `.claude/` (its layer is `.claude/rules/claude-code.md`) | the directory |
| Antigravity | `AGENTS.md`, which it reads natively, and the `.agents/skills` link below | — |
| Gemini CLI | `.gemini/settings.json`, which points it at `AGENTS.md` | `.gemini/` |
| Cursor | `.cursor/rules/` | the directory |
| Custom skills, rules, or hooks that need regression tests | `evals/` | the directory (the common case) |

There's no `GEMINI.md` ([decision 0025](decisions/0025-no-gemini-md.md)): Antigravity reads `AGENTS.md` natively, and loads
a `GEMINI.md` beside it, so one would only repeat it. Antigravity reads skills from `.agents/skills`. The framework ships no symlinks, so link it to Claude
Code's skills yourself:

```bash
mkdir -p .agents && ln -s ../.claude/skills .agents/skills
```

Add to `.gitignore`: `.env` files, `.claude/settings.local.json`, `CLAUDE.local.md`, and
`.claude/worktrees/`.

## 2. Add the modules you need (optional)

| Module | When |
|---|---|
| `github` | The repository is on GitHub — PR template with traceability and constitution gates, issue forms, secret scan, base-branch policy |
| `git-hooks` | You want a `pre-push` gate for every git client, not only Claude Code |
| `clickup` | Requirements arrive as ClickUp tasks — ClickUp's MCP server and a read-only allowlist (install with `modules/clickup/install.sh .`, which merges) |
| `parallel-agents` | Several agent sessions work at once, each needing a running app |
| `docker` | The local stack runs on Docker Compose — `/dev-env` sets it up, gives each worktree its own stack, and diagnoses or resets it; destructive docker commands ask first (then run `modules/docker/install.sh .`, which merges its permission rules) |

```bash
cp -Rn /path/to/AgenticDevelopmentFramework/modules/<name>/files/. .
python3 /path/to/AgenticDevelopmentFramework/scripts/build-committed.py . --modules <name>
```

The second line adds the module's skills, which its plugin carries — `parallel-agents`' `/dispatch`,
`docker`'s `/dev-env` — and does nothing for a module without any. Each module's `MODULE.md` says what to customize. See [`modules/README.md`](../modules/README.md).

**Connecting a tracker or a service** — Jira, Linear, GitLab, Supabase, Vercel, Contentful — is a job
for the `adf-connect` plugin, not a module. Turn it on with `"adf-connect@aplyca": true` in
`enabledPlugins`, then run `/adf-connect:connect <service>`. It writes the project's `.mcp.json` entry
with safe defaults (read-only, never production, no credentials committed) and pre-approves only the
tools that read ([decision 0023](decisions/0023-plugins-by-concern.md)).

**Seeing the local environment's URL** — turn on `adf-dev` (`"adf-dev@aplyca": true` in
`enabledPlugins`, in either install) and set `LOCAL_URL` in `.claude/hooks/config.sh` (step 5). Its mod
draws a line above the prompt with the URL and whether it answers; with the parallel-agents module,
each worktree shows its own port from `READY_URL`. It needs Claude Code v2.1.287 or later in a
terminal, or the desktop app from v2.1.286 ([decision 0026](decisions/0026-display-only-mods.md)).

## 3. Fill in AGENTS.md — the file every tool reads

Replace every `[bracketed placeholder]` with facts you can point to in the repository (manifests,
lockfiles, CI config, `git log`). What you can't verify becomes `<!-- TODO(team): question -->`.

- **Project identity and stack**
- **Ground rules** — the day-to-day subset of the constitution
- **Delivery rules** — the base branch and protected branches
- **Boundaries & antipatterns** — frozen directories, generated code, append-only history, deliberate deviations
- **Coding conventions**, **project structure**, and the **quick reference** — commands exactly as typed

Keep it under ~200 lines; it loads in every session. In a monorepo, add a nested `AGENTS.md` in each
module whose rules differ (the template is in `.claude/skills/init-project/SKILL.md`) — nearest wins.

**No `CLAUDE.md`.** Claude Code reads `AGENTS.md` natively (v2.1.281 or later), and its own layer
from `.claude/rules/claude-code.md`. A `CLAUDE.md` or `CLAUDE.local.md` in the project or a folder above
it makes Claude Code read that file *instead of* `AGENTS.md` ([decision 0024](decisions/0024-agents-md-only.md)). Merge an existing
`CLAUDE.md` into those two files, then delete it.

## 4. Write the constitution

`docs/CONSTITUTION.md`: 5–10 real non-negotiables, who approves amendments. It overrides `AGENTS.md`
on conflict, so the two must agree — especially about branches and merge targets.

## 5. Configure the guardrails (Claude Code)

- **`.claude/hooks/config.sh`** — `PROTECTED_BRANCHES` (every permanent branch), `APPEND_ONLY_GLOBS`
  (e.g. migrations), `GENERATED_GLOBS` (add generated types), `CAREFUL_GLOBS` (the sensitive areas you
  list in `AGENTS.md` — any change there takes at least the careful lane), `ENV_TEMPLATE` if not
  auto-detected, `LOCAL_URL` (the URL the developer opens for the local check).
- **`.claude/settings.json`** — extend `permissions.allow` with your routine read-only commands. Keep
  the `ask` rules (pushes and pull-request actions need a human) and the `deny` rules (`.env` reads).
  On GitLab, add the `glab` equivalents of the `gh` rules.
- **`.claude/rules/`** — update the `<!-- CUSTOMIZE -->` sections and the `paths:` frontmatter of
  `architecture`, `ui-ux`, `deployment`, `performance`, `observability`; delete rules that can't apply.
  `code-quality`, `testing`, `security`, and `git-workflow` are universal.

The hooks need `jq` (or `python3`) on the PATH. See `.claude/hooks/README.md`.

## 6. Fill in the process documents

- **`CONTRIBUTING.md`** — keep the branching model you use (A: feature branches into `main`; B:
  integration branch + tagged releases), the status vocabulary for requesters, and an honest "what's
  enforced" section.
- **`docs/TRACKER-INTEGRATION.md`** — your tracker, its MCP server in `.mcp.json`, and a read-only
  allowlist from the server's real tool names. Delete the page if requirements don't come from a tracker.
- **`docs/process/`** — record the adoption as `0001-adopt-ai-assisted-workflow.md` (why, what it
  adds, what it costs) and list it in the index.

## 7. Fill in the technical docs

Each customizable doc starts with `<!-- owner · last_updated · scope -->` — fill it and keep
`last_updated` current: it tells agents and people whether a doc is worth trusting and who to ask.

- `docs/ARCHITECTURE.md` — system context, components, data flow, stack rationale
- `docs/security/SECURITY.md` — authentication, authorization, data classification, threat model
- `docs/infrastructure/OVERVIEW.md` — hosting, environments, CI/CD, monitoring
- `docs/getting-started/DEV-SETUP.md` — including the one command surface people and agents share
- `docs/GLOSSARY.md` — domain terms
- `docs/reference/` — optional code-level pages for the hardest subsystems

### Customizing the spec model (optional)

`docs/SPEC-MODEL.md` and `specs/_templates/spec.md` ship with defaults for web projects. To change role
names, mandatory sections, or conditional rules, update the template, `docs/SPEC-MODEL.md`, and the
enforcement step in `.claude/skills/write-spec/SKILL.md` together. That takes the committed install:
in a packaged project, the spec model and `/adf:write-spec` come from the plugin.

## 8. Stamp, commit, and open a draft pull request

Fill the first line of `AGENTS.md`, the stamp:

```markdown
<!-- Skeleton source: <vX.Y.Z> · <SHA> (<YYYY-MM-DD>) · modules: <list or none> — … -->
```

`<vX.Y.Z>` is the release you copied from, and `<SHA>` its commit: `/adf:upgrade` diffs against it
later ([decision 0017](decisions/0017-semantic-versioning.md)). With the plugin, pin the same release
in `.claude/settings.json` — `"ref": "v<X.Y.Z>"` on the `aplyca` marketplace — so the plugin's copies of
the skills match your committed ones.

```bash
git add AGENTS.md .claude/ specs/ docs/ CONTRIBUTING.md README.md .claudeignore  # plus tool layers and modules you kept
git commit -m "docs: adopt the Agentic Development Framework (skeleton <SHA>)"
```

Open the pull request as a draft; merge after review like any other change.

## Packaged install (Claude Code only)

[Decision 0016](decisions/0016-packaged-install.md). The framework's machinery doesn't enter the
repository: 20 skills, 8 agents, 4 workflows, the hook scripts, the framework's reference docs
([decision 0019](decisions/0019-reference-docs-in-the-plugin.md)), and the `parallel-agents`
module's `/dispatch` ([decision 0020](decisions/0020-every-task-through-dispatch.md)) come from the
`adf` plugin, pinned to a release tag. A development module's skills come the same way from
`adf-dev` — `docker`'s `/dev-env` ([decision 0023](decisions/0023-plugins-by-concern.md)). The repository commits its own
layer as above, and every module's other files.
Choose it when the team works in Claude Code only. Cursor, Copilot, and Gemini users would get
`AGENTS.md` and the rules but no skills, and Claude Code's cloud sessions don't load the plugin.

It pins a release tag ([decision 0017](decisions/0017-semantic-versioning.md)):
`git ls-remote --tags https://github.com/aplyca/AgenticDevelopmentFramework 'v*'`. Pick the newest,
v1.0.0 or later; its entry in [`CHANGELOG.md`](../CHANGELOG.md) says what it brings.

**What changes from the steps above:**

1. **Copy less** (steps 1 and 2). Copy the skeleton, but don't run `build-committed.py`: the plugins
   carry the machinery, the modules' skills included. Leave out `.gemini/`, `.agents/`, and `.cursor/`.
   Modules copy as usual, except a module's scripts its `module.json` lists as `commands`, which the
   plugin carries in `bin/` ([decision 0027](decisions/0027-worktree-scripts-as-plugin-commands.md)):
   for `parallel-agents`, leave out everything in `scripts/agent/` but `worktree.conf`, the project's
   settings. Then point the files that name the reference docs at the release you pin, from the framework copy you took the skeleton from:
   `python3 <framework>/scripts/link-reference-docs.py . --packaged v<X.Y.Z>`.
2. **Wire the plugin, not the hooks** (step 5). Drop the `hooks` block from `.claude/settings.json`,
   since the plugin wires the same hooks, pin the marketplace to the release, and add the read rule to
   `permissions.allow`:

   ```json
   {
     "extraKnownMarketplaces": {
       "aplyca": {
         "source": { "source": "github", "repo": "aplyca/AgenticDevelopmentFramework", "ref": "v<X.Y.Z>" }
       }
     },
     "enabledPlugins": { "adf@aplyca": true },
     "permissions": { "allow": ["Read(~/.claude/plugins/cache/aplyca/adf/**)"] }
   }
   ```

   With a module whose skills `adf-dev` carries, turn that on beside `adf`, with its own read
   rule: `"adf-dev@aplyca": true` in `enabledPlugins` and
   `Read(~/.claude/plugins/cache/aplyca/adf-dev/**)` in `permissions.allow`.

   The hooks read `.claude/hooks/config.sh` from the project, so step 5's settings apply unchanged.
   The read rule lets the plugin's skills and agents open its reference docs: Claude Code asks before
   reading any file outside the project, the plugin's own folder included, unless a rule allows it.
3. **Tell people the names** (step 3). Everything a plugin carries goes by the plugin's name. Add this
   to the start of `.claude/rules/claude-code.md` § Skills, agents, and workflows:

   > **This project uses the packaged install.** Skills, agents, and workflows come from the
   > `adf` plugin, pinned in `.claude/settings.json`. Where these files name a skill or
   > workflow — `/triage`, `/deep-review` — type `/adf:triage`, `/adf:deep-review`.
   > Where they name an agent — `@code-reviewer` — its name is `adf:code-reviewer`. The
   > framework's reference docs — the spec model, the cost model, the memory strategy, MCP
   > integration — come from the plugin too; these files link them at the pinned release.
   > With the parallel-agents module, the worktree scripts are the plugin's commands: where these
   > files name `scripts/agent/worktree-new.sh`, `worktree-ls.sh`, or `worktree-rm.sh`, run
   > `adf-worktree-new`, `adf-worktree-ls`, or `adf-worktree-rm`.

   People read the key commands in `docs/getting-started/DEV-SETUP.md` § AI-assisted development,
   so write them there by their full names: `/adf:triage`, `@adf:code-reviewer`. A
   module's skills go by the name of the plugin that carries them: `/adf-dev:dev-env`. With the
   parallel-agents module, `AGENTS.md` § Quick reference lists the worktree commands by theirs:
   `adf-worktree-new`, `adf-worktree-ls`, `adf-worktree-rm`.

4. **Stamp the install** (step 8): `<!-- Skeleton source: v<X.Y.Z> · <SHA> (<date>) · modules: <list> · install: packaged — … -->`,
   with the pinned release and its commit. `install: packaged` is what turns the plugin's copies on.

**Verify** as below, with two differences. Pipe the hook samples to the plugin's scripts, with the
project and the plugin named: `CLAUDE_PROJECT_DIR="$PWD" CLAUDE_PLUGIN_ROOT=<marketplace folder>/plugins/adf <marketplace folder>/plugins/adf/hooks/guard-git.sh`,
where the marketplace folder is the `installLocation` of `aplyca` in
`claude plugin marketplace list --json`. And in a new session, `/adf:triage` is offered — and, with
the parallel-agents module, `adf-worktree-ls` lists the main checkout.

Each teammate gets the plugin, and the read rule, once they trust the folder. A machine nobody opens a
session on — CI — installs it first, from the repository's folder; a headless run (`claude -p`) never
trusts the folder, so pass the read rule with `--allowedTools` if it uses the plugin's skills:

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework#v<X.Y.Z> --scope project
claude plugin install adf@aplyca --scope project
claude -p "<the task>" --allowedTools "Read(~/.claude/plugins/cache/aplyca/adf/**)"
```

A job that uses `adf-dev`'s skills installs that plugin too, and passes its read rule:

```bash
claude plugin install adf-dev@aplyca --scope project
```

## Verify

- **Both instruction files load:** start a new Claude Code session and run `/memory` — `AGENTS.md`
  and `.claude/rules/claude-code.md` are listed. The session-context hook prints its lines, with no
  warning about a `CLAUDE.md`.
- **The hooks fire:** on `main`, ask the agent to `git commit --allow-empty -m test` — the git guard
  blocks it. Or test directly:
  ```bash
  printf '{"cwd":".","tool_input":{"command":"git push origin main"}}' | .claude/hooks/guard-git.sh; echo "exit $?"   # expect 2
  ```
- **Agents know the project:** `@code-reviewer review <a file>` cites your conventions.
- **No drift on day one:** run `/context-audit` once the files are filled in.

## Updating

Update the plugin from the adopted repository's folder, restart Claude Code, then run `/upgrade` there —
it plans the update from the baseline stamp, keeps your customizations, and prepares a draft pull
request:

```bash
claude plugin marketplace update aplyca
claude plugin update adf@aplyca
```

By hand, or to cherry-pick one change: [UPGRADING.md](./UPGRADING.md). Read each release's
**Upgrade impact** in the [CHANGELOG](../CHANGELOG.md) first.

## What not to customize

- **Skills, agents, workflows, and hook scripts** are framework-owned and replaced on upgrade. Put
  project specifics in `AGENTS.md`, the rules, and `.claude/hooks/config.sh` — that's
  where agents and hooks read them.
- **The workflow skill** (`spec-workflow`) is the shared process; project-specific workflow details
  belong in `AGENTS.md`, `CONTRIBUTING.md`, or a PDR.
