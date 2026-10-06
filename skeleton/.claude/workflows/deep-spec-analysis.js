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

// The spec model the lenses check against. The aplyca-adf plugin's copy carries the model's text here
// instead: a packaged project keeps no copy of it in docs/ (decision 0019).
const SPEC_MODEL = 'Read docs/SPEC-MODEL.md.'

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
    agent(`${lens.prompt}\n\n${context}`, { label: `analyze:${lens.key}`, phase: 'Analyze', schema: FINDINGS_SCHEMA }).then(
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
