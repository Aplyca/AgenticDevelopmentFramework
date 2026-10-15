# Worked examples

Two end-to-end walkthroughs of the framework's workflow on one fictional feature: a newsletter
signup form on a marketing site built with **Next.js (App Router), Contentful, and Vercel**, sending
subscribers to **Mailchimp**. The patterns carry over to any stack — only the file paths and code
idioms change.

| Example | What it shows | Files |
| --- | --- | --- |
| [newsletter-signup/](newsletter-signup/README.md) | **A new feature, start to finish.** Triage → a spec folder (`spec.md`, `plan.md`, `tasks.md`) → `@spec-analyzer` catching a change-surface problem → the approval gate, where the developer corrects an assumption → docs first → one red-then-green commit per task → reconciled docs → gate results → review → a draft pull request → the update to the requester | [README](newsletter-signup/README.md) · [spec.md](newsletter-signup/spec.md) · [plan.md](newsletter-signup/plan.md) · [tasks.md](newsletter-signup/tasks.md) |
| [newsletter-topics/](newsletter-topics/README.md) | **A change request on the delivered feature.** Triage finds the existing folder and computes the delta — half of it only in tracker comments → `CR 1` amends the same folder (new ACs AC7–AC10, AC4 struck through) → the same gate, for the delta only → per-task commits → a draft pull request — and what deliberately did not change | [README](newsletter-topics/README.md) · [spec-diff.md](newsletter-topics/spec-diff.md) · [plan-diff.md](newsletter-topics/plan-diff.md) · [tasks-diff.md](newsletter-topics/tasks-diff.md) |

**Reading order:** `newsletter-signup` first — the whole workflow on a new feature — then
`newsletter-topics`, the same feature three months later. The second is closer to what most
day-to-day work looks like.

## How to read an example

1. **Start with the README.** It is the narrative: what the developer typed, what the agent said
   and did, the decisions people made, and why each step exists. It quotes the key outputs — the
   triage statement, the `@spec-analyzer` report, the approval gate, red and green test runs, the
   pull request body, the message to the requester.
2. **Then open the spec folder.** `newsletter-signup/spec.md`, `plan.md`, and `tasks.md` are the
   folder exactly as it sits in the project at `specs/007-newsletter-signup/` after delivery. Read
   them in that order: what and why, then how and where (the change surface), then the commits and
   the evidence. The README files are walkthroughs, not part of the spec folder.
3. **For the change request, read the diffs against those files.** `spec-diff.md`, `plan-diff.md`,
   and `tasks-diff.md` show exactly what `CR 1` added, retired, and left alone in the same folder.

The files follow the templates in [`skeleton/specs/_templates/`](../../skeleton/specs/_templates/spec.md)
section by section, and the process in [`skeleton/specs/README.md`](../../skeleton/specs/README.md).
The spec model behind `spec.md` is [`plugins/adf/docs/SPEC-MODEL.md`](../../plugins/adf/docs/SPEC-MODEL.md).

## Conventions in these examples

- **Acceptance criteria keep their numbers for life.** The first delivery defines AC1–AC6; CR 1
  adds AC7–AC10 and strikes AC4 through instead of deleting it.
- **Task IDs are stable too.** The first delivery uses T000–T042; CR 1 starts at T100.
- **One task, one commit**, with two visible exceptions: `/write-docs` commits the docs-first tasks
  together, and a reconciliation that finds nothing to change has nothing to commit. Commit prefixes
  follow [`git-workflow.md`](../../skeleton/.claude/rules/git-workflow.md): `spec:`, `docs:`, then
  one `feat:` / `refactor:` / `test:` per task, then `docs:` again.
- **People are fictional**, and named only where it helps to follow the story: Dana (marketing
  lead, the requester), Lee (privacy lead), Sam (tech lead, the developer working with the agent).
  Other roles appear by title.
- **Links are placeholders.** `tracker.example.com` stands in for whichever tracker you use
  (ClickUp, Jira, Linear, GitHub Issues…); `github.com/<org>/marketing-site` for your repository.

## What the examples don't show

- **Real credentials, URLs, or IDs** — placeholders only.
- **Every line of code** — only the parts that show the workflow; assume the rest is ordinary
  Next.js.
- **A perfect session** — the agent's output is realistic, not idealized, and real sessions have
  more back-and-forth. But the stops are the same: the triage stated, the gate presented, the red
  seen before the green, the evidence recorded, nothing pushed until someone asks.
- **Runnable files** — test, doc, and implementation code appears as excerpts in the walkthroughs.

## When to come back to the examples

- **Onboarding** — pair a new team member through one example before their first feature.
- **Debating a workflow choice** — point at the example to ground the discussion in something
  concrete.
- **Changing a skill, rule, or template** — walk the example again to check the change still makes
  sense end to end, and update the example in the same pull request.
