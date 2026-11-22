#!/usr/bin/env bash
#
# refresh-after-cr: the draft for the fast lane's light CR 2 — the email label reads "Your email" — is
# open and its preview deployed. Its description has the agent-owned sections between their adf:
# markers, and text people added outside them: a note from marketing, a ticked box, a screenshot. The
# preview redeploys on each push.
#
set -euo pipefail
work="$1"
source "$(dirname "$0")/stubs.sh"
cd "$work"
git switch -q -c fix/newsletter-email-label
sed -i.bak "s/emailLabel: 'Email address'/emailLabel: 'Your email'/" components/newsletter-copy.mjs
sed -i.bak 's/>Email address</>Your email</' tests/newsletter-form.test.mjs
rm -f components/*.bak tests/*.bak
cat >> specs/007-newsletter-signup/spec.md <<'SPEC'

# CR 2 — The email field's label reads "Your email" (2026-10-18) · light

- **Requested:** https://tracker.example.com/t/MKT-530 · by marketing

| Aspect | Delivered (PR 142) | Change |
| --- | --- | --- |
| Email field label | "Email address", fixed text | "Your email", fixed text |

Done when the signup form shows "Your email" and the label test passes.
SPEC
git add -A && git commit -q -m 'fix(newsletter): the email label reads "Your email" (CR 2)'
python3 - <<'PY'
from pathlib import Path
p = Path("specs/007-newsletter-signup/spec.md"); s = p.read_text()
first = '  - "https://github.com/<org>/marketing-site/pull/142 · initial delivery"\n'
assert first in s
p.write_text(s.replace(first, first + '  - "https://github.com/example-org/newsletter-site/pull/42 · CR 2"\n', 1))
PY
git add specs/007-newsletter-signup/spec.md && git commit -q -m "spec: link newsletter-signup pull request"
git push -q -u origin fix/newsletter-email-label

cat > "$work.pr-body.md" <<'MD'
## Traceability
**Spec:** `specs/007-newsletter-signup/` (CR 2, light)
**Tracker task:** https://tracker.example.com/t/MKT-530
**Lane:** fast — a precise copy change the requester decided; set by the triggers
Note from marketing: the label must match the mobile app's wording.

## What changed and why
<!-- adf:what-changed -->
The newsletter form's email label reads "Your email" instead of "Email address" (light CR 2), so the
form matches the copy marketing approved.
<!-- /adf:what-changed -->

## How to verify
<!-- adf:how-to-verify -->
1. Open any article page and find the signup form.
2. The email field's label reads "Your email".
**Tests:** `tests/newsletter-form.test.mjs` · "labels the email field", updated
<!-- /adf:how-to-verify -->

## Verified / not verified
<!-- adf:verified -->
- Verified: `pnpm lint && pnpm typecheck && pnpm test` — 3 tests pass; the label test failed first on the old text
- Local check: the signup form on the local server shows "Your email"
- Preview: the signup form on the preview shows "Your email"; nothing submitted
- Not verified: the mobile layout
<!-- /adf:verified -->

## Merge danger
**Reversible:** yes — reverting the merge undoes it
**Blast radius:** the signup form's label, on every article page

## Screenshots
![The form with the new label](https://example.com/screenshots/newsletter-label.png)

## Checklist
- [x] Git hooks were not bypassed (`--no-verify` was not used)
MD
cp "$work.pr-body.md" "$work.pr-body.before.md"
"$work.bin/gh" __deploy
touch "$work.redeploy"
: > "$work.events"
git rev-parse HEAD > "$work.setup-head"
