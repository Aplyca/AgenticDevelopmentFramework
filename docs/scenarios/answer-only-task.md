# Scenario: Answer-only task — investigation, impact analysis, estimate

## When to use this

The task asks for an answer, not a change to the repository:

- "What would it take to move the newsletter to another email provider?"
- "Why did signups drop last week?"
- "Estimate topic selection before marketing commits to it."
- "Which pages break if we rename this CMS field?"

Triage says **Deliverable: answer**.

**Not this scenario:**

- The task asks for the change itself → the feature flow, or a [change request](change-request.md).
- You're diagnosing a bug you will then fix → [Debugging](debugging.md). If the task only asks *why*, the diagnosis is the answer and you're here.

## Why it has its own playbook

Feature work starts by setting things up: an environment, a spec folder, a plan. For an answer, all
of that is cost with no deliverable at the end — and an answer delivered as a spec folder with a
migration plan is the wrong deliverable, however thorough, because nobody has approved a change yet.

> **A cautionary tale.** On one project, a task asked for an impact analysis of a platform change:
> what changes, what it affects, what would have to be done. The agent built the application's
> container image, installed dependencies, created a spec folder, and wrote a migration plan — all
> before producing any analysis. The developer stopped it, and the analysis, the one thing the task
> asked for, came afterwards. None of the setup was used. That is what triage is for, and why the
> framework [made it the first step](../decisions/0004-triage-before-setup.md).

## Steps

1. **Triage** (`/triage`): deliverable answer; environment none — unless a step must run something
   (time a query, reproduce a race, count records), and then only for that step; spec folder none;
   open questions about what the answer must cover, where it goes, and by when.

2. **Read, don't build.** Start from the record: the feature's spec folder says what was decided and
   built (`plan.md`'s change surface is often half an impact analysis already), then ADRs and PDRs,
   `docs/reference/`, the code, `git log`, and the tracker thread. For breadth, read-only agents
   (`@architect`, `@debugger`) or `/orchestrate investigate`; for options with trade-offs,
   `/evaluate`.

3. **Run something only when a claim needs it**, and say what you ran. Whatever you didn't verify is
   listed as not verified.

4. **Write the answer for the person who asked**: the answer first, then the evidence (files, spec
   criteria, commands and their output), what wasn't verified, assumptions, open questions. An
   estimate states what it includes, what it excludes, and how confident it is. A recommendation
   says what would need approving.

5. **Deliver it where the task asks.** Usually the tracker task: a write the requester sees, so the
   developer sees the exact text first and it's posted only on their yes. A document in the
   repository when the task asks for one: a `docs:` commit, and a draft pull request when asked.

6. **If someone approves a recommended change**, it becomes a new task with its own triage — a new
   spec folder, or a `CR N` on the feature's folder. The spec links the analysis; it doesn't copy it.

## Example

Tracker task: *"Marketing is evaluating a move away from Mailchimp. What would it take on our side?
Impact analysis and a rough estimate by Thursday."*

**Triage**

```
Triage — Impact of switching email providers (https://tracker.example.com/t/MKT-530)
- Deliverable: answer — impact analysis and a rough estimate, on the task
- Kind: none yet — nothing is requested to change
- Environment: none — the spec folder, the code, and the docs answer it
- Spec folder: none. If marketing approves the move, it gets a spec (likely a CR on
  specs/007-newsletter-signup/) and an ADR superseding the provider decision
- Open questions: 1) Is a provider chosen, or should the answer stay provider-neutral?
  2) Do existing subscribers and their topic choices move too, or only new signups?
- Next: read specs/007-newsletter-signup/ (spec, plan, CR sections), the provider wrapper, the provider ADR
```

**The answer**, as shown to the developer before posting (excerpt):

```markdown
**Short answer:** about 3–4 days of engineering if the new provider has an equivalent of
interest groups; 1–2 more if it doesn't. Moving existing subscribers is a separate data task,
not included.

**What changes**
- The provider wrapper — the only module that calls the provider. It makes one add-or-update call
  that saves the chosen topics and never changes an existing subscriber's status (AC9, AC10). A
  provider without such a call needs a lookup before each signup.
- Topic mapping — each topic in Contentful stores the provider's interest-group ID (CR 1): a
  content-model change, and marketing re-mapping every topic.
- Two environment variables replaced — declared in .env.example and set on every environment.
- The admin guide's topics section and the runbook.

**Not affected:** the form, email validation, rate limiting, the Contentful copy.

**Not verified:** the new provider's API — none is chosen yet. Nothing was run.

**Question for marketing:** do current subscribers and their topic choices move with the list?
```

The developer reworded one sentence and approved; the agent posted it on the task. No environment, no
spec folder, no branch work.

## Commits it produces

None. The answer lives on the tracker task, and `git status` is clean. (With the parallel-agents
module, the worktree is removed with `worktree-rm.sh`.)

When the task asks for the analysis as a document in the repository, one commit:

```
$ git log --oneline main..docs/email-provider-impact
2f8c4d1 docs: add the email-provider switch impact analysis
```

## Common mistakes

| Mistake | What happens | Instead |
|---|---|---|
| Starting the environment "so it's ready" | Builds and installs for an answer that only needed reading | Start it when a step actually runs something |
| Creating a spec folder | A plan for a change nobody approved, with the answer buried in it | No folder until a change is approved |
| Writing the migration plan instead of the analysis | The requester gets a solution to a decision they haven't made | Answer the question asked; recommend, don't plan |
| Unverified claims stated as fact | Decisions made on guesses | Say what you ran and what you didn't |
| Posting on the tracker without showing the text | A message the requester reads under the developer's name, unreviewed | Show the exact text; post on an explicit yes |
| An estimate without assumptions | A number that turns into a commitment | State inclusions, exclusions, and confidence |
| Copying the analysis into the later spec | Two versions drift | Link it |

**Reference:** [`/triage`](../../plugins/adf/skills/triage/SKILL.md) ·
[`/evaluate`](../../plugins/adf/skills/evaluate/SKILL.md) ·
[tracker rules for agents](../../skeleton/docs/TRACKER-INTEGRATION.md)
