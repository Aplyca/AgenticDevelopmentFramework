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
# skeleton/ and modules/.
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"
SKELETON="$REPO_ROOT/skeleton"

if [ ! -d "$SKELETON/.claude/skills" ]; then
    echo "ERROR: cannot locate skeleton/.claude/skills under $REPO_ROOT" >&2
    echo "       This script must be run from inside the framework repo." >&2
    exit 2
fi

SKILLS_DIR="$SKELETON/.claude/skills"
AGENTS_DIR="$SKELETON/.claude/agents"
WORKFLOWS_DIR="$SKELETON/.claude/workflows"
HOOKS_DIR="$SKELETON/.claude/hooks"
SETTINGS="$SKELETON/.claude/settings.json"
TEMPLATES="$SKELETON/specs/_templates"
AGENTS_MD="$SKELETON/AGENTS.md"
CLAUDE_MD="$SKELETON/CLAUDE.md"
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
DISCIPLINE_SKILLS="write-spec write-plan write-tests write-docs implement review commit refactor debug spec-drift orchestrate triage open-pr stakeholder-update record-decision context-audit dispatch"
# Skills with side effects outside this machine as soon as they run: user-invoked only.
OUTWARD_SKILLS="open-pr"
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
    report=$(python3 - "$SETTINGS" "$SKELETON" <<'PY'
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
for outward in ("git push", "gh pr create", "gh pr ready", "gh pr merge"):
    if outward not in asks:
        problems.append(f"permissions.ask does not cover '{outward}'")
print("\n".join(problems) if problems else "OK")
PY
)
    if [ "$report" = "OK" ]; then
        pass "settings.json: valid JSON, alias model, nested hooks pointing at executable scripts, outward actions in permissions.ask"
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

check_claude_md_imports_agents_md() {
    # Claude Code reads CLAUDE.md INSTEAD of AGENTS.md when both exist — the import is what loads it.
    if file_contains "$CLAUDE_MD" '^@AGENTS\.md$'; then
        pass "CLAUDE.md: imports AGENTS.md (@AGENTS.md)"
    else
        fail "CLAUDE.md: missing the '@AGENTS.md' import" "without it Claude Code never loads AGENTS.md"
    fi
    if file_contains "$CLAUDE_MD" 'Skeleton source:'; then
        pass "CLAUDE.md: has the skeleton-source stamp line"
    else
        fail "CLAUDE.md: missing the 'Skeleton source:' stamp line"
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
    # Relative markdown links inside the skeleton must resolve inside the skeleton — an adopting repo
    # has no framework docs next to it. Module files may also point at skeleton files.
    local report
    report=$(python3 - "$SKELETON" "$MODULES_DIR" <<'PY'
import os, re, sys
skeleton, modules = sys.argv[1], sys.argv[2]
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
                        broken.append(f"{os.path.relpath(path, os.path.dirname(skeleton))}:{number} -> {target}")
scan(skeleton, [])
if os.path.isdir(modules):
    for module in os.listdir(modules):
        files = os.path.join(modules, module, "files")
        if os.path.isdir(files):
            scan(files, [skeleton])
print("\n".join(broken) if broken else "OK")
PY
)
    if [ "$report" = "OK" ]; then
        pass "links: every relative link in skeleton/ and modules/*/files resolves inside the adopted repo"
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
        if [ -f "$module/MODULE.md" ] && [ -d "$module/files" ]; then
            pass "module '$name': has MODULE.md and files/"
        else
            fail "module '$name': needs MODULE.md and a files/ tree"
        fi
        if [ -f "$module/files/README.md" ]; then
            fail "module '$name': files/README.md would overwrite the adopting repo's README"
        fi
    done
    local fragment problems
    for fragment in "$MODULES_DIR"/*/settings-fragment.json; do
        [ -f "$fragment" ] || continue
        name=$(basename "$(dirname "$fragment")")
        # A module may pre-approve MCP tools only if they read: a write tool must always prompt.
        problems=$(python3 - "$fragment" "$(dirname "$fragment")/files/.mcp.json" <<'PY'
import json, re, sys
fragment, mcp = sys.argv[1], sys.argv[2]
out = []
try:
    allow = json.load(open(fragment)).get("permissions", {}).get("allow", [])
except Exception as e:
    print(f"settings-fragment.json is not valid JSON: {e}"); sys.exit()
write = re.compile(r"(create|update|delete|remove|add|set|send|post|move|attach|start|stop|edit|comment|assign|resolve|merge|upload)", re.I)
for rule in allow:
    if rule.startswith("mcp__"):
        tool = rule.split("__", 2)[-1]
        if tool in ("", "*") or write.search(tool):
            out.append(f"allows a tool that may write: {rule}")
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
            pass "module '$name': pre-approves read-only MCP tools only; no credentials in .mcp.json"
        else
            fail "module '$name': $problems"
        fi
    done
    local skill
    for skill in "$MODULES_DIR"/*/files/.claude/skills/*/; do
        [ -d "$skill" ] || continue
        check_skill_frontmatter "$skill"
        check_skill_has_steps_or_phases "$skill"
        check_skill_discipline "$skill"
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
    file_contains "$SKELETON/docs/COST-MODEL.md" '^## Between phases' || missing+=("COST-MODEL.md: between phases")
    file_contains "$SKILLS_DIR/handoff/SKILL.md" 'never a copy' || missing+=("/handoff: pointers, not copies")
    file_contains "$HOOKS_DIR/session-context.sh" 'branch name is generated' || missing+=("session-context.sh: Claude Code's own worktrees are workers, told what they lack (0015)")
    [ -f "$MODULES_DIR/parallel-agents/files/.worktreeinclude" ] || missing+=("parallel-agents: .worktreeinclude")
    file_contains "$MODULES_DIR/parallel-agents/files/.claude/skills/dispatch/SKILL.md" '## Which route' || missing+=("/dispatch: which route a task takes")
    file_contains "$MODULES_DIR/parallel-agents/files/scripts/agent/worktree.conf" '^PORT_SLOTS=0 ' || missing+=("worktree.conf: ports off by default")
    file_contains "$AGENTS_MD" 'write or update the test that asserts the new behavior and watch it fail' || missing+=("AGENTS.md: the fast lane is test-first")
    file_contains "$SKELETON/.claude/rules/testing.md" '^## Red, then green — every change, in every lane' || missing+=("testing rule: red then green in every lane")
    grep -q 'protect-hub.sh' "$SETTINGS" || missing+=("settings.json: protect-hub hook")
    file_contains "$HOOKS_DIR/config.sh" '^HUB_READONLY=' || missing+=("config.sh: HUB_READONLY")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/upgrade/SKILL.md" "Offer the modules the project doesn't have" || missing+=("/upgrade: offers missing modules")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/adopt/SKILL.md" '### A new project' || missing+=("/adopt: new-project mode")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/upgrade/SKILL.md" "don't follow into the worktree" || missing+=("/upgrade: carries uncommitted changes into the hub's worktree")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/adopt/SKILL.md" 'Ask how to install' || missing+=("/adopt: committed or packaged (0016)")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/upgrade/SKILL.md" "sort=-v:refname" || missing+=("/upgrade: moves a packaged project to the newest release tag")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/upgrade/SKILL.md" 'aplyca-framework@aplyca' || missing+=("/upgrade: migrates the plugin's old name")
    file_contains "$REPO_ROOT/plugins/aplyca-adf/skills/upgrade/SKILL.md" 'Record the switch' || missing+=("/upgrade: records an install switch as a PDR")
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
    local plugin="$REPO_ROOT/plugins/aplyca-adf" skill
    for skill in "$plugin"/skills/*/; do
        [ -d "$skill" ] && check_skill_frontmatter "$skill"
    done
    local script
    for script in "$plugin"/skills/*/*.py; do
        [ -f "$script" ] || continue
        if python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' "$script" 2>/dev/null; then
            pass "plugin script '$(basename "$script")': compiles"
        else
            fail "plugin script '$(basename "$script")': does not compile"
        fi
    done
}

check_packaged_plugin() {
    # The machinery in plugins/aplyca-adf is generated from skeleton/.claude (decision 0016). A
    # skeleton change that wasn't rebuilt would ship the old machinery to every packaged project.
    local tmp report
    tmp="$(mktemp -d)"
    cp -R "$REPO_ROOT/plugins/aplyca-adf" "$tmp/aplyca-adf"
    if ! "$REPO_ROOT/scripts/build-aplyca-adf.sh" "$tmp/aplyca-adf" >/dev/null 2>&1; then
        fail "plugins/aplyca-adf: scripts/build-aplyca-adf.sh failed"
    elif diff -r "$tmp/aplyca-adf" "$REPO_ROOT/plugins/aplyca-adf" >/dev/null 2>&1; then
        pass "plugins/aplyca-adf matches skeleton/.claude"
    else
        fail "plugins/aplyca-adf is out of date with skeleton/.claude — run scripts/build-aplyca-adf.sh"
    fi
    rm -rf "$tmp"
    report=$(python3 - "$REPO_ROOT" <<'PY'
import json, os, re, sys
root = sys.argv[1]
market = json.load(open(os.path.join(root, ".claude-plugin", "marketplace.json")))
names = [p["name"] for p in market["plugins"]]
if names != ["aplyca-adf"]:
    print(f"marketplace.json should list the one plugin, aplyca-adf — it lists {names}")
version = json.load(open(os.path.join(root, "plugins", "aplyca-adf", ".claude-plugin", "plugin.json"))).get("version", "")
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    print(f"aplyca-adf's version '{version}' isn't MAJOR.MINOR.PATCH (decision 0017)")
releases = re.findall(r"^## v(\d+\.\d+\.\d+) ", open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8").read(), re.M)
if releases and releases[0] != version:
    print(f"aplyca-adf is {version}, but the newest release in CHANGELOG.md is v{releases[0]}")
PY
)
    if [ -z "$report" ]; then
        pass "marketplace lists aplyca-adf; its version is semver and matches the newest release"
    else
        fail "plugin version: $report"
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
    report=$(python3 - "$REPO_ROOT/README.md" "$REPO_ROOT/plugins/aplyca-adf/README.md" <<'PY'
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
    bad=$(python3 - "$REPO_ROOT/plugins/aplyca-adf/hooks" <<'PY'
import glob, json, os, re, sys
hooks_dir = sys.argv[1]
for group in json.load(open(os.path.join(hooks_dir, "hooks.json")))["hooks"].values():
    for entry in group:
        for hook in entry["hooks"]:
            if not re.fullmatch(r'"\$\{CLAUDE_PLUGIN_ROOT\}/hooks/[a-z-]+\.sh"', hook["command"]):
                print(f"hooks.json: {hook['command']}")
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
]
for path in sorted(glob.glob(os.path.join(hooks_dir, "*.sh"))):
    for number, line in enumerate(open(path, encoding="utf-8"), 1):
        if line.lstrip().startswith("#"):
            continue
        for pattern, what in rules:
            if re.search(pattern, line):
                print(f"{os.path.basename(path)}:{number} {what}")
PY
)
    if [ -z "$links" ] && [ -z "$bad" ]; then
        pass "the Claude Directory's checks: no symlinks; the plugin's hooks name every file they load or run literally, with no inline programs"
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
for workflow in "$WORKFLOWS_DIR"/*.js; do
    [ -f "$workflow" ] && check_workflow "$workflow"
done

echo ""
check_settings
check_hook_scripts_syntax
check_claude_md_imports_agents_md
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
check_install_scope
check_install_prompt
check_lanes
check_practices
check_plugin
check_no_tracked_junk
check_directory_rules

echo ""
echo "==========================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -gt 0 ] && exit 1
exit 0
