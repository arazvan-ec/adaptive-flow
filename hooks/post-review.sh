#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: post-review — Validates review completeness after reviewer
# ─────────────────────────────────────────────────────────────────────
# Runs after the reviewer worker returns.
# Checks that criteria were verified with evidence.
#
# Exit 0 = pass (may emit warnings), Exit 1 = block.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

CHANGES_DIR="openspec/changes"
if [ ! -d "$CHANGES_DIR" ]; then
  echo "INFO: No openspec/changes/ directory. Skipping post-review validation."
  exit 0
fi

LATEST_SLUG=$(ls -t "$CHANGES_DIR" 2>/dev/null | head -1)
if [ -z "$LATEST_SLUG" ]; then
  echo "INFO: No change directories found. Skipping."
  exit 0
fi

SLUG_DIR="$CHANGES_DIR/$LATEST_SLUG"

# ── Look for QA report ───────────────────────────────────────────────
QA_REPORT=$(find "$SLUG_DIR" -name "qa-report*" -o -name "review*" 2>/dev/null | head -1)

if [ -z "$QA_REPORT" ]; then
  echo "WARNING: No QA report found in $SLUG_DIR"
  echo "The reviewer should produce a QA report with verdict."
  exit 0
fi

# ── Check for verdict ────────────────────────────────────────────────
if grep -qi "APPROVED\|REJECTED" "$QA_REPORT"; then
  VERDICT=$(grep -oi "APPROVED\|REJECTED" "$QA_REPORT" | head -1)
  echo "Review verdict: $VERDICT"

  if [ "$VERDICT" = "REJECTED" ]; then
    echo "WARNING: Review was REJECTED. Address blocking issues before proceeding."
  fi
else
  echo "WARNING: QA report missing verdict (APPROVED/REJECTED)."
fi

# ── Check for evidence ───────────────────────────────────────────────
if ! grep -qi "evidence\|verified\|PASS\|FAIL" "$QA_REPORT"; then
  echo "WARNING: QA report may lack evidence for criteria verification."
fi

echo "Post-review validation completed."
exit 0
