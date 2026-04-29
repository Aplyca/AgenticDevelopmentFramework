#!/usr/bin/env bash
#
# Static evals — structural checks of the framework's skill / agent / rule / template files.
# Zero AI invocation. Runs in milliseconds. Exit 0 on all-pass, non-zero on any failure.
#
# Usage: ./check-skills.sh [--verbose]
#

set -uo pipefail

# Resolve paths relative to this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This script lives at evals/static/ in the framework repo root.
# Two levels up from evals/static/ is the framework repo root.
# The framework's files-under-evaluation live under skeleton/.
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"

if [ -d "$REPO_ROOT/skeleton/.claude/skills" ]; then
    SKILLS_DIR="$REPO_ROOT/skeleton/.claude/skills"
    AGENTS_DIR="$REPO_ROOT/skeleton/.claude/agents"
    SPEC_TEMPLATE="$REPO_ROOT/skeleton/specs/_template.md"
    AGENTS_MD="$REPO_ROOT/skeleton/AGENTS.md"
    GIT_RULE="$REPO_ROOT/skeleton/.claude/rules/git-workflow.md"
else
    echo "ERROR: cannot locate skeleton/.claude/skills under $REPO_ROOT" >&2
    echo "       This script must be run from inside the framework repo." >&2
    exit 2
fi

PASS=0
FAIL=0
VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

pass() {
    PASS=$((PASS+1))
    echo "✓ $1"
}

fail() {
    FAIL=$((FAIL+1))
    echo "✘ $1"
    [ -n "${2:-}" ] && echo "    $2"
}

file_contains() {
    # file_contains <file> <pattern>
    grep -qE "$2" "$1" 2>/dev/null
}

file_contains_literal() {
    # file_contains_literal <file> <literal_string>
    grep -qF -- "$2" "$1" 2>/dev/null
}

count_matches() {
    # count_matches <file> <pattern>
    # grep -c returns exit 1 when zero matches; suppress that so the count is just an integer.
    local n
    n=$(grep -cE "$2" "$1" 2>/dev/null) || n=0
    echo "$n"
}

count_section_table_rows() {
    # count_section_table_rows <file> <heading-regex>
    # Extract from heading to next ##/### heading and count lines starting with |
    local n
    n=$(sed -n "/$2/,/^#\{2,3\} /p" "$1" 2>/dev/null | grep -c '^|') || n=0
    echo "$n"
}

# ─── Checks ───────────────────────────────────────────────────────────────

check_skill_frontmatter() {
    local skill_dir="$1"
    local name=$(basename "$skill_dir")
    local file="$skill_dir/SKILL.md"

    if [ ! -f "$file" ]; then
        fail "skill '$name': SKILL.md exists" "expected $file"
        return
    fi

    local has_frontmatter
    has_frontmatter=$(head -1 "$file" | grep -c '^---$' || echo 0)
    if [ "$has_frontmatter" -ne 1 ]; then
        fail "skill '$name': has YAML frontmatter" "first line is not '---'"
        return
    fi

    if ! file_contains "$file" '^name:'; then
        fail "skill '$name': frontmatter has 'name:'"
        return
    fi
    if ! file_contains "$file" '^description:'; then
        fail "skill '$name': frontmatter has 'description:'"
        return
    fi

    pass "skill '$name': has valid frontmatter"
}

check_skill_has_steps_or_phases() {
    local skill_dir="$1"
    local name=$(basename "$skill_dir")
    local file="$skill_dir/SKILL.md"
    [ ! -f "$file" ] && return

    # Accept ## Steps, ## Phase, ### Phase (some skills use h3 phases).
    if file_contains "$file" '^## Steps' || \
       file_contains "$file" '^## Phase' || \
       file_contains "$file" '^### Phase'; then
        pass "skill '$name': has Steps or Phase section"
    else
        fail "skill '$name': missing '## Steps' / '## Phase' / '### Phase' section"
    fi
}

check_skill_has_rationalizations() {
    local skill_dir="$1"
    local name=$(basename "$skill_dir")
    local file="$skill_dir/SKILL.md"
    [ ! -f "$file" ] && return

    # TDD-discipline skills must have anti-rationalization tables.
    case "$name" in
        write-spec|write-tests|write-docs|implement|review|commit|refactor|debug|spec-drift)
            if file_contains "$file" '^## Rationalizations'; then
                local rows
                rows=$(count_section_table_rows "$file" '^## Rationalizations')
                # Header row + separator row + 4 actual rows = 6 total minimum
                if [ "$rows" -ge 6 ]; then
                    pass "skill '$name': has Rationalizations table with content ($rows table rows)"
                else
                    fail "skill '$name': Rationalizations table too thin" "found $rows table rows, expected ≥6"
                fi
            else
                fail "skill '$name': missing '## Rationalizations' section"
            fi
            ;;
        *)
            # Other skills (init-project, evaluate, spec-workflow) — table optional
            ;;
    esac
}

check_skill_has_verification() {
    local skill_dir="$1"
    local name=$(basename "$skill_dir")
    local file="$skill_dir/SKILL.md"
    [ ! -f "$file" ] && return

    case "$name" in
        write-spec|write-tests|write-docs|implement|review|commit|refactor|debug|spec-drift)
            if file_contains "$file" '^## Verification'; then
                local checkboxes
                checkboxes=$(count_matches "$file" '^- \[ \]')
                if [ "$checkboxes" -ge 4 ]; then
                    pass "skill '$name': has Verification checklist ($checkboxes items)"
                else
                    fail "skill '$name': Verification checklist too thin" "found $checkboxes checkboxes, expected ≥4"
                fi
            else
                fail "skill '$name': missing '## Verification' section"
            fi
            ;;
    esac
}

check_write_spec_mandatory_enforcement() {
    local file="$SKILLS_DIR/write-spec/SKILL.md"
    [ ! -f "$file" ] && { fail "write-spec mandatory enforcement check: SKILL.md missing"; return; }

    if file_contains_literal "$file" "Mandatory section enforcement" || \
       file_contains_literal "$file" "mandatory-section enforcement" || \
       file_contains "$file" 'refuse.*approval'; then
        pass "/write-spec: references mandatory section enforcement"
    else
        fail "/write-spec: missing mandatory section enforcement language"
    fi
}

check_implement_reads_docs() {
    local file="$SKILLS_DIR/implement/SKILL.md"
    [ ! -f "$file" ] && { fail "implement reads docs check: SKILL.md missing"; return; }

    if file_contains_literal "$file" "committed docs"; then
        pass "/implement: references reading committed docs as design context"
    else
        fail "/implement: missing 'committed docs' references — docs-first integration broken"
    fi
}

check_implement_reconciles_docs() {
    local file="$SKILLS_DIR/implement/SKILL.md"
    [ ! -f "$file" ] && return

    if file_contains_literal "$file" "Reconcile docs" || file_contains "$file" 'reconcile.*doc'; then
        pass "/implement: includes doc-reconciliation step"
    else
        fail "/implement: missing doc-reconciliation step"
    fi
}

check_write_docs_skip_clean() {
    local file="$SKILLS_DIR/write-docs/SKILL.md"
    [ ! -f "$file" ] && { fail "write-docs skip-clean check: SKILL.md missing"; return; }

    if file_contains_literal "$file" "skip cleanly" || file_contains "$file" 'Skip cleanly'; then
        pass "/write-docs: documents skip-clean condition"
    else
        fail "/write-docs: missing skip-clean condition"
    fi
}

check_spec_template_frontmatter() {
    local file="$SPEC_TEMPLATE"
    [ ! -f "$file" ] && { fail "spec template check: $SPEC_TEMPLATE missing"; return; }

    local missing=()
    file_contains "$file" '^feature-type:' || missing+=("feature-type")
    file_contains "$file" '^personal-data:' || missing+=("personal-data")
    file_contains "$file" '^owners:' || missing+=("owners")
    file_contains "$file" '^references:' || missing+=("references")

    if [ ${#missing[@]} -eq 0 ]; then
        pass "spec template: frontmatter has required fields"
    else
        fail "spec template: frontmatter missing fields" "${missing[*]}"
    fi
}

check_spec_template_required_sections() {
    local file="$SPEC_TEMPLATE"
    [ ! -f "$file" ] && return

    local missing=()
    file_contains "$file" '## Business \[REQUIRED\]' || missing+=("Business [REQUIRED]")
    file_contains "$file" '## Functional \[REQUIRED\]' || missing+=("Functional [REQUIRED]")
    file_contains "$file" '## Out of scope \[REQUIRED\]' || missing+=("Out of scope [REQUIRED]")
    file_contains "$file" '## Security \[REQUIRED\]' || missing+=("Security [REQUIRED]")
    file_contains "$file" '## Testing \[REQUIRED\]' || missing+=("Testing [REQUIRED]")
    file_contains "$file" '## Documentation \[REQUIRED\]' || missing+=("Documentation [REQUIRED]")
    file_contains "$file" '## Clarifications \[REQUIRED' || missing+=("Clarifications [REQUIRED]")

    if [ ${#missing[@]} -eq 0 ]; then
        pass "spec template: all always-required sections present"
    else
        fail "spec template: missing required sections" "${missing[*]}"
    fi
}

check_spec_template_doc_subsections() {
    local file="$SPEC_TEMPLATE"
    [ ! -f "$file" ] && return

    if file_contains "$file" 'Pre-implementable docs' && file_contains "$file" 'Post-implementable docs'; then
        pass "spec template: Documentation has Pre-implementable + Post-implementable subsections"
    else
        fail "spec template: Documentation section missing Pre/Post-implementable split"
    fi
}

check_agents_md_workflow_includes_docs() {
    local file="$AGENTS_MD"
    [ ! -f "$file" ] && { fail "AGENTS.md workflow check: file missing"; return; }

    if file_contains_literal "$file" "/write-docs" || \
       file_contains "$file" 'docs-first' || \
       file_contains "$file" 'Plan docs'; then
        pass "AGENTS.md: feature workflow includes the docs phase"
    else
        fail "AGENTS.md: feature workflow missing the docs phase"
    fi
}

check_git_workflow_has_all_prefixes() {
    local file="$GIT_RULE"
    [ ! -f "$file" ] && { fail "git-workflow check: $GIT_RULE missing"; return; }

    local missing=()
    file_contains_literal "$file" '`spec:`' || missing+=("spec:")
    file_contains_literal "$file" '`test:`' || missing+=("test:")
    file_contains_literal "$file" '`docs:`' || missing+=("docs:")
    file_contains_literal "$file" '`feat:`' || missing+=("feat:")

    if [ ${#missing[@]} -eq 0 ]; then
        pass "git-workflow rule: documents all four pre-impl commit prefixes"
    else
        fail "git-workflow rule: missing prefixes" "${missing[*]}"
    fi
}

check_agent_descriptions_not_misleading() {
    local file="$AGENTS_DIR/test-runner/agent.md"
    [ ! -f "$file" ] && return

    # The test-runner description used to say "Use after implementation" — wrong for TDD.
    if grep -E '^description:.*[Uu]se after implementation' "$file" >/dev/null 2>&1; then
        fail "agent test-runner: description says 'use after implementation' (wrong for TDD)"
    else
        pass "agent test-runner: description correctly positions tests in TDD workflow"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────

echo ""
echo "Static evals — framework structural checks"
echo "==========================================="
echo ""
echo "Skills directory: $SKILLS_DIR"
echo ""

# Per-skill checks
for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    check_skill_frontmatter "$skill_dir"
    check_skill_has_steps_or_phases "$skill_dir"
    check_skill_has_rationalizations "$skill_dir"
    check_skill_has_verification "$skill_dir"
done

# Workflow integrity checks
echo ""
check_write_spec_mandatory_enforcement
check_implement_reads_docs
check_implement_reconciles_docs
check_write_docs_skip_clean

# Template checks
echo ""
check_spec_template_frontmatter
check_spec_template_required_sections
check_spec_template_doc_subsections

# Top-level integration checks
echo ""
check_agents_md_workflow_includes_docs
check_git_workflow_has_all_prefixes
check_agent_descriptions_not_misleading

# Summary
echo ""
echo "==========================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
