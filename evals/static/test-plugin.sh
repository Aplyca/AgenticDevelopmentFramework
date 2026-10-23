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

# /track-time's session_time.py (decision 0043): a task's active time by day and block, from the
# transcripts of the main checkout and its worktrees, in UTC so the days are fixed.
TIMER="$REPO_ROOT/plugins/adf/skills/track-time/session_time.py"
TP="$WORK/code/shop"
mkdir -p "$TP" && git -C "$TP" init -q -b main && git -C "$TP" -c user.email=t@e -c user.name=t commit -q --allow-empty -m init
git -C "$TP" worktree add -q -b feat/newsletter-signup "$WORK/code/feat-newsletter-signup" 2>/dev/null
TMAIN="$WORK/projects/$(slug "$TP")"
TWT="$WORK/projects/$(slug "$WORK/code/feat-newsletter-signup")"
mkdir -p "$TMAIN" "$TWT" "$TMAIN--claude-worktrees-calm-otter"
python3 - "$TMAIN" "$TWT" <<'PY'
import json, sys, datetime
main, wt = sys.argv[1:3]

def session(path, events):
    with open(path, "w") as f:
        for when, branch in events:
            f.write(json.dumps({"type": "assistant", "timestamp": when + "Z", "gitBranch": branch}) + "\n")

def every(start, minutes, branch, step=60):
    t = datetime.datetime.fromisoformat(start)
    return [((t + datetime.timedelta(seconds=s)).isoformat(), branch) for s in range(0, minutes * 60 + 1, step)]

# Main checkout: an hour on another task, a break, 10 minutes of triage on main, then the move.
session(f"{main}/11111111-a.jsonl",
        every("2026-10-14T07:00:00", 60, "main") + every("2026-10-14T09:00:00", 10, "main")
        + every("2026-10-14T09:10:00", 30, "feat/newsletter-signup"))
# The worktree: 20 minutes overlapping the session above, a block after lunch, and the next day.
session(f"{wt}/22222222-b.jsonl",
        every("2026-10-14T09:30:00", 20, "feat/newsletter-signup")
        + every("2026-10-14T14:00:00", 45, "feat/newsletter-signup")
        + every("2026-10-15T10:00:00", 30, "feat/newsletter-signup"))
# Another task's session: never on the branch.
session(f"{main}/33333333-c.jsonl", every("2026-10-14T09:15:00", 30, "fix/other-thing"))
# The desktop app's own worktree: 40 minutes on its generated branch, a two-hour break, then the move.
session(f"{main}--claude-worktrees-calm-otter/44444444-d.jsonl",
        every("2026-10-16T09:00:00", 40, "claude/calm-otter") + every("2026-10-16T11:40:00", 10, "fix/nav-focus"))
PY
timer() { TZ=UTC python3 "$TIMER" feat/newsletter-signup "$TP" --projects-dir "$WORK/projects" "$@" 2>&1; }
tjson=$(timer --json)
tq() { printf '%s' "$tjson" | python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"; }
check "track-time: counts the task's sessions in the main checkout and its worktree, not another task's (got $(tq 'd["sessions"]'))" \
    "[ \"\$(tq 'd[\"sessions\"]')\" = \"['11111111', '22222222']\" ]"
# A gap counts up to 5 minutes, as in /cost-report, so a block ends 5 minutes after its last event when a
# longer break follows. 14th: 09:00–09:55 (triage, then the branch; the overlap counted once) and
# 14:00–14:50; 15th: 10:00–10:30.
check "track-time: the triage before the move counts, earlier work and overlaps don't (got $(tq 'd["days"][0]["active_min"]') min on the 14th)" \
    "[ \"\$(tq 'd[\"days\"][0][\"active_min\"]')\" = '105' ]"
check "track-time: splits a day into blocks at breaks longer than 30 minutes (got $(tq '[(b["start"][11:16], b["end"][11:16]) for b in d["days"][0]["blocks"]]'))" \
    "[ \"\$(tq '[(b[\"start\"][11:16], b[\"end\"][11:16]) for b in d[\"days\"][0][\"blocks\"]]')\" = \"[('09:00', '09:55'), ('14:00', '14:50')]\" ]"
check "track-time: one entry per day, and the total (got $(tq '[x["date"] for x in d["days"]], d["total_min"]'))" \
    "[ \"\$(tq '[x[\"date\"] for x in d[\"days\"]], d[\"total_min\"]')\" = \"['2026-10-14', '2026-10-15'] 135\" ]"
since=$(timer --json --since 2026-10-14T14:30:00+00:00 | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["total_min"], d["days"][0]["blocks"][0]["start"][11:16])')
check "track-time: --since counts only what's after the last entry logged (got $since)" "[ '$since' = '50 14:30' ]"
tout=$(timer)
check "track-time: prints the days and their blocks" "echo \"\$tout\" | grep -q '^feat/newsletter-signup · 2 sessions · 2h 15m active over 2 days' && echo \"\$tout\" | grep -q '14:00–14:50'"
generated=$(TZ=UTC python3 "$TIMER" fix/nav-focus "$TP" --projects-dir "$WORK/projects" --json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["total_min"])')
# 09:00–09:40 on the generated branch, its last gap capped at 5 minutes, then 11:40–11:50: 45 + 10.
check "track-time: a session in the app's own worktree counts from its start, before the move (got $generated min)" "[ '$generated' = '55' ]"
none=$(TZ=UTC python3 "$TIMER" feat/never-started "$TP" --projects-dir "$WORK/projects" 2>&1); code=$?
check "track-time: a branch no session ran on says so and exits non-zero" "[ $code -ne 0 ] && echo \"\$none\" | grep -q 'No session ran on feat/never-started'"

# link-reference-docs.py (decision 0019), on a copy of the skeleton: a packaged project links the
# reference docs at the release it pins; a committed one, in its own docs/.
LINKS="$REPO_ROOT/scripts/link-reference-docs.py"
SITE="$WORK/linked"
cp -R "$REPO_ROOT/skeleton" "$SITE"
NAMES='COST-MODEL|MCP-INTEGRATION|MEMORY-STRATEGY|SPEC-MODEL'
local_refs() { grep -rlE "(^|[^/.A-Za-z0-9_-])docs/($NAMES)\.md" "$SITE" --include='*.md' --include='*.mdc' | grep -v -e "/\.claude/\(skills\|agents\|workflows\|hooks\)/" -e "/docs/[A-Z-]*\.md$"; }
plugin_docs=$(cd "$REPO_ROOT/plugins/adf/docs" && ls | sort | tr '\n' ' ')
check "link-reference-docs: the plugin carries the four reference docs and the parallel-agents guide (got: $plugin_docs)" \
    "[ '$plugin_docs' = 'COST-MODEL.md MCP-INTEGRATION.md MEMORY-STRATEGY.md PARALLEL-AGENTS.md SPEC-MODEL.md ' ]"
first=$(python3 "$LINKS" "$SITE" --packaged v9.9.9)
check "link-reference-docs: --packaged links every skeleton file at the release, in the plugin" \
    "[ -z \"\$(local_refs)\" ] && grep -q 'blob/v9.9.9/plugins/adf/docs/SPEC-MODEL.md' \"\$SITE/AGENTS.md\""
again=$(python3 "$LINKS" "$SITE" --packaged v9.9.9)
check "link-reference-docs: a second run changes nothing" "echo \"\$again\" | grep -q 'in 0 file(s)'"
python3 "$LINKS" "$SITE" --packaged v9.9.10 >/dev/null
check "link-reference-docs: a new pin moves every link" \
    "! grep -rq 'blob/v9.9.9/' \"\$SITE\" && grep -q 'blob/v9.9.10/plugins/adf/docs/COST-MODEL.md' \"\$SITE/.claude/rules/claude-code.md\""
python3 "$LINKS" "$SITE" --packaged v1.4.0 >/dev/null
old_pin=$(grep -c 'blob/v1.4.0/skeleton/docs/COST-MODEL.md' "$SITE/.claude/rules/claude-code.md")
python3 "$LINKS" "$SITE" --packaged v2.0.0 >/dev/null
check "link-reference-docs: a pin before v2.0.0 links skeleton/docs, where the docs were, and moves to the plugin's (decision 0028)" \
    "[ '$old_pin' -ge 1 ] && ! grep -rq 'skeleton/docs/' \"\$SITE\" && grep -q 'blob/v2.0.0/plugins/adf/docs/COST-MODEL.md' \"\$SITE/.claude/rules/claude-code.md\""
python3 "$LINKS" "$SITE" --committed >/dev/null
check "link-reference-docs: --committed restores the skeleton's files exactly" "diff -r \"\$REPO_ROOT/skeleton\" \"\$SITE\" >/dev/null"
bad=$(python3 "$LINKS" "$SITE" --packaged main 2>&1); code=$?
check "link-reference-docs: --packaged takes a release tag only" "[ $code -ne 0 ] && echo \"\$bad\" | grep -q 'release tag'"
check "link-reference-docs: the files it rewrote are the skeleton's, its committed rules included" "echo \"\$first\" | grep -q 'AGENTS.md, CONTRIBUTING.md' && echo \"\$first\" | grep -q '\.claude/rules/claude-code.md'"
# Decision 0044: the parallel-agents guide is a reference doc, and the module's own page links it.
MSITE="$WORK/linked-module"
cp -R "$REPO_ROOT/skeleton" "$MSITE" && cp -R "$REPO_ROOT/modules/parallel-agents/files/." "$MSITE/"
python3 "$LINKS" "$MSITE" --packaged v9.9.9 >/dev/null
check "link-reference-docs: --packaged links the module's page to the guide at the release" \
    "grep -q 'blob/v9.9.9/plugins/adf/docs/PARALLEL-AGENTS.md' \"\$MSITE/docs/SHARED-SERVICES.md\" && ! grep -q '\`docs/PARALLEL-AGENTS.md\`' \"\$MSITE/docs/SHARED-SERVICES.md\""
without=$(python3 "$LINKS" "$MSITE" --committed)
check "link-reference-docs: --committed restores the module's page exactly" \
    "diff \"\$REPO_ROOT/modules/parallel-agents/files/docs/SHARED-SERVICES.md\" \"\$MSITE/docs/SHARED-SERVICES.md\" >/dev/null"
sed -i.bak '1s/modules: \[none\]/modules: github, parallel-agents/' "$MSITE/AGENTS.md" && rm "$MSITE/AGENTS.md.bak"
with=$(python3 "$LINKS" "$MSITE" --committed)
check "link-reference-docs: a committed project misses the guide only when its stamp names the module" \
    "echo \"\$without\" | grep 'Missing from docs/' | grep -qv PARALLEL-AGENTS && echo \"\$with\" | grep 'Missing from docs/' | grep -q 'docs/PARALLEL-AGENTS.md'"

# build-committed.py (decision 0028): a committed project's machinery, written from the plugins.
BC="$REPO_ROOT/scripts/build-committed.py"
CP="$WORK/committed-project"
mkdir -p "$CP/.claude/skills/review" && echo '# our own review' > "$CP/.claude/skills/review/SKILL.md"
out=$(python3 "$BC" "$CP" --modules parallel-agents 2>&1); code=$?
check "build-committed: writes the core skills, agents, workflows, hooks, and reference docs" \
    "[ $code -eq 0 ] && [ -f '$CP/.claude/skills/triage/SKILL.md' ] && [ -f '$CP/.claude/agents/code-reviewer/agent.md' ] && [ -f '$CP/.claude/workflows/deep-review.js' ] && [ -x '$CP/.claude/hooks/guard-git.sh' ] && [ ! -x '$CP/.claude/hooks/_lib.sh' ] && [ -f '$CP/docs/SPEC-MODEL.md' ]"
check "build-committed: the committed form — bare names, local docs, no Step 0, the module's script" \
    "grep -q '/write-spec' '$CP/.claude/skills/triage/SKILL.md' && ! grep -rqE '/adf:(triage|write-spec|dispatch)|@adf:|CLAUDE_PLUGIN_ROOT|Step 0 — which copy|adf-worktree-new' '$CP/.claude/skills' '$CP/.claude/agents' && grep -q 'ops/agent/worktree-new.sh <type>/<slug> --no-start' '$CP/.claude/skills/dispatch/SKILL.md' && grep -q \"const SPEC_MODEL = 'Read docs/SPEC-MODEL.md.'\" '$CP/.claude/workflows/deep-spec-analysis.js'"
python3 "$BC" "$WORK/core-only" >/dev/null
check "build-committed: writes the parallel-agents guide only with the module, in the committed form (decision 0044)" \
    "[ -f '$CP/docs/PARALLEL-AGENTS.md' ] && [ ! -e '$WORK/core-only/docs/PARALLEL-AGENTS.md' ] && [ -f '$WORK/core-only/docs/SPEC-MODEL.md' ] && grep -q 'ops/agent/worktree-new.sh <type>/<slug> --no-start' '$CP/docs/PARALLEL-AGENTS.md' && ! grep -qE 'adf-worktree-|/adf:' '$CP/docs/PARALLEL-AGENTS.md'"
check "build-committed: takes only the modules it's given, and never the installer's skills" \
    "[ -d '$CP/.claude/skills/dispatch' ] && [ ! -e '$CP/.claude/skills/dev-env' ] && [ ! -e '$CP/.claude/skills/track-time' ] && [ ! -e '$CP/.claude/skills/end-user-docs' ] && [ ! -e '$CP/.claude/skills/adopt' ] && [ ! -e '$CP/.claude/skills/connect' ] && [ ! -e '$CP/.claude/hooks/hooks.json' ]"
check "build-committed: keeps a file the project already has, and says so" \
    "[ \"\$(cat '$CP/.claude/skills/review/SKILL.md')\" = '# our own review' ] && echo \"\$out\" | grep -q 'Kept 1 .*\.claude/skills/review/SKILL.md'"
python3 "$BC" "$WORK/docs-project" --modules end-user-docs >/dev/null
check "build-committed: writes /end-user-docs with its module, in the committed form (decision 0048)" \
    "[ -f '$WORK/docs-project/.claude/skills/end-user-docs/SKILL.md' ] && grep -q '/write-docs' '$WORK/docs-project/.claude/skills/end-user-docs/SKILL.md' && ! grep -qE '/adf:|Step 0 — which copy' '$WORK/docs-project/.claude/skills/end-user-docs/SKILL.md'"
out=$(python3 "$BC" "$WORK/elsewhere-project" --modules no-such-module 2>&1); code=$?
check "build-committed: refuses a module that doesn't exist" "[ $code -ne 0 ] && echo \"\$out\" | grep -q 'no such module'"

# The plugin's commands (decision 0027): the parallel-agents scripts, on the Bash tool's PATH — last,
# as Claude Code puts the plugin's bin/ — in a packaged project, which commits only worktree.conf.
BIN="$REPO_ROOT/plugins/adf/bin"
COMMANDS="adf-worktree-new adf-worktree-ls adf-worktree-rm"
check "commands: adf carries $COMMANDS, executable" "for c in $COMMANDS; do [ -x \"\$BIN/\$c\" ] || exit 1; done"
check "commands: each is one file — none loads a helper or looks beside itself" \
    "! grep -l -e 'dirname \"\$0\"' -e BASH_SOURCE -e '_worktree-lib.sh\"' \"\$BIN\"/* | grep -q ."
check "commands: the plugins' copies name the commands, not the module's scripts" \
    "! grep -rnE '(^|[^/\$A-Za-z0-9_-])((ops|scripts)/agent/)?worktree-(new|ls|rm)\.sh' \"\$REPO_ROOT/plugins/adf/skills/dispatch\" \"\$REPO_ROOT/plugins/adf/hooks\" \"\$REPO_ROOT/plugins/adf/docs\" \"\$REPO_ROOT/plugins/adf-dev/skills\" \"\$BIN\" | grep -v -e 'ADF_MODULE_DIR/' -e \"plugin's copy of the\" | grep -q ."
on_path() { PATH="$PATH:$BIN" "$@"; }
WT="$WORK/worktrees"
mkdir -p "$WT" && git init -q --bare "$WT/origin.git" && git clone -q "$WT/origin.git" "$WT/site" 2>/dev/null
S="$WT/site"
git -C "$S" config user.email test@example.com && git -C "$S" config user.name test && git -C "$S" symbolic-ref HEAD refs/heads/main
mkdir -p "$S/ops/agent" "$S/docs"
cp "$REPO_ROOT/modules/parallel-agents/files/ops/agent/worktree.conf" "$S/ops/agent/"
python3 - "$S/ops/agent/worktree.conf" <<'CONF'
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
printf '#!/bin/sh\necho "$@" > "%s/handed-over"\n' "$WT" > "$S/ops/agent/worktree-new.sh" && chmod +x "$S/ops/agent/worktree-new.sh"
out=$(cd "$S" && on_path adf-worktree-new feat/committed --no-start 2>&1); code=$?
check "adf-worktree-new: in a committed install, runs the project's own script with the same arguments" \
    "[ $code -eq 0 ] && [ \"\$(cat '$WT/handed-over' 2>/dev/null)\" = 'feat/committed --no-start' ] && [ ! -e '$WT/feat-committed' ]"

# A project that hasn't moved the module to ops/agent/ yet (decision 0032): the commands read scripts/agent/.
LW="$WORK/legacy"
mkdir -p "$LW" && git init -q --bare "$LW/origin.git" && git clone -q "$LW/origin.git" "$LW/site" 2>/dev/null
L="$LW/site"
git -C "$L" config user.email test@example.com && git -C "$L" config user.name test && git -C "$L" symbolic-ref HEAD refs/heads/main
mkdir -p "$L/scripts/agent"
sed -e 's/^PORT_SLOTS=0/PORT_SLOTS=180/' -e "s|^ENV_OVERRIDES=''|ENV_OVERRIDES='FROM=scripts'|" \
    "$REPO_ROOT/modules/parallel-agents/files/ops/agent/worktree.conf" > "$L/scripts/agent/worktree.conf"
printf 'APP_PORT=\n' > "$L/.env.example" && printf '.env\n' > "$L/.gitignore"
git -C "$L" add -A && git -C "$L" commit -qm init && git -C "$L" push -q -u origin main 2>/dev/null
out=$(cd "$L" && on_path adf-worktree-new feat/legacy --no-start 2>&1); code=$?
check "adf-worktree-new: in a project that still keeps scripts/agent/, reads its settings there" \
    "[ $code -eq 0 ] && grep -q '^FROM=scripts$' '$LW/feat-legacy/.env' && grep -qE '^APP_PORT=[0-9]+$' '$LW/feat-legacy/.env'"
mkdir -p "$L/ops/agent" && sed 's/FROM=scripts/FROM=ops/' "$L/scripts/agent/worktree.conf" > "$L/ops/agent/worktree.conf"
out=$(cd "$L" && on_path adf-worktree-new feat/both --no-start 2>&1); code=$?
check "adf-worktree-new: with both folders, ops/agent/ wins" "[ $code -eq 0 ] && grep -q '^FROM=ops$' '$LW/feat-both/.env'"
rm -rf "$L/ops"
printf '#!/bin/sh\necho "$@" > "%s/legacy-handed-over"\n' "$LW" > "$L/scripts/agent/worktree-new.sh" && chmod +x "$L/scripts/agent/worktree-new.sh"
out=$(cd "$L" && on_path adf-worktree-new feat/old-committed --no-start 2>&1); code=$?
check "adf-worktree-new: runs a committed script still in scripts/agent/" \
    "[ $code -eq 0 ] && [ \"\$(cat '$LW/legacy-handed-over' 2>/dev/null)\" = 'feat/old-committed --no-start' ]"

echo "======================================="
echo "Results: $PASS passed, $FAIL failed"
echo ""
[ "$FAIL" -gt 0 ] && exit 1
exit 0
