#!/usr/bin/env bash
#
# Functional tests for the scripted upgrade (decision 0046): scripts/upgrade.py, its migrations, the
# rule for dropping covered allow rules, and the adf-upgrade command. Builds throwaway projects adopted
# at an older release from this repository's own history, and upgrades them to this tree (as an
# unreleased commit). No AI invocation, no network. Needs bash, git, python3, and the release tags
# (a full clone: CI checks out with fetch-depth 0). Exit 0 on all-pass.
#
set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"
UPGRADE="$REPO_ROOT/scripts/upgrade.py"
FROM="${UPGRADE_FROM:-v2.3.0}"

PASS=0
FAIL=0
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

check() { # check <description> <shell condition>
    if eval "$2"; then PASS=$((PASS+1)); echo "✓ $1"; else FAIL=$((FAIL+1)); echo "✘ $1"; fi
}

echo ""
echo "Upgrade tests — scripts/upgrade.py"
echo "=================================="

if ! git -C "$REPO_ROOT" rev-parse --verify -q "$FROM^{commit}" >/dev/null; then
    echo "(skipped: no $FROM tag here — a shallow clone; fetch the tags to run these)"
    exit 0
fi

# ─── covered allow rules (§ 4) ──────────────────────────────────────────────
out=$(python3 - "$REPO_ROOT/scripts" <<'PY'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("upgrade", sys.argv[1] + "/upgrade.py")
u = importlib.util.module_from_spec(spec); spec.loader.exec_module(u)
s = {"permissions": {
    "allow": ["Bash(make *)", "Bash(make test)", "Bash(make test *)", "Bash(make)", "Bash(makefile-lint)",
              "Bash(git *)", "Bash(git status)", "Bash(git status)", "Bash(npm:*)", "Bash(npm run build)",
              "Read(src/**)", "Read(src/a.ts)", "Bash(a * b *)", "Bash(a * b c)"],
    "ask": ["Bash(make reset*)", "Bash(make *)"],
    "deny": ["Bash(git push --force *)"]}}
dropped = u.prune_allow(s)
print(json.dumps({"allow": s["permissions"]["allow"], "ask": s["permissions"]["ask"],
                  "deny": s["permissions"]["deny"], "dropped": dropped}))
PY
)
has() { python3 -c "import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if $2 else 1)" "$out"; }
check "prune: Bash(make *) covers Bash(make test) and Bash(make test *)" \
    "has x '\"Bash(make test)\" not in d[\"allow\"] and \"Bash(make test *)\" not in d[\"allow\"]'"
check "prune: Bash(make) and Bash(makefile-lint) stay (no space after the prefix)" \
    "has x '\"Bash(make)\" in d[\"allow\"] and \"Bash(makefile-lint)\" in d[\"allow\"]'"
check "prune: the :* spelling covers too (Bash(npm run build))" "has x '\"Bash(npm run build)\" not in d[\"allow\"]'"
check "prune: an exact duplicate goes, once" "has x 'd[\"allow\"].count(\"Bash(git *)\") == 1 and \"Bash(git status)\" not in d[\"allow\"]'"
check "prune: Read rules and wildcard prefixes are never touched" \
    "has x '\"Read(src/a.ts)\" in d[\"allow\"] and \"Bash(a * b c)\" in d[\"allow\"]'"
check "prune: ask and deny are never touched" \
    "has x 'd[\"ask\"] == [\"Bash(make reset*)\", \"Bash(make *)\"] and d[\"deny\"] == [\"Bash(git push --force *)\"]'"

# ─── a project adopted at $FROM ─────────────────────────────────────────────
FW="$WORK/fw-$FROM"
mkdir -p "$FW" && git -C "$REPO_ROOT" archive "$FROM" skeleton modules | tar -x -C "$FW"
FROM_SHA=$(git -C "$REPO_ROOT" rev-parse --short "$FROM^{commit}")

new_project() { # new_project <dir> <packaged|committed> <modules, comma-separated>
    local P="$1" install="$2" modules="$3"
    mkdir -p "$P" && cp -R "$FW/skeleton/." "$P/"
    local m
    for m in ${modules//,/ }; do
        [ -d "$FW/modules/$m/files" ] && cp -R "$FW/modules/$m/files/." "$P/"
    done
    python3 - "$P" "$install" "$modules" "$FROM" "$FROM_SHA" <<'PY'
import json, os, sys
p, install, modules, tag, sha = sys.argv[1:]
path = os.path.join(p, ".claude", "settings.json")
s = json.load(open(path))
s["permissions"]["allow"] += ["Bash(git status)", "Bash(make *)", "Bash(make test)"]
s["extraKnownMarketplaces"] = {"aplyca": {"source": {"source": "github", "repo": "aplyca/AgenticDevelopmentFramework", "ref": tag}}}
s["enabledPlugins"] = {"adf@aplyca": True}
if install == "packaged":
    s.pop("hooks", None)
json.dump(s, open(path, "w"), indent=2); open(path, "a").write("\n")
agents = os.path.join(p, "AGENTS.md")
text = open(agents).read().split("\n", 1)[1]
stamp = f"<!-- Skeleton source: {tag} · {sha} (2026-10-15) · modules: {modules.replace(',', ', ') or 'none'}"
stamp += " · install: packaged" if install == "packaged" else ""
open(agents, "w").write(stamp + " — update on every framework upgrade. See docs/UPGRADING.md in AgenticDevelopmentFramework. -->\n" + text)
# The team's customizations: one line in AGENTS.md, one in a customizable rule.
with open(agents, "a") as f:
    f.write("\n## Team notes\n\nThe newsletter service owns the subscriber list.\n")
rule = os.path.join(p, ".claude", "rules", "deployment.md")
with open(rule, "a") as f:
    f.write("\n<!-- team: deploys go through the newsletter pipeline -->\n")
PY
    if [ "$install" = "packaged" ]; then
        rm -f "$P"/ops/agent/*.sh
    else
        python3 - "$FW" "$REPO_ROOT" "$FROM" "$P" "$modules" <<'PY'
import os, subprocess, sys, tempfile
fw, repo, tag, p, modules = sys.argv[1:]
tree = tempfile.mkdtemp()
subprocess.run(f"git -C {repo} archive {tag} | tar -x -C {tree}", shell=True, check=True)
args = [sys.executable, f"{tree}/scripts/build-committed.py", p] + (["--modules", modules] if modules else [])
subprocess.run(args, check=True, capture_output=True)
PY
    fi
    for m in ${modules//,/ }; do
        [ -f "$FW/modules/$m/install.sh" ] && sh "$FW/modules/$m/install.sh" "$P" >/dev/null
    done
    git init -q -b main "$P"
    git -C "$P" config user.email test@example.com
    git -C "$P" config user.name test
    git -C "$P" add -A && git -C "$P" commit -qm "adopt $FROM"
    # The upgrade runs in its own worktree, as in a hub: the main checkout takes no edits.
    git -C "$P" worktree add -q -b chore/skeleton-upgrade "$P-up"
}
upgrade() { # upgrade <project> [options] — the report on stdout, the exit code kept
    python3 "$UPGRADE" "$1" --history "$REPO_ROOT" --unreleased "${@:2}"
}
gitdir() { git -C "$1" rev-parse --absolute-git-dir; }
report() { python3 -c "import json,sys; r=json.load(open(sys.argv[1]+'/adf-upgrade/report.json')); sys.exit(0 if $2 else 1)" "$(gitdir "$1")"; }

# ─── packaged, with parallel-agents and docker ──────────────────────────────
new_project "$WORK/packaged" packaged "parallel-agents,docker"
P="$WORK/packaged-up"
# The team recorded its shared services in the guide's copy.
python3 - "$P/docs/PARALLEL-AGENTS.md" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
marker = "<!-- CUSTOMIZE: what worktrees share, what a task may copy, and what that costs -->"
t = t.replace("[team or person]", "platform team", 1).replace(marker, marker + "\n\nWorktrees share the newsletter sandbox; a task may copy its database.", 1)
open(p, "w").write(t)
PY
git -C "$P" commit -qam "record shared services"
HEAD_BEFORE=$(git -C "$P" rev-parse HEAD)

upgrade "$P" --dry-run > "$WORK/dry.md"; rc=$?
check "dry run: exits 0" "[ $rc -eq 0 ]"
check "dry run: changes nothing in the project" "[ -z \"\$(git -C '$P' status --porcelain)\" ]"
check "dry run: the report says it's a dry run" "grep -q 'dry run: nothing changed' '$WORK/dry.md'"

upgrade "$P" > "$WORK/run.md" 2>"$WORK/run.err"; rc=$?
check "run: exits 0" "[ $rc -eq 0 ] || { cat '$WORK/run.err'; false; }"
check "run: AGENTS.md keeps the team's notes" "grep -q 'The newsletter service owns the subscriber list' '$P/AGENTS.md'"
check "run: restamped, packaged, with the modules" \
    "head -1 '$P/AGENTS.md' | grep -q \"Skeleton source: $(git -C "$REPO_ROOT" rev-parse --short=7 HEAD) .* modules: parallel-agents, docker · install: packaged — update on every\""
check "run: the customized rule keeps its line" "grep -q 'newsletter pipeline' '$P/.claude/rules/deployment.md'"
check "run: settings.json parses and has no hooks block" \
    "python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); sys.exit(\"hooks\" in s)' '$P/.claude/settings.json'"
check "run: Bash(make test) dropped, covered by Bash(make *)" "report '$P' '{\"rule\": \"Bash(make test)\", \"covered_by\": \"Bash(make *)\"} in r[\"applied\"][\"allow_rules_dropped\"]'"
check "run: Bash(git status) dropped, covered by Bash(git *)" "! grep -q '\"Bash(git status)\"' '$P/.claude/settings.json'"
check "run: autoUpdate added (v2.4.0's migration)" \
    "python3 -c 'import json,sys; sys.exit(not json.load(open(sys.argv[1]))[\"extraKnownMarketplaces\"][\"aplyca\"].get(\"autoUpdate\"))' '$P/.claude/settings.json'"
check "run: the guide's copy is split — SHARED-SERVICES.md keeps the team's text and owner" \
    "grep -q 'newsletter sandbox' '$P/docs/SHARED-SERVICES.md' && grep -q 'owner: platform team' '$P/docs/SHARED-SERVICES.md'"
check "run: the packaged copy of the guide is gone" "[ ! -f '$P/docs/PARALLEL-AGENTS.md' ]"
check "run: no worktree scripts committed in a packaged project" "[ -z \"\$(ls '$P'/ops/agent/*.sh 2>/dev/null)\" ] && [ -f '$P/ops/agent/worktree.conf' ]"
check "run: every hook's smoke test passes, with both variables exported" \
    "report '$P' 'all(c[\"ok\"] for c in r[\"checks\"]) and any(c[\"check\"].startswith(\"hook \") for c in r[\"checks\"])'"
check "run: clean merges carry a hunk count" \
    "report '$P' 'r[\"applied\"][\"clean_merges\"] and all(c[\"hunks\"] > 0 for c in r[\"applied\"][\"clean_merges\"])'"
check "run: the report has every section, Follow-ups last" \
    "grep -n '^## ' \"\$(gitdir '$P')/adf-upgrade/report.md\"  | cut -d' ' -f2- | tr '\n' '|' | grep -q '^Releases|Needs you|Applied|Checks|On each machine|Follow-ups|$'"
check "run: the machines' commands update adf" "grep -q 'claude plugin update adf@aplyca' '$WORK/run.md'"
check "run: the docker spec change gives a dev-env follow-up, or none when it didn't change" \
    "report '$P' 'all(set(f) == {\"command\", \"why\", \"source\", \"plugin\", \"when\"} for f in r[\"follow_ups\"])'"
check "run: commits nothing (the skill commits after approval)" "[ \"\$(git -C '$P' rev-parse HEAD)\" = '$HEAD_BEFORE' ]"

git -C "$P" add -A && git -C "$P" commit -qm upgrade
upgrade "$P" > /dev/null 2>"$WORK/again.err"; rc=$?
check "again: refuses — the project is already at this commit (exit 2)" "[ $rc -eq 2 ] && grep -q 'already at' '$WORK/again.err'"

# ─── migrations run twice change nothing ────────────────────────────────────
python3 - "$REPO_ROOT" "$P" > "$WORK/twice.out" 2>&1 <<'PY'
import importlib.util, os, sys
root, p = sys.argv[1:]
spec = importlib.util.spec_from_file_location("upgrade", root + "/scripts/upgrade.py")
u = importlib.util.module_from_spec(spec); spec.loader.exec_module(u)

class Fake:  # just enough of an Upgrade for a migration's context
    pass
f = Fake()
f.ws = u.Workspace(p, False); f.repo = p; f.install = "packaged"; f.modules = ["parallel-agents", "docker"]
f.dry = False; f.touched = set(); f.history = root
f.old = u.Release(root, "v2.3.0", "v2.3.0"); f.new = u.Release(root, "HEAD", "v2.4.0")
ctx = u.MigrationContext(f)
for folder, name, path in u.discover_migrations(root, "v2.0.0", "v2.4.0", True):
    status, text = u.load_migration(path).run(ctx)
    print(f"{folder}/{name}: {status}")
PY
check "migrations: a second run returns done for each" "! grep -qv ': done$' '$WORK/twice.out' && [ -s '$WORK/twice.out' ]"
check "migrations: the tree is unchanged after them" "[ -z \"\$(git -C '$P' status --porcelain)\" ]"

# ─── committed, with parallel-agents still in scripts/agent/ ────────────────
new_project "$WORK/committed" committed "parallel-agents"
C="$WORK/committed-up"
mkdir -p "$C/scripts" && git -C "$C" mv ops/agent scripts/agent && git -C "$C" commit -qm "the folder before 0032"
echo "# the team's own line" >> "$C/.claude/skills/triage/SKILL.md" && git -C "$C" commit -qam "edit a skill"
upgrade "$C" > "$WORK/committed.md" 2>"$WORK/committed.err"; rc=$?
check "committed: exits 0" "[ $rc -eq 0 ] || { cat '$WORK/committed.err'; false; }"
check "committed: scripts/agent/ moved to ops/agent/ before the merges (module.json's moved_from)" \
    "[ ! -d '$C/scripts/agent' ] && [ -x '$C/ops/agent/worktree-new.sh' ] && [ -f '$C/ops/agent/worktree.conf' ]"
check "committed: an unchanged skill is overwritten from the new build" \
    "diff -q '$C/.claude/skills/debug/SKILL.md' <(python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); from forms import Machinery; print(Machinery(sys.argv[2]).committed_files([\"parallel-agents\"])[\".claude/skills/debug/SKILL.md\"][0], end=\"\")' '$REPO_ROOT/scripts' '$REPO_ROOT') >/dev/null"
check "committed: the edited skill keeps the team's line, flagged as edited machinery" \
    "grep -q \"the team's own line\" '$C/.claude/skills/triage/SKILL.md' || report '$C' 'any(c[\"file\"].endswith(\"triage/SKILL.md\") for c in r[\"needs_you\"][\"conflicts\"])'"
check "committed: the guide becomes the built one" "! grep -q 'owner:' '$C/docs/PARALLEL-AGENTS.md' && [ -f '$C/docs/SHARED-SERVICES.md' ]"
check "committed: the stamp has no install: packaged" "! head -1 '$C/AGENTS.md' | grep -q 'install: packaged'"
check "committed: hooks smoke-tested from the project's .claude/hooks" \
    "report '$C' 'all(c[\"ok\"] for c in r[\"checks\"])'"

# ─── refusals ───────────────────────────────────────────────────────────────
new_project "$WORK/dirty" packaged ""
D="$WORK/dirty-up"
echo x >> "$D/README.md"
upgrade "$D" > /dev/null 2>&1; rc=$?
check "refuses a dirty working tree (exit 2)" "[ $rc -eq 2 ]"
git -C "$D" checkout -q -- README.md
upgrade "$WORK/dirty" > /dev/null 2>&1; rc=$?
check "refuses the default branch (exit 2)" "[ $rc -eq 2 ]"
python3 "$UPGRADE" "$D" --history "$REPO_ROOT" > /dev/null 2>"$WORK/rel.err"; rc=$?
check "refuses a tree that isn't a release without --unreleased" "[ $rc -eq 2 ] && grep -q 'unreleased' '$WORK/rel.err'"
python3 "$UPGRADE" "$D" --history "$REPO_ROOT" --protocol 9 > /dev/null 2>&1; rc=$?
check "refuses a wrapper protocol it doesn't speak" "[ $rc -eq 2 ]"
new_project "$WORK/old" packaged ""
OLD="$WORK/old-up"
python3 - "$OLD/AGENTS.md" "$(git -C "$REPO_ROOT" rev-parse --short 'v1.4.0^{commit}')" <<'PY'
import re, sys
p, sha = sys.argv[1:]; t = open(p).read()
open(p, "w").write(re.sub(r"v\d+\.\d+\.\d+ · [0-9a-f]+", f"v1.4.0 · {sha}", t, count=1))
PY
git -C "$OLD" commit -qam old
upgrade "$OLD" > /dev/null 2>"$WORK/floor.err"; rc=$?
check "refuses a project below v2.0.0, pointing at the manual procedure" "[ $rc -eq 2 ] && grep -q 'v2.0.0' '$WORK/floor.err'"

# ─── adf-upgrade: the plugin's command ──────────────────────────────────────
new_project "$WORK/wrapper" packaged ""
W="$WORK/wrapper-up"
mkdir -p "$WORK/cache"
out=$(cd "$W" && XDG_CACHE_HOME="$WORK/cache" ADF_FRAMEWORK="$REPO_ROOT" "$REPO_ROOT/plugins/adf/bin/adf-upgrade" "$FROM" --offline --dry-run 2>&1); rc=$?
check "adf-upgrade: a release without scripts/upgrade.py says to follow the manual procedure" \
    "[ $rc -eq 2 ] && printf '%s' \"\$out\" | grep -q 'predates the scripted upgrade'"
out=$(cd "$W" && XDG_CACHE_HOME="$WORK/cache" ADF_FRAMEWORK="$REPO_ROOT" "$REPO_ROOT/plugins/adf/bin/adf-upgrade" --unreleased HEAD --offline --dry-run 2>&1); rc=$?
check "adf-upgrade: runs the target's own script from the cached tree" \
    "[ $rc -eq 0 ] && [ -f '$WORK/cache/adf/trees/$(git -C "$REPO_ROOT" rev-parse HEAD)/.complete' ] && printf '%s' \"\$out\" | grep -q 'dry run: nothing changed'"
check "adf-upgrade: passes --dry-run through" "[ -z \"\$(git -C '$W' status --porcelain)\" ]"
out=$(cd "$WORK" && "$REPO_ROOT/plugins/adf/bin/adf-upgrade" 2>&1); rc=$?
check "adf-upgrade: outside a repository it says so" "[ $rc -eq 2 ] && printf '%s' \"\$out\" | grep -q 'not inside a git repository'"

echo "======================================="
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
