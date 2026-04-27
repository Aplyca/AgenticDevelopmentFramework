# Scenario playbooks

One-page, situational guides for common day-to-day situations. Each playbook tells you **which workflow applies, which skills/agents to use, and the exact prompts** for that situation.

If you're not sure which one you're in, the table below picks one for you.

| You're about to... | Use this playbook |
|---|---|
| Build a brand-new feature from scratch | The full cycle in [ONBOARDING.md](../ONBOARDING.md) and the [worked example](../examples/newsletter-signup/) |
| Change behavior of a feature that already exists | [Modifying an existing feature](modifying-existing-feature.md) |
| Fix a production-breaking bug right now | [Hotfix](hotfix.md) |
| Restructure code without changing behavior | [Refactor](refactor.md) |
| Investigate why something is broken or behaves unexpectedly | [Debugging](debugging.md) |

## Format

Each playbook follows the same shape so you can find what you need quickly:

1. **When to use this** — and when *not* to (so you pick the right one).
2. **Steps** — numbered, with the prompt to type at each step.
3. **Common mistakes** — what teams get wrong on this scenario.
4. **Example** — a tiny scenario walked through.

## A note on stack

Examples use **Next.js + Contentful + Vercel** because that's the most common shape at our shop. The scenarios themselves are stack-neutral — only the file paths and command names change.
