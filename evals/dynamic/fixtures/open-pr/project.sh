#!/usr/bin/env bash
#
# Builds the /adf:open-pr suite's project: a packaged install, like plugin-docs' project, of a small
# newsletter site that runs on Node alone — `pnpm dev` serves the signup form on $PORT, and the gate
# (`pnpm lint && pnpm typecheck && pnpm test`) needs nothing installed. The server writes one line
# per start and request to $REQUEST_LOG, which inspect.sh reads to tell what ran, and in what order.
# Each case's setup puts its own change on a work branch and the stand-ins for the remote, gh, and the
# preview next to the run's copy (stubs.sh).
#
cd "$1" || exit 1
FW="$2"
git init -q -b main && git config user.email dev@example.com && git config user.name dev
cp -R "$FW/skeleton/." .
rm -rf .claude/skills .claude/agents .claude/workflows .cursor .gemini
find .claude/hooks -type f ! -name config.sh -delete
rm -f docs/COST-MODEL.md docs/MCP-INTEGRATION.md docs/MEMORY-STRATEGY.md docs/SPEC-MODEL.md
python3 "$FW/scripts/link-reference-docs.py" . --packaged v1.1.0 >/dev/null
mkdir -p specs/007-newsletter-signup app components lib tests
cp "$FW"/docs/examples/newsletter-signup/{spec,plan,tasks}.md specs/007-newsletter-signup/

cat > components/newsletter-copy.mjs <<'EOF'
export const copy = {
  emailLabel: 'Email address',
  ctaLabel: 'Subscribe',
  successMessage: 'Thanks — check your inbox to confirm.',
};
EOF
cat > lib/validate-email.mjs <<'EOF'
const EMAIL = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/;

export function validateEmail(input) {
  if (typeof input !== 'string' || input.trim() === '') return { ok: false, reason: 'empty' };
  const email = input.trim().toLowerCase();
  if (email.length > 254 || !EMAIL.test(email)) return { ok: false, reason: 'invalid' };
  return { ok: true, email };
}
EOF
cat > app/page.mjs <<'EOF'
import { copy } from '../components/newsletter-copy.mjs';

export function page(extra = '') {
  return `<!doctype html><title>Newsletter Site</title>
<h1>Latest articles</h1>
<form method="post" action="/api/newsletter">
  <label for="newsletter-email">${copy.emailLabel}</label>
  <input id="newsletter-email" name="email" type="email">
  <button type="submit">${copy.ctaLabel}</button>
</form>${extra}`;
}
EOF
cat > app/server.mjs <<'EOF'
import http from 'node:http';
import { appendFileSync } from 'node:fs';
import { page } from './page.mjs';
import { validateEmail } from '../lib/validate-email.mjs';

const port = Number(process.env.PORT || 3000);
const where = process.env.PREVIEW ? 'preview' : 'local';
export function log(line) {
  if (process.env.REQUEST_LOG) appendFileSync(process.env.REQUEST_LOG, `${Date.now() / 1000} ${where} ${line}\n`);
}

export async function render() {
  return page();
}

http.createServer(async (req, res) => {
  log(`${req.method} ${req.url}`);
  if (req.method === 'POST' && req.url === '/api/newsletter') {
    let body = '';
    for await (const chunk of req) body += chunk;
    const email = new URLSearchParams(body).get('email') ?? JSON.parse(body || '{}').email;
    const check = validateEmail(email);
    res.writeHead(check.ok ? 200 : 400, { 'content-type': 'application/json' });
    return res.end(JSON.stringify(check.ok ? { status: 'subscribed' } : { error: 'invalid_email' }));
  }
  res.writeHead(200, { 'content-type': 'text/html' });
  res.end(await render());
}).listen(port, () => {
  log(`start ${port}`);
  console.log(`Ready on http://localhost:${port}`);
});
EOF
cat > tests/newsletter-form.test.mjs <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { page } from '../app/page.mjs';
import { validateEmail } from '../lib/validate-email.mjs';

test('labels the email field', () => {
  assert.match(page(), /<label for="newsletter-email">Email address<\/label>/);
});
test('normalizes a valid address', () => {
  assert.deepEqual(validateEmail('  Reader@Example.com '), { ok: true, email: 'reader@example.com' });
});
test('rejects an address without a domain', () => {
  assert.deepEqual(validateEmail('a@b'), { ok: false, reason: 'invalid' });
});
EOF
cat > package.json <<'EOF'
{
  "name": "newsletter-site",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "node app/server.mjs",
    "urls": "node -e \"console.log('http://localhost:' + (process.env.PORT || 3000))\"",
    "test": "node --test",
    "lint": "node --check app/server.mjs && node --check app/page.mjs",
    "typecheck": "node --check components/newsletter-copy.mjs && node --check lib/validate-email.mjs"
  }
}
EOF
printf 'DATABASE_URL=\nMAILCHIMP_API_KEY=\n' > .env.example
printf 'node_modules/\n.env\n.env.local\n' > .gitignore

python3 - <<'PY'
import json
from pathlib import Path
def fill(path, pairs):
    p = Path(path); s = p.read_text()
    for old, new in pairs:
        assert old in s, (path, old)
        s = s.replace(old, new, 1)
    p.write_text(s)
note = ("**This project uses the packaged install.** Skills, agents, and workflows come from the `adf` plugin, "
        "pinned in `.claude/settings.json`. Where these files name a skill or workflow — `/triage`, `/open-pr` — type "
        "`/adf:triage`, `/adf:open-pr`. Where they name an agent — `@code-reviewer` — its name is "
        "`adf:code-reviewer`.\n\n")
fill(".claude/rules/claude-code.md", [("# [PROJECT NAME] — Claude Code", "# Newsletter Site — Claude Code\n\n" + note)])
agents = Path("AGENTS.md").read_text().split("\n", 1)[1]
Path("AGENTS.md").write_text("<!-- Skeleton source: v2.0.0 · de05c95 (2026-10-08) · modules: none · install: packaged -->\n" + agents)
fill("AGENTS.md", [
    ("# [PROJECT NAME]", "# Newsletter Site"),
    ("[One paragraph: what this project is, who uses it, and its stage — PoC, MVP, or production.]",
     "The marketing site for a publisher: article pages and a newsletter signup (Mailchimp). In production."),
    ("- Install: `[command]`", "- Install: nothing to install (Node 22+)"),
    ("- Dev server: `[command, e.g. make up]` · stop: `[command, e.g. make down]` · where it runs: `[command, e.g. make urls]`",
     "- Dev server: `pnpm dev` · stop: Ctrl-C · where it runs: `pnpm urls`"),
    ('- Production build, locally: `[command, e.g. make prod — or "none"]`', "- Production build, locally: `none`"),
    ("- Tests: `[command]` (on their own port)", "- Tests: `pnpm test`"),
    ("- Lint: `[command]` · Typecheck: `[command]`", "- Lint: `pnpm lint` · Typecheck: `pnpm typecheck`"),
    ("- Full gate before a PR: `[command]`", "- Full gate before a PR: `pnpm lint && pnpm typecheck && pnpm test`"),
    ("- Preview: `[where each pull request's preview deploys, e.g. the host's comment on the PR — or \"none\"]`",
     "- Preview: each pull request deploys one; the `Preview` check on the pull request names its URL (`gh pr checks <n>`)"),
])
settings = json.loads(Path(".claude/settings.json").read_text())
settings.pop("hooks", None)
Path(".claude/settings.json").write_text(json.dumps(settings, indent=2) + "\n")
PY
sed -i.bak 's/^TRIAGE_FIRST="1"/TRIAGE_FIRST=""/' .claude/hooks/config.sh && rm .claude/hooks/config.sh.bak
git add -A && git commit -q -m "chore: adopt the Agentic Development Framework (packaged)"
