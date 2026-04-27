# Worked examples

Concrete, end-to-end walkthroughs of the spec → test → implement → review → commit cycle.

These examples use **Next.js (App Router) + Contentful + Vercel**, the most common stack at our shop. The patterns transfer to any stack — only the file paths and code idioms change.

| Example | What it demonstrates | Size |
|---|---|---|
| [newsletter-signup/](newsletter-signup/) | **New feature, full cycle** — uses the [multi-perspective spec model](../../skeleton/docs/SPEC-MODEL.md) end-to-end. Contentful-driven copy, form validation, API route with rate limiting, accessibility, observability, deployment coordination | 5 ACs + 6 edge cases, ~22 automated tests across Functional/Security/A11y/Privacy |
| [newsletter-topics/](newsletter-topics/) | **Modification cycle** (sequel to newsletter-signup) — adding optional Contentful-managed topic selection that forwards to Mailchimp interest groups. Highlights spec diff as scope, backwards-compat as a first-class concern, and rollout coordination with Contentful schema | 2 new ACs, 4 new edge cases, 7 added tests, 11 unchanged |

**Recommended reading order:** `newsletter-signup` first (the new-feature workflow end-to-end), then `newsletter-topics` (the same feature being modified — which is what most day-to-day work actually looks like).

## How to read an example

Each example folder contains:

1. **README.md** — narrative walkthrough. Read this first. Shows the prompts a developer types, the AI's responses, and the rationale at each step.
2. **spec.md** — the final, approved spec artifact (what gets committed under `specs/`).
3. **test-plan.md** — the AI's output during the planning phase of `/write-tests`. Shows AC → test mapping that the developer reviewed and approved before tests were written.
4. **implementation-plan.md** — the AI's output during the planning phase of `/implement`. Shows the file-by-file breakdown that the developer reviewed and approved before code was written.

Test code and implementation code are shown as snippets within the README, not as runnable files — these examples are illustrative, not executable.

## What examples don't show

- **Real Contentful credentials, API keys, or URLs** — replaced with placeholders.
- **Every line of code** — only the parts that illustrate the workflow. Pretend the rest is straightforward boilerplate.
- **The "perfect" output** — AI responses shown are realistic, not idealized. Real sessions involve back-and-forth and iteration.

## When to come back to the examples

- Onboarding a new team member — pair them through one example as a first exercise.
- Debating a workflow choice — point at the example to ground the discussion in something concrete.
- Updating a skill or rule — re-walk the example to check the change still makes sense end-to-end.
