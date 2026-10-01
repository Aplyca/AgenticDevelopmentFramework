---
name: orchestrate
description: Dispatch multiple specialized agents in parallel for review or investigation tasks. Faster and more thorough than running them sequentially in the main context. Use for thorough pre-merge reviews, multi-perspective investigations, or any analytical task where independent agents add value.
argument-hint: "[review | investigate | pre-commit | custom <description>]"
---

# Orchestrate (Parallel Multi-Agent Coordination)

Dispatch specialized agents in parallel for analytical tasks where independent perspectives add value. The skill plans which agents to run, runs them in parallel where dependencies allow, and synthesizes findings into a unified report.

## When to use

- **Thorough pre-merge review** — code + security + UX in parallel against a diff, faster than sequential
- **Multi-perspective investigation** — debugger + architect + security-reviewer looking at the same area through different lenses
- **High-stakes pre-commit gate** — when the change is meaningful enough to warrant the extra agent invocations
- **Complex bug triage** — parallel exploration of hypotheses

## When NOT to use

- **Trivial changes** — running 3 agents on a 1-line fix is waste (token cost > benefit). Use `/review` (single-context) for small diffs.
- **Phase progression** — this skill does NOT auto-run `/write-plan` → `/write-docs` → `/implement`. The approval gate and the per-task loop are deliberate human checkpoints. Use the explicit skills for those.
- **When you need a quick answer** — orchestration trades latency for thoroughness. Sequential is faster for simple tasks.

## What this is NOT

- **Not a "build the whole feature" command.** Each workflow phase has its own gate for a reason. Orchestration is for analytical/review work, not auto-progression.
- **Not a replacement for `/review`.** `/review` is a single-context multi-perspective review (lighter, faster). `/orchestrate review` dispatches separate agents (heavier, more thorough). Pick based on diff size and stakes.
- **Not a dynamic workflow.** This skill is model-driven: Claude plans, dispatches, and synthesizes in this conversation, and you approve the plan. The `/deep-*` workflows in `.claude/workflows/` are deterministic scripts — a fixed fan-out with adversarial verification of every finding — for when coverage and confidence matter more than cost: `/deep-review` (diff review), `/deep-spec-analysis` (pre-gate spec folder analysis), `/deep-context-audit`, `/deep-drift-sweep`.

## Built-in task types

| Type | Agents dispatched | Parallelism | Use when |
|---|---|---|---|
| `review` | `@code-reviewer`, `@security-reviewer`, `@ux-reviewer` (if UI changes) | All in parallel | Pre-merge review of meaningful diffs (>50 lines or critical paths) |
| `investigate` | `@debugger`, `@architect`, `@security-reviewer` (if security-relevant) | All in parallel | Multi-angle exploration of an issue or area |
| `pre-commit` | `@code-reviewer`, `@security-reviewer`, plus a scope check of the diff against the spec folder's approved change surface | Parallel | High-stakes commits (auth, payments, customer data) |
| `pre-gate` | `@spec-analyzer`, `@architect`, `@security-reviewer` (if security-relevant) on a spec folder | All in parallel | Before the approval gate on non-trivial or risky specs |
| `custom <description>` | User describes intent; skill picks agents | Determined by plan | Anything else |

## Steps

### Phase 1: Plan

1. **Identify scope** — what's being reviewed/investigated? Get the diff (`git diff`), the affected files, and any spec context.

2. **Pick agents** — based on the task type or user description. For `custom`, choose from the available specialized agents (`@code-reviewer`, `@security-reviewer`, `@ux-reviewer`, `@architect`, `@debugger`, `@test-runner`, `@spec-writer`, `@spec-analyzer`).

3. **Determine parallelism** — which agents can run independently (parallel) vs. which need each other's output (sequential)?

   Rule of thumb: review agents (code, security, UX) examining the SAME diff are independent → parallel. An agent whose input is another agent's output is dependent → sequential. Most review work is parallel.

4. **Determine model tiering** — each agent has a default model alias in its `agent.md` frontmatter. Don't override unless you have a specific reason. The defaults already tier sensibly:
   - `@code-reviewer`, `@security-reviewer`, `@ux-reviewer`, `@architect` → `haiku` (well-bounded review)
   - `@spec-writer`, `@test-runner`, `@debugger`, `@spec-analyzer` → `sonnet` (reasoning-heavy)
   See `docs/COST-MODEL.md` for the full per-agent recommendations and trade-offs.

5. **Present the orchestration plan**:
   ```
   Orchestration plan: review the diff for PR #142 (newsletter signup)

   Agents (parallel):
     - @code-reviewer (haiku)    — quality, conventions, complexity
     - @security-reviewer (haiku) — input validation, secret handling, rate-limit
     - @ux-reviewer (haiku)       — UI changes affect the form component

   Estimated cost: ~3 Haiku-tier invocations (~minimal)
   Expected wall-clock: <30s (parallel)

   Synthesis: I'll combine findings, deduplicate, sort by severity,
   present a unified report.
   ```

6. **Get approval** — wait for the user to approve the plan before dispatching. They can adjust agents, parallelism, or scope.

### Phase 2: Execute

7. **Dispatch in parallel** — invoke all parallel agents simultaneously. In Claude Code this means a single message with multiple Agent tool calls. The agents run in isolated context windows; their findings come back as summaries.

8. **Wait for all to complete** — don't proceed to synthesis until every dispatched agent has returned.

9. **Synthesize findings** — combine the agents' outputs into a unified report:
   - **Deduplicate** — if two agents flagged the same issue, surface it once with attribution
   - **Sort by severity** — Critical → Warning → Nit
   - **Group by file** — easier to action than scattered findings
   - **Note disagreements** — if `@code-reviewer` says "this pattern is fine" but `@architect` flags it as a layering violation, surface BOTH views

10. **Present the unified report** to the user. Include: total findings count, severity breakdown, agents consulted, any agents that returned no findings (so the user knows nothing was missed silently).

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll run them sequentially since it's simpler" | Sequential defeats the purpose of orchestration. If you wanted sequential, use `/review`. Parallel is the point — both for speed and for context isolation. |
| "I'll skip the plan and just dispatch" | The plan is the gate. The user needs to approve which agents and what scope before tokens are spent on multi-agent invocation. |
| "I'll auto-run /implement after the review passes" | NO. Phase progression is intentionally manual. This skill ends with a report, not action. |
| "I'll add `@spec-writer` to the review since it 'might catch something'" | Speculative agent inclusion is waste. Dispatch only the agents whose perspective is genuinely needed. Each agent costs tokens. |
| "I'll invoke the same agent twice for different angles" | If you need two perspectives, use two different agents. If only one agent applies, run it once. Re-invoking doesn't add signal; it just costs tokens. |
| "I'll synthesize by picking the agent I trust most and ignoring the others" | Disagreements between agents are signal. Surface them; let the user judge. The synthesis combines, it doesn't filter. |
| "The agents disagreed on severity, I'll average them" | Don't average opinions on findings. Show both views with their reasoning; the user picks. |

## Red flags (stop and reassess)

- **Dispatching more than 4 agents in parallel** — you're probably over-orchestrating. Pick the agents that matter.
- **Total findings count >50** — synthesis becomes overwhelming. Either the diff is too large for orchestration (split it) or the agents are over-flagging (tune their scope).
- **An agent returns "no findings" repeatedly across runs** — it shouldn't have been invoked. Refine the task-type defaults.
- **You feel tempted to dispatch agents in a loop ("if X, then dispatch Y")** — that's a different pattern (chained agents); this skill is single-pass parallel. Stop and design the chain explicitly.

## Cost considerations

Orchestration costs more than `/review` because each agent has its own context window and full system prompt overhead. For a typical PR review:

- `/review` (single context): ~5-10k input + ~2-5k output, mostly cached
- `/orchestrate review` (3 parallel agents, Haiku-tier): ~15-25k input + ~5-10k output (each agent independently)

Roughly 2-3× the cost. Worth it for high-stakes diffs; overkill for trivial ones. See `docs/COST-MODEL.md` for the full cost model.

## Verification

- [ ] Orchestration plan was presented and approved before dispatch
- [ ] Agents were dispatched in parallel where independent (single message with multiple Agent calls)
- [ ] All dispatched agents returned before synthesis began
- [ ] Findings are deduplicated, sorted by severity, grouped by file
- [ ] Disagreements between agents are surfaced (not averaged)
- [ ] Report names which agents were consulted (including any with zero findings)
- [ ] No phase-progression actions taken (e.g., did not auto-run `/implement` after `/orchestrate review` passed)

## Principles

- **Plan before dispatch.** Multi-agent invocations cost real tokens; the user approves the plan first.
- **Parallel is the point.** If you'd run them sequentially, use `/review` instead.
- **Synthesize, don't filter.** Combine all findings; surface disagreements; let the user judge.
- **Stop at the report.** This skill ends with findings. Action goes through the normal workflow.
- **Trust the agent defaults.** Each agent's `model:` is set deliberately — don't override casually.
- **No auto-progression.** The approval gate and the per-task loop are human checkpoints; orchestration is analytical, not progressive.
