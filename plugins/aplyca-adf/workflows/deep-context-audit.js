export const meta = {
  name: 'deep-context-audit',
  description: 'Audit every agent-instruction and process file against the repository in parallel, then cross-check the files against each other for contradictions',
  whenToUse: 'Monthly, after a process change or a framework upgrade, or before onboarding someone. Read-only. The single-context version is the /aplyca-adf:context-audit skill.',
  phases: [
    { title: 'Inventory', detail: 'list instruction, process, hook and CI files' },
    { title: 'Check', detail: 'one agent per file verifies its claims against the repository' },
    { title: 'Cross-check', detail: 'find contradictions between files and say which one wins' },
  ],
}

const READ_ONLY = 'Do not modify, create, or delete any file, and do not run commands that write, install, deploy, or migrate. Read files and run read-only commands only.'

const INVENTORY_SCHEMA = {
  type: 'object',
  required: ['files'],
  properties: { files: { type: 'array', items: { type: 'string' } } },
}

const FILE_SCHEMA = {
  type: 'object',
  required: ['file', 'findings', 'policy'],
  properties: {
    file: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['category', 'line', 'claim', 'evidence', 'fix'],
        properties: {
          category: { type: 'string', enum: ['FALSE CLAIM', 'STALE', 'UNVERIFIED', 'HYGIENE'] },
          line: { type: 'integer' },
          claim: { type: 'string' },
          evidence: { type: 'string' },
          fix: { type: 'string' },
        },
      },
    },
    policy: {
      type: 'array',
      description: 'policy statements this file makes, for the cross-file check',
      items: {
        type: 'object',
        required: ['topic', 'statement', 'line'],
        properties: {
          topic: { type: 'string', enum: ['base branch', 'protected branches', 'merge method', 'release process', 'review rule', 'pull request state', 'commit convention', 'branch naming', 'spec requirement', 'approval gate', 'outward actions', 'other'] },
          statement: { type: 'string' },
          line: { type: 'integer' },
        },
      },
    },
  },
}

const CONTRADICTIONS_SCHEMA = {
  type: 'object',
  required: ['contradictions'],
  properties: {
    contradictions: {
      type: 'array',
      items: {
        type: 'object',
        required: ['topic', 'sides', 'winner', 'wrongAction', 'fix'],
        properties: {
          topic: { type: 'string' },
          sides: { type: 'string', description: 'file:line and what each says' },
          winner: { type: 'string', description: 'which file wins by precedence, and why' },
          wrongAction: { type: 'string', description: 'what an agent following that precedence would wrongly do' },
          fix: { type: 'string' },
        },
      },
    },
  },
}

const scopeHint = typeof args === 'string' && args.trim() ? `Limit the inventory to: ${args.trim()}.` : ''

phase('Inventory')
const inventory = await agent(
  `List the agent-instruction and process files in this repository. ${READ_ONLY} ${scopeHint}
Include when present: AGENTS.md and every nested AGENTS.md, CLAUDE.md, GEMINI.md, .cursor/rules/*, .claude/rules/*, project-specific .claude/skills/*/SKILL.md and .claude/agents/*, .claude/settings.json, .claude/hooks/config.sh, docs/CONSTITUTION.md, CONTRIBUTING.md, README.md, specs/README.md, the pull request template, CI workflow files, git hook scripts, and the ADR and PDR index READMEs. Exclude node_modules, build output, and .claude/worktrees.`,
  { label: 'inventory', phase: 'Inventory', schema: INVENTORY_SCHEMA },
)

const files = inventory ? inventory.files : []
if (files.length === 0) {
  log('No instruction files found.')
  return { files: [], findings: [], contradictions: [] }
}
log(`${files.length} files to check.`)

const checked = await pipeline(files, (file) =>
  agent(
    `Audit ${file} against the repository. ${READ_ONLY}
- Every command it mentions exists (manifest script, Makefile target, binary). Don't run anything that writes.
- Every path it references exists.
- What it says hooks, CI, and git hooks do matches the scripts and workflow files.
- Enforcement claims ("required", "protected", "blocked"): check what you can read-only; report the rest as UNVERIFIED, never as true.
- Versions and environment variables match the version files, manifests, and env template.
- Hygiene: owner/last_updated/scope metadata present and not older than the file's last meaningful change (git log -1 --format=%cs -- ${file}); leftover template placeholders; generic advice; over ~200 lines for always-loaded files; instructions the agent follows by default anyway; copies of what one command or file already shows (script lists, trees, versions); material only some tasks need in an always-loaded file; a "don't" with no statement of what to do instead.
Also extract every POLICY statement it makes (base branch, protected branches, merge method, release process, review rule, pull request draft/ready state, commit convention, branch naming, when a spec is required, the approval gate, outward actions), with line numbers.`,
    { label: `check:${file}`, phase: 'Check', schema: FILE_SCHEMA },
  ),
)

const results = checked.filter(Boolean)
const policies = results.flatMap((result) => result.policy.map((statement) => ({ file: result.file, ...statement })))

phase('Cross-check')
const crossCheck = await agent(
  `These are policy statements extracted from the repository's instruction and process files:
${JSON.stringify(policies, null, 1)}

Find every CONTRADICTION: two files that disagree on the same topic. Precedence: docs/CONSTITUTION.md overrides AGENTS.md; a nested AGENTS.md overrides the root for its folder; accepted ADRs and PDRs record decisions the instruction files must reflect. For each contradiction name the winning file, what an agent following that precedence would wrongly do, and the fix (amend which file; a PDR if a rule changes rather than being restated). Read the files to confirm before reporting. ${READ_ONLY}`,
  { label: 'cross-check', phase: 'Cross-check', schema: CONTRADICTIONS_SCHEMA },
)

const findings = results.flatMap((result) => result.findings.map((finding) => ({ file: result.file, ...finding })))
const order = { 'FALSE CLAIM': 0, STALE: 1, UNVERIFIED: 2, HYGIENE: 3 }
findings.sort((a, b) => order[a.category] - order[b.category] || a.file.localeCompare(b.file))
const contradictions = crossCheck ? crossCheck.contradictions : []

log(`${contradictions.length} contradictions, ${findings.length} file findings across ${results.length} of ${files.length} files.`)

return { files: results.map((result) => result.file), contradictions, findings }
