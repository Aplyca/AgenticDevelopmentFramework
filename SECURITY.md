# Security Policy

## Scope

This repository ships prompts, rules, hooks, permission settings, and templates that other teams copy into their own repositories and run with AI coding agents. A security issue here is anything in that material that could make an adopting project less safe, for example:

- A skill, agent, or rule that leads an AI agent to expose secrets, weaken authentication, or skip a security review.
- A hook in `skeleton/.claude/settings.json` that executes unsafe commands, or a permission allowlist broader than its stated intent.
- Behavior in the `adf` plugin (`/adf:adopt`, `/adf:upgrade`, or the hooks it carries) that writes, pushes, or discloses data without the user's approval.
- Guidance in `skeleton/docs/security/` or `skeleton/.claude/rules/security.md` that is incorrect in a way that introduces vulnerabilities.

Vulnerabilities in the AI tools themselves (Claude Code, Cursor, Copilot, and so on) should be reported to their vendors.

## Supported versions

The framework is versioned by commit rather than semver. Fixes land on `main`; adopting projects pick them up through the upgrade procedure in [`docs/UPGRADING.md`](docs/UPGRADING.md). Please verify an issue against the latest `main` before reporting it.

## Reporting a vulnerability

**Please do not open a public issue.** Report it privately instead:

1. Preferred: use GitHub's private vulnerability reporting — open the repository's **Security** tab and choose **Report a vulnerability**.
2. Alternatively, email **dev@aplyca.com** with "Security" in the subject line.

Include the affected files, the steps or prompts that reproduce the problem, which AI tool and model you used, and the impact you observed. We'll acknowledge your report, keep you informed as we investigate, and credit you in the fix's CHANGELOG entry unless you prefer otherwise.
