# Setup Guide

How to adopt the framework in a repository by hand. With Claude Code, the installer plugin does all of
this for you — `/adopt` inspects the repository, copies the skeleton and the modules you choose, fills
the placeholders from verified facts, configures the hooks, and opens a draft pull request:

```bash
claude plugin marketplace add aplyca/AgenticDevelopmentFramework
claude plugin install aplyca-framework@aplyca
# then, in the repository:  /adopt
```

That installs the plugin for every project on your machine. For this project only, run both
commands from its folder with `--scope project` (committed, so the team is offered it — the right
choice when the project uses the dispatcher hub, since every worktree gets the setting) or
`--scope local` (only you).

The manual path below is the same procedure, step by step.

## 1. Copy the skeleton (on a branch)

```bash
cd your-project
git switch -c docs/agentic-adoption
cp -Rn /path/to/AgenticDevelopmentFramework/skeleton/. .
```

`-n` never overwrites a file you already have; merge collisions (`README.md`, `CONTRIBUTING.md`,
`.claude/settings.json`) by hand — keep your content, add the skeleton's missing sections.

Remove the layers your team doesn't use:

| Tool | Keep | Remove if unused |
|---|---|---|
| Every tool | `AGENTS.md` | — always keep |
| Claude Code | `CLAUDE.md`, `.claude/` | both |
| Antigravity / Gemini | `GEMINI.md`, `.agents/` | both |
| Cursor | `.cursor/rules/` | the directory |
| Custom skills, rules, or hooks that need regression tests | `evals/` | the directory (the common case) |

Add to `.gitignore`: `.env` files, `.claude/settings.local.json`, `CLAUDE.local.md`, and
`.claude/worktrees/`.

## 2. Add the modules you need (optional)

| Module | When |
|---|---|
| `github` | The repository is on GitHub — PR template with traceability and constitution gates, issue forms, secret scan, base-branch policy |
| `git-hooks` | You want a `pre-push` gate for every git client, not only Claude Code |
| `clickup` | Requirements arrive as ClickUp tasks — ClickUp's MCP server and a read-only allowlist (install with `modules/clickup/install.sh .`, which merges) |
| `parallel-agents` | Several agent sessions work at once, each needing a running app |

```bash
cp -Rn /path/to/AgenticDevelopmentFramework/modules/<name>/files/. .
```

Each module's `MODULE.md` says what to customize. See [`modules/README.md`](../modules/README.md).

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

**`CLAUDE.md` must keep `@AGENTS.md` as its first instruction.** When both files exist, Claude Code
reads `CLAUDE.md` *instead of* `AGENTS.md`; the import is what loads it.

## 4. Write the constitution

`docs/CONSTITUTION.md`: 5–10 real non-negotiables, who approves amendments. It overrides `AGENTS.md`
on conflict, so the two must agree — especially about branches and merge targets.

## 5. Configure the guardrails (Claude Code)

- **`.claude/hooks/config.sh`** — `PROTECTED_BRANCHES` (every permanent branch), `APPEND_ONLY_GLOBS`
  (e.g. migrations), `GENERATED_GLOBS` (add generated types), `CAREFUL_GLOBS` (the sensitive areas you
  list in `AGENTS.md` — any change there takes at least the careful lane), `ENV_TEMPLATE` if not
  auto-detected.
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
enforcement step in `.claude/skills/write-spec/SKILL.md` together.

## 8. Stamp, commit, and open a draft pull request

Fill the first line of `CLAUDE.md`:

```markdown
<!-- Skeleton source: <SHA> (<YYYY-MM-DD>) · modules: <list or none> — … -->
```

`<SHA>` is the framework commit you copied from. `/upgrade` diffs against it later.

```bash
git add AGENTS.md CLAUDE.md .claude/ specs/ docs/ CONTRIBUTING.md README.md .claudeignore  # plus tool layers and modules you kept
git commit -m "docs: adopt the Agentic Development Framework (skeleton <SHA>)"
```

Open the pull request as a draft; merge after review like any other change.

## Verify

- **Both instruction files load:** start a new Claude Code session and run `/memory` — `CLAUDE.md` is
  listed, with `AGENTS.md` coming in through the import. The session-context hook prints its lines.
- **The hooks fire:** on `main`, ask the agent to `git commit --allow-empty -m test` — the git guard
  blocks it. Or test directly:
  ```bash
  printf '{"cwd":"%s","tool_input":{"command":"git push origin main"}}' "$PWD" | .claude/hooks/guard-git.sh; echo "exit $?"   # expect 2
  ```
- **Agents know the project:** `@code-reviewer review <a file>` cites your conventions.
- **No drift on day one:** run `/context-audit` once the files are filled in.

## Updating

Update the plugin, restart Claude Code, then run `/upgrade` in the adopted repository — it plans the
update from the baseline stamp, keeps your customizations, and prepares a draft pull request:

```bash
claude plugin marketplace update aplyca
claude plugin update aplyca-framework@aplyca
```

By hand, or to cherry-pick one change: [UPGRADING.md](./UPGRADING.md). Read each release's
**Upgrade impact** in the [CHANGELOG](../CHANGELOG.md) first.

## What not to customize

- **Skills, agents, workflows, and hook scripts** are framework-owned and replaced on upgrade. Put
  project specifics in `AGENTS.md`, `CLAUDE.md`, the rules, and `.claude/hooks/config.sh` — that's
  where agents and hooks read them.
- **The workflow skill** (`spec-workflow`) is the shared process; project-specific workflow details
  belong in `AGENTS.md`, `CONTRIBUTING.md`, or a PDR.
