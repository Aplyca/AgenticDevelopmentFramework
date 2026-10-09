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

// The method each auditor follows is the spec-drift skill's. The adf plugin's copy carries the skill's
// steps here instead: a packaged project keeps no copy of the skills, and a workflow can't reach the
// plugin's (decision 0030).
const SPEC_DRIFT_STEPS = "The spec-drift skill's steps, which this audit follows:\n\n## Steps\n\n### Phase 1: Read the spec and identify the surface\n\n1. **Read the committed spec folder.** `spec.md` — every section, not just Functional, including every `CR N` section (the latest change request is the current requirement). Pay attention to:\n   - Functional ACs (what should be observable), including those tagged `(CR N)` and those struck through\n   - Edge cases (what failure modes were promised)\n   - Security / Privacy / Accessibility / Performance (testable requirements that may have eroded)\n   - Documentation (which doc files were committed)\n   - Constraints & prior decisions, and References (ADRs, PDRs, designs)\n\n   Then `plan.md` (architecture, change surface, contracts) and `tasks.md` (the test each task named, and the gate results). A legacy single-file spec has no plan or tasks — rely on its Technical section and the heuristics below.\n\n2. **Identify the implementation surface.** Use these signals:\n   - The change surface table in `plan.md` — the files the feature was built in\n   - The tests named on each task in `tasks.md`\n   - Doc file paths from the Documentation section\n   - For legacy specs: the Technical section, and test files added near the spec's commit date (`git log --diff-filter=A -- e2e/ tests/ '**/*.test.*' '**/*.spec.*'`)\n   - Heuristics: the slug or feature name in file, component, and route names\n\n3. **Read the current state of those files.** Use the smallest set that gives you the picture.\n\n4. **Read the related tests and docs.** Same surface as above.\n\n### Phase 2: Compare and report\n\n5. **Walk the spec against reality.** For each filled section:\n   - **Functional ACs**: does each AC have a corresponding test? Does the test still assert what the AC says? Does the code make the test pass in the way the AC describes?\n   - **Edge cases**: are they all still tested?\n   - **Security / Privacy / Accessibility / Performance**: are the testable requirements still enforced? Is the rate limit still 10/min, or did someone change it without updating the spec?\n   - **Documentation**: do the committed admin guides still describe what the code actually does? Has marketing copy in CMS diverged from documented defaults?\n   - **Plan** (`plan.md`): are the architecture, integrations, and contracts still as described? Did someone swap the rate-limit store for an in-memory cache without updating the plan? Has the feature spread far beyond its change surface?\n   - **Out of scope**: did anything from the out-of-scope list get implemented anyway? (Scope creep that bypassed spec update.)\n\n6. **Categorize each divergence:**\n   - **CONTRADICTION** — code does something the spec explicitly forbids or contradicts (highest severity)\n   - **DRIFT** — code does something the spec doesn't address; spec is silent on real behavior (needs spec update)\n   - **MISSING** — spec promises something but the code/test no longer implements/verifies it (regression risk)\n   - **STALE REFERENCE** — spec references a file / module / integration that no longer exists or has been renamed\n   - **DOC MISMATCH** — committed docs describe behavior that doesn't match current implementation\n\n7. **Present the drift report.** Structured format:\n   ```\n   Spec: specs/007-newsletter-signup/ (last spec commit: 2025-11-12, 7 PRs since)\n\n   ✓ AC1 (form renders with Contentful copy) — code matches, test in place\n   ✓ AC2 (success message after valid submission) — matches\n   ✘ AC3 (inline error for invalid email) — DRIFT\n       Spec says: \"focus moves to the input\"\n       Code: focus does not move (commit a1b2c3d removed the focus management\n             \"for accessibility refactor\"; spec was not updated)\n       Recommendation: update spec to reflect new behavior, OR restore focus management\n   ✘ Edge case \"Mailchimp 5xx → retry-able error\" — MISSING\n       Test was removed in commit d4e5f6g; code still has the path but no test\n       Recommendation: restore the test (it's a real edge case)\n   ✘ Security: \"Rate limit 10 req/IP/min\" — CONTRADICTION\n       Code: lib/newsletter/rate-limit.ts now uses 30 req/IP/min\n       (changed in commit a7b8c9d \"increase rate limit per marketing request\",\n       no spec update)\n       Recommendation: spec update required — this is a deliberate change that\n       bypassed the change-request workflow\n\n   Summary: 1 CONTRADICTION, 1 DRIFT, 1 MISSING — spec is meaningfully out of date.\n   Recommended action: open a spec update PR addressing the three findings.\n   ```\n\n8. **Do NOT auto-fix.** This skill reports; it does not modify. The fix goes through the change-request workflow (`specs/README.md` § Change requests): a `CR N` amendment of the spec folder, test changes, and doc updates as needed."

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
      `Run a read-only drift audit of ${spec}. ${READ_ONLY}
Read the whole spec (every section and change request), plan.md and tasks.md when present. Identify the implementation surface from the plan's change surface and the tests named in tasks.md (legacy specs: their Technical section, then heuristics). Compare each acceptance criterion, edge case, testable requirement, documentation claim and plan item with the current code, tests and docs. Categorize each divergence: CONTRADICTION, MISSING, DRIFT, STALE REFERENCE, DOC MISMATCH. Report the last commit that touched the spec (git log -1 --format='%h %cs' -- ${spec}).
${SPEC_DRIFT_STEPS}
Return the findings in the response schema, one per divergence, instead of writing the report the steps describe.`,
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
