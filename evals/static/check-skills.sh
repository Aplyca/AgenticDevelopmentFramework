#!/usr/bin/env bash
#
# Static evals — structural checks of the framework's skills, agents, rules, workflows, hooks,
# settings, templates, and links. Zero AI invocation. Runs in seconds. Exit 0 on all-pass.
#
# Usage: ./check-skills.sh [--verbose]
#

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This script lives at evals/static/ in the framework repo; the files under evaluation live under
# plugins/ (the machinery's source, decision 0028), skeleton/, and modules/.
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"
SKELETON="$REPO_ROOT/skeleton"

if [ ! -d "$REPO_ROOT/plugins/adf/skills" ] || [ ! -d "$SKELETON" ]; then
    echo "ERROR: cannot locate plugins/adf/skills and skeleton/ under $REPO_ROOT" >&2
    echo "       This script must be run from inside the framework repo." >&2
    exit 2
fi

# Most checks read the machinery the way a committed project keeps it: scripts/build-committed.py
# writes that copy from the plugins, with every module's skills, and the skeleton's config.sh joins it.
COMMITTED="$(mktemp -d)"
trap 'rm -rf "$COMMITTED"' EXIT
if ! python3 "$REPO_ROOT/scripts/build-committed.py" "$COMMITTED" --modules all >/dev/null; then
    echo "ERROR: scripts/build-committed.py couldn't write the committed install" >&2
    exit 2
fi
cp "$SKELETON/.claude/hooks/config.sh" "$COMMITTED/.claude/hooks/"
SKILLS_DIR="$COMMITTED/.claude/skills"
AGENTS_DIR="$COMMITTED/.claude/agents"
WORKFLOWS_DIR="$COMMITTED/.claude/workflows"
HOOKS_DIR="$COMMITTED/.claude/hooks"
SETTINGS="$SKELETON/.claude/settings.json"
TEMPLATES="$SKELETON/specs/_templates"
AGENTS_MD="$SKELETON/AGENTS.md"
CLAUDE_LAYER="$SKELETON/.claude/rules/claude-code.md"
GIT_RULE="$SKELETON/.claude/rules/git-workflow.md"
MODULES_DIR="$REPO_ROOT/modules"

PASS=0
FAIL=0

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
    grep -qE "$2" "$1" 2>/dev/null
}

file_contains_literal() {
    grep -qF -- "$2" "$1" 2>/dev/null
}

count_matches() {
    local n
    n=$(grep -cE "$2" "$1" 2>/dev/null) || n=0
    echo "$n"
}

count_section_table_rows() {
    # Extract from heading to next ##/### heading and count lines starting with |
    local n
    n=$(sed -n "/$2/,/^#\{2,3\} /p" "$1" 2>/dev/null | grep -c '^|') || n=0
    echo "$n"
}

frontmatter() {
    # Print the YAML frontmatter block of a markdown file (between the first two --- lines).
    awk 'NR==1 && $0!="---" {exit} NR==1 {next} $0=="---" {exit} {print}' "$1"
}

# Skills that carry the full discipline: rationalizations table + verification checklist.
DISCIPLINE_SKILLS="write-spec write-plan write-tests write-docs implement review commit refactor debug spec-drift orchestrate triage open-pr stakeholder-update record-decision context-audit dispatch dev-env"
# Skills with side effects outside this machine as soon as they run: user-invoked only.
OUTWARD_SKILLS=""  # /open-pr runs on its own after the local check (decision 0022)
# Skills that may start from a plain request but post only after showing the draft.
DRAFT_FIRST_SKILLS="stakeholder-update"

is_discipline_skill() {
    case " $DISCIPLINE_SKILLS " in *" $1 "*) return 0 ;; esac
    return 1
}

# ─── Skills ────────────────────────────────────────────────────────────────

check_skill_frontmatter() {
    local skill_dir="$1"
    local name; name=$(basename "$skill_dir")
    local file="$skill_dir/SKILL.md"

    if [ ! -f "$file" ]; then
        fail "skill '$name': SKILL.md exists" "expected $file"
        return
    fi
    if [ "$(head -1 "$file")" != "---" ]; then
        fail "skill '$name': has YAML frontmatter" "first line is not '---'"
        return
    fi
    local fm; fm=$(frontmatter "$file")
    if ! printf '%s\n' "$fm" | grep -qE "^name: $name$"; then
        fail "skill '$name': frontmatter 'name:' matches its directory"
        return
    fi
    if ! printf '%s\n' "$fm" | grep -qE '^description: .{40,}'; then
        fail "skill '$name': frontmatter has a meaningful 'description:'"
        return
    fi
    # Claude Code silently ignores unknown keys — underscore spellings never take effect.
    local bad
    bad=$(printf '%s\n' "$fm" | grep -oE '^(user_invocable|disable_model_invocation|allowed_tools|argument_hint|when_to_use_it|disallowed_tools):' | tr '\n' ' ')
    if [ -n "$bad" ]; then
        fail "skill '$name': frontmatter keys use hyphens" "invalid (silently ignored): $bad"
        return
    fi
    pass "skill '$name': valid frontmatter"
}

check_skill_has_steps_or_phases() {
    local name; name=$(basename "$1")
    local file="$1/SKILL.md"
    [ -f "$file" ] || return
    if file_contains "$file" '^## (Steps|Phase|Workflow)' || file_contains "$file" '^### Phase'; then
        pass "skill '$name': has Steps / Phase / Workflow sections"
    else
        fail "skill '$name': missing '## Steps', '## Phase', or '## Workflow' section"
    fi
}

check_skill_discipline() {
    local name; name=$(basename "$1")
    local file="$1/SKILL.md"
    [ -f "$file" ] || return
    is_discipline_skill "$name" || return

    if file_contains "$file" '^## Rationalizations'; then
        local rows; rows=$(count_section_table_rows "$file" '^## Rationalizations')
        # Header + separator + at least 4 rows
        if [ "$rows" -ge 6 ]; then
            pass "skill '$name': Rationalizations table ($rows table rows)"
        else
            fail "skill '$name': Rationalizations table too thin" "found $rows table rows, expected ≥6"
        fi
    else
        fail "skill '$name': missing '## Rationalizations' section"
    fi

    if file_contains "$file" '^## Verification'; then
        local boxes; boxes=$(count_matches "$file" '^- \[ \]')
        if [ "$boxes" -ge 4 ]; then
            pass "skill '$name': Verification checklist ($boxes items)"
        else
            fail "skill '$name': Verification checklist too thin" "found $boxes, expected ≥4"
        fi
    else
        fail "skill '$name': missing '## Verification' section"
    fi
}

check_outward_skills_user_invoked() {
    local name file
    for name in $OUTWARD_SKILLS; do
        file="$SKILLS_DIR/$name/SKILL.md"
        if [ ! -f "$file" ]; then
            fail "outward skill '$name' exists"
        elif frontmatter "$file" | grep -qE '^disable-model-invocation: true$'; then
            pass "skill '$name': user-invoked only (disable-model-invocation: true)"
        else
            fail "skill '$name': acts outside the machine but can be auto-invoked" "add 'disable-model-invocation: true'"
        fi
    done
    for name in $DRAFT_FIRST_SKILLS; do
        file="$SKILLS_DIR/$name/SKILL.md"
        if [ ! -f "$file" ]; then
            fail "draft-first skill '$name' exists"
        elif grep -q 'Show the full draft' "$file" && grep -q 'ask before posting' "$file"; then
            pass "skill '$name': shows the draft, and asks before posting when nobody asked for it"
        else
            fail "skill '$name': can start from a plain request but doesn't show the draft and ask before posting"
        fi
    done
}

# ─── Agents ────────────────────────────────────────────────────────────────

check_agent() {
    local file="$1"
    local dir_name; dir_name=$(basename "$(dirname "$file")")
    local fm; fm=$(frontmatter "$file")
    if ! printf '%s\n' "$fm" | grep -qE "^name: $dir_name$"; then
        fail "agent '$dir_name': frontmatter 'name:' matches its directory"
        return
    fi
    if ! printf '%s\n' "$fm" | grep -qE '^description: .{40,}'; then
        fail "agent '$dir_name': frontmatter has a meaningful 'description:'"
        return
    fi
    local model; model=$(printf '%s\n' "$fm" | sed -n 's/^model: *//p')
    case "$model" in
        haiku|sonnet|opus|fable|inherit|claude-*) pass "agent '$dir_name': valid frontmatter (model: $model)" ;;
        *) fail "agent '$dir_name': model is an alias or full model ID" "got '$model'" ;;
    esac
}

# ─── Workflows ─────────────────────────────────────────────────────────────

check_workflow() {
    local file="$1"
    local name; name=$(basename "$file" .js)
    if ! grep -q '^export const meta = {' "$file"; then
        fail "workflow '$name': starts with 'export const meta = {'"
        return
    fi
    local meta; meta=$(sed -n '/^export const meta = {/,/^}/p' "$file")
    if ! printf '%s\n' "$meta" | grep -qE "name: '$name'"; then
        fail "workflow '$name': meta.name matches the file name"
        return
    fi
    if ! printf '%s\n' "$meta" | grep -qE "description: '"; then
        fail "workflow '$name': meta has a description"
        return
    fi
    if printf '%s\n' "$meta" | grep -qE '\$\{|Date\.now|Math\.random'; then
        fail "workflow '$name': meta is a pure literal" "no interpolation or calls"
        return
    fi
    if grep -qE 'Date\.now\(\)|Math\.random\(\)|new Date\(\)' "$file"; then
        fail "workflow '$name': no Date.now / Math.random / new Date() (they break resume)"
        return
    fi
    local declared used
    declared=$(printf '%s\n' "$meta" | grep -oE "title: '[^']+'" | sed "s/title: //" | sort -u | tr '\n' ' ')
    used=$( { grep -oE "phase\('[^']+'\)" "$file" | sed -E "s/phase\('([^']+)'\)/'\1'/"; grep -oE "phase: '[^']+'" "$file" | sed "s/phase: //"; } | sort -u | tr '\n' ' ')
    if [ "$declared" != "$used" ]; then
        fail "workflow '$name': phase titles in meta match the phases used" "meta: $declared | used: $used"
        return
    fi
    if command -v node >/dev/null 2>&1; then
        # Workflow scripts use top-level await and return: wrap them in an async function to parse.
        local tmp; tmp=$(mktemp -d)
        { echo "(async () => {"; sed 's/^export const meta/const meta/' "$file"; echo "})"; } > "$tmp/workflow.js"
        if ! node --check "$tmp/workflow.js" 2>/dev/null; then
            rm -rf "$tmp"
            fail "workflow '$name': JavaScript parses"
            return
        fi
        rm -rf "$tmp"
    fi
    pass "workflow '$name': valid meta, phases, and syntax"
}

# ─── Settings and hooks ────────────────────────────────────────────────────

check_settings() {
    if ! command -v python3 >/dev/null 2>&1; then
        fail "settings.json checks need python3"
        return
    fi
    local report
    report=$(python3 - "$SETTINGS" "$COMMITTED" <<'PY'
import json, os, re, sys
path, skeleton = sys.argv[1], sys.argv[2]
problems = []
try:
    settings = json.load(open(path))
except ValueError as error:
    print(f"invalid JSON: {error}")
    sys.exit(0)
model = settings.get("model", "")
if model not in ("haiku", "sonnet", "opus", "fable") and not model.startswith("claude-"):
    problems.append(f"model '{model}' is not an alias or full model ID")
for event, entries in settings.get("hooks", {}).items():
    for entry in entries:
        if "command" in entry or not isinstance(entry.get("hooks"), list):
            problems.append(f"{event}: entry must nest its commands in a 'hooks' array")
            continue
        for hook in entry["hooks"]:
            command = hook.get("command", "")
            if hook.get("type") != "command" or not command:
                problems.append(f"{event}: hook without type 'command' and a command")
            if "CLAUDE_FILE_PATH" in command:
                problems.append(f"{event}: $CLAUDE_FILE_PATH does not exist — read tool_input.file_path from stdin")
            match = re.search(r'\.claude/hooks/[\w.-]+', command)
            if match:
                script = os.path.join(skeleton, match.group(0))
                if not os.path.isfile(script):
                    problems.append(f"{event}: {match.group(0)} does not exist")
                elif not os.access(script, os.X_OK):
                    problems.append(f"{event}: {match.group(0)} is not executable")
asks = " ".join(settings.get("permissions", {}).get("ask", []))
# The work branch's push and its draft pull request follow the developer's local check (decision
# 0022); everything else that leaves the machine still asks.
for outward in ("gh pr ready", "gh pr merge", "gh pr comment", "gh issue comment", "gh release"):
    if outward not in asks:
        problems.append(f"permissions.ask does not cover '{outward}'")
print("\n".join(problems) if problems else "OK")
PY
)
    if [ "$report" = "OK" ]; then
        pass "settings.json: valid JSON, alias model, nested hooks pointing at executable scripts, outward actions past the draft pull request in permissions.ask"
    else
        fail "settings.json: structural problems" "$(printf '%s' "$report" | tr '\n' ';')"
    fi
}

check_hook_scripts_syntax() {
    local script bad=""
    for script in "$HOOKS_DIR"/*.sh; do
        bash -n "$script" 2>/dev/null || bad="$bad $(basename "$script")"
    done
    if [ -z "$bad" ]; then pass "hook scripts: bash syntax OK"; else fail "hook scripts: bash syntax errors" "$bad"; fi
}

# ─── Instruction files ─────────────────────────────────────────────────────

check_instruction_files() {
    # Claude Code reads AGENTS.md natively, and reads a CLAUDE.md or CLAUDE.local.md INSTEAD of it
    # (decision 0024): the skeleton ships neither, the stamp is AGENTS.md's first line, and the Claude
    # Code layer is a rule with no paths:, which loads in every session.
    if [ ! -e "$SKELETON/CLAUDE.md" ] && [ ! -e "$SKELETON/CLAUDE.local.md" ] && [ ! -e "$SKELETON/.claude/CLAUDE.md" ]; then
        pass "skeleton: no CLAUDE.md to read instead of AGENTS.md"
    else
        fail "skeleton: ships a CLAUDE.md" "Claude Code would read it instead of AGENTS.md (decision 0024)"
    fi
    # No GEMINI.md either (decision 0025): Antigravity reads AGENTS.md natively and loads a GEMINI.md
    # beside it; Gemini CLI reads AGENTS.md through .gemini/settings.json.
    if [ ! -e "$SKELETON/GEMINI.md" ] && python3 -c 'import json, sys; sys.exit(0 if "AGENTS.md" in json.load(open(sys.argv[1]))["context"]["fileName"] else 1)' "$SKELETON/.gemini/settings.json" 2>/dev/null; then
        pass "skeleton: no GEMINI.md; .gemini/settings.json points Gemini CLI at AGENTS.md"
    else
        fail "skeleton: a GEMINI.md, or .gemini/settings.json doesn't name AGENTS.md in context.fileName" "decision 0025"
    fi
    if head -n 1 "$AGENTS_MD" | grep -q '^<!-- Skeleton source:'; then
        pass "AGENTS.md: the skeleton-source stamp is its first line"
    else
        fail "AGENTS.md: the 'Skeleton source:' stamp must be its first line" "/upgrade and the plugin's hooks read it there"
    fi
    if [ -f "$CLAUDE_LAYER" ] && ! frontmatter "$CLAUDE_LAYER" | grep -q '^paths:' && file_contains "$CLAUDE_LAYER" '^## Skills, agents, and workflows'; then
        pass ".claude/rules/claude-code.md: the Claude Code layer, with no paths: so it loads in every session"
    else
        fail ".claude/rules/claude-code.md: missing, scoped by paths:, or without its skills section"
    fi
}

check_agents_md_workflow() {
    local missing=()
    file_contains "$AGENTS_MD" '[Tt]riage' || missing+=("triage")
    file_contains "$AGENTS_MD" '[Aa]pproval gate' || missing+=("approval gate")
    file_contains "$AGENTS_MD" '[Cc]hange surface' || missing+=("change surface")
    file_contains "$AGENTS_MD" '[Dd]ocs first' || missing+=("docs first")
    file_contains "$AGENTS_MD" 'watch it fail' || missing+=("red before green")
    file_contains "$AGENTS_MD" '[Cc]hange request' || missing+=("change requests")
    file_contains "$AGENTS_MD" '[Dd]on.t invent requirements' || missing+=("don't invent requirements")
    file_contains "$AGENTS_MD" '[Bb]oundaries' || missing+=("boundaries section")
    file_contains "$AGENTS_MD" '\*\*Lane\*\*' || missing+=("lane in the triage")
    file_contains "$AGENTS_MD" '\*\*Fast\*\*' && file_contains "$AGENTS_MD" '\*\*Careful\*\*' && file_contains "$AGENTS_MD" '\*\*Full\*\*' || missing+=("the three lanes")
    file_contains "$AGENTS_MD" '^## Sensitive areas' || missing+=("sensitive areas section")
    file_contains "$AGENTS_MD" '^## Working economically' || missing+=("working economically section")
    if [ ${#missing[@]} -eq 0 ]; then
        pass "AGENTS.md: workflow covers triage, lanes, gate, change surface, docs first, red-green, change requests, sensitive areas, economy, boundaries"
    else
        fail "AGENTS.md: workflow is missing" "${missing[*]}"
    fi
    local lines; lines=$(wc -l < "$AGENTS_MD" | tr -d ' ')
    if [ "$lines" -le 200 ]; then
        pass "AGENTS.md: $lines lines (≤ 200 — it loads every session)"
    else
        fail "AGENTS.md: $lines lines — keep the always-loaded file under 200"
    fi
}

check_git_workflow_prefixes() {
    local missing=()
    local prefix
    for prefix in spec: test: docs: feat: fix: refactor: chore:; do
        file_contains_literal "$GIT_RULE" "\`$prefix\`" || missing+=("$prefix")
    done
    if [ ${#missing[@]} -eq 0 ]; then
        pass "git-workflow rule: documents the commit prefixes"
    else
        fail "git-workflow rule: missing prefixes" "${missing[*]}"
    fi
    if file_contains "$GIT_RULE" '[Dd]raft' && file_contains "$GIT_RULE" 'only when'; then
        pass "git-workflow rule: draft pull requests and outward actions only when asked"
    else
        fail "git-workflow rule: missing draft-PR / outward-action rules"
    fi
}

check_agent_descriptions_not_misleading() {
    local file="$AGENTS_DIR/test-runner/agent.md"
    [ -f "$file" ] || return
    if grep -E '^description:.*[Uu]se after implementation' "$file" >/dev/null 2>&1; then
        fail "agent test-runner: description says 'use after implementation' (wrong for TDD)"
    else
        pass "agent test-runner: description positions tests before implementation"
    fi
}

# ─── Workflow integrity ────────────────────────────────────────────────────

check_workflow_integrity() {
    file_contains "$SKILLS_DIR/write-spec/SKILL.md" '[Mm]andatory section enforcement' \
        && pass "/write-spec: enforces mandatory sections" || fail "/write-spec: missing mandatory section enforcement"
    file_contains "$SKILLS_DIR/write-spec/SKILL.md" 'CR N' \
        && pass "/write-spec: has change-request (CR) mode" || fail "/write-spec: missing change-request mode"
    file_contains "$SKILLS_DIR/write-plan/SKILL.md" '[Aa]pproval gate' && file_contains "$SKILLS_DIR/write-plan/SKILL.md" '[Cc]hange surface' \
        && pass "/write-plan: holds the approval gate on the change surface" || fail "/write-plan: missing approval gate or change surface"
    file_contains "$SKILLS_DIR/implement/SKILL.md" 'status: approved' \
        && pass "/implement: refuses to start without an approved spec" || fail "/implement: missing the approved-spec prerequisite"
    file_contains "$SKILLS_DIR/implement/SKILL.md" 'watch it fail' \
        && pass "/implement: red before green per task" || fail "/implement: missing red-before-green"
    file_contains "$SKILLS_DIR/implement/SKILL.md" '[Rr]econcile' \
        && pass "/implement: reconciles docs with reality" || fail "/implement: missing doc reconciliation"
    file_contains "$SKILLS_DIR/implement/SKILL.md" '[Gg]ate results' \
        && pass "/implement: records gate results" || fail "/implement: missing gate results"
    file_contains "$SKILLS_DIR/write-docs/SKILL.md" '[Ss]kip cleanly' \
        && pass "/write-docs: documents the skip-clean condition" || fail "/write-docs: missing skip-clean condition"
    file_contains "$SKILLS_DIR/open-pr/SKILL.md" '[Dd]raft' && file_contains "$SKILLS_DIR/open-pr/SKILL.md" '[Nn]ever marks' \
        && pass "/open-pr: opens drafts and never marks them ready" || fail "/open-pr: missing draft / never-ready rule"
}

# ─── Spec templates ────────────────────────────────────────────────────────

check_spec_templates() {
    local spec="$TEMPLATES/spec.md" plan="$TEMPLATES/plan.md" tasks="$TEMPLATES/tasks.md"
    local file
    for file in "$spec" "$plan" "$tasks" "$SKELETON/specs/README.md"; do
        [ -f "$file" ] || { fail "spec scaffold: ${file#$SKELETON/} exists"; return; }
    done
    pass "spec scaffold: specs/README.md and _templates/{spec,plan,tasks}.md exist"
    [ ! -e "$SKELETON/specs/_template.md" ] && pass "spec scaffold: legacy single-file template removed" \
        || fail "spec scaffold: legacy specs/_template.md still present"

    local missing=()
    local field
    for field in feature-type personal-data owners references tracker approvals status; do
        file_contains "$spec" "^$field:" || missing+=("$field")
    done
    [ ${#missing[@]} -eq 0 ] && pass "spec.md: frontmatter has the required fields" \
        || fail "spec.md: frontmatter missing fields" "${missing[*]}"

    missing=()
    local section
    for section in 'Business' 'Functional' 'Out of scope' 'Security' 'Testing' 'Documentation'; do
        file_contains "$spec" "^## $section \\[REQUIRED\\]" || missing+=("$section")
    done
    file_contains "$spec" '^## Clarifications \[REQUIRED' || missing+=("Clarifications")
    [ ${#missing[@]} -eq 0 ] && pass "spec.md: all always-required sections present" \
        || fail "spec.md: missing required sections" "${missing[*]}"

    file_contains "$spec" 'Pre-implementable docs' && file_contains "$spec" 'Post-implementable docs' \
        && pass "spec.md: Documentation has Pre- and Post-implementable subsections" \
        || fail "spec.md: Documentation missing the Pre/Post-implementable split"

    missing=()
    for section in 'Constitution check' 'Change surface' 'Test strategy' 'Documentation plan' 'Assumptions'; do
        file_contains "$plan" "^## $section" || missing+=("$section")
    done
    [ ${#missing[@]} -eq 0 ] && pass "plan.md: has constitution check, change surface, test strategy, documentation plan, assumptions" \
        || fail "plan.md: missing sections" "${missing[*]}"

    file_contains "$tasks" '^## Gate results' && file_contains "$tasks" 'watch it fail' \
        && pass "tasks.md: TDD loop per task and a Gate results section" \
        || fail "tasks.md: missing the TDD loop or Gate results"
}

# ─── Links ─────────────────────────────────────────────────────────────────

check_links() {
    # Relative markdown links inside the skeleton must resolve inside the adopted repo — it has no
    # framework docs next to it. That repo is the skeleton plus, in a committed install, the machinery
    # build-committed.py writes (the reference docs among it); module files may point at either.
    local report
    report=$(python3 - "$SKELETON" "$MODULES_DIR" "$COMMITTED" <<'PY'
import os, re, sys
skeleton, modules, committed = sys.argv[1], sys.argv[2], sys.argv[3]
link = re.compile(r'\]\(([^)\s#]+)(#[^)]*)?\)')
fence = re.compile(r'^\s*(```|~~~)')
broken = []
def scan(root, fallbacks):
    for directory, _, files in os.walk(root):
        if "/.git" in directory:
            continue
        for name in files:
            if not name.endswith((".md", ".mdc")):
                continue
            path = os.path.join(directory, name)
            in_fence = False
            for number, line in enumerate(open(path, encoding="utf-8"), 1):
                if fence.match(line):
                    in_fence = not in_fence
                    continue
                if in_fence:
                    continue
                for target, _ in link.findall(line):
                    if re.match(r'^[a-z]+:', target) or target.startswith("/"):
                        continue
                    candidates = [os.path.normpath(os.path.join(directory, target))]
                    relative_dir = os.path.relpath(directory, root)
                    candidates += [os.path.normpath(os.path.join(base, relative_dir, target)) for base in fallbacks]
                    if not any(os.path.exists(candidate) for candidate in candidates):
                        where = os.path.relpath(path, committed) if path.startswith(committed) else os.path.relpath(path, os.path.dirname(skeleton))
                        broken.append(f"{where}:{number} -> {target}")
scan(skeleton, [committed])
scan(committed, [skeleton])
if os.path.isdir(modules):
    for module in os.listdir(modules):
        files = os.path.join(modules, module, "files")
        if os.path.isdir(files):
            scan(files, [skeleton, committed])
print("\n".join(broken) if broken else "OK")
PY
)
    if [ "$report" = "OK" ]; then
        pass "links: every relative link in skeleton/, the committed machinery, and modules/*/files resolves inside the adopted repo"
    else
        fail "links: broken relative links (framework-only targets don't exist in adopting repos)" "$(printf '%s' "$report" | tr '\n' ';')"
    fi
}

# ─── Modules ───────────────────────────────────────────────────────────────

check_modules() {
    [ -d "$MODULES_DIR" ] || { fail "modules/ directory exists"; return; }
    local module name
    for module in "$MODULES_DIR"/*/; do
        name=$(basename "$module")
        # A module whose plugin carries all it adds (a skill, decision 0028) has no files/ of its own.
        if [ -f "$module/MODULE.md" ] && { [ -d "$module/files" ] || [ -f "$module/module.json" ]; }; then
            pass "module '$name': has MODULE.md, and files/ or a module.json"
        else
            fail "module '$name': needs MODULE.md, and a files/ tree or a module.json"
        fi
        if [ -f "$module/files/README.md" ]; then
            fail "module '$name': files/README.md would overwrite the adopting repo's README"
        fi
        # A module names the plugin that carries its skills and agents (decision 0023): adf
        # for the process, adf-dev for development.
        local problem
        problem=$(python3 - "$module" "$name" "$REPO_ROOT/plugins" <<'PY'
import json, os, sys
module, name, plugins = sys.argv[1], sys.argv[2], sys.argv[3]
claude = os.path.join(module, "files", ".claude")
# A module's skills and agents are its plugin's, never files the module copies (decision 0028).
for kind in ("skills", "agents", "workflows", "hooks"):
    if os.path.isdir(os.path.join(claude, kind)):
        print(f"ships files/.claude/{kind}/: its plugin carries a module's skills, and a committed install takes them from there")
manifest = os.path.join(module, "module.json")
if not os.path.exists(manifest):
    sys.exit()
try:
    data = json.load(open(manifest, encoding="utf-8"))
except Exception as e:
    print(f"module.json is not valid JSON: {e}"); sys.exit()
if "plugin" not in data or not set(data) <= {"plugin", "skills", "commands", "moved_from"}:
    print(f"module.json takes plugin and, optionally, skills, commands, and moved_from — it has {sorted(data)}")
elif not os.path.exists(os.path.join(plugins, str(data["plugin"]), ".claude-plugin", "plugin.json")):
    print(f"module.json names {data['plugin']}, which isn't a plugin in plugins/")
for skill in data.get("skills", []):
    if not os.path.isfile(os.path.join(plugins, str(data.get("plugin")), "skills", skill, "SKILL.md")):
        print(f"module.json names the skill {skill}, which plugins/{data.get('plugin')} doesn't carry")
# Decision 0027: the scripts a plugin carries as commands, each named after the plugin.
commands = data.get("commands", {})
for command, rel in commands.items():
    if not command.startswith(f"{data.get('plugin')}-") or not os.path.isfile(os.path.join(module, "files", rel)):
        print(f"module.json: command {command} must be named {data.get('plugin')}-<name> and come from a script in files/")
if not data.get("skills") and not commands:
    print("has a module.json but no skills or commands for a plugin to carry")
# Decision 0032: the folder the commands' scripts lived in before, which the commands still read.
folders = {os.path.dirname(rel) for rel in commands.values()}
if "moved_from" in data and (len(folders) != 1 or not isinstance(data["moved_from"], str) or data["moved_from"] in folders):
    print("module.json: moved_from is the one folder all its commands' scripts lived in before, not the one they're in")
PY
)
        if [ -n "$problem" ]; then
            fail "module '$name': $problem"
        elif [ -f "$module/module.json" ]; then
            pass "module '$name': module.json names the plugin that carries its skills and commands"
        fi
    done
    local fragment problems
    for fragment in "$MODULES_DIR"/*/settings-fragment.json; do
        [ -f "$fragment" ] || continue
        name=$(basename "$(dirname "$fragment")")
        # A module may pre-approve MCP tools and commands only if they read: a write must always
        # prompt, and so must a command that prints secrets.
        problems=$(python3 - "$fragment" "$(dirname "$fragment")/files/.mcp.json" <<'PY'
import json, re, sys
fragment, mcp = sys.argv[1], sys.argv[2]
out = []
try:
    allow = json.load(open(fragment)).get("permissions", {}).get("allow", [])
except Exception as e:
    print(f"settings-fragment.json is not valid JSON: {e}"); sys.exit()
write = re.compile(r"(create|update|delete|remove|add|set|send|post|move|attach|start|stop|edit|comment|assign|resolve|merge|upload)", re.I)
changes = re.compile(r"\b(down|rm|rmi|prune|kill|stop|restart|start|exec|run|up|build|pull|push|cp|create|inspect|login|delete|remove)\b")
for rule in allow:
    if rule.startswith("mcp__"):
        tool = rule.split("__", 2)[-1]
        if tool in ("", "*") or write.search(tool):
            out.append(f"allows a tool that may write: {rule}")
    elif rule.startswith("Bash("):
        command = rule[5:-1]
        if changes.search(command) or command.rstrip(" *").endswith(" config") or re.search(r"\bconfig\b(?! --(quiet|services)\b)", command):
            out.append(f"allows a command that changes state or prints secrets: {rule}")
        elif re.fullmatch(r"[\w-]+( \*)?", command):
            out.append(f"allows a whole program: {rule}")
try:
    servers = json.load(open(mcp)).get("mcpServers", {})
    for name, cfg in servers.items():
        if set(cfg) & {"headers", "env"} or re.search(r"(token|key|secret)=", json.dumps(cfg), re.I):
            out.append(f".mcp.json server '{name}' carries credentials or env")
except FileNotFoundError:
    pass
except Exception as e:
    out.append(f"files/.mcp.json is not valid JSON: {e}")
print("; ".join(out))
PY
)
        if [ -z "$problems" ]; then
            pass "module '$name': pre-approves read-only MCP tools and commands only; no credentials in .mcp.json"
        else
            fail "module '$name': $problems"
        fi
    done
}

check_lanes() {
    local readme="$SKELETON/specs/README.md" triage="$SKILLS_DIR/triage/SKILL.md" missing=()
    file_contains "$readme" '^## Lanes' || missing+=("specs/README.md § Lanes")
    file_contains "$readme" '^### Escalation triggers' || missing+=("specs/README.md § Escalation triggers")
    file_contains "$readme" '^### Careful-lane checklists' || missing+=("specs/README.md § Careful-lane checklists")
    file_contains "$readme" '^### The developer decides' || missing+=("specs/README.md § The developer decides")
    file_contains "$readme" '\*\*Light\*\*' || missing+=("specs/README.md light change request")
    for lane in fast careful full; do
        file_contains "$triage" "$lane" || missing+=("/triage: $lane lane")
    done
    file_contains "$triage" "developer's call" || missing+=("/triage: the developer's call")
    file_contains "$SKILLS_DIR/review/SKILL.md" 'Check the lane' || missing+=("/review: lane check")
    file_contains "$HOOKS_DIR/config.sh" '^CAREFUL_GLOBS=' || missing+=("config.sh: CAREFUL_GLOBS")
    grep -q 'careful-paths.sh' "$SETTINGS" || missing+=("settings.json: careful-paths hook")
    file_contains "$HOOKS_DIR/config.sh" '^TRIAGE_FIRST=' || missing+=("config.sh: TRIAGE_FIRST")
    python3 - "$SETTINGS" <<'PY' || missing+=("settings.json: triage-first hook on Edit|Write|MultiEdit and Bash")
import json, sys
pre = json.load(open(sys.argv[1]))["hooks"]["PreToolUse"]
wired = {e["matcher"] for e in pre for h in e["hooks"] if h["command"].endswith("triage-first.sh")}
sys.exit(0 if {"Bash", "Edit|Write|MultiEdit"} <= wired else 1)
PY
    file_contains "$TEMPLATES/spec.md" '· light' || missing+=("spec template: light change request")
    if [ ${#missing[@]} -eq 0 ]; then
        pass "lanes: defined in specs/README.md, decided by /triage, checked by /review, enforced for sensitive paths"
    else
        fail "lanes: missing" "${missing[*]}"
    fi
}

check_practices() {
    local missing=()
    file_contains "$SKILLS_DIR/debug/SKILL.md" 'Get a failing signal' || missing+=("/debug: failing signal first")
    file_contains "$SKILLS_DIR/debug/SKILL.md" 'Rank 3–5 hypotheses' || missing+=("/debug: ranked hypotheses")
    file_contains "$SKILLS_DIR/debug/SKILL.md" 'DEBUG-' || missing+=("/debug: tagged debug logs")
    file_contains "$AGENTS_MD" 'Ask questions in rounds' || missing+=("AGENTS.md: question rounds")
    file_contains "$SKILLS_DIR/write-spec/SKILL.md" 'Ask in rounds' || missing+=("/write-spec: question rounds")
    file_contains "$SKELETON/docs/GLOSSARY.md" '\*\*Avoid:\*\*' || missing+=("GLOSSARY.md: Avoid list")
    file_contains "$SKILLS_DIR/open-pr/SKILL.md" '## Merge danger' || missing+=("/open-pr: merge danger")
    file_contains "$MODULES_DIR/github/files/.github/pull_request_template.md" '## Merge danger' || missing+=("PR template: merge danger")
    file_contains "$SKELETON/.claude/rules/testing.md" 'Expected values come from outside the code' || missing+=("testing rule: independent expected values")
    file_contains "$SKILLS_DIR/record-decision/SKILL.md" 'hard to reverse' || missing+=("/record-decision: threshold")
    file_contains "$SKILLS_DIR/triage/SKILL.md" 'Declined before' || missing+=("/triage: declined-before check")
    file_contains "$COMMITTED/docs/COST-MODEL.md" '^## Between phases' || missing+=("COST-MODEL.md: between phases")
    file_contains "$SKILLS_DIR/handoff/SKILL.md" 'never a copy' || missing+=("/handoff: pointers, not copies")
    file_contains "$AGENTS_MD" 'Local check before the pull request' || missing+=("AGENTS.md: the developer's local check before the pull request (0022)")
    file_contains "$SKILLS_DIR/open-pr/SKILL.md" 'the \*\*local check\*\*' || missing+=("/open-pr: stops without the developer's local check (0022)")
    file_contains "$HOOKS_DIR/guard-git.sh" 'check_pr_create' || missing+=("guard-git.sh: a pull request opens only as a draft (0022)")
    file_contains "$SKELETON/.claude/rules/git-workflow.md" 'Open after the local check' || missing+=("git-workflow rule: a pull request opens after the local check (0022)")
    file_contains "$HOOKS_DIR/session-context.sh" 'branch name is generated' || missing+=("session-context.sh: Claude Code's own worktrees are workers, told what they lack (0015)")
    [ -f "$MODULES_DIR/parallel-agents/files/.worktreeinclude" ] || missing+=("parallel-agents: .worktreeinclude")
    file_contains "$SKILLS_DIR/dispatch/SKILL.md" 'worktree-new.sh <type>/<slug> --no-start' || missing+=("/dispatch: the worker's prompt has it create the task's worktree with the scripts (0021)")
    file_contains "$SKILLS_DIR/dispatch/SKILL.md" 'move this session into it' || missing+=("/dispatch: the worker's prompt has it move into the worktree (0021)")
    file_contains "$SKILLS_DIR/dispatch/SKILL.md" 'task chip for this main checkout' || missing+=("/dispatch: the chip opens in the main checkout (0021)")
    file_contains "$SKILLS_DIR/dispatch/SKILL.md" 'It runs no scripts' || missing+=("/dispatch: the dispatcher runs nothing (0021)")
    file_contains "$SKILLS_DIR/dispatch/SKILL.md" 'task.s title alone' || missing+=("/dispatch: the chip's title is the task's, without the branch (0021, amended)")
    file_contains "$HOOKS_DIR/session-context.sh" 'is that task.s worker, not the dispatcher' || missing+=("session-context.sh: a dispatched session in the main checkout is told it's the worker and its first step (0021)")
    file_contains "$SKILLS_DIR/dispatch/SKILL.md" 'worktree.conf` in this' || missing+=("/dispatch: stops without the module's settings, since the plugin carries it (0020, 0027)")
    file_contains_literal "$HOOKS_DIR/protect-hub.sh" 'worktree_settings "$root" >/dev/null || exit 0' || missing+=("protect-hub.sh: the module's settings show it's installed, in either install (0027)")
    file_contains "$REPO_ROOT/plugins/adf/.generated" '^bin$' || missing+=("the plugin carries the worktree scripts as commands (0027)")
    [ -f "$REPO_ROOT/plugins/adf/skills/dispatch/SKILL.md" ] || missing+=("the plugin carries /dispatch (0020)")
    file_contains "$HOOKS_DIR/session-context.sh" 'Give every task to /dispatch' || missing+=("session-context.sh: the dispatcher gives every task to /dispatch (0020)")
    file_contains "$MODULES_DIR/parallel-agents/files/ops/agent/worktree.conf" '^PORT_SLOTS=0 ' || missing+=("worktree.conf: ports off by default")
    file_contains "$AGENTS_MD" 'write or update the test that asserts the new behavior and watch it fail' || missing+=("AGENTS.md: the fast lane is test-first")
    file_contains "$SKELETON/.claude/rules/testing.md" '^## Red, then green — every change, in every lane' || missing+=("testing rule: red then green in every lane")
    grep -q 'protect-hub.sh' "$SETTINGS" || missing+=("settings.json: protect-hub hook")
    file_contains "$HOOKS_DIR/config.sh" '^HUB_READONLY=' || missing+=("config.sh: HUB_READONLY")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" "Offer the modules the project doesn't have" || missing+=("/upgrade: offers missing modules")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" '### A new project' || missing+=("/adopt: new-project mode")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" "don't follow into the worktree" || missing+=("/upgrade: carries uncommitted changes into the hub's worktree")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'Ask how to install' || missing+=("/adopt: committed or packaged (0016)")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'Packaged\*\* — the default' || missing+=("/adopt: packaged is the default (0018)")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'Adopt from a release' || missing+=("/adopt: takes the framework at the release it pins")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" "sort=-v:refname" || missing+=("/upgrade: moves a packaged project to the newest release tag")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" 'aplyca-framework@aplyca' || missing+=("/upgrade: migrates the plugin's old name")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" 'aplyca-adf@aplyca' || missing+=("/upgrade: renames aplyca-adf to adf (v2.0.0, 0023)")
    python3 -c 'import json, sys; sys.exit(0 if json.load(open(sys.argv[1])).get("renames") == {"aplyca-framework": "aplyca-adf", "aplyca-adf": "adf"} else 1)' "$REPO_ROOT/.claude-plugin/marketplace.json" || missing+=("marketplace: renames aplyca-framework → aplyca-adf → adf, append-only")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" 'Record the switch' || missing+=("/upgrade: records an install switch as a PDR")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'Turn on the plugin that carries a module' || missing+=("/adopt: turns on the plugin that carries a module in a packaged install (0023)")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'Offer `adf-connect`' || missing+=("/adopt: offers adf-connect (0023)")
    file_contains "$HOOKS_DIR/session-context.sh" "replaces this project's AGENTS.md" || missing+=("session-context.sh: warns when a CLAUDE.md replaces AGENTS.md (0024)")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" 'From `CLAUDE.md` to `AGENTS.md`' || missing+=("/upgrade: moves CLAUDE.md into AGENTS.md and the rule (0024)")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'An existing `CLAUDE.md`' || missing+=("/adopt: merges an existing CLAUDE.md (0024)")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" '\*\*No `GEMINI.md`\*\*' || missing+=("/upgrade: removes GEMINI.md (0025)")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'An existing `GEMINI.md`' || missing+=("/adopt: merges an existing GEMINI.md (0025)")
    [ ! -e "$REPO_ROOT/CLAUDE.md" ] || missing+=("this repository: its instructions are AGENTS.md, with no CLAUDE.md (0024)")
    local connect="$REPO_ROOT/plugins/adf-connect/skills/connect/SKILL.md"
    file_contains_literal "$connect" 'No credentials in the repository.' || missing+=("/connect: no credentials committed")
    file_contains_literal "$connect" 'Read-only and not production, unless the developer decides otherwise.' || missing+=("/connect: read-only, not production")
    file_contains_literal "$connect" 'Never allow `mcp__<server>__*`.' || missing+=("/connect: never pre-approves a whole server")
    file_contains_literal "$connect" 'Asking for a write — drafted, not sent — prompts' || missing+=("/connect: verifies that writes prompt")
    file_contains "$REPO_ROOT/plugins/adf/skills/adopt/SKILL.md" 'modules/docker/install.sh' || missing+=("/adopt: offers and installs the docker module")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" '<plugin>@aplyca' || missing+=("/upgrade: turns on the plugin that carries a module (0023)")
    file_contains "$REPO_ROOT/plugins/adf/skills/upgrade/SKILL.md" 'modules/docker/install.sh' || missing+=("/upgrade: reruns and installs the docker module")
    file_contains "$SKILLS_DIR/dev-env/SKILL.md" 'list names `docker`' || missing+=("/dev-env: stops without the module, since a plugin carries it (0023)")
    file_contains "$SKILLS_DIR/dev-env/SKILL.md" 'this is the main checkout of a hub' || missing+=("/dev-env: stops in the hub")
    file_contains "$SKILLS_DIR/dev-env/SKILL.md" 'without `--quiet`' || missing+=("/dev-env: never prints a resolved Compose config")
    ! file_contains "$REPO_ROOT/CONTRIBUTING.md" 'Bump the plugin version' || missing+=("CONTRIBUTING.md: the plugin's version changes only in a release (0017)")
    file_contains "$REPO_ROOT/docs/SETUP.md" '## Packaged install' || missing+=("SETUP.md: the packaged install")
    file_contains_literal "$REPO_ROOT/ADOPT.md" '--scope project' || missing+=("ADOPT.md: the agent entry point installs per project")
    file_contains_literal "$REPO_ROOT/README.md" '(ADOPT.md)' || missing+=("README.md: points agents to ADOPT.md")
    file_contains "$SKELETON/docs/getting-started/DEV-SETUP.md" 'needs no install step' || missing+=("DEV-SETUP.md: joining a project needs no install")
    file_contains "$REPO_ROOT/README.md" 'claude plugin marketplace update aplyca' || missing+=("install prompt: refreshes a marketplace added before")
    file_contains "$REPO_ROOT/README.md" 'there is nothing to install' || missing+=("install prompt: stops when the project already turns the plugin on")
    file_contains "$REPO_ROOT/docs/SETUP.md" 'by their full names' || missing+=("SETUP.md: a packaged DEV-SETUP.md names the commands in full")
    if [ ${#missing[@]} -eq 0 ]; then
        pass "practices: signal-first debugging, question rounds, glossary, merge danger, test independence, decision threshold, handoff, worktree roles, portable worktree defaults, test-first in every lane, the hub enforced, /upgrade offers modules, adopting from one prompt and in a new project, joining one with no install"
    else
        fail "practices: missing" "${missing[*]}"
    fi
}

check_plugin() {
    local skill
    for skill in "$REPO_ROOT"/plugins/*/skills/*/; do
        [ -d "$skill" ] && check_skill_frontmatter "$skill"
    done
    local report
    report=$(python3 - "$REPO_ROOT/plugins" <<'PY'
import os, re, sys
plugins = sys.argv[1]
owner = {}
for plugin in sorted(os.listdir(plugins)):
    for kind in ("skills", "agents"):
        folder = os.path.join(plugins, plugin, kind)
        for entry in sorted(os.listdir(folder)) if os.path.isdir(folder) else []:
            name = entry[:-3] if kind == "agents" else entry
            if (kind, name) in owner:
                print(f"{kind[:-1]} '{name}' is in both {owner[kind, name]} and {plugin}")
            owner[kind, name] = plugin
            if kind == "agents":
                head = open(os.path.join(folder, entry), encoding="utf-8").read().split("\n---\n")[0]
                if not re.search(rf"^name: {re.escape(name)}$", head, re.M):
                    print(f"{plugin}/agents/{entry}: frontmatter 'name:' isn't {name}")
                if not re.search(r"^description: .{40,}", head, re.M):
                    print(f"{plugin}/agents/{entry}: no meaningful description")
PY
)
    if [ -z "$report" ]; then
        pass "plugins: every skill and agent name is unique across plugins; flat agents have valid frontmatter"
    else
        fail "plugins: $report"
    fi
    local script
    for script in "$REPO_ROOT"/plugins/*/skills/*/*.py; do
        [ -f "$script" ] || continue
        if python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' "$script" 2>/dev/null; then
            pass "plugin script '$(basename "$script")': compiles"
        else
            fail "plugin script '$(basename "$script")': does not compile"
        fi
    done
}

check_packaged_plugin() {
    # The plugins are the machinery's source (decision 0028); build-plugins.sh generates the parts that
    # can't be kept by hand — the module commands in bin/; the spec model, the agents' checklists, and
    # the skills' steps in adf's workflows; and the version. A source change that wasn't rebuilt would
    # ship the old ones to every packaged project.
    local tmp report
    tmp="$(mktemp -d)"
    cp -R "$REPO_ROOT/plugins" "$tmp/plugins"
    if ! "$REPO_ROOT/scripts/build-plugins.sh" "$tmp" >/dev/null 2>&1; then
        fail "plugins: scripts/build-plugins.sh failed" "$("$REPO_ROOT/scripts/build-plugins.sh" "$tmp" 2>&1 | tail -1)"
    elif diff -r "$tmp/plugins" "$REPO_ROOT/plugins" >/dev/null 2>&1; then
        pass "plugins/: the generated parts match the modules' scripts, the spec model, the agents' checklists, the skills' steps, and adf's version"
    else
        fail "plugins/ is out of date with a module's scripts, the spec model, an agent's checklist, a skill's steps, or adf's version — run scripts/build-plugins.sh"
    fi
    # Every file a committed install carries comes back unchanged from its committed form, so the two
    # forms can't drift apart: a bare /triage, a local docs/ path, or a stale Step 0 fails here.
    if report=$(python3 "$REPO_ROOT/scripts/build-committed.py" --check 2>&1); then
        pass "plugins: every carried file survives the round trip to the committed form and back"
    else
        fail "plugins: the committed form doesn't round-trip" "$(printf '%s' "$report" | head -12 | tr '\n' ' ')"
    fi
    rm -rf "$tmp"
    report=$(python3 - "$REPO_ROOT" <<'PY'
import json, os, re, sys
root = sys.argv[1]
market = json.load(open(os.path.join(root, ".claude-plugin", "marketplace.json")))
folders = sorted(d for d in os.listdir(os.path.join(root, "plugins")) if os.path.isdir(os.path.join(root, "plugins", d)))
expected = ["adf"] + [d for d in folders if d != "adf"]
names = [p["name"] for p in market["plugins"]]
if names != expected:
    print(f"marketplace.json should list every plugin in plugins/, adf first, {expected} — it lists {names}")
for entry in market["plugins"]:
    if entry.get("source") != f"./plugins/{entry['name']}":
        print(f"{entry['name']}: source should be ./plugins/{entry['name']}")
    if "version" in entry:
        print(f"{entry['name']}: the marketplace entry sets a version — plugin.json carries it")
version = json.load(open(os.path.join(root, "plugins", "adf", ".claude-plugin", "plugin.json"))).get("version", "")
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    print(f"adf's version '{version}' isn't MAJOR.MINOR.PATCH (decision 0017)")
releases = re.findall(r"^## v(\d+\.\d+\.\d+) ", open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8").read(), re.M)
if releases and releases[0] != version:
    print(f"adf is {version}, but the newest release in CHANGELOG.md is v{releases[0]}")
for name in expected:
    manifest = os.path.join(root, "plugins", name, ".claude-plugin", "plugin.json")
    data = json.load(open(manifest)) if os.path.exists(manifest) else {}
    if data.get("name") != name:
        print(f"plugins/{name}/.claude-plugin/plugin.json: name should be {name}")
    if data.get("version") != version:
        print(f"{name} is {data.get('version')}, adf is {version} — every plugin carries the release (decision 0023)")
PY
)
    if [ -z "$report" ]; then
        pass "marketplace lists every plugin, adf first; every plugin's version is the newest release"
    else
        fail "plugin versions and marketplace: $report"
    fi
}

check_plugin_workflow_paths() {
    # A packaged project keeps no copy of the agents or the skills, and a workflow script can't reach the
    # plugin's (decision 0019): a plugin workflow that names .claude/agents/ or .claude/skills/ sends its
    # agents to a file that isn't there. It carries the agent's checklist or the skill's steps it needs
    # instead (decisions 0029 and 0030).
    local report
    report=$(python3 - "$REPO_ROOT" <<'PY'
import glob, os, re, sys
root = sys.argv[1]
# What a packaged project has: the skeleton, and the files its modules copy.
bases = [os.path.join(root, "skeleton")] + glob.glob(os.path.join(root, "modules", "*", "files"))
for workflow in sorted(glob.glob(os.path.join(root, "plugins", "*", "workflows", "*.js"))):
    for number, line in enumerate(open(workflow, encoding="utf-8"), 1):
        if line.lstrip().startswith("//"):
            continue
        # A path to an agent or a skill; a glob over the project's own (.claude/skills/*/SKILL.md) names none.
        for path in re.findall(r"\.claude/(?:agents|skills)/[\w-][\w./-]*", line):
            path = path.rstrip(".")
            if not any(os.path.exists(os.path.join(base, path)) for base in bases):
                print(f"{os.path.relpath(workflow, root)}:{number} names {path}")
PY
)
    if [ -z "$report" ]; then
        pass "plugin workflows: no .claude/agents/ or .claude/skills/ path a packaged project lacks — each carries the checklists and steps it names"
    else
        fail "plugin workflows name an agent or skill file a packaged project lacks — carry the agent's checklist (const <AGENT>_CHECKLIST, decision 0029) or the skill's steps (const <SKILL>_STEPS, decision 0030)" "$(printf '%s' "$report" | tr '\n' ';')"
    fi
}

check_plugin_committed_paths() {
    # The skills, agents, reference docs, and hooks a packaged project runs are the plugin's: it has no
    # .claude/agents/, .claude/workflows/, or .claude/skills/ of the framework's, no agent.md, and no hook
    # script in .claude/hooks/ but config.sh. Text that names one sends a packaged project to a file that
    # isn't there, unless its paragraph says it's about a committed install. The Step 0 names the committed
    # copy on purpose, a glob names the project's own, and the installer's skills (no Step 0) cover both
    # installs.
    local report
    report=$(python3 - "$REPO_ROOT" <<'PY'
import glob, os, re, sys
root = sys.argv[1]
sys.path.insert(0, os.path.join(root, "scripts"))
from forms import STEP0, Machinery
machinery = Machinery(root)
files = glob.glob(os.path.join(root, "plugins", "*", "agents", "*.md"))
files += glob.glob(os.path.join(root, "plugins", "*", "docs", "*.md"))
files += [f for f in glob.glob(os.path.join(root, "plugins", "*", "hooks", "*"))
          if os.path.basename(f) not in ("hooks.json", "README.md")]
for name, plugin in machinery.skills.items():
    files += glob.glob(os.path.join(root, "plugins", plugin, "skills", name, "**", "*.md"), recursive=True)
committed_only = re.compile(r"\.claude/(?:agents|workflows|skills)(?:/[\w<>{}*./-]*)?"
                            r"|(?<![\w/-])agent\.md\b|\.claude/hooks/(?!config\.sh)[\w$][^\s\x60\x27\x22):]*")
for path in sorted(files):
    text = open(path, encoding="utf-8").read()
    step0 = STEP0.match(text)
    # The context that can say "a committed install": a paragraph of prose; one line of a script, where
    # a comment elsewhere in the block doesn't cover a message the hook prints.
    gap = "\n\n" if path.endswith(".md") else "\n"
    for m in committed_only.finditer(text):
        if "*" in m.group(0) or (step0 and len(step0.group(1)) <= m.start() < step0.end()):
            continue
        start = text.rfind(gap, 0, m.start())
        end = text.find(gap, m.end())
        if "committed" in text[start + 1:end if end != -1 else len(text)].lower():
            continue
        print(f"{os.path.relpath(path, root)}:{text.count(chr(10), 0, m.start()) + 1} names {m.group(0)}")
PY
)
    if [ -z "$report" ]; then
        pass "plugin skills, agents, docs, and hooks: no committed install's path (.claude/agents/, workflows/, skills/, agent.md, a hook script) outside a paragraph about a committed install"
    else
        fail "plugin text names a path only a committed install has — name the skill, agent, or workflow instead (/adf:review, @adf:code-reviewer), or say the paragraph is about a committed install" "$(printf '%s' "$report" | tr '\n' ';')"
    fi
}

check_module_plugins() {
    # Each plugin carries the skills of the modules that name it in module.json (decision 0023), and a
    # committed install carries every skill with a Step 0 (decision 0028). The ones without run only from
    # their plugin: adf's installer, and adf-connect's /connect. A Step 0 dropped by mistake would take a
    # skill out of every committed project.
    local report
    report=$(python3 - "$REPO_ROOT" <<'PY'
import os, re, sys
root = sys.argv[1]
sys.path.insert(0, os.path.join(root, "scripts"))
from forms import CORE, Machinery
try:
    machinery = Machinery(root)
except AssertionError as error:
    print(error); sys.exit()
plugin_only = {"adf": {"adopt", "upgrade", "cost-report"}, "adf-connect": {"connect"}}
for plugin in machinery.plugins:
    folder = os.path.join(root, "plugins", plugin, "skills")
    names = set(os.listdir(folder)) if os.path.isdir(folder) else set()
    only = names - {n for n, p in machinery.skills.items() if p == plugin}
    if only != plugin_only.get(plugin, set()):
        print(f"{plugin}'s skills without a Step 0 are {sorted(only)} — expected {sorted(plugin_only.get(plugin, set()))}")
for module, skills in machinery.module_skills.items():
    plugin = machinery.module_plugin[module]
    for name in skills:
        text = open(os.path.join(root, "plugins", plugin, "skills", name, "SKILL.md"), encoding="utf-8").read()
        for bare in re.findall(rf"/{re.escape(plugin)}:([\w-]+)", text):
            if not os.path.isdir(os.path.join(root, "plugins", plugin, "skills", bare)):
                print(f"{plugin}:{name} names /{plugin}:{bare}, which the plugin doesn't carry")
PY
)
    if [ -z "$report" ]; then
        pass "plugins by concern: each carries the skills its modules name; every skill but the installer's goes to a committed install"
    else
        fail "plugins by concern: $report"
    fi
}

check_marketplace_snippets() {
    # extraKnownMarketplaces is an object keyed by marketplace name; an array is silently ignored,
    # so a team registration copied from the docs would never offer the plugin.
    local hits
    hits=$(grep -rnE '"extraKnownMarketplaces"[[:space:]]*:[[:space:]]*\[' "$REPO_ROOT/plugins" "$REPO_ROOT/docs" \
        "$SKELETON" "$MODULES_DIR" "$REPO_ROOT/README.md" 2>/dev/null)
    if [ -z "$hits" ]; then
        pass "extraKnownMarketplaces snippets use the object form"
    else
        fail "extraKnownMarketplaces must be an object keyed by marketplace name: $hits"
    fi
}

check_install_scope() {
    # Without --scope, `claude plugin marketplace add` and `claude plugin install` default to user
    # scope, which turns the plugin on in every project on the machine. Installs are per project.
    local hits
    hits=$(grep -rnE 'claude plugin (marketplace add|install) ' "$REPO_ROOT/plugins" "$REPO_ROOT/docs" \
        "$SKELETON" "$MODULES_DIR" "$REPO_ROOT/README.md" "$REPO_ROOT/ADOPT.md" 2>/dev/null | grep -vE -- '--scope (project|local)')
    if [ -z "$hits" ]; then
        pass "install commands pass --scope project or local"
    else
        fail "install commands without --scope project/local install for every project: $hits"
    fi
}

check_install_prompt() {
    # The install prompt is printed in two READMEs; a fix made in one must reach the other.
    local report
    report=$(python3 - "$REPO_ROOT/README.md" "$REPO_ROOT/plugins/adf/README.md" <<'PY'
import sys, textwrap
blocks = []
for path in sys.argv[1:]:
    lines = open(path, encoding="utf-8").read().split("\n")
    try:
        start = next(i for i, l in enumerate(lines) if "<!-- install-prompt:" in l) + 2
        end = next(i for i in range(start, len(lines)) if lines[i].strip() == chr(96) * 3)  # the closing fence
    except StopIteration:
        print(f"{path}: no install prompt")
        continue
    blocks.append(textwrap.dedent("\n".join(lines[start:end])))
if len(blocks) == 2 and blocks[0] != blocks[1]:
    print("the copies in README.md and the plugin's README differ")
PY
)
    if [ -z "$report" ]; then
        pass "install prompt: identical in README.md and the plugin's README"
    else
        fail "install prompt: $report"
    fi
}

check_english() {
    # Everything in the repository is in English (CONTRIBUTING.md § Ground rules): adopting teams of
    # any language read it, and agents follow one language more consistently.
    git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    local hits
    # This check names the words it looks for, so it skips its own file.
    hits=$(git -C "$REPO_ROOT" ls-files -z -- '*.md' '*.mdc' '*.sh' '*.js' '*.json' '*.py' '*.jq' '*.yml' '*.yaml' ':!evals/static/check-skills.sh' | python3 -c '
import re, sys
spanish = re.compile(r"[áíóúñÁÍÓÚÑ¿¡]|\b(también|según|además|herramienta|desarrollo|cómo|qué|está|nuestr[oa]s?)\b", re.I)
for path in sys.stdin.read().split("\0"):
    if not path:
        continue
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except (OSError, UnicodeDecodeError):
        continue
    for number, line in enumerate(lines, 1):
        if spanish.search(line):
            print(f"{path}:{number}")
            break
' 2>/dev/null)
    if [ -z "$hits" ]; then
        pass "language: every file is in English"
    else
        fail "language: Spanish text — write it in English (CONTRIBUTING.md § Ground rules)" "$(echo "$hits" | tr '\n' ' ')"
    fi
}

check_mods() {
    # The framework's mods are display-only (decision 0026): they read, draw, and add commands. They
    # never approve, refuse, or rewrite a tool call or a prompt, start a turn, run a process, write a
    # file, call a model, or change settings — each of those is the process's, through skills, hooks,
    # and permissions every install shares. One exception (decision 0032): adf-dev's band may run
    # `docker compose port <service> <port>`, read-only, for the port Docker picked — that call,
    # with that argument vector, in that file, and no other. Each mod carries tests (`claude plugin test`).
    local report
    report=$(python3 - "$REPO_ROOT/plugins" <<'PY'
import glob, json, os, re, sys
plugins = sys.argv[1]
display = {"session.start", "session.end", "turn.complete", "command.run", "command.describe",
           "ui.render", "ui.press", "ui.input", "ui.select", "ui.close", "ui.focus", "ui.scroll"}
banned = re.compile(r"\$\.(prompt\.submit|tool\.|process\.|model\.|agent\.|fs\.write|config\.set|env\.set|session\.(?:send|append|compact))")
lookup = re.compile(r"\$\.process\.run\(\['docker', 'compose', 'port', target\.service, target\.port\], \{")
for wiring in sorted(glob.glob(os.path.join(plugins, "*", "hooks", "hooks.json"))):
    if not json.load(open(wiring)).get("modules"):
        continue
    plugin = os.path.dirname(os.path.dirname(wiring))
    name = os.path.basename(plugin)
    sources = [p for p in glob.glob(os.path.join(plugin, "hooks", "*")) if re.search(r"\.(m?[jt]sx?|c[jt]s)$", p)]
    for path in sorted(sources):
        text = open(path, encoding="utf-8").read()
        for event in re.findall(r"\bon\(\s*['\"]([\w.]+)['\"]", text):
            if event not in display:
                print(f"{name}/hooks/{os.path.basename(path)} hooks {event}, which a display-only mod doesn't")
        calls = banned.findall(text)
        if (name, os.path.basename(path)) == ("adf-dev", "register.tsx") and calls.count("process.") == 1 \
                and len(lookup.findall(text)) == 1 and "const target = parseService(service)" in text:
            calls.remove("process.")
        for call in calls:
            print(f"{name}/hooks/{os.path.basename(path)} calls $.{call}, which a display-only mod doesn't")
    if not glob.glob(os.path.join(plugin, "**", "*.test.ts*"), recursive=True):
        print(f"{name}: a mod with no *.test.ts")
PY
)
    if [ -z "$report" ]; then
        pass "mods: display-only — they read, draw, and add commands, never act on a tool call or a prompt, and run no process but the band's docker compose port lookup (0032); each has tests"
    else
        fail "mods: $report"
    fi
}

check_dev_env_templates() {
    # Decision 0032: the stack /dev-env writes from its templates keeps the local-environment
    # conventions — and the scripts any module or skill ships run on macOS's bash 3.2.
    local problems
    problems=$(python3 - "$REPO_ROOT" <<'PY'
import glob, os, re, sys
root = sys.argv[1]
tpl = os.path.join(root, "plugins", "adf-dev", "skills", "dev-env", "templates")
def read(rel):
    with open(os.path.join(tpl, rel), encoding="utf-8") as f:
        return f.read()
files = ["compose.yaml", "Makefile", ".env.example", "ops/scripts/ports.sh", "ops/docker/web/Dockerfile",
         "ops/docker/web/Dockerfile.dockerignore"]
missing = [f for f in files if not os.path.isfile(os.path.join(tpl, f))]
for f in missing:
    print(f"templates/{f} is missing")
if missing:
    sys.exit()
if not os.access(os.path.join(tpl, "ops/scripts/ports.sh"), os.X_OK):
    print("templates/ops/scripts/ports.sh isn't executable")

declared = {m.group(1): m.group(2) for m in re.finditer(r"^([A-Z_][A-Z0-9_]*)=(.*)$", read(".env.example"), re.M)}
for name, value in declared.items():
    if (name.endswith("_PORT") or name == "COMPOSE_PROJECT_NAME") and value:
        print(f".env.example: {name} has a value — empty lets Docker pick the port and the folder name the project")

compose = [l for l in read("compose.yaml").split("\n") if not l.lstrip().startswith("#")]
text = "\n".join(compose)
for key in ("env_file:", "container_name:"):
    if key in text:
        print(f"compose.yaml uses {key}")
if re.search(r"^name:", text, re.M):
    print("compose.yaml has a top-level name:")
for var in sorted(set(re.findall(r"[$][{]([A-Z_][A-Z0-9_]*)", text)) - set(declared)):
    print(f"compose.yaml uses the variable {var}, which .env.example doesn't declare")
for image in re.findall(r"^\s*image:\s*(\S+)", text, re.M):
    if ":" not in image or image.endswith(":latest"):
        print(f"compose.yaml: image {image} isn't pinned")
services, current, in_ports = {}, None, False
for line in compose:
    if re.match(r"^  [a-z][\w-]*:\s*$", line):
        current = line.strip()[:-1]
        services[current] = ""
    elif current and line.startswith("    "):
        services[current] += line + "\n"
    elif line and not line.startswith(" "):
        current = None
for name, body in services.items():
    for port in re.findall(r"^      - (.+)$", body.split("    ports:\n", 1)[1].split("\n    ", 1)[0], re.M) if "    ports:\n" in body else []:
        if not re.fullmatch(r'"127[.]0[.]0[.]1:[$][{][A-Z_][A-Z0-9_]*_PORT:-[}]:[0-9]+"', port.strip()):
            print(f"compose.yaml: {name} publishes {port.strip()}, not on 127.0.0.1 from an empty <NAME>_PORT")
    for dep, condition in re.findall(r"^      ([\w-]+):\n        condition: (\S+)", body, re.M):
        if condition != "service_healthy" or "healthcheck:" not in services.get(dep, ""):
            print(f"compose.yaml: {name} waits for {dep} without a healthcheck it waits on")

make = read("Makefile")
targets = set(re.findall(r"^([a-z][a-z-]*):", make, re.M))
for target in "help env up down build ps logs urls shell services native test lint reset".split():
    if target not in targets:
        print(f"Makefile has no {target} target")
if not re.search(r"^\.DEFAULT_GOAL := help$", make, re.M):
    print("Makefile: help isn't the default target")
for bad, why in ((r"^\.ONESHELL", ".ONESHELL"), (r"!=", "!="), (r"[$][(]file ", "the file function"), (r"^\s*-?include\s+\.env", "include .env"),
                 (r"^export\b", "export")):
    if re.search(bad, make, re.M):
        print(f"Makefile uses {why}, which GNU make 3.81 lacks or which leaks .env")
if re.search(r"^ +\S", "\n".join(l for l in make.split("\n") if not l.startswith("#") and "=" not in l.split(":")[0]), re.M):
    print("Makefile: a recipe line is indented with spaces, not a tab")
logs = re.search(r"^logs:.*\n((?:\t.*\n)+)", make, re.M)
if not logs or not re.search(r"--tail \d+", logs.group(1)) or re.search(r"(^|\s)(-f|--follow)(\s|$)", logs.group(1)):
    print("Makefile: logs must show the last lines and never follow")

bash4 = re.compile(r"declare -A|\bmapfile\b|\breadarray\b|\$\{\w+(,,|\^\^)|\|&|&>>|\bcoproc\b")
scripts = glob.glob(os.path.join(root, "modules", "*", "files", "**", "*.sh"), recursive=True)
scripts += glob.glob(os.path.join(root, "plugins", "*", "skills", "**", "*.sh"), recursive=True)
for script in sorted(scripts):
    for n, line in enumerate(open(script, encoding="utf-8"), 1):
        if not line.lstrip().startswith("#") and bash4.search(line):
            print(f"{os.path.relpath(script, root)}:{n} needs bash 4, and macOS has 3.2")
PY
)
    if [ -z "$problems" ]; then
        pass "dev-env templates: compose.yaml, the Makefile, and .env.example keep the conventions (0032); shipped scripts run on bash 3.2"
    else
        fail "dev-env templates" "$(echo "$problems" | tr '\n' ';')"
    fi
}

check_no_tracked_junk() {
    git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    local hits
    hits=$(git -C "$REPO_ROOT" ls-files | grep -E '(^|/)__pycache__/|\.py[cod]$|(^|/)\.DS_Store$|(^|/)Thumbs\.db$|\.swp$|(^|/)\.claude/settings\.local\.json$|(^|/)\.claude/worktrees/|(^|/)\.env(\.[^/]*)?$' | grep -v '\.env\.example$' | tr '\n' ' ')
    if [ -z "$hits" ]; then
        pass "no bytecode, OS files, local settings, worktrees, or env files are committed"
    else
        fail "committed files that .gitignore should keep out: $hits"
    fi
}

check_directory_rules() {
    git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    local links bad
    links=$(git -C "$REPO_ROOT" ls-files -s | awk '$1 == "120000" { print $4 }' | tr '\n' ' ')
    # The Claude Directory refuses a command whose file the shell computes, and inline programs: the
    # plugin's hooks name every file they load or run literally, and keep programs in files.
    bad=$(python3 - "$REPO_ROOT/plugins" <<'PY'
import glob, json, os, re, sys
hooks_dirs = sorted(glob.glob(os.path.join(sys.argv[1], "*", "hooks")))
for hooks_dir in hooks_dirs:
    wiring = os.path.join(hooks_dir, "hooks.json")
    if not os.path.exists(wiring):
        continue
    wired = json.load(open(wiring))
    # A mod's hooks module (decision 0026): one path, beside hooks.json, to a file of the plugin's.
    for module in wired.get("modules", []):
        target = os.path.normpath(os.path.join(hooks_dir, module))
        if module.startswith("/") or ".." in module.split("/") or not os.path.isfile(target):
            print(f"{os.path.relpath(wiring, sys.argv[1])}: module {module} isn't a file beside it")
    for group in wired.get("hooks", {}).values():
        for entry in group:
            for hook in entry["hooks"]:
                if not re.fullmatch(r'"\$\{CLAUDE_PLUGIN_ROOT\}/hooks/[a-z-]+\.sh"', hook["command"]):
                    print(f"{os.path.relpath(wiring, sys.argv[1])}: {hook['command']}")
command = r'(?:^|[|;&({`]|\$\(|\bthen\b|\bdo\b|\belse\b)\s*'  # where a program name starts a command
rules = [
    (r'^\s*(\.|source)\s+(?!"\$\{CLAUDE_PLUGIN_ROOT\}/hooks/_lib\.sh"$)', "sources a computed path"),
    (r'\$HOOKS_DIR|dirname "\$0"|BASH_SOURCE', "computes the hooks folder"),
    (command + r'(awk|sed|perl|ruby|node)\b', "runs an inline program"),
    (command + r'python3?\s+(-c\b|-\s)', "runs inline Python"),
    (command + r'(ba)?sh\s+-c\b', "runs an inline shell program"),
    (r"<<-?\s*'?[A-Z]+'?\s*$", "feeds a program a here-document"),
    (command + r'jq\b(?!.*\s-f\s)', "runs an inline jq program"),
    (r'(^|[\s(])"?\$[{A-Za-z_][^"\s]*"?/\*', "lists files with a wildcard"),
    (r'\*/\*', "has a */* wildcard"),
    (r"-name\s+'[^']*\*", "has a find -name wildcard"),
    (r'\{\d*,\d*\}', "has a brace pattern"),
    (r'(^|[^<>&0-9])(>>?|<)\s*"?\$', "redirects to or from a computed path"),
    (r'\bcd\s+"\$\(', "changes into a computed directory"),
    (r'\b(jq|python3?)\b[^|]*\s"\$(?!1"|\{CLAUDE_PLUGIN_ROOT\})', "hands a program interpreter a computed path"),
    (r'\$\{TMPDIR:-/tmp\}', "builds a path from a defaulted variable"),
    (r'>\.', "has a greater-than sign before a period, read as a redirect to the folder"),
]
for path in sorted(p for d in hooks_dirs for p in glob.glob(os.path.join(d, "*.sh"))):
    for number, line in enumerate(open(path, encoding="utf-8"), 1):
        if line.lstrip().startswith("#"):
            continue
        for pattern, what in rules:
            if re.search(pattern, line):
                print(f"{os.path.relpath(path, sys.argv[1])}:{number} {what}")
PY
)
    bad+=$(git -C "$REPO_ROOT" grep -n -F '${CLAUDE_PLUGIN_ROOT}/..' -- plugins | sed 's/$/ reaches outside the plugin/')
    if [ -z "$links" ] && [ -z "$bad" ]; then
        pass "the Claude Directory's checks: no symlinks; the plugin's hooks name every file they load or run literally, with no inline programs; nothing reaches outside the plugin"
    else
        fail "the Claude Directory's checks: symlinks [$links] ${bad//$'\n'/; }"
    fi
}

# ─── Main ──────────────────────────────────────────────────────────────────

echo ""
echo "Static evals — framework structural checks"
echo "==========================================="
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    check_skill_frontmatter "$skill_dir"
    check_skill_has_steps_or_phases "$skill_dir"
    check_skill_discipline "$skill_dir"
done
check_outward_skills_user_invoked

echo ""
for agent_file in "$AGENTS_DIR"/*/agent.md; do
    check_agent "$agent_file"
done
check_agent_descriptions_not_misleading

echo ""
for workflow in "$WORKFLOWS_DIR"/*.js "$REPO_ROOT"/plugins/*/workflows/*.js; do
    [ -f "$workflow" ] && check_workflow "$workflow"
done

echo ""
check_settings
check_hook_scripts_syntax
check_instruction_files
check_agents_md_workflow
check_git_workflow_prefixes

echo ""
check_workflow_integrity

echo ""
check_spec_templates

echo ""
check_links
check_modules
check_marketplace_snippets
check_packaged_plugin
check_plugin_workflow_paths
check_plugin_committed_paths
check_module_plugins
check_install_scope
check_install_prompt
check_lanes
check_practices
check_plugin
check_mods
check_dev_env_templates
check_no_tracked_junk
check_english
check_directory_rules

echo ""
echo "==========================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -gt 0 ] && exit 1
exit 0
