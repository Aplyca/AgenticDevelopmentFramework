# Cost model and model tiering

How to manage AI development costs in a project that uses this framework. Covers the three model tiers, per-skill / per-agent recommendations, prompt-caching strategy, cost attribution patterns, and tool integrations.

The framework is opinionated about WHEN to use which model and HOW to structure context for cache efficiency. Teams that follow these recommendations spend noticeably less than teams that default everything to Opus: at current list prices Sonnet costs about half as much per token and Haiku about a quarter, and a stable, cache-friendly context cuts input costs further. The overall saving depends on your mix of work — measure it rather than assuming a multiple.

## Why this matters

By 2026, AI engineering workflows are the #1 line item in many teams' LLM token spend. The difference between "default to Opus for everything" and "default to Sonnet, escalate to Opus only when needed, route triage through Haiku, cache aggressively" shows up directly in the monthly bill — roughly 2× per token from the Sonnet-vs-Opus choice alone, with prompt caching (cache reads bill at a tenth of the base input price or less) often mattering as much as the model choice.

For consultancies billing AI-assisted work to clients, cost attribution per feature/per project is also a billing requirement, not just an internal concern.

## The three tiers

This framework is built around three Claude model tiers. Use the right tier for the task — over-spec'ing wastes money; under-spec'ing produces worse output that costs more to iterate on.

| Tier | Model alias (current model, September 2026) | Use when... | Approximate relative cost (vs Haiku) |
|---|---|---|---|
| **Capable** | `haiku` (Haiku 4.5) | Routing, triage, well-bounded checks, drafting commit messages, simple lookups, deterministic-ish work | 1× (cheapest) |
| **Balanced** | `sonnet` (Sonnet 5.5) | Most engineering work — spec writing, test planning, implementation, code review, debugging, refactoring | 2× Haiku input and output |
| **Frontier** | `opus` (Opus 5.5) | Hard reasoning — complex architecture decisions, multi-step debugging, novel design problems, evaluating tradeoffs across many constraints | 4× Haiku input and output |

Configure models with these aliases everywhere Claude Code takes one: `.claude/settings.json` (`"model": "sonnet"`), agent frontmatter (`model: haiku`), and `/model`. They're version-less — each resolves to the current model of its tier and moves forward as Claude Code updates, so keep Claude Code current with `claude update` (Sonnet 5.5 needs v2.1.284+, Opus 5.5 v2.1.280+). On Amazon Bedrock, Google Cloud, and Microsoft Foundry an alias can resolve to an older model (e.g. `sonnet` → Sonnet 4.5); pin the provider's model ID there with `ANTHROPIC_DEFAULT_SONNET_MODEL` / `ANTHROPIC_DEFAULT_OPUS_MODEL` / `ANTHROPIC_DEFAULT_HAIKU_MODEL`. Pin a full model ID (e.g. `claude-sonnet-5-5`) only when your team needs a fixed version.

> **Pricing changes** — ratios are from list prices per million input / output tokens as of September 2026: Haiku 4.5 $1 / $5, Sonnet 5.5 $2 / $10, Opus 5.5 $4 / $20. Sonnet 5.5 and Opus 5.5 use a newer tokenizer that produces roughly 30% more tokens than Haiku 4.5 for the same text, so per unit of work their gap to Haiku is somewhat wider than the per-token ratio. Cache reads cost $0.20 / MTok on both Sonnet 5.5 and Opus 5.5, so in cache-heavy sessions the Sonnet–Opus difference is mostly in output and uncached input. `fable` (Fable 5.1, $10 / $50, 10× Haiku) sits above these tiers; the decision rules below stop at Opus. Always check [current Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) before doing detailed cost projections. The decision rules below stay valid even as absolute prices shift.

### Decision rules

- **Default to Sonnet** for any new skill or agent unless you have a specific reason to escalate or de-escalate.
- **Use Haiku** when the task is well-defined and bounded: classification, routing, formatting, drafting commit messages from a diff, simple lookups, structural verification (most reviews).
- **Escalate to Opus** when: (a) the task involves >5 interacting constraints to satisfy simultaneously, (b) the cost of a wrong decision is significantly higher than the cost difference, or (c) you've tried Sonnet and it consistently produces inadequate output. Most teams escalate <10% of work to Opus.
- **Don't escalate "just in case"** — Opus on tasks Sonnet handles well is pure waste. The framework's anti-rationalization tables, plan-then-execute gates, and verification checklists do most of the quality work that escalation would otherwise paper over.

### Switching tiers in Claude Code

- `/model` — built-in command to switch the session's model (e.g. `/model opus` before a hard reasoning task, then `/model sonnet` after).
- Agent frontmatter — set `model:` in an agent's `agent.md` to pin that agent to a tier regardless of the session default. Use this for `@architect`, `@evaluate`-style work that should always run on Opus, and for `@code-reviewer` / `@security-reviewer` that should always run on Haiku.
- `/fast` — built-in Claude Code toggle (research preview) that runs Opus in a faster-output configuration. It is the same model — it does NOT downgrade to a smaller one — with up to ~2.5× faster output at premium pricing ($8 / $40 per MTok on Opus 5.5, vs $4 / $20 standard). Supported on Opus 5.5, Opus 5, and Opus 4.8, and only through the Anthropic API or subscription plans' usage credits (not Bedrock, Google Cloud, or Foundry). Turn it on at the start of a session: enabling it mid-conversation bills the whole existing context at the fast-mode uncached input rate. Useful when you're already on Opus for a hard problem and want quicker streaming; it's a per-user preference (`fastMode` in user settings), not a project-level setting.

## Per-skill recommendations

Skills run in your main AI conversation, so they use whatever model your AI tool is set to. The framework can't enforce per-skill model choice — but it can recommend.

| Skill | Recommended tier | Why |
|---|---|---|
| `/init-project` | Sonnet | Multi-perspective setup decisions; one-time so cost is small |
| `/write-spec` | Sonnet | Multi-section reasoning + mandatory enforcement + clarification interrogation. Escalate to Opus only for genuinely complex/novel features. |
| `/write-tests` | Sonnet | AC → test mapping is moderate complexity |
| `/write-docs` | Sonnet | Synthesis from spec + tests; matters for tone and accuracy |
| `/implement` | Sonnet | Multi-file changes with multiple constraints. Escalate to Opus for >5 file changes or non-trivial architectural decisions. |
| `/review` | Sonnet | Multi-perspective review of diffs |
| `/debug` | Sonnet | Root cause analysis. Escalate to Opus for tricky bugs (race conditions, distributed-system issues, anything you've tried to fix twice) |
| `/refactor` | Sonnet | Pattern extraction + maintaining test parity |
| `/commit` | **Haiku** | Drafting a commit message from a diff is well-bounded — Haiku handles it fine |
| `/evaluate` | Sonnet (or Opus for hard decisions) | Deep analysis with options and tradeoffs. The "evaluate" name implies the higher-value work where escalation often pays off. |
| `/spec-workflow` | n/a | Reference doc, no AI invocation |

**Practical guidance:** set your default to Sonnet. Switch to Haiku for `/commit` (or just leave it on Sonnet — the cost is negligible). Manually escalate to Opus only when you hit the explicit triggers above.

## Per-agent recommendations

Agents have a `model:` field in their frontmatter, so the framework CAN enforce model choice for them. Current defaults in `.claude/agents/`:

| Agent | Current frontmatter | Why |
|---|---|---|
| `@spec-writer` | `model: sonnet` | Same reasoning as `/write-spec` skill |
| `@code-reviewer` | `model: haiku` | Code review against established conventions is well-bounded; Haiku handles it efficiently |
| `@security-reviewer` | `model: haiku` | Pattern-matching against OWASP-style checks; Haiku handles it. Escalate manually for novel attack surfaces. |
| `@test-runner` | `model: sonnet` | Test writing requires understanding the spec and matching patterns |
| `@architect` | `model: haiku` | **Trade-off** — Haiku is fast and cheap, but architecture review involves cross-cutting reasoning. Consider escalating to Sonnet if your team finds the agent missing important concerns. The framework defaults to Haiku because most architecture review is convention-checking; complex architecture decisions should use `/evaluate` instead. |
| `@debugger` | `model: sonnet` | Root cause analysis benefits from stronger reasoning |
| `@ux-reviewer` | `model: haiku` | Pattern-matching UI against spec ACs; Haiku handles it |

**To override** for a specific project, edit the agent's `agent.md` frontmatter. Document your override and why.

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

1. **Use plan-then-execute as designed.** Approving a plan before code is written prevents the AI from going down expensive wrong paths. Every wasted exploration costs tokens.
2. **Use subagents for context-heavy work.** When you need to load a lot of one-off context (e.g., reading 20 files to answer one question), invoke a subagent with the right tools — it returns a summary, the parent's context stays clean, and your cache prefix stays stable.
3. **Compact long conversations.** Most AI tools (Claude Code, Cursor) auto-compact when the context window fills. Don't fight it.
4. **Use memory for repeated context.** Per-project gotchas, terminology, recurring patterns — these belong in memory (where they're loaded just-in-time) not in CLAUDE.md (where they bloat every request).
5. **Use the smallest model that works for the job.** Default to Sonnet, not Opus. Use Haiku for well-bounded tasks like commit drafting.
6. **Run static evals in CI, not dynamic evals.** Static checks cost nothing. Dynamic evals cost real tokens — run them nightly or pre-release, not on every PR. (See `evals/STRATEGY.md`.)
7. **Cache aggressively.** Keep AGENTS.md / CLAUDE.md / rules stable. Batch edits. Don't put per-feature content in shared files.

## Quick reference: when costs spike

If your monthly bill jumps unexpectedly:

1. Check Anthropic Console for the timeline of the spike. Which day? Which API key?
2. Look at your gateway dashboard (if you have one) for the requests in that window — what tasks were being run? What models?
3. Common causes:
   - Someone defaulted their tool to Opus
   - A skill was modified and the cache prefix got reordered (cache hit rate drops, every request becomes cache miss)
   - Long-running agentic loops with no termination condition
   - Manual experimentation in the AI tool that was forgotten
4. Fix at the source. Don't add hard limits as a band-aid for an upstream problem.

## See also

- [`evals/STRATEGY.md`](../../evals/STRATEGY.md) — cost-conscious eval discipline
- [`AGENTS.md`](../AGENTS.md) — project-wide AI conventions
- [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing) — current rates
- [Helicone docs](https://docs.helicone.ai) — gateway setup
- [LiteLLM docs](https://docs.litellm.ai) — multi-provider proxy setup
