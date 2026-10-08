---
name: evaluate
description: Deep analysis of a question, proposal, or decision. Researches thoroughly, presents options with pros/cons/risks, and recommends an approach with rationale. Use when facing design decisions, tech choices, or when you want a second opinion on an approach.
argument-hint: "[question, proposal, or decision to evaluate]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/evaluate/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Evaluate

Perform a thorough analysis of a question, proposal, or decision. Research before responding. Present options, not just answers.

## Steps

1. **Understand the question** — What is being decided? What are the constraints? What's the context (project stage, team size, timeline, budget)?

2. **Research** — Before forming an opinion:
   - Read relevant project files (AGENTS.md, specs, existing code, rules)
   - Read `docs/ARCHITECTURE.md` and `docs/architecture/decisions/` for existing design decisions and constraints
   - Read `docs/security/SECURITY.md` and `docs/infrastructure/OVERVIEW.md` if the decision affects those areas
   - Search for established patterns, best practices, and prior art
   - Consider what professional teams do in similar situations
   - Look for data, benchmarks, or case studies when available

3. **Identify options** — List at least 2-3 viable approaches. For each option:
   - **Description**: what it is and how it works
   - **Pros**: concrete advantages (not generic)
   - **Cons**: concrete disadvantages (not generic)
   - **Risks**: what could go wrong, and how likely is it
   - **Effort**: relative implementation complexity (low / medium / high)
   - **Fit**: how well it aligns with the project's current state and constraints

4. **Compare** — Create a clear comparison:

   | Criteria | Option A | Option B | Option C |
   |---|---|---|---|
   | [Relevant criterion] | [Assessment] | [Assessment] | [Assessment] |

5. **Recommend** — State your recommendation clearly:
   - Which option and why
   - Under what conditions your recommendation would change
   - What to watch out for during implementation

6. **Invite challenge** — End with: "This is my assessment based on [what I researched]. If you have context I'm missing, let me know — it could change the recommendation."

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "Option A is clearly the best, no need to list alternatives" | Every decision has trade-offs. If you can't name alternatives, you haven't researched enough. |
| "This is what most projects use" | Popularity is not a reason. Explain why it fits THIS project's constraints, stage, and team. |
| "Let's go with the simpler option to save time" | Simpler isn't always better. If the simpler option creates tech debt or doesn't scale, the time saved is borrowed. |
| "I don't have enough information to recommend" | Then say what information you'd need and where to find it. An incomplete analysis with clear unknowns is more useful than no analysis. |

## Verification

- [ ] At least 2-3 options presented with concrete pros/cons
- [ ] Research included project-specific context (architecture docs, existing decisions, constraints)
- [ ] Recommendation includes rationale and conditions for changing it
- [ ] Trade-offs are honest — no option is presented as having no downsides

## Principles

- **Research first, opinion second.** Never lead with a gut feeling. Back up your position.
- **Honest trade-offs.** Every option has downsides. If you can't name them, you haven't thought hard enough.
- **Context matters.** The right answer for a PoC is different from a production system. The right answer for a 2-person team is different from a 50-person team.
- **Challenge the premise.** If the question itself is flawed or the developer's proposal has a fundamental issue, say so respectfully. "Have you considered that the real problem might be X rather than Y?"
- **No false balance.** If one option is clearly better, say so. Don't artificially inflate weaker options to seem thorough.
- **Acknowledge uncertainty.** If you don't have enough information to make a confident recommendation, say what you'd need to know to decide.

## Example invocations

```
/adf:evaluate Should we use PostgreSQL or MongoDB for this project?
/adf:evaluate Is it better to implement auth with NextAuth or a custom JWT solution?
/adf:evaluate The team wants to split the monolith into microservices — is that the right call?
/adf:evaluate I'm thinking of adding Redis for caching — what do you think?
/adf:evaluate Should we write unit tests or stick with e2e only for this PoC?
```
