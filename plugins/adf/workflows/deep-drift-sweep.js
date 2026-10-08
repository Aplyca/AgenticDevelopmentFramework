export const meta = {
  name: 'deep-drift-sweep',
  description: 'Audit every spec folder (or every spec in an area) for drift against the current code, tests and docs, one agent per spec, verifying contradictions',
  whenToUse: 'Quarterly, or before a large change to an old area. The single-spec version is the /adf:spec-drift skill. Optional argument: a path or keyword to limit the sweep.',
  phases: [
    { title: 'Discover', detail: 'list spec folders and legacy single-file specs' },
    { title: 'Audit', detail: 'one drift audit per spec' },
    { title: 'Verify', detail: 'a skeptic re-checks each CONTRADICTION and MISSING finding' },
  ],
}

const READ_ONLY = 'Do not modify, create, or delete any file. Read files and run read-only git commands only.'

const DISCOVER_SCHEMA = {
  type: 'object',
  required: ['specs'],
  properties: { specs: { type: 'array', items: { type: 'string' } } },
}

const DRIFT_SCHEMA = {
  type: 'object',
  required: ['spec', 'lastSpecCommit', 'findings', 'summary'],
  properties: {
    spec: { type: 'string' },
    lastSpecCommit: { type: 'string' },
    summary: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['category', 'reference', 'observed', 'recommendation'],
        properties: {
          category: { type: 'string', enum: ['CONTRADICTION', 'MISSING', 'DRIFT', 'STALE REFERENCE', 'DOC MISMATCH'] },
          reference: { type: 'string', description: 'the AC, section, or plan item' },
          observed: { type: 'string', description: 'what the code, tests or docs do now, with file:line' },
          recommendation: { type: 'string' },
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

const filter = typeof args === 'string' ? args.trim() : ''

phase('Discover')
const discovered = await agent(
  `List every spec to audit. ${READ_ONLY}
Spec folders are specs/NNN-<slug>/ containing spec.md; legacy single-file specs are specs/*.md other than README.md. Skip specs/_templates.${filter ? ` Keep only specs matching "${filter}" (path or keyword).` : ''} Return the paths.`,
  { label: 'discover', phase: 'Discover', schema: DISCOVER_SCHEMA },
)

const specs = discovered ? discovered.specs : []
if (specs.length === 0) {
  log('No specs found.')
  return { audited: [], findings: [] }
}
log(`${specs.length} specs to audit.`)

const audited = await pipeline(
  specs,
  (spec) =>
    agent(
      `Run a read-only drift audit of ${spec}, following the method in .claude/skills/spec-drift/SKILL.md. ${READ_ONLY}
Read the whole spec (every section and change request), plan.md and tasks.md when present. Identify the implementation surface from the plan's change surface and the tests named in tasks.md (legacy specs: their Technical section, then heuristics). Compare each acceptance criterion, edge case, testable requirement, documentation claim and plan item with the current code, tests and docs. Categorize each divergence: CONTRADICTION, MISSING, DRIFT, STALE REFERENCE, DOC MISMATCH. Report the last commit that touched the spec (git log -1 --format='%h %cs' -- ${spec}).`,
      { label: `drift:${spec}`, phase: 'Audit', schema: DRIFT_SCHEMA },
    ),
  (drift) =>
    parallel(
      drift.findings.map((finding) => () => {
        if (finding.category !== 'CONTRADICTION' && finding.category !== 'MISSING') return Promise.resolve({ ...finding, verdict: null })
        return agent(
          `Try to REFUTE this drift finding for ${drift.spec}. ${READ_ONLY}
${finding.category} — ${finding.reference}: ${finding.observed}
Refute it if the code, tests, or a later change request in the spec actually agree. Default to refuted=true when you cannot confirm it.`,
          { label: `verify:${drift.spec}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ).then((verdict) => ({ ...finding, verdict }))
      }),
    ).then((findings) => ({
      ...drift,
      findings: findings.filter(Boolean).filter((finding) => !finding.verdict || !finding.verdict.refuted),
    })),
)

const results = audited.filter(Boolean)
const weight = { CONTRADICTION: 4, MISSING: 3, 'DOC MISMATCH': 2, DRIFT: 1, 'STALE REFERENCE': 1 }
const table = results
  .map((result) => ({
    spec: result.spec,
    lastSpecCommit: result.lastSpecCommit,
    counts: result.findings.reduce((counts, finding) => ({ ...counts, [finding.category]: (counts[finding.category] || 0) + 1 }), {}),
    score: result.findings.reduce((sum, finding) => sum + weight[finding.category], 0),
    summary: result.summary,
  }))
  .sort((a, b) => b.score - a.score)

if (results.length < specs.length) log(`${specs.length - results.length} specs could not be audited.`)
log(`${table.filter((row) => row.score > 0).length} of ${results.length} specs show drift.`)

return { table, findings: results.map((result) => ({ spec: result.spec, findings: result.findings })) }
