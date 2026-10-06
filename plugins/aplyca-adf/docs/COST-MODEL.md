# Cost model and model tiering

How to manage AI development costs — tokens and time — in a project that uses this framework. Covers what a session actually costs, the lanes and the effort dials, the three model tiers, per-skill / per-agent recommendations, prompt caching, measuring, cost attribution, and tool integrations.

The framework is opinionated about WHEN to use which model and HOW to structure context for cache efficiency. Teams that follow these recommendations spend noticeably less than teams that default everything to Opus: at current list prices Sonnet costs about half as much per token and Haiku about a quarter, and a stable, cache-friendly context cuts input costs further. The overall saving depends on your mix of work — measure it rather than assuming a multiple.

## Why this matters

By 2026, AI engineering workflows are the #1 line item in many teams' LLM token spend. The difference between "default to Opus for everything" and "default to Sonnet, escalate to Opus only when needed, route triage through Haiku, cache aggressively" shows up directly in the monthly bill — roughly 2× per token from the Sonnet-vs-Opus choice alone, with prompt caching (cache reads bill at a tenth of the base input price or less) often mattering as much as the model choice.

For consultancies billing AI-assisted work to clients, cost attribution per feature/per project is also a billing requirement, not just an internal concern.

## What a session costs

Every call to the model re-reads the whole conversation — instructions, every message, every tool
output so far — mostly from the prompt cache. So a session costs roughly **number of calls × context
size**, plus the tokens the model writes. Measured on 48 sessions in two production projects
(September 2026, Opus 5 and 5.5):

| Measure | Value |
|---|---|
| Median cost per call | about $0.06 |
| Context at the first call | 46–66k tokens — Claude Code and its tools, the instruction files, memory. This framework's always-loaded instructions are about 5–7k of that |
| Where the money goes | about 47% re-reading cached context, 27% writing the cache, 17% output |
| Sessions under 30 calls | median about $1 and 10 minutes of activity |
| 30–100 calls | median about $4 and 35 minutes |
| Over 100 calls | median about $20 and 2+ hours |

What drives the bill, in order:

1. **The number of calls.** Every step — a file read, a test run, a question, a spec section — is a
   call. Ceremony that isn't needed adds calls; so do verification loops (re-running a whole suite,
   browser checks).
2. **The context size.** Long sessions and verbose output make every later call more expensive: in
   sessions over ~90 calls the average call carried 145–190k tokens, against ~60k at the start.
3. **Pauses longer than the cache lifetime.** The prompt cache expires about 5 minutes after its last
   use (Claude Code uses a longer-lived cache for some requests). After a longer wait — an
   unanswered question, a gate, a meeting — the next call writes the whole context again: about
   $0.75–1.20 for 150k tokens on Opus 5.5.
4. **The model** — Opus costs twice Sonnet for output and uncached input; cache reads cost the same
   (see the tiers below).

The framework's fixed overhead is small by comparison: the always-loaded instructions add a fraction
of a cent per call once cached, and the guardrail hooks take 60–140 ms per tool call against 5–10
seconds of model time.

## Lanes and what they cost

The lane (`specs/README.md` § Lanes) is the biggest lever a team controls. Typical ranges on Opus 5.5
at the measured $0.06–0.09 per call; Sonnet runs about 25–35% less:

| Work | Lane | Calls | Agent time | Cost |
|---|---|---|---|---|
| Typo, copy, a precise adjustment | Fast | 8–20 | 2–10 min | $0.5–1.5 |
| Bug with a clear cause | Fast | 15–30 | 5–15 min, plus test runtime | $1–2 |
| Either, in a risk area | Careful | fast + 5–15 for the checklist and confirmation | +5–10 min | $1.5–3 |
| Bug, cause unknown | `/aplyca-adf:debug`, then a lane | 30–60 | 15–40 min | $2–5 |
| Change request with something to decide | Full | 60–120 | 30–90 min, plus the wait at the gate | $5–12 |
| New feature | Full | 150–400 | hours | $10–40 |
| A `/deep-*` workflow run | Opt-in | 6–15 agents, each starting from a fresh context | — | $2–8 |

A precise adjustment pushed through the full lane costs 5–10× the fast lane, and the extra steps
record decisions nobody had to make: the tests, the review, and the human QC — the steps that find
defects — run in every lane.

## Effort — what to raise, and what it costs

A developer's intuition that a task needs more care is a valid input — triage honors any request to
raise effort. The dials are independent, so raise the one the intuition points at:

| Dial | How to ask | What it adds | Cost |
|---|---|---|---|
| **Lane** | "full lane on this", "be careful here" | Careful: the area's checklist and a confirmation. Full: spec, plan, gate | Careful: roughly +20–50%. Full: roughly 5–10× the fast lane |
| **Understanding** | "question my request first" | Clarifying questions before any code | One exchange — though a wait past the cache lifetime re-writes the context |
| **Design** | "compare approaches first" (`/aplyca-adf:evaluate`) | Options with trade-offs and a recommendation | One analysis pass, typically 10–30 calls |
| **Thinking** | The desktop app's effort selector or `effortLevel` in settings; `/model opus` | More reasoning per step | More output tokens per call; Opus doubles output and uncached input |
| **Verification** | "add edge-case tests", "`@aplyca-adf:security-reviewer` on this", "`/aplyca-adf:deep-review` before the PR" | Independent checks | A subagent starts from a fresh ~50–60k-token context; `/aplyca-adf:deep-review` runs 6–15 of them |

## Choosing between Sonnet and Opus

Pick the model by the kind of work, with the version-less aliases (`sonnet`, `opus`) — never a pinned
version. The test, from Anthropic's guidance for these models: **does the task have a clear spec and
a way to check the result?**

| Work | Model | Effort |
|---|---|---|
| Fast lane — a precise change proved by a test | `sonnet` | Default (medium) |
| Careful lane — the same in a risk area | `sonnet` | `high` |
| Bug fix, cause clear or found quickly | `sonnet` | Default; `high` for a stubborn one |
| Bug that resists two hypotheses; concurrency, caching, distributed state | `opus` | `high` |
| Investigation, impact analysis, estimate; reviews; drafting docs | `sonnet` | Default |
| Full lane: spec, plan, and the approval gate — ambiguity and judgment | `opus` | `high` |
| Full lane after the gate: `/aplyca-adf:write-docs`, `/aplyca-adf:implement` — an approved plan with named tests | `sonnet` | Default; `high` for a hard task |
| Architecture-level questions, long-horizon work across many files | `opus` | `high` |

- **Switch where the cache is cold or small.** Each model has its own prompt cache: after a switch,
  the next call re-reads the whole conversation uncached. Switch when the session starts, right
  after triage (the context is still small — `/aplyca-adf:triage` says when the model doesn't fit), or in a
  fresh session after the approval gate: the spec folder is the handoff, and the wait at the gate has
  usually let the cache expire anyway. Don't switch for a single step.
- **Effort before model.** Within Sonnet, `/effort high` for harder or longer work is often enough.
  `xhigh` and `max` make Sonnet think longer and cost more — at that point Opus is usually the
  better trade.
- **Claude Code's own `default` is Opus.** The project setting (`"model": "sonnet"`) covers new
  sessions, but the desktop app's picker and `/model` decide for a session — pick Sonnet for quick
  work. `opusplan` (Opus in plan mode, Sonnet otherwise) suits developers who plan in plan mode.
- **Subagents carry their own model** in frontmatter and run in their own context, so their choice
  costs no cache switch — reviews on `sonnet`, adversarial analysis and architecture on `opus` (see
  Per-agent recommendations).

## Keeping sessions cheap

- **One task per session; `/clear` before the next.** A fresh session starts at ~60k tokens; a long
  one can carry 200k+ on every call.
- **A 1M-context model is for work that needs it.** With a 1M window (e.g. `opus[1m]`) compaction
  happens late, so routine sessions grow far past what the task needs — and every call pays for it.
- **Keep output short.** Quiet test reporters, `| tail -n 40`, reading the lines you need. A log
  printed once is paid for on every later call.
- **Targeted tests while iterating, the full gate once** (`.claude/rules/testing.md` § Verification
  budget).
- **Browser checks by the agent only when asked or for a visual change.** In one measured bug fix,
  210 browser calls cost more than the rest of the session; the human QC on the preview is the check.
- **Ask together, then wait once.** Batch blocking questions into one round, each with a recommended
  answer; state minor implementation choices as assumptions in the pull request.

## Between phases — continue, clear, hand off, or compact

A task has phases: triage, spec and plan, implementation, review. Decide what happens to the
conversation at the boundary between two of them, never in the middle of one — compacting mid-phase
loses the thread. Ask in order; the first yes wins.

1. **Does the next phase need this conversation as it happened?** Continue. Triage → a fast-lane
   edit, or clarifying a spec → writing it: the reasoning is the input, and any summary of it loses
   something.
2. **Is everything here disposable?** `/clear` — a finished task, an unrelated next one. It's the
   cheapest move, and the old session stays resumable.
3. **Does the work travel** — to a teammate, another worktree, another tool? Write a short handoff
   (`/aplyca-adf:handoff`): what was decided, what's next, and pointers to the spec folder, branch, and pull
   request rather than copies of them. In the full lane after the approval gate, the spec folder
   already is the handoff: start a fresh session from it.
4. **Can the next step run unattended?** Give it to an agent (`@aplyca-adf:code-reviewer`, `/aplyca-adf:deep-review`): it
   works in its own context and returns a report, and this session stays as it is.
5. **Otherwise, `/compact`** — with an instruction about what the next phase needs
   (`/compact keep the open questions and the change surface`).

Switching the model follows the same logic: `/model opus` in place re-reads the conversation once,
uncached, but keeps all of it; a fresh session is cheaper only when files carry what the next phase
needs.

## Measuring

- **`/cost`** in Claude Code shows the current session.
- **The framework plugin's `/cost-report`** reads Claude Code's local transcripts for a project and
  reports each session's calls, active time, tokens, and estimated cost, with the patterns above
  flagged (long context, many waits, browser loops). Run it after a few weeks on a new lane setup
  to see what changed.
- **Track rework next to cost.** Reopened tasks, follow-up fixes, and review rejections per lane tell
  you whether the triggers are tight enough; adjust them with a PDR (`docs/process/`).

## The three tiers

This framework is built around three Claude model tiers. Use the right tier for the task — over-spec'ing wastes money; under-spec'ing produces worse output that costs more to iterate on.

| Tier | Model alias (current model, September 2026) | Use when... | Approximate relative cost (vs Haiku) |
|---|---|---|---|
| **Capable** | `haiku` (Haiku 4.5) | Narrow, well-bounded subagent work in a small context: classification, simple lookups, deterministic-ish checks | 1× (cheapest) |
| **Balanced** | `sonnet` (Sonnet 5.5) | Work with a clear spec and a way to check the result — fast and careful lanes, bug fixes, implementing an approved plan, investigation, review, drafting | 2× Haiku input and output |
| **Frontier** | `opus` (Opus 5.5) | Judgment — the full lane's spec and plan, ambiguous or long-horizon work, architecture decisions, bugs that resist diagnosis | 4× Haiku input and output |

Configure models with these aliases everywhere Claude Code takes one: `.claude/settings.json` (`"model": "sonnet"`), agent frontmatter (`model: haiku`), and `/model`. They're version-less — each resolves to the current model of its tier and moves forward as Claude Code updates, so keep Claude Code current with `claude update` (Sonnet 5.5 needs v2.1.284+, Opus 5.5 v2.1.280+). On Amazon Bedrock, Google Cloud, and Microsoft Foundry an alias can resolve to an older model (e.g. `sonnet` → Sonnet 4.5); pin the provider's model ID there with `ANTHROPIC_DEFAULT_SONNET_MODEL` / `ANTHROPIC_DEFAULT_OPUS_MODEL` / `ANTHROPIC_DEFAULT_HAIKU_MODEL`. Pin a full model ID (e.g. `claude-sonnet-5-5`) only when your team needs a fixed version.

> **Pricing changes** — ratios are from list prices per million input / output tokens as of September 2026: Haiku 4.5 $1 / $5, Sonnet 5.5 $2 / $10, Opus 5.5 $4 / $20. Sonnet 5.5 and Opus 5.5 use a newer tokenizer that produces roughly 30% more tokens than Haiku 4.5 for the same text, so per unit of work their gap to Haiku is somewhat wider than the per-token ratio. Cache reads cost $0.20 / MTok on both Sonnet 5.5 and Opus 5.5, so in cache-heavy sessions the Sonnet–Opus difference is mostly in output and uncached input. `fable` (Fable 5.1, $10 / $50, 10× Haiku) sits above these tiers; the decision rules below stop at Opus. Always check [current Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) before doing detailed cost projections. The decision rules below stay valid even as absolute prices shift.

### Decision rules

- **Default to Sonnet** for work with a clear spec and a way to check the result — most work, once the lanes route it.
- **Use Haiku** for well-defined, bounded work that runs in its own small context: subagents for convention checks and most reviews, classification, routing, simple lookups. Inside a long main conversation, switching to Haiku for one step costs more than it saves — the cache is per model.
- **Use Opus** where judgment is the work: the full lane up to the gate, ambiguous requirements, long-horizon changes, architecture, a bug that resists two hypotheses — and when Sonnet at `high` effort keeps producing inadequate output.
- **Don't escalate "just in case"** — Opus on tasks Sonnet handles well is pure waste. The framework's anti-rationalization tables, plan-then-execute gates, and verification checklists do most of the quality work that escalation would otherwise paper over.

### Switching tiers in Claude Code

- `/model` — built-in command to switch the session's model (e.g. `/model opus` before a hard reasoning task, then `/model sonnet` after). Switching mid-session means the new model reads the whole context uncached once — switch at the start of a task, not for a single step.
- Precedence — the desktop app's model picker and `/model` override the project's `.claude/settings.json`, which overrides user settings. A user-level `"model": "opus[1m]"` is a costly default for routine work.
- Agent frontmatter — set `model:` in an agent's `agent.md` to pin that agent to a tier regardless of the session default (aliases here too). Use it for work that should always run on a given tier, e.g. `@aplyca-adf:code-reviewer` / `@aplyca-adf:security-reviewer` on `haiku`.
- `/fast` — built-in Claude Code toggle (research preview) that runs Opus in a faster-output configuration. It is the same model — it does NOT downgrade to a smaller one — with up to ~2.5× faster output at premium pricing ($8 / $40 per MTok on Opus 5.5, vs $4 / $20 standard). Supported on Opus 5.5, Opus 5, and Opus 4.8, and only through the Anthropic API or subscription plans' usage credits (not Bedrock, Google Cloud, or Foundry). Turn it on at the start of a session: enabling it mid-conversation bills the whole existing context at the fast-mode uncached input rate. Useful when you're already on Opus for a hard problem and want quicker streaming; it's a per-user preference (`fastMode` in user settings), not a project-level setting.

## Per-skill recommendations

Skills run in your conversation, on its model. A skill could name its own model, but a switch mid-session re-reads the whole context uncached on the new model — so for skills the lever is the **session's** model: Sonnet for fast- and careful-lane sessions, Opus when a session is planning or debugging something hard.

| Skill | Recommended tier | Why |
|---|---|---|
| `/aplyca-adf:init-project` | Sonnet | Multi-perspective setup decisions; one-time so cost is small |
| `/aplyca-adf:triage` | Sonnet | Reading a task in full and deciding what it needs; cheap, and it prevents the most expensive mistakes |
| `/aplyca-adf:write-spec` | Opus | Full lane: ambiguity, clarification, and the decisions the spec records — judgment work |
| `/aplyca-adf:write-plan` | Opus | The change surface and test strategy decide everything downstream; the gate follows — then hand off to a fresh Sonnet session |
| `/aplyca-adf:write-tests` | Sonnet | AC → test mapping is moderate complexity |
| `/aplyca-adf:write-docs` | Sonnet | Synthesis from spec + tests; matters for tone and accuracy |
| `/aplyca-adf:implement` | Sonnet | An approved plan with named tests is a clear spec with a way to check the result; Opus for a task that turns out genuinely hard |
| `/aplyca-adf:review` | Sonnet | Multi-perspective review of diffs |
| `/aplyca-adf:debug` | Sonnet → Opus | Sonnet for most diagnoses; Opus after two disproven hypotheses, or for concurrency, caching, and distributed state |
| `/aplyca-adf:refactor` | Sonnet | Pattern extraction + maintaining test parity |
| `/aplyca-adf:commit` | Session model | A few short calls; switching to Haiku for them would re-read the whole context uncached |
| `/aplyca-adf:handoff` | Session model | A short message of pointers, written where the context already is |
| `/aplyca-adf:open-pr`, `/aplyca-adf:stakeholder-update` | Sonnet | Short, but every claim must be checked against the diff, the gate results, or the live site |
| `/aplyca-adf:record-decision`, `/aplyca-adf:context-audit`, `/aplyca-adf:spec-drift` | Sonnet | Reading and comparing many files; precision matters more than depth |
| `/aplyca-adf:evaluate` | Sonnet (or Opus for hard decisions) | Deep analysis with options and tradeoffs. The "evaluate" name implies the higher-value work where escalation often pays off. |
| `/aplyca-adf:spec-workflow` | n/a | Reference doc, no AI invocation |

**Practical guidance:** set your default to Sonnet and pick the model per session, by the work it will do. Escalate to Opus only when you hit the explicit triggers above.

## Per-agent recommendations

Agents have a `model:` field in their frontmatter, so the framework CAN enforce model choice for them. Current defaults in `.claude/agents/`:

| Agent | Current frontmatter | Why |
|---|---|---|
| `@aplyca-adf:spec-writer` | `model: sonnet` | Same reasoning as `/aplyca-adf:write-spec` skill |
| `@aplyca-adf:code-reviewer` | `model: sonnet` | Review is well-defined, repeatable work — where Anthropic's guidance places Sonnet; it costs about twice Haiku per token, a few cents per review |
| `@aplyca-adf:security-reviewer` | `model: sonnet` | Security review in the careful lane needs real reasoning about data flow; escalate to Opus for novel attack surfaces |
| `@aplyca-adf:test-runner` | `model: sonnet` | Test writing requires understanding the spec and matching patterns |
| `@aplyca-adf:architect` | `model: opus` | Architecture review weighs trade-offs across the system — judgment work; it runs rarely |
| `@aplyca-adf:debugger` | `model: sonnet` | Root cause analysis benefits from stronger reasoning |
| `@aplyca-adf:ux-reviewer` | `model: sonnet` | Review against the spec's stories, states, and accessibility — well-defined review work |
| `@aplyca-adf:spec-analyzer` | `model: opus` | Adversarial analysis of a plan is judgment work, and it runs once per full-lane folder, before the gate — where a missed problem is most expensive |

**To override** for a specific project, edit the agent's `agent.md` frontmatter. Document your override and why.

## Dynamic workflows

The `/deep-*` workflows in `.claude/workflows/` fan out to many agents — one per review dimension,
spec lens, file, or spec — and then spend more agents verifying each finding. A `/aplyca-adf:deep-review` of a
moderate diff typically runs 6–7 reviewers plus one verifier per finding: several times the cost of
`/aplyca-adf:review`, for higher coverage and fewer false positives. Use them where that trade pays — high-stakes
changes, pre-gate analysis of risky specs, periodic sweeps — and the single-context skills
everywhere else. Workflow agents inherit the session model unless the script pins one.

## Prompt caching strategy

Anthropic's prompt caching can reduce input cost by ~90% on cache hits (with a 5-minute TTL). To exploit it, structure context so the **stable prefix** (rarely-changing) comes BEFORE the **variable suffix** (per-message specifics).

### What's stable, what's variable

| Stable (cache prefix — put first) | Variable (cache suffix — put last) |
|---|---|
| AGENTS.md, CLAUDE.md | Current conversation messages |
| Loaded engineering rules (`.claude/rules/`) | Per-task spec / test / doc references |
| Loaded skill (`.claude/skills/<name>/SKILL.md`) | Tool call results from this turn |
| Long-lived memory facts | Active file edits |
| Reference docs (architecture, security, glossary) | |

### Practical rules to keep cache hit rates high

- **Don't edit AGENTS.md / CLAUDE.md / engineering rules continuously.** Each edit busts the cache for every subsequent request. Batch edits into a single PR.
- **Avoid putting per-feature volatile content in CLAUDE.md.** That belongs in the feature's spec or in memory. CLAUDE.md should describe the project's stable identity.
- **Memory entries are great for project-specific gotchas** that change occasionally — they evolve without busting the CLAUDE.md cache.
- **Subagents have their own cache.** A subagent invocation doesn't bust the parent's cache. Use them for anything that loads a lot of one-off context.
- **Long conversations get compacted automatically.** Cleared tool outputs cost nothing on subsequent turns. You don't need to manage compaction by hand, but be aware that it can change cache prefix length.

### Verifying cache behavior

Anthropic API responses include `usage.cache_creation_input_tokens` and `usage.cache_read_input_tokens`. If you see lots of `cache_creation` and few `cache_read`, your prefix is unstable. Investigate what's varying.

## Cost attribution patterns

For consultancies and multi-project teams, attributing tokens to features / projects / clients matters for billing and budgeting.

### Per-feature attribution

Tag each AI session with the feature spec name. Manually: include "working on spec: newsletter-signup" in your first message. Programmatically: API requests can include a custom `metadata.user_id` field that you can set to the spec name; aggregate by metadata at month end.

### Per-team / per-project attribution

Use **separate API keys per team or per project**. Anthropic Console attributes spend by API key automatically. This requires no code changes.

### Per-client attribution (consultancy pattern)

Use an **AI gateway** (Helicone, LiteLLM) that routes by client and tags every request with a client ID. The gateway aggregates spend per client and produces invoice-ready reports.

## Tool integrations

| Tool | Best for | Setup effort |
|---|---|---|
| **[Anthropic Console](https://console.anthropic.com)** | Built-in dashboards by API key. Zero setup. | None |
| **[Helicone](https://helicone.ai)** | Open-source LLM gateway. Per-request cost tracking, dashboards, custom properties for tagging. Free tier suitable for small teams. | ~30 min — proxy your Anthropic base URL through Helicone |
| **[LiteLLM](https://litellm.ai)** | Multi-provider proxy with budget enforcement, alerts, and routing rules. Open-source. | ~1 hour — deploy as a service, point clients at it |
| **[Braintrust](https://braintrust.dev)** | Eval-focused but tracks per-run cost. Good if you're already running dynamic evals (see `evals/`). | ~1 hour |
| **Custom (Anthropic API direct)** | Full control. Read `usage` from response headers, log to your own DB. | Variable |

For a typical consultancy or agency running AI-assisted work across several client projects, the recommended stack is:
- **Anthropic Console** for high-level monthly visibility (free, built-in)
- **Helicone or LiteLLM gateway** for per-client attribution and budget enforcement (when monthly spend is meaningful enough to justify the setup)

## Budget enforcement

| Level | What it does | When to use |
|---|---|---|
| **Soft alerts** (50%/80%/100% of monthly budget) | Email/Slack notifications when spend crosses thresholds | Always — easy and prevents surprise bills |
| **Hard limits at the gateway** | Refuses requests over the limit, returning 429 | When you've had a runaway-cost incident OR when client contracts cap spend |
| **Per-feature ceilings** | Manual approval if a single feature exceeds N tokens | Rarely — most features fit fine within reasonable limits; ceilings add friction |

Don't enforce per-feature ceilings by default — most features don't need them, and the friction outweighs the savings.

## Cost-conscious framework practices

The framework's structural choices already help cost. To get the most savings:

1. **Match the lane to the risk.** The full lane's plan-then-execute prevents expensive wrong paths where there's something to decide; for precise requests, the fast lane gets the same proof for a fraction of the calls.
2. **Use subagents for context-heavy work.** When you need to load a lot of one-off context (e.g., reading 20 files to answer one question), invoke a subagent with the right tools — it returns a summary, the parent's context stays clean, and your cache prefix stays stable.
3. **Keep sessions short.** One task per session, `/clear` between tasks, short tool output. Auto-compaction helps when a window fills, but a session that never grows that large is cheaper on every call.
4. **Use memory for repeated context.** Per-project gotchas, terminology, recurring patterns — these belong in memory (where they're loaded just-in-time) not in CLAUDE.md (where they bloat every request).
5. **Use the smallest model that works for the job.** Default to Sonnet, not Opus — chosen per session. Haiku belongs to subagents with small contexts.
6. **Run static evals in CI, not dynamic evals.** Static checks cost nothing. Dynamic evals cost real tokens — run them nightly or pre-release, not on every PR (see `evals/README.md`, if this project keeps evals).
7. **Cache aggressively.** Keep AGENTS.md / CLAUDE.md / rules stable. Batch edits. Don't put per-feature content in shared files.

## Quick reference: when costs spike

If your monthly bill jumps unexpectedly:

1. Check Anthropic Console for the timeline of the spike. Which day? Which API key?
2. Look at your gateway dashboard (if you have one) for the requests in that window — what tasks were being run? What models?
3. Common causes:
   - Someone defaulted their tool to Opus, or to a 1M-context model
   - Long sessions: many tasks in one conversation, or verbose logs and browser loops filling the context
   - Small changes routed through the full lane
   - A skill was modified and the cache prefix got reordered (cache hit rate drops, every request becomes cache miss)
   - Long-running agentic loops with no termination condition
   - Manual experimentation in the AI tool that was forgotten
4. Fix at the source. Don't add hard limits as a band-aid for an upstream problem.

## See also

- [`AGENTS.md`](../AGENTS.md) — project-wide AI conventions
- [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) — current rates
- [Helicone docs](https://docs.helicone.ai) — gateway setup
- [LiteLLM docs](https://docs.litellm.ai) — multi-provider proxy setup
