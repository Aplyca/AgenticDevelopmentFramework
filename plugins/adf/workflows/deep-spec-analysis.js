export const meta = {
  name: 'deep-spec-analysis',
  description: 'Analyze a spec folder from several independent lenses before the approval gate, verify each gap, and return a readiness verdict',
  whenToUse: 'Before asking the developer to approve a high-stakes spec folder (auth, payments, personal data, migrations, many layers). Argument: the spec folder path; defaults to the folder matching the current branch.',
  phases: [
    { title: 'Locate', detail: 'find the spec folder and read its status' },
    { title: 'Analyze', detail: 'independent lenses over spec, plan, tasks, and the code' },
    { title: 'Verify', detail: 'a skeptic tries to refute each critical finding and gap' },
  ],
}

const READ_ONLY = 'Do not modify, create, or delete any file. Read files and run read-only commands (git log, grep) only.'

// The spec model the lenses check against. The adf plugin's copy carries the model's text here
// instead: a packaged project keeps no copy of it in docs/ (decision 0019).
const SPEC_MODEL = "The spec model (SPEC-MODEL.md), which these checks follow:\n\n# Spec model\n\nThis project uses a **multi-perspective spec model**: every feature's `spec.md` captures input from\nall relevant roles in one document, with required sections enforced before the spec can go to\nplanning. The spec lives in a **spec folder** (`specs/NNN-<slug>/`) next to the `plan.md` that says\nhow it will be built and the `tasks.md` that breaks the plan into commits — see `specs/README.md` for\nthe process.\n\n| File | Answers | Written by |\n|---|---|---|\n| `spec.md` | WHAT and WHY — every role's requirements | `/adf:write-spec` |\n| `plan.md` | HOW — architecture, change surface, test strategy, documentation plan, assumptions | `/adf:write-plan` |\n| `tasks.md` | In what order, one commit at a time — each task names its test | `/adf:write-plan` |\n\n## Why this model\n\nMost spec templates capture only what the business wants. Real features need input from multiple\nroles — security, accessibility, design, deployment, documentation — and skipping any of them creates\nthe \"we forgot about X\" problem after launch:\n\n- The form that shipped without bot protection because security wasn't asked.\n- The page that's invisible to screen readers because accessibility wasn't asked.\n- The deploy that broke because nobody documented the new environment variable.\n- The feature nobody knows how to use because the docs were \"later\".\n\nThis model forces the conversation across all perspectives **before code is written**, while keeping\nthe spec readable and its diff useful.\n\n## Structure of spec.md\n\nSix parts. Sections are **required**, **conditional** (required when a frontmatter flag says so), or\n**optional** (filled only when relevant).\n\n### Part 1 — Intent (required)\n\n| Section | Status | Owned by |\n|---|---|---|\n| Business | Required | Client / PM |\n| Functional (user stories, numbered ACs, edge cases) | Required | Senior dev / tech lead |\n| Out of scope | Required | Senior dev / tech lead |\n\n### Part 2 — User experience\n\n| Section | Status | Owned by |\n|---|---|---|\n| Design | Optional | Designer |\n| Accessibility | Required if UI | A11y lead / designer |\n\n### Part 3 — Non-functional requirements\n\n| Section | Status | Owned by |\n|---|---|---|\n| Security | Required | Security lead / architect |\n| Privacy | Required if `personal-data: yes` | Privacy / legal / tech lead |\n| Performance | Optional | Tech lead |\n| SEO | Optional | SEO / marketing |\n| Analytics | Optional | Analytics lead / marketing |\n| Localization | Optional | Localization lead / tech lead |\n\n### Part 4 — Constraints\n\n| Section | Status | Owned by |\n|---|---|---|\n| Constraints & prior decisions (business rules, compliance, ADRs and PDRs to respect, reasoned constraints on HOW) | Optional | Tech lead |\n\nThe design itself — architecture, integrations, diagrams, the files that change — is not part of the\nspec. It lives in `plan.md`, and is approved together with the spec at the approval gate.\n\n### Part 5 — Validation & delivery\n\n| Section | Status | Owned by |\n|---|---|---|\n| Testing | Required | QA / tech lead |\n| Documentation (pre- and post-implementable) | Required | Tech writer / dev |\n| Observability | Optional | DevOps / SRE |\n| Deployment | Optional | DevOps |\n\n### Part 6 — Meta\n\n| Section | Status | Owned by |\n|---|---|---|\n| Clarifications | Required | Whoever wrote the spec |\n| References | Optional | Whoever wrote the spec |\n\n### Change requests\n\nWhen delivered work changes, the same `spec.md` gets a `CR N` section — intent plus a Delivered →\nChange table — and new acceptance criteria tagged `(CR N)`. Retired criteria are struck through, not\ndeleted. The folder stays the single record of the feature, before and after.\n\n## Mandatory enforcement\n\n`/adf:write-spec` **refuses to hand a spec to planning** while a required section is empty:\n\n**Always required:** Business · Functional (at least one numbered AC) · Out of scope · Security ·\nTesting · Documentation (both subsections) · Clarifications (may be an empty list, but it exists).\n\n**Conditionally required:**\n- **Accessibility** — when `feature-type` is `ui` or `mixed`. For `api`, `infra`, or `content`, mark `> Not applicable: [reason]`.\n- **Privacy** — when `personal-data: yes`. Collecting an email address counts.\n\n**Approval** happens later, at the gate in `/adf:write-plan`, once the change surface is known: the\ndeveloper signs off on scope, change surface, and assumptions together, and `status` becomes\n`approved` with an `approvals:` line.\n\n## How to \"fill\" a section\n\n1. **Concrete content** — requirements, mockup links, environment variables.\n2. **Standard rules apply** — `> Standard project [area] applies (see .claude/rules/[file].md). No additional requirements.` Common for Security and Accessibility on routine features.\n3. **Not applicable** — `> Not applicable: [one-line reason]`, only when the section truly doesn't apply.\n\nAll three count as filled. An empty section, or one holding only template text, blocks planning.\n\n## How the AI uses each section\n\n| Skill / agent | Reads |\n|---|---|\n| `/adf:write-spec` | All sections — orchestrates filling them and enforces the required ones |\n| `/adf:write-plan` | All sections — turns them into the change surface, a test for every testable requirement, and doc tasks |\n| `@adf:spec-analyzer` | The whole folder — every AC → task → test, constitution conflicts, change-surface gaps, unstated assumptions |\n| `/adf:write-tests` | **Functional** ACs and edge cases, **Testing**, and testable criteria from **Security**, **Accessibility**, **Performance**, **Privacy**, **Analytics**, **Localization** |\n| `/adf:write-docs` | **Documentation → Pre-implementable**, via the plan's documentation plan; ACs and planned tests are the source of truth for every claim |\n| `/adf:implement` | All sections, through `tasks.md` — every task's code satisfies the requirements its ACs and sections carry |\n| `/adf:review` | All sections — checks each requirement was actually met, inside the approved change surface |\n\n## The Documentation section: pre-implementable vs post-implementable\n\n**Pre-implementable docs** (written via `/adf:write-docs` before code):\n- Admin and operator guides\n- API contracts (OpenAPI, GraphQL schemas, public type signatures)\n- End-user help and copy defaults (often seeded into a CMS)\n- Public READMEs and SDK documentation\n\n**Post-implementable docs** (backfilled after code — they need real output):\n- Runbooks with real metrics, dashboards, and logs\n- Tutorials with real screenshots\n- Troubleshooting guides built from real failure modes\n\nBoth subsections must be filled or marked `Not applicable: [reason]`.\n\n## Which sections get filled for common feature types\n\n### Newsletter signup form (UI + form + third-party integration)\n\nFilled: Business, Functional, Out of scope, Design, Accessibility, Security, Privacy, Constraints &\nprior decisions (subscribers live only in the email provider), Testing, Documentation, Deployment,\nClarifications, References. Not filled: Performance (default applies), SEO (form not SEO-relevant),\nAnalytics (separate task), Localization (English only this iteration), Observability (default\napplies).\n\n### Health-check API endpoint (no UI, no personal data)\n\nFilled: Business, Functional, Out of scope, Security (\"Standard applies\"), Accessibility (\"Not\napplicable: no UI\"), Testing, Documentation, Observability, Clarifications.\n\n### CMS content-model change (field rename, no UI change)\n\nFilled: Business, Functional, Out of scope, Accessibility (\"Not applicable: no UI change\"), Security\n(\"Standard applies\"), Testing, Documentation, Deployment (schema change ordered before the code\ndeploy), Clarifications.\n\n### Analytics tracking on existing pages (integration only)\n\nFilled: Business, Functional, Out of scope, Security (\"Standard applies\"), Accessibility (\"Not\napplicable: no new UI\"), Privacy (tracking implications), Analytics, Testing, Documentation,\nDeployment (env vars), Clarifications.\n\n## Owners and handoffs\n\nThe `owners:` map in the frontmatter records who is responsible for each filled section:\nreviewers know who to ask, partial updates (only Security changed) go to the right person, and\nclarification questions route themselves. Role labels by default (`client`, `senior-dev`,\n`designer`, `tech-lead`, `qa`, `tech-writer`, `devops`, `security-lead`, `a11y-lead`, `privacy`);\nreplace them with names if your team prefers.\n\n## Frontmatter reference\n\n```yaml\n---\ntitle: \"\"\narea: \"\"                       # e.g. \"marketing\", \"auth\", \"checkout\"\nstatus: draft                  # draft → in-review → approved → implemented\nfeature-type: ui | api | infra | content | mixed\npersonal-data: yes | no        # collecting email/name/IP/etc. counts as yes\ntracker: \"\"                    # link to the requirement — never a copy of it\napprovals: []                  # \"YYYY-MM-DD · <who> · initial scope\" / \"… · CR 1\"\npull-requests: []              # \"<url> · initial delivery\" / \"<url> · CR 1\"\nowners:\n  business: client\n  functional: senior-dev\n  # one entry per filled section\nreferences:\n  figma: \"\"\n  adrs: []\n  pdrs: []\n  related-specs: []\n---\n```\n\n## When the model gets in the way\n\n1. **Ceremony on changes with nothing to decide.** A typo, a version bump, or a precise adjustment\n   the requester already decided needs no spec folder — it takes the fast or careful lane\n   (`specs/README.md` § Lanes), with a light `CR N` entry when it changes recorded behavior. The test is \"is there\n   anything to decide, and how risky is the area?\", not \"is it big?\".\n2. **Speculative filling.** Writing Performance and Deployment \"just in case\" is worse than leaving\n   them out. An absent optional section says \"this didn't apply\"; a guessed one says \"we didn't\n   really think about it\" while looking like we did.\n\n## Related\n\n- `specs/README.md` — the process: the lanes, the flow, the approval gate, change requests\n- `specs/_templates/` — the files to copy (`spec.md`, `plan.md`, `tasks.md`)\n- `docs/CONSTITUTION.md` — the gate every spec and plan is checked against\n- `.claude/skills/write-spec/`, `write-plan/`, `implement/` — the playbooks\n"

const LOCATE_SCHEMA = {
  type: 'object',
  required: ['specFolder', 'status', 'isChangeRequest', 'summary'],
  properties: {
    specFolder: { type: 'string', description: 'path to the spec folder, or empty string if none found' },
    status: { type: 'string' },
    isChangeRequest: { type: 'boolean' },
    summary: { type: 'string' },
  },
}

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings', 'checked'],
  properties: {
    checked: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'where', 'gap', 'evidence', 'fix'],
        properties: {
          severity: { type: 'string', enum: ['critical', 'gap', 'question'] },
          where: { type: 'string', description: 'file:line or section' },
          gap: { type: 'string' },
          evidence: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['refuted', 'reason'],
  properties: { refuted: { type: 'boolean' }, reason: { type: 'string' } },
}

const requested = typeof args === 'string' ? args.trim() : (args && args.specFolder) || ''

phase('Locate')
const located = await agent(
  `Locate the spec folder to analyze. ${READ_ONLY}
${requested ? `The user named: "${requested}".` : 'Use the folder in specs/ whose slug matches the current branch (<type>/<slug> ↔ specs/NNN-<slug>/).'}
Return its path, the status in spec.md frontmatter, whether its latest section is a change request (CR N), and a two-sentence summary of what it specifies.`,
  { label: 'locate', phase: 'Locate', schema: LOCATE_SCHEMA },
)

if (!located || !located.specFolder) {
  log('No spec folder found — nothing to analyze.')
  return { located, verdict: 'NO SPEC FOLDER', confirmed: [], questions: [] }
}

const folder = located.specFolder
const context = `Spec folder: ${folder} (status: ${located.status}${located.isChangeRequest ? ', latest section is a change request — analyze the CR against what was delivered' : ''}). Read spec.md, plan.md and tasks.md in full, plus docs/CONSTITUTION.md and specs/README.md. ${SPEC_MODEL} ${READ_ONLY}
Report only gaps you can evidence. Severity: critical = blocks approval (constitution conflict, AC with no task or test, missing layer in the change surface, invented requirement); gap = should be fixed before approval; question = only a human can answer.`

const LENSES = [
  { key: 'coverage', prompt: 'COVERAGE AND TRACEABILITY: every acceptance criterion (including CR-tagged ones) maps to a task that names a test; every task maps to an AC or states why not; every testable requirement in the filled Security, Accessibility, Privacy, Performance, Analytics and Localization sections maps to a test; every pre-implementable doc has a doc task.' },
  { key: 'change-surface', prompt: 'CHANGE SURFACE: search the code for the entities, routes, components, tables and functions the plan changes. Find callers, shared components, configuration, migrations, access policies and tests that plan.md does not list; list unlisted consumers of shared code; flag files named in tasks.md that are missing from the change surface table.' },
  { key: 'constitution', prompt: 'CONSTITUTION AND DECISIONS: read every principle in docs/CONSTITUTION.md and every accepted ADR (docs/architecture/decisions/) and PDR (docs/process/) the plan touches against the spec folder. Authorization changes, append-only history, dependencies, silenced types, accessibility, secrets.' },
  { key: 'consistency', prompt: 'CONSISTENCY AND ASSUMPTIONS: contradictions between spec, plan and tasks; requirements nothing backs (no tracker link, clarification, or stated requirement — plausible additions are the most dangerous); assumptions the plan relies on but does not list; open questions still open; for a change request, whether the Delivered → Change table matches what the spec records as delivered.' },
  { key: 'perspectives', prompt: 'MULTI-PERSPECTIVE COMPLETENESS: required sections filled for this feature-type and personal-data value (the spec model); "Not applicable" used with a real reason; no speculative optional sections; acceptance criteria numbered and independently testable; edge cases cover empty, error and boundary states.' },
]

const analyzed = await pipeline(
  LENSES,
  (lens) =>
    agent(`${context}\n\n${lens.prompt}`, { label: `analyze:${lens.key}`, phase: 'Analyze', schema: FINDINGS_SCHEMA }).then(
      (result) => ({ lens: lens.key, checked: result ? result.checked : 'analyzer did not return', findings: result ? result.findings : [] }),
    ),
  (analysis) =>
    parallel(
      analysis.findings.map((finding) => () => {
        if (finding.severity === 'question') return Promise.resolve({ ...finding, lens: analysis.lens, verdict: null })
        return agent(
          `Try to REFUTE this finding about ${folder}. ${READ_ONLY}
(${analysis.lens}, ${finding.severity}) at ${finding.where}: ${finding.gap}
Evidence given: ${finding.evidence}
Refute it if the spec folder or the code already covers it, or the evidence is wrong. Default to refuted=true when you cannot confirm it.`,
          { label: `verify:${analysis.lens}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ).then((verdict) => ({ ...finding, lens: analysis.lens, verdict }))
      }),
    ).then((findings) => ({ ...analysis, findings: findings.filter(Boolean) })),
)

const analyses = analyzed.filter(Boolean)
const all = analyses.flatMap((analysis) => analysis.findings)
const questions = all.filter((finding) => finding.severity === 'question')
const confirmed = all.filter((finding) => finding.severity !== 'question' && finding.verdict && !finding.verdict.refuted)
const refutedCount = all.length - questions.length - confirmed.length
const critical = confirmed.filter((finding) => finding.severity === 'critical')

const verdict = critical.length > 0 ? 'NOT READY' : confirmed.length > 0 ? 'READY WITH GAPS' : 'READY FOR THE GATE'
log(`${verdict}: ${critical.length} critical, ${confirmed.length - critical.length} gaps, ${questions.length} questions; ${refutedCount} findings refuted by verification.`)

return {
  specFolder: folder,
  verdict,
  lenses: analyses.map((analysis) => ({ lens: analysis.lens, checked: analysis.checked })),
  confirmed,
  questions,
  refutedCount,
}
