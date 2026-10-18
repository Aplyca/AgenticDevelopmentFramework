#!/usr/bin/env bash
#
# visible-change: the fast lane's light CR 2 — the form's email label reads "Your email" — implemented,
# tested, and committed on its work branch, nothing pushed. Its local environment starts.
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
git rev-parse HEAD > "$work.setup-head"
