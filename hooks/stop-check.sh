#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: stop-check — Enforces compound-capture for gravity 3+ tasks
# ─────────────────────────────────────────────────────────────────────
# Triggered on Stop.
# Checks if the current task is gravity 3+ and whether compound-capture
# was executed (retrospective.md exists).
#
# IMPORTANT: Checks stop_hook_active to prevent infinite loops.
# Exit 0 = allow stop. Non-zero or decision:block = prevent stop.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
TASK_DIR="$PLUGIN_ROOT/memory/current-task"
META_FILE="$TASK_DIR/meta.yaml"

# ── Prevent infinite loops ─────────────────────────────────────────
# If this hook already triggered a stop prevention, don't block again
LOCK_FILE="/tmp/adaptive-flow-stop-check-$$"
if [ -f "/tmp/adaptive-flow-stop-active" ]; then
  # Already blocked once this session, allow stop now
  rm -f "/tmp/adaptive-flow-stop-active"
  echo "{}"
  exit 0
fi

# ── Check if there is an active task with gravity ──────────────────
if [ ! -f "$META_FILE" ]; then
  # No active task, allow stop
  echo "{}"
  exit 0
fi

# ── Parse gravity from meta.yaml ───────────────────────────────────
GRAVITY=""
if command -v python3 &>/dev/null; then
  GRAVITY=$(python3 -c "
import yaml, sys
try:
    with open('$META_FILE') as f:
        data = yaml.safe_load(f)
    print(data.get('gravity', 0))
except Exception:
    print(0)
" 2>/dev/null || echo "0")
else
  GRAVITY=$(grep -E '^gravity:' "$META_FILE" 2>/dev/null | awk '{print $2}' || echo "0")
fi

# ── Only enforce for gravity 3+ ───────────────────────────────────
if [ "$GRAVITY" -lt 3 ] 2>/dev/null; then
  echo "{}"
  exit 0
fi

# ── Check if compound-capture was executed ─────────────────────────
if [ -f "$TASK_DIR/retrospective.md" ]; then
  # Compound capture was done, allow stop
  echo "{}"
  exit 0
fi

# ── Block stop and remind about compound-capture ───────────────────
touch "/tmp/adaptive-flow-stop-active"
echo "{\"decision\": \"block\", \"reason\": \"This is a gravity ${GRAVITY} task. Run /adaptive-flow:compound-capture before completing to extract learnings and patterns. This maintains the compound engineering loop.\"}"
