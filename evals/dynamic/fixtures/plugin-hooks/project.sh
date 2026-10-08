#!/usr/bin/env bash
#
# Builds a project on the packaged install (decision 0016): no hook scripts of its own, only
# .claude/hooks/config.sh, and the stamp on AGENTS.md's first line saying `install: packaged`, so the
# adf plugin's hooks — loaded per session with --plugin-dir — act. On a work branch with a spec
# folder, a sensitive area, a lockfile, and an env template, so each hook has something to stop.
#
cd "$1" || exit 1
git init -q -b main && git config user.email dev@example.com && git config user.name dev
mkdir -p .claude/hooks specs/007-newsletter-signup src/billing src/newsletter
printf '<!-- Skeleton source: v2.0.0 · ab56cb6 (2026-10-08) · modules: none · install: packaged -->\n# Newsletter Site\n' > AGENTS.md
printf -- '---\nstatus: draft\n---\n# Newsletter signup\n' > specs/007-newsletter-signup/spec.md
printf 'PROTECTED_BRANCHES="main"\nGENERATED_GLOBS="package-lock.json"\nCAREFUL_GLOBS="src/billing/*"\nTRIAGE_FIRST="1"\n' > .claude/hooks/config.sh
printf 'MAILCHIMP_API_KEY=\n' > .env.example
printf 'export const listName = "weekly";\n' > src/newsletter/config.ts
printf '{}\n' > package-lock.json
git add -A && git commit -q -m "chore: a project on the packaged install"
git switch -q -c feat/newsletter-signup
