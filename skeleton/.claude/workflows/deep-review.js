export const meta = {
  name: 'deep-review',
  description: 'Multi-agent review of the current branch against its spec folder; every finding is independently verified before it is reported',
  whenToUse: 'High-stakes or large changes before delivery (auth, payments, personal data, migrations, many layers). Several times the cost of /review. Optional argument: the base branch.',
  phases: [
    { title: 'Scope', detail: 'diff against the base branch, spec folder, dimensions that apply' },
    { title: 'Review', detail: 'one reviewer per dimension, in parallel' },
    { title: 'Verify', detail: 'a skeptic tries to refute each critical and warning finding' },
  ],
}

const READ_ONLY = 'Do not modify, create, or delete any file, and do not run commands that write, push, or install. Read files and run read-only git commands only.'

const SCOPE_SCHEMA = {
  type: 'object',
  required: ['base', 'files', 'specFolder', 'hasUI', 'hasDocs', 'summary'],
  properties: {
    base: { type: 'string', description: 'base ref the branch is compared against' },
    files: { type: 'array', items: { type: 'string' } },
    specFolder: { type: 'string', description: 'spec folder for this branch, or empty string' },
    hasUI: { type: 'boolean' },
    hasDocs: { type: 'boolean', description: 'the change includes or should include user-facing docs' },
    summary: { type: 'string' },
  },
}

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings', 'checked'],
  properties: {
    checked: { type: 'string', description: 'what this reviewer checked, in one or two sentences' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'line', 'severity', 'title', 'evidence', 'fix'],
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['critical', 'warning', 'nit'] },
          title: { type: 'string' },
          evidence: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['refuted', 'severity', 'reason'],
  properties: {
    refuted: { type: 'boolean' },
    severity: { type: 'string', enum: ['critical', 'warning', 'nit'] },
    reason: { type: 'string' },
  },
}

const requestedBase = typeof args === 'string' ? args.trim() : (args && args.base) || ''

phase('Scope')
const scope = await agent(
  `Scope a review of the current git branch. ${READ_ONLY}
Base ref: ${requestedBase ? `use "${requestedBase}"` : 'use the base branch named in CONTRIBUTING.md or AGENTS.md; otherwise the merge-base with the remote default branch'}.
Run git diff --stat <base>...HEAD and list every changed file. Find the spec folder whose slug matches the branch name (<type>/<slug> ↔ specs/NNN-<slug>/), or return an empty string.
Set hasUI if the change touches UI components or styles; hasDocs if it touches user-facing docs or the spec lists pre-implementable docs.
Summarize the change in two sentences.`,
  { label: 'scope', phase: 'Scope', schema: SCOPE_SCHEMA },
)

if (!scope || scope.files.length === 0) {
  log('No changes found against the base branch — nothing to review.')
  return { scope, confirmed: [], refuted: [], nits: [] }
}

const context = `Branch diff: git diff ${scope.base}...HEAD (${scope.files.length} files). ${scope.specFolder ? `Spec folder: ${scope.specFolder} — read spec.md (every filled section, including CR sections), plan.md (the approved change surface) and tasks.md (gate results).` : 'No spec folder matches this branch; review against AGENTS.md and the rules.'} ${READ_ONLY}
Report only real issues with concrete evidence (file and line). If the dimension has nothing to report, return an empty findings list and say what you checked.`

const DIMENSIONS = [
  { key: 'spec-compliance', prompt: `Review for SPEC AND SCOPE COMPLIANCE. Every acceptance criterion and every requirement from each filled spec section is implemented; nothing beyond the spec was built; every changed file is inside plan.md's change surface (or the extension is recorded and re-confirmed in approvals); no principle in docs/CONSTITUTION.md is violated.` },
  { key: 'correctness', prompt: `Review for CORRECTNESS. Logic errors, unhandled edge cases the spec lists, error handling, null and type guards at boundaries, race conditions, and regressions in callers or other consumers of changed shared code.` },
  { key: 'security', prompt: `Review for SECURITY using the checklist in .claude/agents/security-reviewer/agent.md: injection (HTML, SQL, shell, headers, paths), secrets in code or client bundles, validation at boundaries, authorization loosened or bypassed, error details leaked, risky new dependencies. If nothing is security-relevant, say so.` },
  { key: 'conventions', prompt: `Review for CONVENTIONS against AGENTS.md and .claude/rules/: naming, typing (no silenced types), existing patterns over new ones, no premature abstraction or speculative code, no unjustified dependencies — and the comments rule in .claude/rules/code-quality.md (flag comments that restate code, repeat signatures, narrate steps, label sections, or record history).` },
  { key: 'tests-and-evidence', prompt: `Review TESTS AND EVIDENCE. Each acceptance criterion and testable requirement has a test; tests assert behavior, not implementation; external services are mocked; tasks.md § Gate results records red-then-green evidence, commands and counts, and what was not run — claims without evidence are findings.` },
]
if (scope.hasUI) {
  DIMENSIONS.push({ key: 'ux-accessibility', prompt: `Review UX AND ACCESSIBILITY using .claude/agents/ux-reviewer/agent.md: the UI matches the spec's stories, design and committed docs; loading, empty and error states; semantic HTML, keyboard support, labels, contrast; consistent language.` })
}
if (scope.hasDocs) {
  DIMENSIONS.push({ key: 'docs', prompt: `Review DOC ACCURACY. Committed user-facing docs match what was built; divergences were reconciled in docs: commits or called out in a task commit; nothing fabricated.` })
}

const reviewed = await pipeline(
  DIMENSIONS,
  (dimension) =>
    agent(`${dimension.prompt}\n\n${context}`, { label: `review:${dimension.key}`, phase: 'Review', schema: FINDINGS_SCHEMA }).then(
      (result) => ({ dimension: dimension.key, checked: result ? result.checked : 'reviewer did not return', findings: result ? result.findings : [] }),
    ),
  (review) =>
    parallel(
      review.findings.map((finding) => () => {
        if (finding.severity === 'nit') {
          return Promise.resolve({ ...finding, dimension: review.dimension, verdict: null })
        }
        return agent(
          `Try to REFUTE this code review finding. ${READ_ONLY}
Finding (${review.dimension}, ${finding.severity}) at ${finding.file}:${finding.line}: ${finding.title}
Evidence given: ${finding.evidence}
Read the code and the spec folder${scope.specFolder ? ` (${scope.specFolder})` : ''}. Refute it if the evidence is wrong, the behavior is intended by the spec or plan, or it is handled elsewhere. If it stands, confirm the severity or correct it. Default to refuted=true when you cannot confirm it from the code.`,
          { label: `verify:${finding.file}:${finding.line}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ).then((verdict) => ({ ...finding, dimension: review.dimension, verdict }))
      }),
    ).then((findings) => ({ ...review, findings: findings.filter(Boolean) })),
)

const reviews = reviewed.filter(Boolean)
const all = reviews.flatMap((review) => review.findings)
const seen = new Set()
const confirmed = []
const refuted = []
const nits = []
for (const finding of all) {
  const key = `${finding.file}:${finding.line}:${finding.title.toLowerCase()}`
  if (seen.has(key)) continue
  seen.add(key)
  if (finding.severity === 'nit') nits.push(finding)
  else if (finding.verdict && !finding.verdict.refuted) confirmed.push({ ...finding, severity: finding.verdict.severity })
  else refuted.push(finding)
}
const rank = { critical: 0, warning: 1, nit: 2 }
confirmed.sort((a, b) => rank[a.severity] - rank[b.severity] || a.file.localeCompare(b.file) || a.line - b.line)

log(`${confirmed.length} confirmed, ${refuted.length} refuted by verification, ${nits.length} nits (not verified).`)

return {
  scope,
  dimensions: reviews.map((review) => ({ dimension: review.dimension, checked: review.checked, findings: review.findings.length })),
  confirmed,
  refuted: refuted.map((finding) => ({ file: finding.file, line: finding.line, title: finding.title, reason: finding.verdict ? finding.verdict.reason : 'verifier did not return' })),
  nits,
}
