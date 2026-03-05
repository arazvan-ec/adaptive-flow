#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: post-write-check — Validates artifacts after writing
# ─────────────────────────────────────────────────────────────────────
# Triggered on PostToolUse(Write|Edit).
# Validates structure of spec/design/tasks artifacts when they are
# written to memory/current-task/.
#
# Receives tool output JSON on stdin.
# Exit 0 = pass (may emit warnings).
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
TASK_DIR="$PLUGIN_ROOT/memory/current-task"

# Read stdin (tool output JSON)
INPUT=$(cat)

# Extract file_path from the JSON
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")

# Only validate files in the current-task directory
case "$FILE_PATH" in
  *memory/current-task/*)
    ;;
  *)
    exit 0
    ;;
esac

WARNINGS=""

# ── Validate spec.md ───────────────────────────────────────────────
if [ "$FILENAME" = "spec.md" ] && [ -f "$FILE_PATH" ]; then
  if ! grep -qi "acceptance criteria\|acceptance criterion" "$FILE_PATH"; then
    WARNINGS="${WARNINGS}WARNING: spec.md missing 'Acceptance Criteria' section. "
  fi
  if ! grep -qi "out of scope\|out-of-scope" "$FILE_PATH"; then
    WARNINGS="${WARNINGS}INFO: spec.md could benefit from an 'Out of Scope' section. "
  fi
fi

# ── Validate design.md ─────────────────────────────────────────────
if [ "$FILENAME" = "design.md" ] && [ -f "$FILE_PATH" ]; then
  if ! grep -qi "SOLID\|solid" "$FILE_PATH"; then
    WARNINGS="${WARNINGS}WARNING: design.md missing SOLID analysis section. "
  fi
fi

# ── Validate tasks.md ──────────────────────────────────────────────
if [ "$FILENAME" = "tasks.md" ] && [ -f "$FILE_PATH" ]; then
  if ! grep -qE '\[ \]|\[x\]|\[~\]' "$FILE_PATH"; then
    WARNINGS="${WARNINGS}WARNING: tasks.md has no checkbox items. Expected task list format. "
  fi
fi

# ── Validate plan-and-tasks.md ─────────────────────────────────────
if [ "$FILENAME" = "plan-and-tasks.md" ] && [ -f "$FILE_PATH" ]; then
  if ! grep -qi "acceptance criteria\|acceptance criterion" "$FILE_PATH"; then
    WARNINGS="${WARNINGS}WARNING: plan-and-tasks.md missing 'Acceptance Criteria' section. "
  fi
  if ! grep -qi "## Plan" "$FILE_PATH"; then
    WARNINGS="${WARNINGS}WARNING: plan-and-tasks.md missing '## Plan' section. "
  fi
  if ! grep -qi "## Tasks" "$FILE_PATH"; then
    WARNINGS="${WARNINGS}WARNING: plan-and-tasks.md missing '## Tasks' section. "
  fi
fi

# ── Output warnings ───────────────────────────────────────────────
if [ -n "$WARNINGS" ]; then
  ESCAPED=$(echo "$WARNINGS" | sed 's/\\/\\\\/g; s/"/\\"/g')
  echo "{\"additionalContext\": \"$ESCAPED\"}"
else
  echo "{}"
fi
