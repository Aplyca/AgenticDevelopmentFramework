#!/usr/bin/env bash
#
# docs-only: a fast-lane guide for the newsletter's admins — one Markdown file, nothing a person sees
# in the site — committed on its work branch, nothing pushed.
#
set -euo pipefail
work="$1"
source "$(dirname "$0")/stubs.sh"
cd "$work"
git switch -q -c docs/newsletter-admin-guide
cat > docs/NEWSLETTER-ADMIN.md <<'MD'
# Newsletter signup — admin guide

For the marketing team. The signup form appears on every article page.

## Changing the form's copy

The button text and the success message come from `components/newsletter-copy.mjs`; ask a developer
to change them. The email field's label is fixed text, recorded in `specs/007-newsletter-signup/`.

## Reading the subscriber list

Subscribers go to the Mailchimp audience "Newsletter". Export it from Mailchimp: Audience → All
contacts → Export audience. The site keeps no copy of the list.
MD
git add -A && git commit -q -m "docs: a guide to the newsletter signup for its admins"
git rev-parse HEAD > "$work.setup-head"
