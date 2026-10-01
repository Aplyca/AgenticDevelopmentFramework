#!/usr/bin/env bash
#
# Runs the /triage routing fixtures (fixtures/triage/) against real Claude Code sessions.
#
# Builds a fictional project in a temp directory — the skeleton, the delivered newsletter-signup
# spec folder from docs/examples/, and a few stub source files matching the fixtures' context — then
# runs each fixture's prompt headless with `claude -p` on each model. Each run works in its own
# throwaway copy, may edit it (so the project's hooks — triage-first, careful-paths — take part), and
# is turn- and budget-capped; `--read-only` denies edits instead, so a run stops at its first edit.
# Transcripts land in the output directory for grading against each fixture's .expected.md.
#
# Usage: ./run-triage-evals.sh [--models "sonnet opus"] [--cases "fast-copy-change ..."]
#                              [--out DIR] [--budget 1.50] [--parallel 4] [--read-only]
# Needs: a signed-in Claude Code CLI (`claude auth login`), git, python3.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures/triage"
MODELS="sonnet opus"
CASES=""
BUDGET="1.50"
PARALLEL=4
OUT=""
READ_ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --models) MODELS="$2"; shift 2 ;;
    --cases) CASES="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --budget) BUDGET="$2"; shift 2 ;;
    --parallel) PARALLEL="$2"; shift 2 ;;
    --read-only) READ_ONLY=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[ -n "$CASES" ] || CASES="$(ls "$FIXTURES" | sed -n 's/\.input\.md$//p' | tr '\n' ' ')"
claude auth status 2>/dev/null | grep -q '"loggedIn": true' || { echo "Sign in first: claude auth login" >&2; exit 1; }

WORK="$(cd "$(mktemp -d)" && pwd -P)"
OUT="${OUT:-$WORK/out}"
mkdir -p "$OUT"
REPO="$WORK/repo"

# ─── The fictional project ──────────────────────────────────────────────────
mkdir -p "$REPO"
cp -R "$FW/skeleton/." "$REPO/"
cd "$REPO" || exit 1
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
git add -A && git commit -qm "chore: adopt the AI-assisted development framework"

# ─── Runs ───────────────────────────────────────────────────────────────────
run_case() { # run_case <case> <model>
  local case_name=$1 model=$2 work prompt
  work="$WORK/runs/$case_name.$model"
  mkdir -p "$WORK/runs" && cp -R "$REPO" "$work"
  prompt="$(python3 - "$FIXTURES/$case_name.input.md" <<'PY'
import re, sys
section = open(sys.argv[1]).read().split("## Prompt to give the AI", 1)[1]
print(re.search(r"```\n(.*?)\n```", section, re.S).group(1))
PY
)"
  local edits=(--permission-mode acceptEdits)
  [ -n "$READ_ONLY" ] && edits=(--disallowedTools Edit Write MultiEdit NotebookEdit)
  (cd "$work" && claude -p "$prompt" --model "$model" --output-format stream-json --verbose --max-turns 14 \
    "${edits[@]}" \
    --allowedTools Read Grep Glob Skill "Bash(git log:*)" "Bash(git status)" "Bash(git show:*)" "Bash(git diff:*)" \
      "Bash(git switch:*)" "Bash(git checkout:*)" "Bash(git branch:*)" "Bash(ls:*)" "Bash(grep:*)" "Bash(find:*)" \
      "Bash(cat:*)" "Bash(head:*)" "Bash(wc:*)" \
    --setting-sources project,local --strict-mcp-config --max-budget-usd "$BUDGET" \
    < /dev/null > "$OUT/$case_name.$model.jsonl" 2> "$OUT/$case_name.$model.err")
  echo "  $case_name · $model done"
}
export -f run_case
export WORK REPO OUT FIXTURES BUDGET READ_ONLY
echo "Fixture project: $REPO"
echo "Running: $CASES on $MODELS ($PARALLEL at a time, \$$BUDGET cap each)"
for c in $CASES; do for m in $MODELS; do echo "$c $m"; done; done | xargs -P "$PARALLEL" -n 2 bash -c 'run_case "$0" "$1"'

# ─── Transcripts ────────────────────────────────────────────────────────────
python3 - "$OUT" <<'PY'
import json, sys, glob, os, re
out = sys.argv[1]
rows = []
for path in sorted(glob.glob(os.path.join(out, "*.jsonl"))):
    name = os.path.basename(path)[:-6]
    parts, meta = [], {}
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
                    brief = i.get("command") or i.get("file_path") or i.get("pattern") or json.dumps(i)[:150]
                    parts.append(f"`tool: {b['name']} — {re.sub(r'/[^ ]*/runs/[^/ ]*/', '', str(brief))[:160]}`")
        elif d.get("type") == "result":
            meta.update(cost=d.get("total_cost_usd") or 0, turns=d.get("num_turns"), seconds=round((d.get("duration_ms") or 0) / 1000), error=d.get("is_error"))
    with open(os.path.join(out, name + ".md"), "w") as f:
        f.write(f"# {name}\n\nmodel {meta.get('model')} · turns {meta.get('turns')} · ${meta.get('cost', 0):.3f} · {meta.get('seconds')}s{' · ERROR' if meta.get('error') else ''}\n\n" + "\n\n".join(parts) + "\n")
    rows.append((name, meta))
print()
for name, m in rows:
    print(f"{name:<38} {str(m.get('model')):<20} turns {str(m.get('turns')):>3}  ${m.get('cost', 0):>6.3f}  {m.get('seconds')}s{'  ERROR' if m.get('error') else ''}")
print(f"\nTotal ≈ ${sum(m.get('cost', 0) for _, m in rows):.2f} (API-equivalent). Transcripts: {out}/*.md — grade each against fixtures/triage/<case>.expected.md")
PY
echo "The fixture project and each run's copy (with whatever it edited) are in $WORK — delete it when done."
