#!/usr/bin/env bash
#
# Functional tests for the plugin's scripts: /cost-report's session_cost.py against synthetic Claude
# Code transcripts in a throwaway projects directory, the reference-doc links /adopt and /upgrade
# rewrite with scripts/link-reference-docs.py, on a copy of the skeleton, and the commands in the
# plugin's bin/ in throwaway repositories. No AI invocation, no network. Needs bash, git ≥ 2.31, and
# python3. Exit 0 on all-pass.
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

# The plugin's commands (decision 0025): the parallel-agents scripts, on the Bash tool's PATH — last,
# as Claude Code puts the plugin's bin/ — in a packaged project, which commits only worktree.conf.
BIN="$REPO_ROOT/plugins/adf/bin"
COMMANDS="adf-worktree-new adf-worktree-ls adf-worktree-rm"
check "commands: adf carries $COMMANDS, executable" "for c in $COMMANDS; do [ -x \"\$BIN/\$c\" ] || exit 1; done"
check "commands: each is one file — none loads a helper or looks beside itself" \
    "! grep -l -e 'dirname \"\$0\"' -e BASH_SOURCE -e '_worktree-lib.sh\"' \"\$BIN\"/* | grep -q ."
check "commands: the plugins' copies name the commands, not the module's scripts" \
    "! grep -rnE '(^|[^/\$A-Za-z0-9_-])(scripts/agent/)?worktree-(new|ls|rm)\.sh' \"\$REPO_ROOT/plugins/adf/skills/dispatch\" \"\$REPO_ROOT/plugins/adf/hooks\" \"\$REPO_ROOT/plugins/adf-dev/skills\" \"\$BIN\" | grep -v -e 'ADF_CHECKOUT/scripts/agent/' -e \"plugin's copy of the\" | grep -q ."
on_path() { PATH="$PATH:$BIN" "$@"; }
WT="$WORK/worktrees"
mkdir -p "$WT" && git init -q --bare "$WT/origin.git" && git clone -q "$WT/origin.git" "$WT/site" 2>/dev/null
S="$WT/site"
git -C "$S" config user.email test@example.com && git -C "$S" config user.name test && git -C "$S" symbolic-ref HEAD refs/heads/main
mkdir -p "$S/scripts/agent" "$S/docs"
cp "$REPO_ROOT/modules/parallel-agents/files/scripts/agent/worktree.conf" "$S/scripts/agent/"
python3 - "$S/scripts/agent/worktree.conf" <<'CONF'
import sys
path = sys.argv[1]
text = open(path).read()
for old, new in (('PORT_SLOTS=0', 'PORT_SLOTS=180'), ("ENV_OVERRIDES=''", "ENV_OVERRIDES='SITE_URL=http://localhost:${APP_PORT}'")):
    assert old in text, old
    text = text.replace(old, new, 1)
open(path, "w").write(text)
CONF
printf 'SECRET=\nAPP_PORT=\n' > "$S/.env.example" && printf '.env\n' > "$S/.gitignore" && echo '# Site' > "$S/docs/README.md"
git -C "$S" add -A && git -C "$S" commit -qm init && git -C "$S" push -q -u origin main 2>/dev/null
printf 'SECRET=abc\n' > "$S/.env"
out=$(cd "$S" && on_path adf-worktree-new feat/newsletter-signup --no-start 2>&1); code=$?
W1="$WT/feat-newsletter-signup"
check "adf-worktree-new: creates a sibling worktree in a project that commits only worktree.conf" \
    "[ $code -eq 0 ] && [ -f '$W1/.git' ] && [ -f \"\$(git -C '$W1' rev-parse --absolute-git-dir)/agent-worktree\" ]"
check "adf-worktree-new: reads the project's worktree.conf — a port, and the overrides with it" \
    "grep -q '^SECRET=abc$' '$W1/.env' && grep -qE '^SITE_URL=http://localhost:[0-9]+$' '$W1/.env'"
echo 'LOCAL_EXPERIMENT=1' >> "$W1/.env"
out=$(cd "$W1" && on_path adf-worktree-new fix/other-thing --no-start 2>&1); code=$?
W2="$WT/fix-other-thing"
check "adf-worktree-new: from inside a worktree, makes a sibling of the main checkout, seeded from it" \
    "[ $code -eq 0 ] && [ -f '$W2/.git' ] && grep -q '^SECRET=abc$' '$W2/.env' && ! grep -q LOCAL_EXPERIMENT '$W2/.env'"
out=$(cd "$S/docs" && on_path adf-worktree-new chore/from-docs --no-start 2>&1); code=$?
check "adf-worktree-new: works from a subdirectory of the checkout" "[ $code -eq 0 ] && [ -f '$WT/chore-from-docs/.git' ]"
out=$(cd "$S" && on_path adf-worktree-ls 2>&1)
check "adf-worktree-ls: lists every worktree and marks the main checkout" \
    "echo \"\$out\" | grep -q feat/newsletter-signup && echo \"\$out\" | grep -q fix/other-thing && echo \"\$out\" | grep -q 'main checkout'"
out=$(cd "$S" && on_path adf-worktree-rm fix/other-thing 2>&1); code=$?
check "adf-worktree-rm: removes the worktree and its merged branch" \
    "[ $code -eq 0 ] && [ ! -d '$W2' ] && ! git -C '$S' show-ref --verify --quiet refs/heads/fix/other-thing"
out=$(cd "$WT" && on_path adf-worktree-new feat/nowhere --no-start 2>&1); code=$?
check "adf-worktree-new: outside a repository, stops and says so" "[ $code -ne 0 ] && echo \"\$out\" | grep -q 'not inside a git repository'"
mkdir -p "$WT/plain" && git -C "$WT/plain" init -q -b main && git -C "$WT/plain" -c user.email=t@e -c user.name=t commit -q --allow-empty -m init
out=$(cd "$WT/plain" && on_path adf-worktree-new feat/nothing --no-start 2>&1); code=$?
check "adf-worktree-new: in a project without the module, stops and creates nothing" \
    "[ $code -ne 0 ] && echo \"\$out\" | grep -q \"doesn't use the parallel-agents module\" && [ ! -e '$WT/feat-nothing' ]"
printf '#!/bin/sh\necho "$@" > "%s/handed-over"\n' "$WT" > "$S/scripts/agent/worktree-new.sh" && chmod +x "$S/scripts/agent/worktree-new.sh"
out=$(cd "$S" && on_path adf-worktree-new feat/committed --no-start 2>&1); code=$?
check "adf-worktree-new: in a committed install, runs the project's own script with the same arguments" \
    "[ $code -eq 0 ] && [ \"\$(cat '$WT/handed-over' 2>/dev/null)\" = 'feat/committed --no-start' ] && [ ! -e '$WT/feat-committed' ]"

echo "======================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""
[ "$FAIL" -gt 0 ] && exit 1
exit 0
