#!/usr/bin/env bash
#
# Functional tests for the optional modules' scripts: the git-hooks pre-push hook, the
# parallel-agents worktree scripts, and the clickup and docker install scripts. Builds throwaway repositories (with a bare "origin") in a temp
# directory. No AI invocation, no network. Needs bash, git ≥ 2.31, and python3. Exit 0 on all-pass.
#
set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${REPO_ROOT:-$( cd "$SCRIPT_DIR/../.." && pwd )}"
MODULES="$REPO_ROOT/modules"

PASS=0
FAIL=0
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

check() { # check <description> <shell condition>
    if eval "$2"; then PASS=$((PASS+1)); echo "✓ $1"; else FAIL=$((FAIL+1)); echo "✘ $1"; fi
}
replace() { # replace <file> <old> <new> — literal, first occurrence, portable across sed flavors
    python3 - "$1" "$2" "$3" <<'PY'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path).read()
if old not in text:
    sys.exit(f"replace: '{old}' not found in {path}")
open(path, "w").write(text.replace(old, new, 1))
PY
}
new_repo() { # new_repo <dir> — a repo with a commit on main and an identity
    git init -q -b main "$1"
    git -C "$1" config user.email test@example.com
    git -C "$1" config user.name test
}

echo ""
echo "Module tests — modules/*/files"
echo "=============================="

# ─── git-hooks: pre-push ────────────────────────────────────────────────────
G="$WORK/hooks"
mkdir -p "$G" && git init -q --bare "$G/origin.git" && new_repo "$G/repo"
R="$G/repo"
cp -R "$MODULES/git-hooks/files/." "$R/" && chmod +x "$R/.githooks/pre-push"
git -C "$R" config core.hooksPath .githooks
mkdir -p "$R/.claude/hooks" && printf 'PROTECTED_BRANCHES="main staging"\n' > "$R/.claude/hooks/config.sh"
echo a > "$R/a" && git -C "$R" add -A && git -C "$R" commit -qm init
git -C "$R" remote add origin "$G/origin.git"
pushes() { git -C "$R" push -q origin "$@" >/dev/null 2>&1; }

check "pre-push: refuses a push to main" "! pushes main"
git -C "$R" switch -q -c feat/x
check "pre-push: allows a work branch" "pushes feat/x"
check "pre-push: refuses feat/x:staging (protected list read from .claude/hooks/config.sh)" "! pushes feat/x:staging"
check "pre-push: refuses HEAD:refs/heads/main" "! pushes HEAD:refs/heads/main"
replace "$R/.githooks/pre-push" 'FAST_CHECKS=""' 'FAST_CHECKS="true
false"'
echo b > "$R/b" && git -C "$R" add -A && git -C "$R" commit -qm b
check "pre-push: a failing fast check refuses the push" "! pushes feat/x"
replace "$R/.githooks/pre-push" 'false"' 'true"'
check "pre-push: passing fast checks allow the push" "pushes feat/x"

# ─── parallel-agents: worktree scripts ──────────────────────────────────────
P="$WORK/proj"
mkdir -p "$P" && git init -q --bare "$WORK/origin.git"
git clone -q "$WORK/origin.git" "$P/main" 2>/dev/null
M="$P/main"
git -C "$M" config user.email test@example.com
git -C "$M" config user.name test
git -C "$M" symbolic-ref HEAD refs/heads/main   # the clone is empty; don't depend on init.defaultBranch
cp -R "$MODULES/parallel-agents/files/." "$M/" && chmod +x "$M"/ops/agent/*.sh
printf 'SECRET=\nAPP_PORT=\n' > "$M/.env.example"
printf '.env\nsetup.txt\nstarted.txt\n' > "$M/.gitignore"
CONF="$M/ops/agent/worktree.conf"
replace "$CONF" 'REQUIRED_ENV=""' 'REQUIRED_ENV="SECRET"'
replace "$CONF" 'SETUP_CMD=""' 'SETUP_CMD="echo setup-${SLUG} > setup.txt"'
replace "$CONF" 'START_CMD=""' 'START_CMD="echo started-${APP_PORT} > started.txt"'
replace "$CONF" 'STOP_CMD=""' 'STOP_CMD="echo stopped > ../stopped-${SLUG}.txt"'
replace "$CONF" "ENV_OVERRIDES=''" "ENV_OVERRIDES='COMPOSE_PROJECT_NAME=\${PROJECT}
SITE_URL=http://localhost:\${APP_PORT}'"
replace "$CONF" 'PORT_SLOTS=0' 'PORT_SLOTS=180'
replace "$CONF" 'ENV_INFO_CMD=""' 'ENV_INFO_CMD="echo info-${SLUG}-${APP_PORT}"'

git -C "$M" add -A && git -C "$M" commit -qm init && git -C "$M" push -q -u origin main 2>/dev/null
printf 'SECRET=abc\nAPP_PORT=1\nCOMPOSE_PROJECT_NAME=stale\n' > "$M/.env"
port_of() { sed -n 's/^APP_PORT=//p' "$1/.env"; }

cd "$M" || exit 1
out=$(ops/agent/worktree-new.sh feat/newsletter-signup --no-start 2>&1); code=$?
W1="$P/feat-newsletter-signup"
check "worktree-new: creates a sibling worktree on a new branch" "[ $code -eq 0 ] && [ -f '$W1/.git' ] && git -C '$M' show-ref --verify --quiet refs/heads/feat/newsletter-signup"
check "worktree-new: the new branch has no upstream" "! git -C '$W1' rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1"
check "worktree-new: inherits secrets from the main checkout" "grep -q '^SECRET=abc$' '$W1/.env'"
P1=$(port_of "$W1")
check "worktree-new: replaces stale overrides with exactly one port ($P1)" "[ \$(grep -c '^APP_PORT=' '$W1/.env') -eq 1 ] && [ '$P1' != 1 ] && [ \$(grep -c '^COMPOSE_PROJECT_NAME=' '$W1/.env') -eq 1 ]"
check "worktree-new: expands placeholders; project prefix is the repository name" "grep -q '^COMPOSE_PROJECT_NAME=origin-feat-newsletter-signup$' '$W1/.env' && grep -q '^SITE_URL=http://localhost:$P1$' '$W1/.env'"
check "worktree-new: --no-start runs no commands" "[ ! -f '$W1/setup.txt' ] && [ ! -f '$W1/started.txt' ]"
out=$(ops/agent/worktree-new.sh feat/newsletter-signup --no-start 2>&1); code=$?
check "worktree-new: rerunning with --no-start changes nothing" "[ $code -eq 0 ] && echo \"\$out\" | grep -q 'Worktree exists' && [ \"\$(port_of '$W1')\" = '$P1' ] && [ ! -f '$W1/setup.txt' ]"
out=$(ops/agent/worktree-new.sh feat/newsletter-signup --setup-only 2>&1); code=$?
check "worktree-new: --setup-only on an existing worktree runs only the setup" "[ $code -eq 0 ] && [ -f '$W1/setup.txt' ] && [ ! -f '$W1/started.txt' ]"
out=$(ops/agent/worktree-new.sh feat/newsletter-signup 2>&1); code=$?
check "worktree-new: rerunning without --no-start starts an existing worktree" "[ $code -eq 0 ] && grep -q 'started-$P1' '$W1/started.txt'"
replace "$M/.env" 'SECRET=abc' 'SECRET=rotated'
out=$(ops/agent/worktree-new.sh feat/newsletter-signup --refresh-env --no-start 2>&1); code=$?
check "worktree-new: --refresh-env re-seeds secrets and keeps the port" "[ $code -eq 0 ] && grep -q '^SECRET=rotated$' '$W1/.env' && [ \"\$(port_of '$W1')\" = '$P1' ] && [ \$(grep -c '^APP_PORT=' '$W1/.env') -eq 1 ]"
replace "$M/.env" 'SECRET=rotated' 'SECRET=abc'

echo 'LOCAL_EXPERIMENT=1' >> "$W1/.env"
cd "$W1" || exit 1
out=$(ops/agent/worktree-new.sh fix/other-thing 2>&1); code=$?
W2="$P/fix-other-thing"
P2=$(port_of "$W2" 2>/dev/null)
check "worktree-new: works from inside another worktree, with setup and start" "[ $code -eq 0 ] && grep -q setup-fix-other-thing '$W2/setup.txt' && grep -q 'started-$P2' '$W2/started.txt'"
check "worktree-new: seeds from the MAIN checkout, never the calling worktree" "! grep -q LOCAL_EXPERIMENT '$W2/.env'"
check "worktree-new: gives each worktree its own port ($P1, $P2)" "[ -n '$P2' ] && [ '$P1' != '$P2' ]"

cd "$M" || exit 1
replace "$M/.env" 'SECRET=abc' 'SECRET='
out=$(ops/agent/worktree-new.sh feat/needs-secret 2>&1); code=$?
check "worktree-new: refuses to start with a required variable empty" "[ $code -ne 0 ] && echo \"\$out\" | grep -q SECRET"
replace "$M/.env" 'SECRET=' 'SECRET=abc'

git -C "$M" branch -q feat/from-remote && git -C "$M" push -q origin feat/from-remote 2>/dev/null && git -C "$M" branch -q -D feat/from-remote
out=$(ops/agent/worktree-new.sh feat/from-remote --no-start 2>&1); code=$?
check "worktree-new: tracks a branch that exists on origin" "[ $code -eq 0 ] && [ \"\$(git -C '$P/feat-from-remote' rev-parse --abbrev-ref '@{u}')\" = origin/feat/from-remote ]"

mkdir -p "$P/.origin-worktree-ports.lock" && echo 999999 > "$P/.origin-worktree-ports.lock/pid"
out=$(ops/agent/worktree-new.sh chore/stale-lock --no-start 2>&1); code=$?
check "worktree-new: reclaims a lock left by a dead process" "[ $code -eq 0 ] && echo \"\$out\" | grep -q 'stale port lock' && [ ! -d '$P/.origin-worktree-ports.lock' ]"

git -C "$M" tag -a v1.0.0 -m "Release v1.0.0"
echo later > "$M/later.txt" && git -C "$M" add later.txt && git -C "$M" commit -qm later && git -C "$M" push -q origin main 2>/dev/null
out=$(ops/agent/worktree-new.sh hotfix/broken-login --from v1.0.0 --no-start 2>&1); code=$?
check "worktree-new: --from starts a new branch at a release tag" "[ $code -eq 0 ] && [ \"\$(git -C '$P/hotfix-broken-login' rev-parse HEAD)\" = \"\$(git -C '$M' rev-parse 'v1.0.0^{commit}')\" ]"

git -C "$M" branch -q feat/old-delivery v1.0.0
out=$(ops/agent/worktree-new.sh feat/old-delivery --no-start 2>&1); code=$?
check "worktree-new: warns when reusing a local branch that is behind the base" "[ $code -eq 0 ] && echo \"\$out\" | grep -q 'behind origin/main'"

out=$(ops/agent/worktree-ls.sh 2>&1)
check "worktree-ls: lists every worktree and marks the main checkout" "echo \"\$out\" | grep -q feat/newsletter-signup && echo \"\$out\" | grep -q fix/other-thing && echo \"\$out\" | grep -q 'main checkout'"
out=$(ops/agent/worktree-ls.sh --info 2>&1)
check "worktree-ls --info: runs ENV_INFO_CMD in each worktree, with its placeholders" "echo \"\$out\" | grep -q 'info-feat-newsletter-signup-$P1'"
check "worktree-new: marks the worktrees it sets up, in their own git directory" "[ -f \"\$(git -C '$W1' rev-parse --absolute-git-dir)/agent-worktree\" ] && [ -z \"\$(git -C '$W1' status --porcelain)\" ]"
git -C "$M" worktree add -q -b claude/eager-lamport "$M/.claude/worktrees/eager-lamport" main 2>/dev/null
git -C "$M" worktree add -q -b fix/in-app "$M/.claude/worktrees/calm-hopper" main 2>/dev/null
out=$(ops/agent/worktree-ls.sh 2>&1)
check "worktree-ls: lists Claude Code's worktrees, and flags one on a generated branch" "echo \"\$out\" | grep -q 'eager-lamport is on a generated branch (claude/eager-lamport)' && echo \"\$out\" | grep -q 'fix/in-app'"
check "worktree-ls: no flag for a renamed branch, and the scripts' worktrees count as theirs" "! echo \"\$out\" | grep -q 'calm-hopper is on' && ! echo \"\$out\" | grep 'feat-newsletter-signup' | grep -q 'not from the scripts'"
git -C "$M" worktree remove --force "$M/.claude/worktrees/eager-lamport"; git -C "$M" worktree remove --force "$M/.claude/worktrees/calm-hopper"

echo work > "$W2/work.txt" && git -C "$W2" add work.txt && git -C "$W2" commit -qm work
echo dirty > "$W2/dirty.txt"
out=$(ops/agent/worktree-rm.sh fix/other-thing 2>&1); code=$?
check "worktree-rm: refuses uncommitted changes" "[ $code -ne 0 ] && [ -d '$W2' ]"
out=$(ops/agent/worktree-rm.sh fix/other-thing --force 2>&1); code=$?
check "worktree-rm: --force stops, removes, and keeps an unmerged branch" "[ $code -eq 0 ] && [ ! -d '$W2' ] && [ -f '$P/stopped-fix-other-thing.txt' ] && echo \"\$out\" | grep -q 'kept branch'"
out=$(ops/agent/worktree-rm.sh chore-stale-lock 2>&1); code=$?
check "worktree-rm: by slug, deletes a merged branch" "[ $code -eq 0 ] && ! git -C '$M' show-ref --verify --quiet refs/heads/chore/stale-lock"
out=$(ops/agent/worktree-rm.sh main 2>&1); code=$?
check "worktree-rm: refuses the main checkout" "[ $code -ne 0 ] && [ -d '$M' ]"

X="$WORK/slots"
mkdir -p "$X" && new_repo "$X/repo"
XR="$X/repo"
cp -R "$MODULES/parallel-agents/files/." "$XR/" && chmod +x "$XR"/ops/agent/*.sh
printf '.env\n' > "$XR/.gitignore" && printf 'A=\n' > "$XR/.env.example"
replace "$XR/ops/agent/worktree.conf" 'PORT_SLOTS=0' 'PORT_SLOTS=2'
git -C "$XR" add -A && git -C "$XR" commit -qm init
cd "$XR" || exit 1
ops/agent/worktree-new.sh feat/one --no-start >/dev/null 2>&1; c1=$?
ops/agent/worktree-new.sh feat/two --no-start >/dev/null 2>&1; c2=$?
o3=$(ops/agent/worktree-new.sh feat/three --no-start 2>&1); c3=$?
q1=$(port_of "$X/feat-one"); q2=$(port_of "$X/feat-two")
check "worktree-new: with 2 slots, two worktrees take both ports ($q1, $q2)" "[ $c1 -eq 0 ] && [ $c2 -eq 0 ] && [ -n '$q1' ] && [ '$q1' != '$q2' ]"
check "worktree-new: honors ports reserved in sibling env files (third fails)" "[ $c3 -ne 0 ] && echo \"\$o3\" | grep -q 'no free port slot'"
check "worktree-new: a failed run releases the port lock" "[ ! -d '$X/.repo-worktree-ports.lock' ]"

# The defaults assume nothing: no env file, no ports, no commands
N="$WORK/plain"
mkdir -p "$N" && new_repo "$N/repo"
NR="$N/repo"
cp -R "$MODULES/parallel-agents/files/." "$NR/" && chmod +x "$NR"/ops/agent/*.sh
git -C "$NR" add -A && git -C "$NR" commit -qm init
cd "$NR" || exit 1
o5=$(ops/agent/worktree-new.sh feat/cli-flag 2>&1); c5=$?
check "worktree-new, defaults: a worktree with no env file, port, or commands when the project has none" "[ $c5 -eq 0 ] && [ -f '$N/feat-cli-flag/.git' ] && [ ! -e '$N/feat-cli-flag/.env' ] && ! echo \"\$o5\" | grep -qE 'Port:|Project:|--setup-only'"
o6=$(ops/agent/worktree-ls.sh 2>&1)
check "worktree-ls, defaults: no port columns when no worktree has a port" "echo \"\$o6\" | grep -q feat/cli-flag && ! echo \"\$o6\" | grep -q PORT"

# ─── clickup: install.sh merges, never overwrites ──────────────────────────
CU="$WORK/clickup-fresh"; mkdir -p "$CU"
"$MODULES/clickup/install.sh" "$CU" >/dev/null 2>&1; c=$?
jsonq() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))" "$@"; }
check "clickup install: creates .mcp.json with the clickup server" "[ $c -eq 0 ] && [ \"\$(jsonq '$CU/.mcp.json' 'd[\"mcpServers\"][\"clickup\"][\"url\"]')\" = 'https://mcp.clickup.com/mcp' ]"
check "clickup install: enables the server and adds the read-only allowlist" "[ \"\$(jsonq '$CU/.claude/settings.json' 'len(d[\"permissions\"][\"allow\"])')\" = 5 ] && [ \"\$(jsonq '$CU/.claude/settings.json' 'd[\"enabledMcpjsonServers\"]')\" = \"['clickup']\" ]"
"$MODULES/clickup/install.sh" "$CU" >/dev/null 2>&1
check "clickup install: a second run adds nothing" "[ \"\$(jsonq '$CU/.claude/settings.json' 'len(d[\"permissions\"][\"allow\"])')\" = 5 ] && [ \"\$(jsonq '$CU/.claude/settings.json' 'len(d[\"enabledMcpjsonServers\"])')\" = 1 ]"

CE="$WORK/clickup-existing"; mkdir -p "$CE/.claude"
printf '{"mcpServers":{"other":{"type":"http","url":"https://mcp.example.com"}}}\n' > "$CE/.mcp.json"
printf '{"$schema":"x","model":"sonnet","permissions":{"allow":["Bash(git status)"],"ask":["Bash(git push)"]}}\n' > "$CE/.claude/settings.json"
"$MODULES/clickup/install.sh" "$CE" >/dev/null 2>&1
check "clickup install: keeps other MCP servers" "[ \"\$(jsonq '$CE/.mcp.json' 'sorted(d[\"mcpServers\"])')\" = \"['clickup', 'other']\" ]"
check "clickup install: keeps existing settings and permission order" "[ \"\$(jsonq '$CE/.claude/settings.json' 'list(d)[:2] == [chr(36) + \"schema\", \"model\"] and d[\"permissions\"][\"allow\"][0] == \"Bash(git status)\" and d[\"permissions\"][\"ask\"] == [\"Bash(git push)\"]')\" = True ]"

CC="$WORK/clickup-custom"; mkdir -p "$CC"
printf '{"mcpServers":{"clickup":{"type":"http","url":"https://proxy.example.com/clickup"}}}\n' > "$CC/.mcp.json"
out=$("$MODULES/clickup/install.sh" "$CC" 2>&1)
check "clickup install: keeps a customized clickup server, and says so" "[ \"\$(jsonq '$CC/.mcp.json' 'd[\"mcpServers\"][\"clickup\"][\"url\"]')\" = 'https://proxy.example.com/clickup' ] && echo \"\$out\" | grep -q 'kept your existing'"

CB="$WORK/clickup-broken"; mkdir -p "$CB/.claude"; printf '{ not json' > "$CB/.claude/settings.json"
"$MODULES/clickup/install.sh" "$CB" >/dev/null 2>&1; c=$?
check "clickup install: refuses invalid JSON and leaves the file alone" "[ $c -ne 0 ] && [ \"\$(cat '$CB/.claude/settings.json')\" = '{ not json' ]"

# ─── docker: install.sh merges the permission rules, never overwrites ──────
DF="$WORK/docker-fresh"; mkdir -p "$DF"
ALLOWS=$(jsonq "$MODULES/docker/settings-fragment.json" 'len(d["permissions"]["allow"])')
ASKS=$(jsonq "$MODULES/docker/settings-fragment.json" 'len(d["permissions"]["ask"])')
"$MODULES/docker/install.sh" "$DF" >/dev/null 2>&1; c=$?
check "docker install: creates .claude/settings.json with the read-only allows and the destructive asks" "[ $c -eq 0 ] && [ \"\$(jsonq '$DF/.claude/settings.json' 'len(d[\"permissions\"][\"allow\"]), len(d[\"permissions\"][\"ask\"])')\" = \"($ALLOWS, $ASKS)\" ]"
check "docker install: no MCP server and nothing enabled" "[ ! -e '$DF/.mcp.json' ] && [ \"\$(jsonq '$DF/.claude/settings.json' 'sorted(d)')\" = \"['permissions']\" ]"
"$MODULES/docker/install.sh" "$DF" >/dev/null 2>&1
check "docker install: a second run adds nothing" "[ \"\$(jsonq '$DF/.claude/settings.json' 'len(d[\"permissions\"][\"allow\"]), len(d[\"permissions\"][\"ask\"])')\" = \"($ALLOWS, $ASKS)\" ]"

DE="$WORK/docker-existing"; mkdir -p "$DE/.claude"
printf '{"$schema":"x","model":"sonnet","permissions":{"allow":["Bash(git status)"],"ask":["Bash(git push)"],"deny":["Read(.env)"]}}\n' > "$DE/.claude/settings.json"
"$MODULES/docker/install.sh" "$DE" >/dev/null 2>&1
check "docker install: keeps existing settings and permission order" "[ \"\$(jsonq '$DE/.claude/settings.json' 'list(d)[:2] == [chr(36) + \"schema\", \"model\"] and d[\"permissions\"][\"allow\"][0] == \"Bash(git status)\" and d[\"permissions\"][\"ask\"][0] == \"Bash(git push)\" and d[\"permissions\"][\"deny\"] == [\"Read(.env)\"]')\" = True ]"

DB="$WORK/docker-broken"; mkdir -p "$DB/.claude"; printf '{ not json' > "$DB/.claude/settings.json"
"$MODULES/docker/install.sh" "$DB" >/dev/null 2>&1; c=$?
check "docker install: refuses invalid JSON and leaves the file alone" "[ $c -ne 0 ] && [ \"\$(cat '$DB/.claude/settings.json')\" = '{ not json' ]"

# Claude Code's matching, as documented: a * matches any text, spaces included; every subcommand
# is matched on its own; deny, then ask, then allow — an ask rule wins over any allow rule.
verdicts=$(python3 - "$MODULES/docker/settings-fragment.json" <<'PY'
import json, re, sys
perms = json.load(open(sys.argv[1]))["permissions"]
def matches(rules, command):
    return any(re.fullmatch(".*".join(map(re.escape, r[5:-1].split("*"))), command) for r in rules)
def verdict(command):
    parts = [p.strip() for p in re.split(r"&&|\|\||;|\|", command)]
    if any(matches(perms["ask"], p) for p in parts):
        return "ask"
    return "allow" if all(matches(perms["allow"], p) for p in parts) else "prompt"
cases = {
    "docker compose down -v": "ask", "docker compose down --volumes": "ask",
    "docker compose -f compose.yaml down -v": "ask", "docker compose down --rmi all": "ask",
    "cd app && docker compose down -v": "ask", "docker volume rm newsletter_redis-data": "ask",
    "docker system prune -af": "ask", "docker volume prune": "ask", "docker image prune -a": "ask",
    "docker rm -f web": "ask", "docker rmi redis:7": "ask", "docker compose rm -f web": "ask",
    "docker compose ps": "allow", "docker compose logs --tail 100 --no-color web": "allow",
    "docker compose config --quiet": "allow", "docker compose port web 3000": "allow",
    "docker system df": "allow",
    "docker compose config": "prompt", "docker inspect web": "prompt", "docker compose down": "prompt",
    "docker run --rm alpine true": "prompt", "docker compose up -d --wait": "prompt",
    # The Makefile's targets (decision 0032): reset deletes the stack's volumes; four read-only ones run.
    "make reset": "ask", "make logs reset": "ask", "make -C site reset": "ask",
    "make urls && make reset": "ask",
    "make help": "allow", "make ps": "allow", "make urls": "allow", "make logs": "allow",
    "make ps down": "prompt", "make up": "prompt", "make down": "prompt", "make native": "prompt",
}
for command, expected in cases.items():
    if verdict(command) != expected:
        print(f"'{command}': {verdict(command)}, expected {expected}")
PY
)
check "docker rules: destructive commands ask, read-only ones run, secret-printing ones aren't allowed" "[ -z \"\$verdicts\" ]"
[ -n "$verdicts" ] && echo "$verdicts" | sed 's/^/    /'

# ─── docker: the stack /dev-env writes from its templates (decision 0032) ──
# A stub docker answers `docker compose port` from STUB_PORTS, so this runs without Docker; the
# helper runs under /bin/bash, which is 3.2 on macOS.
TPL="$REPO_ROOT/plugins/adf-dev/skills/dev-env/templates"
DS="$WORK/docker-stack"; mkdir -p "$DS/site" "$DS/bin"
cp -R "$TPL/." "$DS/site/"
cat > "$DS/bin/docker" <<'STUB'
#!/bin/sh
[ "$1 $2" = "compose port" ] || exit 2
for entry in $STUB_PORTS; do
  [ "${entry%%=*}" = "$3:$4" ] && { echo "127.0.0.1:${entry#*=}"; exit 0; }
done
echo "service \"$3\" is not running" >&2; exit 1
STUB
chmod +x "$DS/bin/docker"
git -C "$DS/site" init -q -b main && printf '.env\n' > "$DS/site/.gitignore"
git -C "$DS/site" add -A && git -C "$DS/site" -c user.email=t@e -c user.name=t commit -qm init
stack() { (cd "$DS/site" && PATH="$DS/bin:$PATH" STUB_PORTS="${STUB_PORTS:-}" "$@"); }
ports() { stack env PORTS='APP_PORT=web:3000 REDIS_PORT=redis:6379' /bin/bash ops/scripts/ports.sh "$@"; }

check "templates: ports.sh is executable" "[ -x '$TPL/ops/scripts/ports.sh' ]"
out=$(stack make env 2>&1)
# GNU stat first: its -f means "file system" and takes %Lp for a file name, so BSD's form tried first
# prints more than the mode on Linux.
check "make env: creates .env from .env.example, readable only by its owner" \
    "[ -f '$DS/site/.env' ] && [ \"\$(stat -c %a '$DS/site/.env' 2>/dev/null || stat -f %Lp '$DS/site/.env')\" = 600 ] && cmp -s '$DS/site/.env' '$DS/site/.env.example'"
echo 'MAILCHIMP_API_KEY=topsecret' >> "$DS/site/.env"
out=$(stack make env 2>&1)
check "make env: leaves an existing .env alone" "grep -q '^MAILCHIMP_API_KEY=topsecret$' '$DS/site/.env' && echo \"\$out\" | grep -q 'left as it is'"
out=$(stack make help 2>&1)
check "make help: the default target lists every task of the mode" \
    "[ \"\$(stack make 2>&1)\" = \"\$out\" ] && for t in help env up down build ps logs urls shell test lint reset; do echo \"\$out\" | grep -q \"make \$t \" || exit 1; done"
out=$(stack make -n reset 2>&1)
check "make reset: deletes the volumes, after the worktree guard" \
    "echo \"\$out\" | grep -q 'down -v' && echo \"\$out\" | sed '/down -v/,\$d' | grep -q 'ports.sh guard'"
out=$(stack make -n logs 2>&1)
check "make logs: the last lines, never followed" \
    "echo \"\$out\" | grep -q -- '--tail 100 --no-color' && ! echo \"\$out\" | grep -qE -- ' -f( |\$)|--follow'"
out=$(STUB_PORTS='web:3000=51000 redis:6379=51001' ports urls 2>&1); code=$?
check "ports.sh urls: where Docker published each service, the app as a URL" \
    "[ $code -eq 0 ] && echo \"\$out\" | grep -q 'web .*http://localhost:51000  (APP_PORT)' && echo \"\$out\" | grep -q 'redis .*localhost:51001  (REDIS_PORT)'"
out=$(STUB_PORTS='redis:6379=51001' ports urls 2>&1)
check "ports.sh urls: a service that's down says so" "echo \"\$out\" | grep -q 'web .*not running'"
out=$(STUB_PORTS='redis:6379=51001' ports env 2>&1); code=$?
check "ports.sh env: each backing service's port, and a free port for the app on the host" \
    "[ $code -eq 0 ] && echo \"\$out\" | grep -q '^export REDIS_PORT=51001$' && echo \"\$out\" | grep -qE '^export APP_PORT=[0-9]+$'"
sed -i.bak 's/^APP_PORT=$/APP_PORT=48765/' "$DS/site/.env" && rm -f "$DS/site/.env.bak"
out=$(STUB_PORTS='redis:6379=51001' ports env 2>&1)
check "ports.sh env: the app keeps a port pinned in .env" "echo \"\$out\" | grep -q '^export APP_PORT=48765$'"
out=$(STUB_PORTS='redis:6379=51001' APP_PORT=47000 ports env 2>&1)
check "ports.sh env: a value in the shell wins, as it does for Compose" "echo \"\$out\" | grep -q '^export APP_PORT=47000$'"
out=$(ports env 2>&1); code=$?
check "ports.sh env: refuses while the backing services are down" "[ $code -ne 0 ] && echo \"\$out\" | grep -q 'make services'"
out=$(ports free); code=$?
check "ports.sh free: a port nothing listens on" \
    "[ $code -eq 0 ] && [ \"\$out\" -ge 20000 ] && [ \"\$out\" -lt 32000 ] && ! (exec 3<>/dev/tcp/127.0.0.1/\$out) 2>/dev/null"
out=$({ STUB_PORTS='web:3000=51000 redis:6379=51001' ports urls; STUB_PORTS='redis:6379=51001' ports env; ports guard; } 2>&1)
check "ports.sh: never prints a value from .env but the ports" "! echo \"\$out\" | grep -q topsecret"
check "ports.sh guard: passes in the main checkout" "ports guard"
git -C "$DS/site" worktree add -q -b feat/copied "$DS/site-feat-copied" && cp "$DS/site/.env" "$DS/site-feat-copied/.env"
out=$(cd "$DS/site-feat-copied" && /bin/bash ops/scripts/ports.sh guard 2>&1); code=$?
reset_out=$(cd "$DS/site-feat-copied" && PATH="$DS/bin:$PATH" make reset 2>&1)
check "ports.sh guard: refuses in a worktree whose .env repeats the main checkout's pinned port, and so does make reset" \
    "[ $code -ne 0 ] && echo \"\$out\" | grep -q 'APP_PORT' && echo \"\$reset_out\" | grep -q 'repeats the main checkout' && ! echo \"\$reset_out\" | grep -q 'down -v'"
sed -i.bak 's/^APP_PORT=48765$/APP_PORT=/' "$DS/site-feat-copied/.env" && rm -f "$DS/site-feat-copied/.env.bak"
check "ports.sh guard: passes there once the copied port is emptied" "(cd '$DS/site-feat-copied' && /bin/bash ops/scripts/ports.sh guard)"

# The mode (decision 0034): the root Makefile loads ops/make/<DEV_MODE>.mk — DEFAULT_MODE, .env, or the
# command line.
check "templates: native.sh is executable" "[ -x '$TPL/ops/scripts/native.sh' ]"
out=$(stack make help 2>&1)
check "make help: names the mode and its file, docker by default" "echo \"\$out\" | head -1 | grep -q '^Mode: docker (ops/make/docker.mk)'"
out=$(stack make -n up 2>&1)
check "make up, docker mode: the whole stack in Docker" "echo \"\$out\" | grep -q 'compose up -d --wait\$' && ! echo \"\$out\" | grep -q 'native.sh start'"
echo 'DEV_MODE=native # this checkout' >> "$DS/site/.env"
out=$(stack make help 2>&1)
check "make help, DEV_MODE=native in .env: native.mk's tasks" \
    "echo \"\$out\" | head -1 | grep -q '^Mode: native (ops/make/native.mk)' && echo \"\$out\" | grep -q 'make services ' && ! echo \"\$out\" | grep -q 'make shell '"
out=$(stack make -n up 2>&1)
check "make up, native mode: the backing services in Docker, the app on the host" \
    "echo \"\$out\" | grep -q 'up -d --wait redis' && echo \"\$out\" | grep -q 'native.sh start'"
out=$(stack make -n up DEV_MODE=docker 2>&1)
check "make up DEV_MODE=docker: the command line wins over .env" "echo \"\$out\" | grep -q 'compose up -d --wait\$' && ! echo \"\$out\" | grep -q 'native.sh start'"
out=$(stack make help DEV_MODE=podman 2>&1); code=$?
check "DEV_MODE: a mode with no file stops make, naming the setting" "[ $code -ne 0 ] && echo \"\$out\" | grep -q \"DEV_MODE is 'podman'\""
out=$(stack make -n reset 2>&1)
check "make reset, native mode: stops the app on the host, then deletes the volumes" \
    "echo \"\$out\" | grep -q 'native.sh stop' && echo \"\$out\" | grep -q 'down -v'"
# The app on the host, for real: a dev command that serves the folder, with nothing in Docker.
NS="$WORK/native-stack"; mkdir -p "$NS" && cp -R "$TPL/." "$NS/"
git -C "$NS" init -q -b main && printf '.env\nops/.run/\n' > "$NS/.gitignore"
sed -i.bak -e 's|^NATIVE_CMD = .*|NATIVE_CMD = exec python3 -m http.server "$$APP_PORT" --bind 127.0.0.1|' -e 's|^SERVICES ?= redis$|SERVICES ?=|' "$NS/ops/make/native.mk" && rm -f "$NS/ops/make/native.mk.bak"
native() { (cd "$NS" && PATH="$DS/bin:$PATH" REDIS_PORT=6399 make "$@" DEV_MODE=native); }
out=$(native up 2>&1); code=$?
port=$(sed -n 's/^APP_PORT=//p' "$NS/ops/.run/app.env" 2>/dev/null)
check "native mode, make up: starts the app in the background and waits until it answers" \
    "[ $code -eq 0 ] && [ -n '$port' ] && (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null && echo \"\$out\" | grep -q \"http://localhost:$port\""
out=$(native urls 2>&1)
check "native mode, make urls: the app on the host" "echo \"\$out\" | grep -q \"web .*http://localhost:$port  (APP_PORT, on the host)\""
out=$(native up 2>&1)
check "native mode, make up again: leaves the running app alone" "echo \"\$out\" | grep -q 'already runs on the host'"
out=$(native down 2>&1); code=$?
check "native mode, make down: stops the app and its process group" \
    "[ $code -eq 0 ] && [ ! -f '$NS/ops/.run/app.env' ] && ! (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null"
out=$(cd "$NS" && PATH="$DS/bin:$PATH" make up DEV_MODE=native 2>&1); code=$?
check "native mode, make up: a backing service neither in Docker nor pinned stops it, saying what to pin" \
    "[ $code -ne 0 ] && echo \"\$out\" | grep -q 'pin REDIS_PORT in .env' && [ ! -f '$NS/ops/.run/app.env' ]"
sed -i.bak 's|^NATIVE_CMD = .*|NATIVE_CMD = echo boom; exit 3|' "$NS/ops/make/native.mk" && rm -f "$NS/ops/make/native.mk.bak"
out=$(native up 2>&1); code=$?
check "native mode, make up: a dev command that exits fails, and shows its log" \
    "[ $code -ne 0 ] && echo \"\$out\" | grep -q boom && [ ! -f '$NS/ops/.run/app.env' ]"
if docker compose version >/dev/null 2>&1; then
    check "compose.yaml: valid, with an empty .env and with pinned ports" \
        "(cd '$DS/site' && docker compose config --quiet) && (cd '$DS/site-feat-copied' && docker compose config --quiet)"
fi


echo "=============================="
echo "Results: $PASS passed, $FAIL failed"
echo ""
[ "$FAIL" -gt 0 ] && exit 1
exit 0
