#!/usr/bin/env bash
#
# Runs a suite of session fixtures (fixtures/<suite>/ — triage by default, debug, adopt, upgrade, or
# plugin-hooks) against real Claude Code sessions.
#
# Builds a fictional project in a temp directory — the skeleton, the delivered newsletter-signup
# spec folder from docs/examples/, and a few stub source files matching the fixtures' context, plus
# whatever the suite's setup.sh adds; a suite with its own project.sh builds its project instead,
# given the project's path and this checkout's —
# then runs each fixture's prompt headless with `claude -p` on each model. Each run works in its own
# throwaway copy, may edit it (so the project's hooks — triage-first, careful-paths — take part), and
# is turn- and budget-capped; `--read-only` denies edits instead, so a run stops at its first edit.
# A fixture with a "## Follow-up" section gets a second turn in the same session. A suite's
# inspect.sh records each run's end state — given the run's copy, its output, and the case — and may
# check it, marking each check ✓ or ✘; the summary counts them. A case's <case>.setup.sh adjusts its
# copy before the session. Transcripts land in the output directory for grading against each
# fixture's .expected.md.
#
# The upgrade suite: a committed adoption at v1.0.0, built from that tag, which /aplyca-adf:upgrade moves
# to the newest release — the switch-to-packaged case switches it to the packaged install on the way. It
# runs like the adopt suite (bypassPermissions on throwaway copies, the plugin per session).
#
# The plugin-hooks suite: a project on the packaged install, with the plugin loaded per session; each
# case drives one of the plugin's hooks in a real session (Haiku by default), and inspect.sh checks
# that it fired — or, in a committed project, that it stood down.
#
# The plugin-docs suite: the same kind of project, without the reference docs in docs/ (decision
# 0019). Sessions run in default permission mode with no extra directory and no blanket Read, as a
# teammate's would: the plugin's folder is readable only through the rule a packaged project commits,
# passed here with --allowedTools for the plugin's path in this checkout. A case marked
# <!-- run: no-read-rule --> runs without it. Agents that ask for opus run on Haiku too.
#
# The adopt suite: {{FRAMEWORK}} in a prompt becomes --source (the framework's GitHub address by
# default — what's published on main; pass this checkout's path to test a branch), and a fixture
# marked <!-- run: plugin-dir --> loads the installer plugin for that session only, so nothing is
# installed on the machine. An adoption copies files in bulk, which headless permission checks
# refuse, so adopt sessions run in bypassPermissions mode on throwaway copies — of the project and of
# this checkout — with deny rules, which hold in every mode, for `claude` commands, `git push`, and
# file-tool edits under your home folder.
#
# Usage: ./run-session-evals.sh [--suite triage|debug|adopt|upgrade|plugin-hooks|plugin-docs] [--models "sonnet opus"] [--cases "a b ..."]
#                               [--out DIR] [--budget USD] [--parallel 4] [--read-only] [--source URL|PATH]
# Needs: a signed-in Claude Code CLI (`claude auth login`), git, python3.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW="$(cd "$SCRIPT_DIR/../.." && pwd)"
SUITE="triage"
MODELS=""
CASES=""
BUDGET=""
SOURCE="https://github.com/aplyca/AgenticDevelopmentFramework"
PARALLEL=4
OUT=""
READ_ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --suite) SUITE="$2"; shift 2 ;;
    --models) MODELS="$2"; shift 2 ;;
    --cases) CASES="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --budget) BUDGET="$2"; shift 2 ;;
    --parallel) PARALLEL="$2"; shift 2 ;;
    --read-only) READ_ONLY=1; shift ;;
    --source) SOURCE="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
FIXTURES="$SCRIPT_DIR/fixtures/$SUITE"
[ -d "$FIXTURES" ] || { echo "no such suite: $SUITE" >&2; exit 2; }
case "$SUITE" in
  debug) MAX_TURNS=30; EXTRA_TOOLS="Bash(node:*)|Bash(pnpm test:*)|Bash(npm test:*)" ;;
  adopt | upgrade) MAX_TURNS=80; BUDGET="${BUDGET:-8.00}"; BYPASS=1
    EXTRA_TOOLS="WebFetch|Bash(git:*)|Bash(cp:*)|Bash(mkdir:*)|Bash(mv:*)|Bash(rm:*)|Bash(chmod:*)|Bash(python3:*)|Bash(printf:*)|Bash(echo:*)|Bash(test:*)|Bash(sed:*)|Bash(touch:*)|Bash(diff:*)" ;;
  plugin-hooks) MAX_TURNS=8; BUDGET="${BUDGET:-0.50}"; MODELS="${MODELS:-haiku}"; EXTRA_TOOLS="Bash(git commit:*)" ;;
  plugin-docs) MAX_TURNS=12; BUDGET="${BUDGET:-0.75}"; MODELS="${MODELS:-haiku}"; EXTRA_TOOLS=""; DOCS_RULE=1 ;;
  *) MAX_TURNS=14; EXTRA_TOOLS="" ;;
esac
MODELS="${MODELS:-sonnet opus}"
BUDGET="${BUDGET:-1.50}"
BYPASS="${BYPASS:-}"
DOCS_RULE="${DOCS_RULE:-}"
[ -n "$CASES" ] || CASES="$(ls "$FIXTURES" | sed -n 's/\.input\.md$//p' | tr '\n' ' ')"
claude auth status 2>/dev/null | grep -q '"loggedIn": true' || { echo "Sign in first: claude auth login" >&2; exit 1; }

WORK="$(cd "$(mktemp -d)" && pwd -P)"
OUT="${OUT:-$WORK/out}"
mkdir -p "$OUT"
REPO="$WORK/repo"
FWC="$FW"
if [ -n "$BYPASS" ]; then # sessions get a copy of this checkout, never the checkout itself
  FWC="$WORK/framework" && mkdir -p "$FWC" && cp -R "$FW/." "$FWC/"
  [ "$SOURCE" = "$FW" ] && SOURCE="$FWC"
fi

# ─── The fictional project ──────────────────────────────────────────────────
mkdir -p "$REPO"
cd "$REPO" || exit 1
if [ -f "$FIXTURES/project.sh" ]; then
bash "$FIXTURES/project.sh" "$REPO" "$FW" || exit 1
else
cp -R "$FW/skeleton/." "$REPO/"
git init -q -b main && git config user.email dev@example.com && git config user.name dev
mkdir -p specs/007-newsletter-signup components/__tests__ lib/newsletter/__tests__ app/api/newsletter db/migrations src/billing/emails
cp "$FW"/docs/examples/newsletter-signup/{spec,plan,tasks}.md specs/007-newsletter-signup/

cat > components/NewsletterForm.client.tsx <<'EOF'
'use client';
import { useState } from 'react';
import { validateEmail } from '../lib/newsletter/validate-email';

export function NewsletterForm({ copy }: { copy: { ctaLabel: string; successMessage: string; errorMessage: string } }) {
  const [email, setEmail] = useState('');
  const [state, setState] = useState<'idle' | 'pending' | 'success' | 'error' | 'invalid'>('idle');

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    const check = validateEmail(email);
    if (!check.ok) return setState('invalid');
    setState('pending');
    const response = await fetch('/api/newsletter', { method: 'POST', body: JSON.stringify({ email: check.email }) });
    setState(response.ok ? 'success' : 'error');
  }

  if (state === 'success') return <p role="status">{copy.successMessage}</p>;
  return (
    <form onSubmit={submit} noValidate>
      <label htmlFor="newsletter-email">Email address</label>
      <input id="newsletter-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
      {state === 'invalid' && <p role="alert">Enter a valid email address.</p>}
      <button type="submit" disabled={state === 'pending'}>{state === 'pending' ? 'Subscribing…' : copy.ctaLabel}</button>
      {state === 'error' && <p>{copy.errorMessage}</p>}
    </form>
  );
}
EOF
cat > components/__tests__/NewsletterForm.test.tsx <<'EOF'
import { render, screen } from '@testing-library/react';
import { NewsletterForm } from '../NewsletterForm.client';

const copy = { ctaLabel: 'Subscribe', successMessage: 'Thanks!', errorMessage: 'Something went wrong.' };

it('labels the email field', () => {
  render(<NewsletterForm copy={copy} />);
  expect(screen.getByLabelText('Email address')).toBeInTheDocument();
});
EOF
cat > lib/newsletter/validate-email.ts <<'EOF'
export type EmailCheck = { ok: true; email: string } | { ok: false; reason: 'empty' | 'invalid' };

const EMAIL = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/;

export function validateEmail(input: unknown): EmailCheck {
  if (typeof input !== 'string' || input.trim() === '') return { ok: false, reason: 'empty' };
  const email = input.trim();
  if (email.length > 254 || !EMAIL.test(email)) return { ok: false, reason: 'invalid' };
  return { ok: true, email: email.toLowerCase() };
}
EOF
cat > lib/newsletter/__tests__/validate-email.test.ts <<'EOF'
import { validateEmail } from '../validate-email';

it('accepts and normalizes a valid address', () => {
  expect(validateEmail('  reader@example.com ')).toEqual({ ok: true, email: 'reader@example.com' });
});
it.each(['no-at-sign', 'a@b', 'a b@example.com'])('rejects %s as invalid', (value) => {
  expect(validateEmail(value)).toEqual({ ok: false, reason: 'invalid' });
});
EOF
cat > app/api/newsletter/route.ts <<'EOF'
import { NextResponse } from 'next/server';
import { validateEmail } from '../../../lib/newsletter/validate-email';
import { subscribe, MailchimpUnavailableError } from '../../../lib/newsletter/mailchimp';
import { hit } from '../../../lib/newsletter/rate-limit';

export async function POST(request: Request) {
  const ip = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
  const limit = await hit(ip);
  if (!limit.allowed) return NextResponse.json({ error: 'rate_limited' }, { status: 429, headers: { 'Retry-After': String(limit.retryAfter) } });
  const check = validateEmail((await request.json().catch(() => ({})))?.email);
  if (!check.ok) return NextResponse.json({ error: 'invalid_email' }, { status: 400 });
  try {
    return NextResponse.json({ status: await subscribe(check.email) });
  } catch (error) {
    if (error instanceof MailchimpUnavailableError) return NextResponse.json({ error: 'provider_unavailable' }, { status: 502 });
    throw error;
  }
}
EOF
printf 'create table events (\n  id bigserial primary key,\n  name varchar(64) not null,\n  source varchar(20) not null,\n  created_at timestamptz not null default now()\n);\n' > db/migrations/001_create_events.sql
printf 'create index events_name_idx on events (name);\n' > db/migrations/002_events_name_index.sql
printf 'export function invoiceEmailSubject(invoiceNumber: string): string {\n  return `Payment Recieved — invoice ${invoiceNumber}`;\n}\n' > src/billing/emails/invoice.ts
printf '{ "name": "newsletter-site", "private": true, "scripts": { "dev": "next dev -p 3000", "test": "vitest run", "lint": "eslint .", "typecheck": "tsc --noEmit" } }\n' > package.json
printf 'MAILCHIMP_API_KEY=\nMAILCHIMP_LIST_ID=\nDATABASE_URL=\n' > .env.example
printf 'node_modules/\n.env\n.env.local\n' > .gitignore

python3 - "$REPO" <<'PY'
import sys
from pathlib import Path
r = Path(sys.argv[1])
def fill(path, pairs):
    p = r / path; s = p.read_text()
    for old, new in pairs:
        s = s.replace(old, new)
    p.write_text(s)
fill("AGENTS.md", [
    ("# [PROJECT NAME]", "# Newsletter Site"),
    ("[One paragraph: what this project is, who uses it, and its stage — PoC, MVP, or production.]",
     "The marketing site for a publisher: article pages, a newsletter signup (Mailchimp), and billing emails for paid subscribers. In production."),
    ("Stack: [languages, frameworks and versions, database, hosting. Example: Next.js 15, React 19, TypeScript, PostgreSQL, Vercel.]",
     "Stack: Next.js 15, React 19, TypeScript, PostgreSQL (append-only SQL migrations in `db/migrations/`), Contentful, Vercel."),
    ("- [e.g. `src/billing/` — invoices and payment state]\n- [e.g. row-level security policies in `db/migrations/`]",
     "- `src/billing/` — invoices, payment state, and billing emails"),
    ("[existing migrations in `db/migrations/`]", "existing migrations in `db/migrations/`"),
    ("[`main`]", "`main`"), ("[`.env.example`]", "`.env.example`"),
    ("- Install: `[command]`", "- Install: `pnpm install`"),
    ("- Dev server: `[command]` (port [XXXX])", "- Dev server: `pnpm dev` (port 3000)"),
    ("- Tests: `[command]` (port [YYYY])", "- Tests: `pnpm test`"),
    ("- Lint: `[command]` · Typecheck: `[command]`", "- Lint: `pnpm lint` · Typecheck: `pnpm typecheck`"),
    ("- Full gate before a PR: `[command]`", "- Full gate before a PR: `pnpm lint && pnpm typecheck && pnpm test`"),
])
fill(".claude/hooks/config.sh", [('CAREFUL_GLOBS=""', 'CAREFUL_GLOBS="src/billing/*"'), ('APPEND_ONLY_GLOBS=""', 'APPEND_ONLY_GLOBS="db/migrations/*"')])
fill("CLAUDE.md", [("# [PROJECT NAME] — Claude Code", "# Newsletter Site — Claude Code")])
PY
[ -f "$FIXTURES/setup.sh" ] && bash "$FIXTURES/setup.sh" "$REPO"
git add -A && git commit -qm "chore: adopt the Agentic Development Framework"
fi

# ─── Runs ───────────────────────────────────────────────────────────────────
run_case() { # run_case <case> <model>
  local case_name=$1 model=$2 work input
  work="$WORK/runs/$case_name.$model"
  input="$FIXTURES/$case_name.input.md"
  mkdir -p "$WORK/runs" && cp -R "$REPO" "$work"
  [ -f "$FIXTURES/$case_name.setup.sh" ] && bash "$FIXTURES/$case_name.setup.sh" "$work"
  python3 - "$input" "$SOURCE" "$work" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
def block(heading):
    if heading not in text:
        return ""
    return re.search(r"```\n(.*?)\n```", text.split(heading, 1)[1], re.S).group(1).replace("{{FRAMEWORK}}", sys.argv[2])
open(sys.argv[3] + ".prompt", "w").write(block("## Prompt to give the AI"))
open(sys.argv[3] + ".follow-up", "w").write(block("## Follow-up"))
PY
  local extra=() dirs=() reads=(Read Grep Glob) run_env=()
  [ -n "$EXTRA_TOOLS" ] && IFS='|' read -r -a extra <<< "$EXTRA_TOOLS"
  local flags=(--model "$model" --output-format stream-json --verbose --max-turns "$MAX_TURNS")
  if [ -n "$READ_ONLY" ]; then flags+=(--disallowedTools Edit Write MultiEdit NotebookEdit)
  elif [ -n "$BYPASS" ]; then
    flags+=(--permission-mode bypassPermissions --disallowedTools "Bash(claude:*)" "Bash(git push:*)" "Edit(~/**)" "Write(~/**)")
  elif [ -n "$DOCS_RULE" ]; then flags+=(--permission-mode default)
  else flags+=(--permission-mode acceptEdits); fi
  if grep -q '<!-- run: plugin-dir -->' "$input"; then
    flags+=(--plugin-dir "$FWC/plugins/aplyca-adf")
    [ -n "$DOCS_RULE" ] || dirs+=("$FWC")
  fi
  if [ -n "$DOCS_RULE" ]; then # reads in the project need no rule; the plugin's folder, the committed one
    reads=() run_env=(ANTHROPIC_DEFAULT_OPUS_MODEL=claude-haiku-4-5-20251001)
    grep -q '<!-- run: no-read-rule -->' "$input" || reads=("Read(/$FWC/plugins/aplyca-adf/**)")
  fi
  [ -d "$SOURCE" ] && [ "$SOURCE" != "$FWC" -o ${#dirs[@]} -eq 0 ] && dirs+=("$SOURCE")
  [ ${#dirs[@]} -gt 0 ] && flags+=(--add-dir "${dirs[@]}")
  flags+=(--allowedTools ${reads[@]+"${reads[@]}"} Skill "Bash(git log:*)" "Bash(git status)" "Bash(git show:*)" "Bash(git diff:*)" \
      "Bash(git switch:*)" "Bash(git checkout:*)" "Bash(git branch:*)" "Bash(ls:*)" "Bash(grep:*)" "Bash(find:*)" \
      "Bash(cat:*)" "Bash(head:*)" "Bash(wc:*)" ${extra[@]+"${extra[@]}"} \
    --setting-sources project,local --strict-mcp-config --max-budget-usd "$BUDGET")
  (cd "$work" && env ${run_env[@]+"${run_env[@]}"} claude -p "$(cat "$work.prompt")" "${flags[@]}" \
    < /dev/null > "$OUT/$case_name.$model.jsonl" 2> "$OUT/$case_name.$model.err")
  if [ -s "$work.follow-up" ]; then
    local sid
    sid="$(python3 -c 'import json, sys
for raw in open(sys.argv[1]):
    try: d = json.loads(raw)
    except ValueError: continue
    if d.get("session_id"): print(d["session_id"]); break' "$OUT/$case_name.$model.jsonl")"
    (cd "$work" && env ${run_env[@]+"${run_env[@]}"} claude -p "$(cat "$work.follow-up")" --resume "$sid" "${flags[@]}" \
      < /dev/null > "$OUT/$case_name.$model.2.jsonl" 2>> "$OUT/$case_name.$model.err")
  fi
  [ -f "$FIXTURES/inspect.sh" ] && bash "$FIXTURES/inspect.sh" "$work" "$OUT/$case_name.$model.jsonl" "$case_name" \
    > "$OUT/$case_name.$model.state.md" 2>&1
  echo "  $case_name · $model done"
}
export -f run_case
export FW FWC WORK REPO OUT FIXTURES BUDGET READ_ONLY MAX_TURNS EXTRA_TOOLS SOURCE BYPASS DOCS_RULE
echo "Fixture project: $REPO"
echo "Running: $CASES on $MODELS ($PARALLEL at a time, \$$BUDGET cap each)"
for c in $CASES; do for m in $MODELS; do echo "$c $m"; done; done | xargs -P "$PARALLEL" -n 2 bash -c 'run_case "$0" "$1"'

# ─── Transcripts ────────────────────────────────────────────────────────────
python3 - "$OUT" "$SUITE" <<'PY'
import json, sys, glob, os, re
out = sys.argv[1]
rows = []
def read(path, parts, meta):
    for raw in open(path):
        try: d = json.loads(raw)
        except ValueError: continue
        if d.get("type") == "system" and d.get("subtype") == "init":
            meta["model"] = d.get("model")
        elif d.get("type") == "assistant":
            for b in d["message"].get("content", []):
                if b.get("type") == "text" and b["text"].strip():
                    parts.append("**Assistant:**\n\n" + b["text"].strip())
                elif b.get("type") == "tool_use":
                    i = b.get("input", {})
                    brief = i.get("command") or i.get("file_path") or i.get("url") or i.get("pattern") or json.dumps(i)[:150]
                    parts.append(f"`tool: {b['name']} — {re.sub(r'/[^ ]*/runs/[^/ ]*/', '', str(brief))[:160]}`")
        elif d.get("type") == "result":
            meta["cost"] = meta.get("cost", 0) + (d.get("total_cost_usd") or 0)
            meta["turns"] = meta.get("turns", 0) + (d.get("num_turns") or 0)
            meta["seconds"] = meta.get("seconds", 0) + round((d.get("duration_ms") or 0) / 1000)
            meta["error"] = meta.get("error") or d.get("is_error")
for path in sorted(p for p in glob.glob(os.path.join(out, "*.jsonl")) if not p.endswith(".2.jsonl")):
    name = os.path.basename(path)[:-6]
    parts, meta = [], {}
    read(path, parts, meta)
    second = os.path.join(out, name + ".2.jsonl")
    if os.path.exists(second):
        parts.append("---\n\n**Follow-up turn** (the fixture's ## Follow-up)")
        read(second, parts, meta)
    state = os.path.join(out, name + ".state.md")
    if os.path.exists(state):
        state_text = open(state).read()
        meta["passed"], meta["failed"] = state_text.count("- ✓ "), state_text.count("- ✘ ")
        parts.append("---\n\n## End state\n\n" + state_text)
    with open(os.path.join(out, name + ".md"), "w") as f:
        f.write(f"# {name}\n\nmodel {meta.get('model')} · turns {meta.get('turns')} · ${meta.get('cost', 0):.3f} · {meta.get('seconds')}s{' · ERROR' if meta.get('error') else ''}\n\n" + "\n\n".join(parts) + "\n")
    rows.append((name, meta))
print()
for name, m in rows:
    checks = f"  checks ✓{m['passed']} ✘{m['failed']}" if m.get("passed") or m.get("failed") else ""
    print(f"{name:<38} {str(m.get('model')):<20} turns {str(m.get('turns')):>3}  ${m.get('cost', 0):>6.3f}  {m.get('seconds')}s{checks}{'  ERROR' if m.get('error') else ''}")
if any(m.get("passed") or m.get("failed") for _, m in rows):
    print(f"\nChecks: {sum(m.get('passed', 0) for _, m in rows)} passed, {sum(m.get('failed', 0) for _, m in rows)} failed")
print(f"\nTotal ≈ ${sum(m.get('cost', 0) for _, m in rows):.2f} (API-equivalent). Transcripts: {out}/*.md — grade each against fixtures/" + sys.argv[2] + "/<case>.expected.md")
PY
echo "The fixture project and each run's copy (with whatever it edited) are in $WORK — delete it when done."
