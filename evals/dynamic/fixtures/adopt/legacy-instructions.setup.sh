#!/usr/bin/env bash
#
# Replaces the suite's new project in this case's copy with one that already has code and its own
# instructions, written before the framework (decision 0099): a CLAUDE.md that mixes project facts
# with a process of its own — ask before every commit, confirm each step — a line the framework
# already says, an override the framework honors (a person marks pull requests ready), a line the pass
# can't classify alone, and a frozen directory. One commit on main; no remote.
# Usage: legacy-instructions.setup.sh <copy>
#
set -euo pipefail
copy="$1"
find "$copy" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
cd "$copy"
git init -q -b main && git config user.email dev@example.com && git config user.name dev
mkdir -p src/newsletter legacy
cat > package.json <<'JSON'
{
  "name": "newsletter-site",
  "private": true,
  "packageManager": "pnpm@9.12.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "test": "vitest run",
    "lint": "eslint ."
  },
  "dependencies": { "next": "15.0.3", "react": "19.0.0", "react-dom": "19.0.0" },
  "devDependencies": { "typescript": "5.6.3", "vitest": "2.1.4", "eslint": "9.14.0" }
}
JSON
cat > src/newsletter/signup.ts <<'TS'
export function isValidEmail(email: string): boolean {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}
TS
cat > legacy/old-signup.js <<'JS'
// The signup form before the move to Next.js. Frozen.
JS
cat > README.md <<'MD'
# Newsletter Site

The marketing site for a publisher: article pages and a newsletter signup.
MD
cat > CLAUDE.md <<'MD'
# Newsletter Site

Marketing site for a publisher: article pages and a newsletter signup.

## Stack

- Next.js 15 with TypeScript, pnpm
- Tests: `pnpm test` (Vitest); lint: `pnpm lint`

## How to work with me

- Ask me before every commit.
- Confirm each step with me before moving on to the next one.
- Never push to main.
- A person marks pull requests ready for review here: leave them as drafts.
- Check with the content team before changing anything under `src/newsletter/`.

## Boundaries

- `legacy/` is frozen: never edit it.
MD
git add -A && git commit -q -m "feat: newsletter signup validation"
