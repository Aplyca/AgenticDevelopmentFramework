# AI-Assisted Development Onboarding

A two-week path for a team adopting the framework: **multi-perspective spec-driven, test-driven,
docs-first development, with AI agents working under the same rules as people.** Week 1 takes one
feature from triage to a draft pull request in a practice repository; week 2 covers the situations
that make up most real work.

The exercises build the fictional feature from the [worked examples](examples/README.md) — a
newsletter signup form on a Next.js + Contentful + Vercel marketing site, submitting to Mailchimp —
in Claude Code. Tests mock both services, so nobody needs an account. With another tool, follow each
skill's `SKILL.md` by hand. Paths are the ones in your project; links go to the originals in
[`skeleton/`](../skeleton/).

## The workflow on one page

Each discipline prevents a different mistake: **specs written from every perspective** (business,
security, accessibility, privacy, testing, docs…) prevent building the wrong thing; **a plan approved
on its change surface** prevents touching the wrong files; **tests that fail first** prevent false
confidence; **docs first** prevent shipping what nobody can use; **guardrails** keep pushing,
publishing, and posting waiting for a person.

**Every task starts with triage** (`/triage`): read the task in full, check for prior work, and state
the deliverable (an answer or a change), the kind, the **lane**, and whether an environment is needed.
Most waste happens in the first minutes — an environment built or a spec written for a task that
wanted an answer or a one-line fix, or delivered work re-analyzed from scratch.
([decision 0004](decisions/0004-triage-before-setup.md))

**The lane follows risk and uncertainty, not size** ([decision 0011](decisions/0011-lanes-ceremony-follows-risk.md)):

- **Fast** — a precise request (or a bug with a clear cause), a few files, no risk trigger: restate it
  with "done when…", the test first (watch it fail), then the edit, `/commit`. On delivered work, a light `CR N` entry.
- **Careful** — the same in a risk area — a migration, authorization, personal data, a shared
  contract, infrastructure, or one of the project's sensitive areas: plus that area's checklist and
  your yes on the risky part.
- **Full** — something to decide, a new feature, cross-layer work: the flow below.

What finds defects — a test that proves the change, the hooks, CI, review, your QC on the preview —
runs in every lane. **Your intuition sets the lane too:** "full lane on this" or "be careful here" is
always honored; "just a quick fix" never silently drops a risk area's checklist. Other ways to ask for
more effort — questions first, `/evaluate`, a higher effort level or model, `/deep-review` — and what
each costs are in the skeleton's `docs/COST-MODEL.md` § Effort.

The full lane flows:

| Step | Skill | Output | Commit |
|---|---|---|---|
| Specify | `/write-spec` | `spec.md` — WHAT and WHY from every role; required sections enforced | — |
| Plan | `/write-plan` | `plan.md` (**change surface**, test strategy, docs plan, assumptions) and `tasks.md` (one task per commit, each naming its test); `@spec-analyzer` checks non-trivial work | — |
| **Approval gate** | `/write-plan` | You approve scope, change surface, and assumptions → `status: approved` | `spec:` |
| Docs first | `/write-docs` | Pre-implementable docs; skips cleanly when there are none | `docs:` |
| Implement | `/implement` | Per task: test → watch it fail → code → green → commit | `feat:` / `fix:` per task |
| Verify | `/implement`, `/review` | Docs reconciled; evidence in `tasks.md` § Gate results | `docs:` |
| Local check | You, on the local environment | You test the change by hand and approve it | — |
| Deliver, on your approval | `/open-pr` | A **draft** pull request: spec folder, tracker task, verified / not verified, and your local check | — |
| Close the loop, when asked | `/stakeholder-update` | The requester's update, shown to you first | — |

It all lives in `specs/NNN-<slug>/` (`spec.md`, `plan.md`, `tasks.md`), copied from
`specs/_templates/`; the slug joins folder, branch (`<type>/<slug>`), and pull request.
([`specs/README.md`](../skeleton/specs/README.md), [decision 0001](decisions/0001-spec-folders-as-record-of-intent.md))

Why it's shaped this way:

- **One gate, after the plan.** Approving a spec alone checks the wrong thing: convincing analyses are
  most often wrong about *which files and layers a change touches*, and that is only known once the
  plan exists. Before the first commit a wrong change surface is a sentence to fix; after it, a
  rewrite. ([0002](decisions/0002-one-approval-gate-on-the-change-surface.md))
- **A test fails before its code exists** — for the right reason: the missing behavior, not an import
  error. A test that never failed proves nothing; it may test what already exists, or nothing at all.
  ([0003](decisions/0003-tdd-at-task-granularity.md))
- **One task, one commit** — every step reviewable, revertible, and backed by a test that once failed.
- **Docs first** — describing use before code forces agreement on behavior while it's cheap to
  change, and docs left for "later" get skipped. They're reconciled when the build shows reality differs.
- **Drafts only.** "Ready" means a person exercised the change — opened the preview, clicked through.
  An agent can't claim that, so it opens drafts, reports what it verified and what it couldn't, and
  never marks them ready on its own — you do, or you ask it to after your QC.
  ([0005](decisions/0005-outward-actions-and-draft-prs.md))

Optional: contract-first acceptance tests — end-to-end tests encoding the criteria, committed red
(`test:`) before the task loop.

## Which workflow applies

| The task is… | Lane | Do this | Spec folder |
|---|---|---|---|
| A typo, copy edit, version bump, dev-only tooling; a precise adjustment the requester already decided | Fast | Edit → targeted test → `/commit` | None — or a light `CR N` when it changes recorded behavior |
| The same, in a risk area or sensitive area | Careful | Fast + the area's checklist + your yes | None — or a light `CR N` |
| A new feature, or a change request with something to decide | Full | The full flow; a change request amends the folder with a `CR N` section, same gate | New / amend |
| A bug restoring documented behavior | Fast (careful in a risk area) | Regression test (watch it fail) → fix → `fix:`; `/debug` first if the cause is unclear | None |
| A bug whose fix changes documented behavior | By the change | A change request — light or full | Amend |
| A hotfix — production is broken now | Careful, without delay | `/debug` → fix + regression test → ship via the hotfix path in `CONTRIBUTING.md` | Backfill |
| A refactor | Fast, or full for a structure others follow | `/refactor`, green after every step → `refactor:` | None |
| An investigation, impact analysis, or estimate | — | Deliver the answer where the task asks | None |
| A change to how the team works | — | `/record-decision` (a PDR) | None |
| A spike or throwaway code | — | No workflow; promoted code gets a lane | — |

The test is **"is there anything to decide, and how risky is the area?"** — not "is it big?".
Ceremony on a typo teaches people to skip the process; a one-line change to an authorization check
still gets the careful lane; a one-line change with a real decision in it still gets a spec. An
answer that recommends a change gets a lane once someone approves the change.

## What's enforced, and what's a convention

Instructions are context: an agent usually follows them. The rules too costly to leave to "usually"
are configuration ([decision 0006](decisions/0006-guardrails-as-configuration.md)):

| Rule | Enforced by |
|---|---|
| Claude Code loads `AGENTS.md` — a `CLAUDE.md` or `CLAUDE.local.md` would replace it | The session-context hook warns when one is in the project or above it |
| No `--no-verify`; no commits on protected branches; no pushes, force-pushes, or deletes targeting them | `guard-git.sh` hook |
| No hand-edits of lockfiles or generated files; existing migrations never modified | `protect-paths.sh` hook |
| Environment variables the code reads are declared in the env template, when there is one | `check-env-declared.sh` hook — reports right after the edit |
| An edit in a sensitive area (`CAREFUL_GLOBS`) stops once per session so the agent confirms the lane | `careful-paths.sh` hook |
| The triage comes before the first change, in text you can read — a session's first edit or new branch with no lane stated stops once, as a reminder (a nudge, not a lock) | `triage-first.sh` hook |
| A person confirms marking a pull request ready, merges, reviews, issue writes, releases, GitHub API writes. Keeping the draft current — pushing, editing it, commenting on it — needs no prompt | `permissions.ask` · `permissions.allow` |
| Pull requests open only as drafts — the agent opens the draft itself once you approve the local check | `guard-git.sh` |
| `.env`, `.env.local`, and `.env.*.local` are never read into context | `permissions.deny` |
| `/stakeholder-update` starts from a plain request ("update the client"), and posts only after you approve the draft in chat | `disable-model-invocation` · the skill's steps |
| No pushes to protected branches, fast checks before every push — any git client, once enabled per clone | [`git-hooks` module](../modules/git-hooks/MODULE.md) |
| Secret scan and base-branch policy — advisory until a ruleset requires them | [`github` module](../modules/github/MODULE.md) |
| Reviews and checks before merge; no direct pushes | Branch protection on the Git host — the real boundary |

Everything above the module rows is Claude Code configuration; Cursor, Copilot, and other tools get
none of it. Hooks match the command text an agent writes, so they stop mistakes, not attackers.

**Conventions** — written in `AGENTS.md`, checked by reviewers, but nothing stops a skip: triage first;
choosing the lane (outside the sensitive areas, `/review` checks it after the fact);
**the approval gate** (`/implement` refuses without `status: approved`, so reviewers check the
`approvals:` line); red before green; one task per commit; docs first; never marking a pull request
ready; confirming tracker writes (mechanical only while the tracker's write tools stay off
`permissions.allow`); human review before merge, unless the host requires it. Write your project's
honest version in `CONTRIBUTING.md` § What's enforced.

## Before week 1: adopt the framework

One person, once:

1. Adopt the framework in your project — `/adopt` from the installer plugin, or [SETUP.md](SETUP.md)
   by hand. The result is a draft pull request: `AGENTS.md` and the constitution filled in, the hook
   configuration, the branching model and status words in `CONTRIBUTING.md`, the tracker integration,
   the modules you chose, and a first PDR recording why. (On an older version: [UPGRADING.md](UPGRADING.md).)
2. Run `/context-audit` on the result. It reports stale commands, wrong paths, and contradictions
   between files before they mislead anyone.
3. Create a **practice repository** for the exercises — a fresh Next.js app (any web stack works),
   adopted the same way, with an `.env.example`.

## Week 1: Fundamentals

### Day 1: Orientation and guardrails (2 hours)

Read, in your project — on the packaged install, the skills and the reference docs (`SPEC-MODEL.md`,
`COST-MODEL.md`, `MEMORY-STRATEGY.md`) come from the plugin: `AGENTS.md` links the docs at the pinned
release, and the originals are linked below:

1. `AGENTS.md` — the contract every AI tool reads: ground rules, how work flows, delivery rules,
   boundaries. ([original](../skeleton/AGENTS.md); 10 min)
2. `docs/CONSTITUTION.md` — the non-negotiables. It overrides `AGENTS.md`, so a stale line there does
   the most damage. (5 min)
3. `specs/README.md` and `docs/SPEC-MODEL.md` — when a spec folder is needed, the flow, change
   requests; a spec's required, conditional, and optional sections. The most important concept here.
   ([original](../plugins/adf/docs/SPEC-MODEL.md); 20 min)
4. `CONTRIBUTING.md` and your tool's layer — `.claude/rules/claude-code.md` or `.cursor/rules/`. (10 min)
5. The [`triage`](../plugins/adf/skills/triage/SKILL.md),
   [`write-plan`](../plugins/adf/skills/write-plan/SKILL.md), and
   [`implement`](../plugins/adf/skills/implement/SKILL.md) skills — above all their
   *Rationalizations* tables, the excuses agents (and people) make for skipping a step. (20 min)
6. `docs/COST-MODEL.md` and `docs/MEMORY-STRATEGY.md` — when to escalate a model, where a fact
   belongs (originals: [cost model](../plugins/adf/docs/COST-MODEL.md),
   [memory strategy](../plugins/adf/docs/MEMORY-STRATEGY.md)). `docs/TRACKER-INTEGRATION.md` if requirements arrive through a tracker. (15 min)
7. The worked example: [examples/newsletter-signup/](examples/newsletter-signup/). (20 min)

| Tool | Reads | Skills and agents | Rules | Hooks, permissions |
|---|---|---|---|---|
| Claude Code | `AGENTS.md`, and `.claude/rules/claude-code.md` | `/skill`, `@agent`, `/deep-…` workflows | `.claude/rules/`, by path | Yes |
| Cursor | `AGENTS.md` | Read the step's `SKILL.md` | `.cursor/rules/` | No |
| Antigravity | `AGENTS.md` | `.agents/skills/` (links to `.claude/skills/`) | `.agents/rules/` — it doesn't read `.claude/rules/` | No |
| Gemini CLI | `AGENTS.md`, through `.gemini/settings.json` | Read the step's `SKILL.md` | — | No |
| Copilot, Codex, others | `AGENTS.md` | Read the step's `SKILL.md` | — | No |

**Exercise — watch the guardrails fire**, in a Claude Code session in the practice repository:

1. Read the session-context lines at the top (checkout, branch, spec folder). Run `/memory`:
   `AGENTS.md` and `.claude/rules/claude-code.md` are listed.
2. On `main`, ask the agent to commit something — the git guard blocks it. Ask it to edit the
   lockfile by hand — blocked too.
3. On a work branch, ask for a server file that reads `process.env.MAILCHIMP_API_KEY`. The env hook
   reports it; the agent adds the name, without a value, to `.env.example`.
4. Ask it to push. Claude Code asks you first — decline.
5. Discuss which of these a teammate on Cursor would get.

### Day 2: Triage (1 hour)

Triage is a judgment stated openly so it's cheap to correct — not an approval. Write your own triage
for each task, then run `/triage` (add "triage only, then stop") and compare:

1. "We need a newsletter signup form on every article page. Copy editable in Contentful; submissions
   go to Mailchimp."
2. "How much work would it be to let readers choose newsletter topics?"
3. "The signup success message says 'subscibing'."
4. "Signups return a 500 on preview deployments."
5. "Readers should be able to pick topics when they sign up." (The signup shipped last month.)
6. "From now on, every pull request needs two approvals."

<details>
<summary>What triage should conclude</summary>

1. Change · new feature · environment later, for the tests · new spec folder · open questions: the
   success metric, what counts as a valid email, what visitors see when Mailchimp is down…
2. **Answer** — an estimate · no environment · no spec folder.
3. Change · **fast lane** — a one-line triage, edit, check, `/commit`.
4. Bug, cause unclear → `/debug`, then the lane the fix needs. A spec is touched only if the fix
   changes documented behavior.
5. **Change request** with something to decide (which topics? how chosen?) — the **full lane**:
   amend the signup's spec folder as `CR N`. Had marketing sent a precise list of topics and where
   they go, the fast or careful lane with a light `CR N` entry would do.
6. Process change → a PDR. The branch rules on the Git host are an admin's job.

</details>

### Days 3–4: First spec folder, up to the gate (3 hours)

One person drives; another plays marketing, the requester.

1. `/triage` task 1, then `/write-spec`. The requester answers the clarifying questions — the agent
   asks rather than guessing, because requirements come from people. Notice which sections became
   required: a form is UI (Accessibility); an email address is personal data (Privacy).
2. Before `/write-plan`, list the files and layers *you* expect to change. Compare your list with the
   plan's change surface and with what `@spec-analyzer` found when the skill ran it.
3. **The gate.** The approver — the developer, or whoever your team names (a good first PDR) —
   approves only when:
   - every acceptance criterion is numbered and testable, and *Out of scope* names what won't be
     built (double opt-in, say);
   - the change surface came from the code — shared code lists its other consumers, and what's *not*
     touched is stated;
   - every assumption is written down — an unstated assumption is how an invented requirement gets in;
   - every criterion maps to a named test, every task names its test, and no question is open.
4. On approval the agent sets `status: approved`, adds the `approvals:` line, and commits
   `spec: approve newsletter-signup scope and plan`. Nothing is pushed.
5. Compare with the example's [spec.md](examples/newsletter-signup/spec.md),
   [plan.md](examples/newsletter-signup/plan.md), and [tasks.md](examples/newsletter-signup/tasks.md).

### Day 5: Docs first, then the task loop (4 hours)

1. `/write-docs` — the admin guide to editing the form's copy in Contentful, committed (`docs:`)
   before any code.
2. `/implement`. Pair on the first two tasks: see each test fail before its code, and check *why* —
   an assertion about the missing behavior is red; module-not-found is broken scaffolding. After each
   commit, `git show --stat` lists the test, the code, and the tick in `tasks.md` — nothing else.
3. Mid-way, the requester asks for the form on the home page too. The agent should stop: new scope and
   a bigger change surface need your re-confirmation.
4. Read the *Gate results* in `tasks.md`: red then green per task, commands and counts, what couldn't
   run and why. A claim without evidence doesn't count.
5. Run `/review` and fix what it finds.
6. The local check: the agent starts the change on your machine and gives you the URL and what to
   try. Test it by hand and approve it.
7. With a remote, your approval opens the pull request: the agent runs `/open-pr`, and it opens as a
   draft. QC it yourself — the preview, if you have one — then mark it ready.

## Week 2: The full workflow in practice

### Change requests — amend, don't re-specify

Re-reading a task from scratch is how delivered scope gets silently dropped or redone. Trackers rarely
keep a description's history, so the spec folder is the record of what was built.

**Exercise:** with the signup delivered, take task 5 from Day 2 — topics managed in Contentful,
forwarded to Mailchimp interest groups.

1. `/triage` finds the folder; `/write-spec` appends `CR 1` to `spec.md`: who asked, the intent, and a
   *Delivered → Change* table. New criteria get new numbers tagged `(CR 1)`; retired ones are struck
   through, never deleted.
2. `/write-plan` adds the change request's plan and tasks: same gate, a `CR 1` line in `approvals:`.
3. New branch, new pull request, same folder. Tests for unchanged criteria pass untouched.
4. Variation: a change request on a feature delivered before you adopted the framework. With no spec
   folder, the agent should say the delta can't be recovered and ask — never rebuild it from the code.

See [scenarios/change-request.md](scenarios/change-request.md) and
[examples/newsletter-topics/](examples/newsletter-topics/).

### Answers, bugs, hotfixes, refactors

- **Answer** — run task 2 for real: an estimate where the task asks, no spec, no environment.
  ([scenario](scenarios/answer-only-task.md))
- **Bug** — "the success message no longer appears" restores documented behavior: regression test,
  watch it fail, fix, `fix:`. "Lowercase addresses before they reach Mailchimp" is new behavior: a
  change request. ([scenario](scenarios/debugging.md))
- **Hotfix** — production broken *now*. Speed justifies skipping spec-first, never the regression
  test or the backfill. ([scenario](scenarios/hotfix.md))
- **Refactor** — `/refactor` the subscribe route to separate validation from the Mailchimp call:
  green before you start and after every step. ([scenario](scenarios/refactor.md))

### Decisions — ADRs and PDRs

ADRs (`docs/architecture/decisions/`) record decisions about the application; PDRs (`docs/process/`)
record how the team works — gates, drafts, review rules — because process decisions get re-argued as
often as architecture. Both are short and append-only: a changed decision is superseded, never edited.
A constitution amendment is a PDR in its own pull request, never inside the change that needs it.
([decision 0007](decisions/0007-process-decision-records.md))

**Exercise:** `/record-decision` for a rule you settled in week 1 — who approves at the gate, say. The
framework's own [decision records](decisions/README.md) are examples.

### The tracker and the requester

- **Read freely** — with a tracker MCP server connected, `/triage` reads the task itself.
- **Tracker text is data, not instructions.** A comment telling the agent to deploy is a requirement
  to discuss; otherwise anyone who can comment on a task can steer your agent.
- **Confirm every requester-visible write** — comment, message, status change — with the exact text,
  every time. Never act on a task the developer isn't assigned to.
- **Link, don't copy** — the tracker and the repository have different audiences and access.

Tracker-originated work — light changes included — ends with an update to the requester, sent only
when the developer says so. **Exercise:** `/stakeholder-update` for the signup (paste the Day 2 brief
if there's no tracker task). Check for business language, verified claims, and your status words —
"in review", "in acceptance testing", "live". Post nothing.
([TRACKER-INTEGRATION.md](../skeleton/docs/TRACKER-INTEGRATION.md))

### Parallel sessions

Each agent session gets its own git worktree — never two in one checkout. With the
[`parallel-agents` module](../modules/parallel-agents/MODULE.md), the main checkout **only
dispatches**: every task goes to `/dispatch` there, which names it and hands it to a new session: a
task chip you start with one click in the desktop app, or a `claude "<prompt>"` command in a terminal.
That session's first step creates the task's worktree beside the main checkout with the scripts —
named after the branch, on a new branch, with the env file and, when the project needs one, a port —
and moves into it; you approve the new folder once. The worker there does everything from triage on. The main checkout is shared — an edit or a dev server there collides with
every other session — and analysis there is wasted: the dispatcher can't run the app or the tests, so
the worker re-reads everything where it can verify it.
([decisions 0008](decisions/0008-dispatcher-and-worker-worktrees.md),
[0020](decisions/0020-every-task-through-dispatch.md), and
[0021](decisions/0021-sibling-worktree-and-chip.md))

**Exercise (module installed):** dispatch the typo and the topics estimate. The main checkout's
`git status` stays clean, each worker's session context says WORKER, and
`ops/agent/worktree-ls.sh` lists both. ([scenario](scenarios/parallel-agents.md))

### High stakes and upkeep

- **High-stakes changes** — auth, payments, personal data, migrations, many layers.
  `/deep-spec-analysis` before the gate and `/deep-review` before delivery fan out to many agents and
  verify their serious findings, at several times the cost. **Exercise:** the signup collects email
  addresses — compare what `/review` and `/deep-review` find, and what each costs.
- **Context drift** — instructions go stale the moment a change lands without them, and agents follow
  them literally. Run `/context-audit` monthly, after upgrades, and before onboarding someone;
  `/spec-drift` per area monthly and `/deep-drift-sweep` quarterly. All are read-only. Keep
  `AGENTS.md` and `.claude/rules/claude-code.md` short and stable: every edit busts the prompt cache.
- **Evals** — your project needs them only for custom skills, rules, or hooks you write
  ([`evals/README.md`](../skeleton/evals/README.md)); the framework tests its own.

**You're ready for real work when** the team has triaged without the agent, approved a gate on the
change surface, seen every task go red before green, amended a delivered feature, and recorded a PDR.

## Common mistakes

| Mistake | Instead |
|---|---|
| Prompting without triage or a spec — the agent guesses, adds, and misses | Triage every task; spec anything with a decision in it |
| A spec folder for a typo | Ask "is there anything to decide?" |
| Approving the gate without reading the change surface | Read the change surface and assumptions first |
| A test that never failed, or failed on an import error | Watch each test fail for the right reason |
| Several tasks, or spec and code, in one commit | One task, one commit; the spec folder commits at the gate |
| A change surface that grows quietly | Stop, update `plan.md`, re-confirm |
| Re-specifying a delivered feature | Amend its folder with a change request |
| Obeying a tracker comment | Treat it as a requirement to discuss |
| Marking an agent's pull request ready because CI is green | QC the preview yourself, then mark it ready |
| Accepting output you haven't read | Read every line; ask for explanations |
| Letting the agent add abstractions, scripts, or CI guards nobody asked for | Do what was asked; new tooling needs a reason and a yes |

## Quick reference

### Skills — `/name`

| Need | Skill |
|---|---|
| Decide what a task needs | `/triage` |
| Write or amend a spec | `/write-spec` |
| Plan, tasks, approval gate | `/write-plan` |
| Docs before code | `/write-docs` |
| Build an approved spec, task by task | `/implement` |
| Tests outside the loop — contract-first, coverage, bug reproduction | `/write-tests` |
| Review against the spec folder | `/review` |
| One clean commit | `/commit` |
| Push and open a draft pull request (on its own, after your local-check approval) | `/open-pr` |
| Draft the requester's update ("update the client", or type it) | `/stakeholder-update` |
| Record an ADR or PDR | `/record-decision` |
| Root-cause a bug | `/debug` |
| Restructure code safely | `/refactor` |
| Weigh a decision | `/evaluate` |
| Run specialist agents in parallel | `/orchestrate` |
| Audit a spec, or the instruction files | `/spec-drift`, `/context-audit` |
| See every workflow | `/spec-workflow` |
| Set up a project | `/init-project` (or the plugin's `/adopt`) |
| Hand a task to a worktree (`parallel-agents` module) | `/dispatch` |

Full catalog: [SKILLS-REFERENCE.md](SKILLS-REFERENCE.md).

### Agents — `@name`

| Agent | For | Access |
|---|---|---|
| `@spec-writer` | Drafting or amending `spec.md` | Writes files |
| `@spec-analyzer` | An adversarial check of a spec folder before the gate | Read-only |
| `@architect` | A plan's design, boundaries, and data flow | Read-only |
| `@code-reviewer` | Quality, conventions, scope, evidence | Read-only |
| `@security-reviewer` | Injection, secrets, authorization, data handling | Read-only |
| `@ux-reviewer` | UI against the spec and UX standards | Read-only |
| `@test-runner` | Writing and running the tests that tasks name | Edits, runs commands |
| `@debugger` | Root-cause analysis | Runs commands, no edits |

Full catalog: [AGENTS-REFERENCE.md](AGENTS-REFERENCE.md).

### Workflows — `/deep-…` (Claude Code)

`/deep-review` (high-stakes diffs, before delivery) · `/deep-spec-analysis` (risky spec folders,
before the gate) · `/deep-context-audit` (every instruction file) · `/deep-drift-sweep` (every spec).

**Skill, agent, or workflow?** A skill for sequential work in your conversation (the cheapest); an
agent for an independent opinion, restricted tools, or parallel work; a workflow for a broad, verified
fan-out.

### Commit prefixes, in order

| Prefix | For |
|---|---|
| `spec:` | The approved spec folder; amendments — a change request, a plan correction, the PR link |
| `docs:` | Docs first; later reconciliation, gate results, backfill, ADRs and PDRs |
| `test:` | Contract-first acceptance tests committed red, or a test-only task |
| `feat:` / `fix:` / `refactor:` | One task — its test and its code together |
| `chore:` / `style:` | Tooling, dependencies, CI, formatting |

Branches are `<type>/<slug>`, after the spec folder's slug: `feat/newsletter-signup`.

## Working with AI effectively

- **Match the prompt to the task.** Nothing to decide: just say it ("fix the typo in the success
  message"). An approved spec: `/implement specs/007-newsletter-signup`. A design choice: `/evaluate`
  ("shared store or in-memory counters for the rate limiter?"). Unsure: ask for options. A big
  question: ask it to research before answering.
- **Be specific about the target and the output** —
  `@security-reviewer review app/api/newsletter/route.ts for rate-limit bypass, findings by severity`,
  not "check my code"; "does this satisfy AC3?", not "does this look right?".
- **Challenge it, and ask to be challenged** — "you recommended A; what about B?", "I'm planning X;
  what am I missing?".
- **Stay in control.** Read every line and push back when something feels wrong. It proposes; you
  decide — and anything irreversible or outward needs your explicit yes.
