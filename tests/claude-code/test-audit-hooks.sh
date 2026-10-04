#!/usr/bin/env bash
# Each hooked skill carries the audit conditional, the user-question reminder,
# and its own event/harvest step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FAILURES=0

pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; FAILURES=$((FAILURES + 1)); }

REMINDER="Audit logging is ON — say 'stop auditing superpowers' to disable."
COND='python3 ../auditing-superpowers/scripts/audit.py enabled'

# has SKILL STRING DESCRIPTION
has() {
    if grep -qF -- "$2" "$REPO_ROOT/skills/$1/SKILL.md"; then pass "$1: $3"; else fail "$1: $3"; fi
}

for skill in brainstorming writing-plans subagent-driven-development executing-plans; do
    has "$skill" "## Audit" "has an Audit section"
    has "$skill" "$COND" "audit section is conditional on the marker"
    has "$skill" "$REMINDER" "carries the user-question reminder"
    has "$skill" "python3 ../auditing-superpowers/scripts/harvest.py" "runs harvest"
done
has brainstorming "audit.py event brainstorm-done" "logs brainstorm-done"
has writing-plans "audit.py event plan-written" "logs plan-written"
has subagent-driven-development "audit.py event dispatch" "logs dispatches"
has subagent-driven-development "diff_bytes" "logs diff size on dispatches"
has subagent-driven-development "audit.py event review" "logs reviews"
has subagent-driven-development "audit.py copy-ledger" "copies the ledger before deleting the workspace"
has executing-plans "audit.py copy-ledger" "copies the ledger before deleting the workspace"

echo ""
if [[ "$FAILURES" -ne 0 ]]; then echo "FAILED: $FAILURES assertion(s)."; exit 1; fi
echo "PASS"
