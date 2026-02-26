#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: on-stop — Stop event hook
# ─────────────────────────────────────────────────────────────────────
# Registered in .claude/settings.json as Stop hook.
# Checks if a gravity 3+ task was completed without running compound-capture.
# Reminds the user to run /adaptive-flow:compound-capture.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

META_FILE=".artifacts/meta.yaml"

# If no meta file exists, this wasn't a tracked task
if [ ! -f "$META_FILE" ]; then
  exit 0
fi

# Extract gravity from meta.yaml (simple grep, no YAML parser needed)
GRAVITY=$(grep -oP 'gravity:\s*\K\d+' "$META_FILE" 2>/dev/null || echo "0")

# Only check for gravity 3+
if [ "$GRAVITY" -lt 3 ] 2>/dev/null; then
  exit 0
fi

# Check if retrospective exists (indicates compound-capture was run)
if [ -f ".artifacts/retrospective.md" ]; then
  exit 0
fi

# Remind about compound capture
echo "[adaptive-flow] This was a gravity ${GRAVITY} task. Consider running /adaptive-flow:compound-capture to extract learnings before finishing."

exit 0
