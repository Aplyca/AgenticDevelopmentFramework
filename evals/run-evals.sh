#!/usr/bin/env bash
#
# Top-level eval runner. Runs every static suite (zero token cost) and, with --all, lists the
# dynamic fixtures to run manually.
#
# Usage:
#   ./run-evals.sh              # static suites
#   ./run-evals.sh --all        # static suites + list dynamic fixtures to run manually
#

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "========================================"
echo "Framework evals"
echo "========================================"

STATUS=0
for suite in check-skills.sh test-hooks.sh test-modules.sh test-plugin.sh; do
    "$SCRIPT_DIR/static/$suite" || STATUS=1
done

if [ "${1:-}" = "--all" ]; then
    echo ""
    echo "----------------------------------------"
    echo "Dynamic evals — manual cases to run"
    echo "----------------------------------------"
    echo ""
    echo "Dynamic evals require an AI tool (Claude Code, Cursor, etc.) and aren't run automatically."
    echo "Run each fixture manually following the steps in dynamic/run-dynamic.md."
    echo ""
    echo "Available fixtures:"
    find "$SCRIPT_DIR/dynamic/fixtures" -name '*.input.md' 2>/dev/null | sort | while read -r f; do
        rel=${f#$SCRIPT_DIR/}
        echo "  - $rel"
    done
    echo ""
    echo "For automated dynamic evals, see dynamic/run-dynamic.md (Anthropic SDK / Braintrust / DeepEval patterns)."
    echo ""
fi

if [ "$STATUS" -eq 0 ]; then
    echo "All static suites passed."
else
    echo "One or more static suites failed."
fi
exit $STATUS
