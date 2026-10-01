#!/usr/bin/env bash
#
# Setup for the /debug cases, run by run-session-evals.sh in the fixture project before its first
# commit. Makes the newsletter code runnable with Node's built-in test runner — Node 22.18+ runs
# TypeScript directly, so there is nothing to install — and adds the rate limit the
# debug-unclear-cause case is about. The two bugs the cases describe are in the code as written:
# validate-email.ts checks its lowercase-only pattern before lowercasing, and client-key.ts sends
# every request without X-Forwarded-For to one shared key.
#
set -euo pipefail
cd "$1"

rm -f components/__tests__/NewsletterForm.test.tsx lib/newsletter/__tests__/validate-email.test.ts

cat > lib/newsletter/client-key.ts <<'EOF'
export function clientKey(headers: Headers): string {
  return headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';
}
EOF

cat > lib/newsletter/rate-limit.ts <<'EOF'
const WINDOW_MS = 60_000;
const LIMIT = 10;
const windows = new Map<string, { start: number; count: number }>();

export function hit(key: string, now: number = Date.now()): { allowed: boolean; retryAfter: number } {
  const current = windows.get(key);
  if (!current || now - current.start >= WINDOW_MS) {
    windows.set(key, { start: now, count: 1 });
    return { allowed: true, retryAfter: 0 };
  }
  current.count += 1;
  if (current.count > LIMIT) {
    return { allowed: false, retryAfter: Math.ceil((current.start + WINDOW_MS - now) / 1000) };
  }
  return { allowed: true, retryAfter: 0 };
}
EOF

cat > app/api/newsletter/route.ts <<'EOF'
import { NextResponse } from 'next/server';
import { validateEmail } from '../../../lib/newsletter/validate-email';
import { subscribe, MailchimpUnavailableError } from '../../../lib/newsletter/mailchimp';
import { hit } from '../../../lib/newsletter/rate-limit';
import { clientKey } from '../../../lib/newsletter/client-key';

export async function POST(request: Request) {
  const limit = hit(clientKey(request.headers));
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

cat > lib/newsletter/__tests__/validate-email.test.ts <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateEmail } from '../validate-email.ts';

test('accepts and normalizes a valid address', () => {
  assert.deepEqual(validateEmail('  reader@example.com '), { ok: true, email: 'reader@example.com' });
});

for (const value of ['no-at-sign', 'a@b', 'a b@example.com']) {
  test(`rejects ${value} as invalid`, () => {
    assert.deepEqual(validateEmail(value), { ok: false, reason: 'invalid' });
  });
}
EOF

cat > lib/newsletter/__tests__/rate-limit.test.ts <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { hit } from '../rate-limit.ts';

test('allows ten signups a minute from one address, then refuses', () => {
  const now = 1_000_000;
  for (let i = 0; i < 10; i++) assert.equal(hit('203.0.113.7', now).allowed, true);
  assert.equal(hit('203.0.113.7', now).allowed, false);
});

test('counts each address separately', () => {
  const now = 2_000_000;
  for (let i = 0; i < 10; i++) hit('198.51.100.1', now);
  assert.equal(hit('198.51.100.2', now).allowed, true);
});
EOF

cat > lib/newsletter/__tests__/client-key.test.ts <<'EOF'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { clientKey } from '../client-key.ts';

test('takes the first address in X-Forwarded-For', () => {
  assert.equal(clientKey(new Headers({ 'x-forwarded-for': '203.0.113.7, 10.0.0.1' })), '203.0.113.7');
});
EOF

printf '{ "name": "newsletter-site", "private": true, "type": "module", "scripts": { "dev": "next dev -p 3000", "test": "node --test", "lint": "eslint .", "typecheck": "tsc --noEmit" } }\n' > package.json
python3 - <<'PY'
from pathlib import Path
p = Path("AGENTS.md"); s = p.read_text()
s = s.replace("- Tests: `pnpm test`", "- Tests: `pnpm test` (Node's built-in runner — `node --test <file>` for one file; nothing to install)")
p.write_text(s)
PY
