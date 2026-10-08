#!/usr/bin/env bash
#
# Functional tests for the plugin's scripts: /cost-report's session_cost.py against synthetic Claude
# Code transcripts in a throwaway projects directory, and the reference-doc links /adopt and /upgrade
# rewrite with scripts/link-reference-docs.py, on a copy of the skeleton. No AI invocation, no
# network. Needs bash and python3. Exit 0 on all-pass.
#
set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"
REPORT="$REPO_ROOT/plugins/adf/skills/cost-report/session_cost.py"

PASS=0
FAIL=0
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

check() { # check <description> <shell condition>
    if eval "$2"; then PASS=$((PASS+1)); echo "✓ $1"; else FAIL=$((FAIL+1)); echo "✘ $1"; fi
}

# A project at $WORK/code/site, its transcripts under $WORK/projects/<slug>, a .claude/worktrees
# session, and a sibling worktree ../site-fix (the parallel-agents naming).
PROJECT="$WORK/code/site"
mkdir -p "$PROJECT"
slug() { python3 -c 'import re,sys; print(re.sub(r"[^A-Za-z0-9]", "-", sys.argv[1]))' "$1"; }
MAIN="$WORK/projects/$(slug "$PROJECT")"
INNER="$WORK/projects/$(slug "$PROJECT/.claude/worktrees/calm-otter")"
SIBLING="$WORK/projects/$(slug "$WORK/code/site-fix")"
mkdir -p "$MAIN" "$INNER" "$SIBLING"

python3 - "$MAIN" "$INNER" "$SIBLING" <<'PY'
import json, sys, datetime
main, inner, sibling = sys.argv[1:4]
start = datetime.datetime(2026, 9, 1, 9, 0, 0)

def session(path, calls, context, model="claude-opus-5-5", gap_seconds=20, browser=0, spec_edits=0, code_edits=0, title="Session"):
    t = start
    lines = [{"type": "custom-title", "customTitle": title},
             {"type": "user", "timestamp": t.isoformat() + "Z", "message": {"role": "user", "content": "do the task"}}]
    for i in range(calls):
        t += datetime.timedelta(seconds=gap_seconds)
        content = []
        if i < browser:
            content.append({"type": "tool_use", "id": f"b{i}", "name": "mcp__Claude_Browser__computer", "input": {}})
        elif i < browser + spec_edits:
            content.append({"type": "tool_use", "id": f"s{i}", "name": "Edit", "input": {"file_path": "/repo/specs/001-x/spec.md"}})
        elif i < browser + spec_edits + code_edits:
            content.append({"type": "tool_use", "id": f"c{i}", "name": "Edit", "input": {"file_path": "/repo/src/app.ts"}})
        lines.append({"type": "assistant", "timestamp": t.isoformat() + "Z", "message": {
            "id": f"msg_{i}", "model": model, "content": content,
            "usage": {"input_tokens": 10, "cache_read_input_tokens": context, "cache_creation_input_tokens": 1000, "output_tokens": 500}}})
    with open(path, "w") as f:
        f.write("\n".join(json.dumps(l) for l in lines) + "\n")

session(f"{main}/aaaaaaaa-1.jsonl", calls=10, context=50_000, title="Quick fix")
session(f"{main}/bbbbbbbb-2.jsonl", calls=40, context=180_000, gap_seconds=400, browser=35, title="Long one")
session(f"{main}/cccccccc-3.jsonl", calls=12, context=60_000, model="claude-sonnet-5-5", spec_edits=6, code_edits=1, title="Spec heavy")
session(f"{inner}/dddddddd-4.jsonl", calls=5, context=40_000, title="Inner worktree")
session(f"{sibling}/eeeeeeee-5.jsonl", calls=5, context=40_000, title="Sibling worktree")
PY

run() { python3 "$REPORT" "$PROJECT" --projects-dir "$WORK/projects" --days 0 "$@" 2>&1; }

echo ""
echo "Plugin tests — plugins/adf"
echo "======================================="

out=$(run)
check "cost-report: counts the project's sessions and its .claude/worktrees" "echo \"\$out\" | grep -q '^4 sessions · 67 calls'"
check "cost-report: leaves sibling worktrees out by default" "! echo \"\$out\" | grep -q 'Sibling worktree'"
out_sib=$(run --siblings)
check "cost-report: --siblings adds them" "echo \"\$out_sib\" | grep -q '^5 sessions'"
check "cost-report: flags long context, pauses, and browser loops" "echo \"\$out\" | grep 'Long one' | grep -q 'long-context' && echo \"\$out\" | grep 'Long one' | grep -q 'pauses:39' && echo \"\$out\" | grep 'Long one' | grep -q 'browser:35'"
check "cost-report: flags a spec-heavy small change" "echo \"\$out\" | grep 'Spec heavy' | grep -q 'spec-heavy'"
check "cost-report: leaves a short, cheap session unflagged" "echo \"\$out\" | grep 'Quick fix' | grep -vq 'long-context\\|pauses\\|browser\\|spec-heavy'"
json=$(run --json)
cost=$(printf '%s' "$json" | python3 -c 'import json,sys; s={x["title"]: x for x in json.load(sys.stdin)}; print(s["Quick fix"]["cost"])')
# 10 calls on Opus: 10×(10×4 + 500×20 + 50,000×0.20 + 1,000×5)/1e6 = 0.25
check "cost-report: prices Opus calls at list prices (\$0.25 for the quick fix, got \$$cost)" "[ '$cost' = '0.25' ]"
sonnet=$(printf '%s' "$json" | python3 -c 'import json,sys; s={x["title"]: x for x in json.load(sys.stdin)}; print(s["Spec heavy"]["model"])')
check "cost-report: recognizes the model tier (got $sonnet)" "[ '$sonnet' = 'sonnet' ]"
on_sonnet=$(printf '%s' "$json" | python3 -c 'import json,sys; s={x["title"]: x for x in json.load(sys.stdin)}; print(s["Quick fix"]["cost_on_sonnet"], s["Spec heavy"]["cost_on_sonnet"] == s["Spec heavy"]["cost"])')
# The same tokens at Sonnet's prices: 10×(10×2 + 500×10 + 50,000×0.20 + 1,000×2.5)/1e6 = 0.18
check "cost-report: re-prices an Opus session at Sonnet's prices (\$0.18; a Sonnet session unchanged — got $on_sonnet)" "[ '$on_sonnet' = '0.18 True' ]"
check "cost-report: shows the Sonnet estimate for Opus sessions only, and totals it" "echo \"\$out\" | grep 'Quick fix' | grep -q '≈0.18' && echo \"\$out\" | grep 'Spec heavy' | grep -q ' - ' && echo \"\$out\" | grep -q '^Model: 3 sessions ran above Sonnet'"
missing=$(python3 "$REPORT" "$WORK/elsewhere" --projects-dir "$WORK/projects" 2>&1); code=$?
check "cost-report: a project without transcripts says so and exits non-zero" "[ $code -ne 0 ] && echo \"\$missing\" | grep -q 'No Claude Code transcripts'"

# link-reference-docs.py (decision 0019), on a copy of the skeleton: a packaged project links the
# reference docs at the release it pins; a committed one, in its own docs/.
LINKS="$REPO_ROOT/scripts/link-reference-docs.py"
SITE="$WORK/linked"
cp -R "$REPO_ROOT/skeleton" "$SITE"
NAMES='COST-MODEL|MCP-INTEGRATION|MEMORY-STRATEGY|SPEC-MODEL'
local_refs() { grep -rlE "(^|[^/.A-Za-z0-9_-])docs/($NAMES)\.md" "$SITE" --include='*.md' --include='*.mdc' | grep -v -e "/\.claude/\(skills\|agents\|workflows\|hooks\)/" -e "/docs/[A-Z-]*\.md$"; }
plugin_docs=$(cd "$REPO_ROOT/plugins/adf/docs" && ls | sort | tr '\n' ' ')
check "link-reference-docs: the plugin carries the four reference docs (got: $plugin_docs)" \
    "[ '$plugin_docs' = 'COST-MODEL.md MCP-INTEGRATION.md MEMORY-STRATEGY.md SPEC-MODEL.md ' ]"
first=$(python3 "$LINKS" "$SITE" --packaged v9.9.9)
check "link-reference-docs: --packaged links every skeleton file at the release" \
    "[ -z \"\$(local_refs)\" ] && grep -q 'blob/v9.9.9/skeleton/docs/SPEC-MODEL.md' \"\$SITE/AGENTS.md\""
again=$(python3 "$LINKS" "$SITE" --packaged v9.9.9)
check "link-reference-docs: a second run changes nothing" "echo \"\$again\" | grep -q 'in 0 file(s)'"
python3 "$LINKS" "$SITE" --packaged v9.9.10 >/dev/null
check "link-reference-docs: a new pin moves every link" \
    "! grep -rq 'blob/v9.9.9/' \"\$SITE\" && grep -q 'blob/v9.9.10/skeleton/docs/COST-MODEL.md' \"\$SITE/.claude/rules/claude-code.md\""
python3 "$LINKS" "$SITE" --committed >/dev/null
check "link-reference-docs: --committed restores the skeleton's files exactly" "diff -r \"\$REPO_ROOT/skeleton\" \"\$SITE\" >/dev/null"
bad=$(python3 "$LINKS" "$SITE" --packaged main 2>&1); code=$?
check "link-reference-docs: --packaged takes a release tag only" "[ $code -ne 0 ] && echo \"\$bad\" | grep -q 'release tag'"
check "link-reference-docs: the files it rewrote are the skeleton's, its committed rules included" "echo \"\$first\" | grep -q 'AGENTS.md, CONTRIBUTING.md' && echo \"\$first\" | grep -q '\.claude/rules/claude-code.md'"

echo "======================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""
[ "$FAIL" -gt 0 ] && exit 1
exit 0
