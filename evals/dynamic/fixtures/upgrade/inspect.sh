#!/usr/bin/env bash
#
# Prints an upgrade run's end state — branches and commits, the stamp, the settings — and, for the
# switch-to-packaged case, checks the packaged layout (../../check-packaged.sh), the PDR that records
# the switch, and that main is untouched. Read-only.
# Usage: inspect.sh <run copy> <session output .jsonl> <case>
#
cd "$1" || exit 1
echo "### Branches and commits"
echo '```'
for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do echo "--- $b"; git log --oneline "$b" 2>&1 | head -5; done
echo "--- current: $(git branch --show-current) · working tree: $(git status --short | wc -l | tr -d ' ') uncommitted paths"
echo '```'
echo "### CLAUDE.md, first line · .claude/ · docs/process/"
echo '```'
head -1 CLAUDE.md
ls .claude .claude/hooks 2>&1
ls docs/process
echo '```'
if [ "${3:-}" = switch-to-packaged ]; then
  echo "### Checks — the switch to the packaged install"
  release="$(git -C "$FW" tag --list 'v*' --sort=-v:refname | head -1)"
  bash "$(dirname "$0")/../../check-packaged.sh" . "$release" "$(git -C "$FW" rev-parse --short "$release^{commit}")" "$FW"
  check() { if eval "$2"; then echo "- ✓ $1"; else echo "- ✘ $1"; fi; }
  check "a new PDR records the switch to the packaged install" \
    "ls docs/process | grep -v -E '^(0000|0001)-|README' | grep -q . && grep -l -i 'packaged' \$(ls docs/process/*.md | grep -v -E '/(0000|0001)-|README') >/dev/null"
  check "PDR-0001 is marked amended" "grep -q -i 'amend' docs/process/0001-*.md"
  check "\`main\` is untouched: the switch is on its own branch" "[ \"\$(git rev-list --count main)\" = 1 ] && [ \"\$(git branch --show-current)\" != main ]"
fi
