#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: post-artifact-check — PostToolUse hook for Write|Edit tools
# ─────────────────────────────────────────────────────────────────────
# Registered in .claude/settings.json as PostToolUse matcher: "Write|Edit"
# Receives JSON on stdin with tool_input (file_path, content, etc.)
# Validates artifact completeness and suggests loading core guides.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Extract the file path being written/edited
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

WARNINGS=""

# ── Validate spec.md artifacts ─────────────────────────────────────
if echo "$FILE_PATH" | grep -q "spec\.md$"; then
  if [ -f "$FILE_PATH" ]; then
    if ! grep -qi "acceptance criteria\|acceptance criterion" "$FILE_PATH" 2>/dev/null; then
      WARNINGS="${WARNINGS}WARNING: spec.md is missing 'Acceptance Criteria' section. "
    fi
  fi
fi

# ── Validate design.md artifacts ───────────────────────────────────
if echo "$FILE_PATH" | grep -q "design\.md$"; then
  if [ -f "$FILE_PATH" ]; then
    if ! grep -qi "SOLID\|solid" "$FILE_PATH" 2>/dev/null; then
      WARNINGS="${WARNINGS}WARNING: design.md is missing SOLID analysis section. "
    fi
  fi
fi

# ── Suggest core guides for security-related files ─────────────────
if echo "$FILE_PATH" | grep -qiE 'auth|security|login|password|token|session|middleware'; then
  WARNINGS="${WARNINGS}[adaptive-flow] Security-related file detected. Consider consulting core/security-guide.md. "
fi

# ── Suggest core guides for API-related files ──────────────────────
if echo "$FILE_PATH" | grep -qiE 'controller|route|endpoint|api|handler'; then
  WARNINGS="${WARNINGS}[adaptive-flow] API file detected. Consider consulting core/api-patterns.md. "
fi

# ── Suggest core guides for test files ─────────────────────────────
if echo "$FILE_PATH" | grep -qiE '\.test\.|\.spec\.|__tests__|test_'; then
  WARNINGS="${WARNINGS}[adaptive-flow] Test file detected. Consider consulting core/testing-guide.md. "
fi

# Output warnings if any
if [ -n "$WARNINGS" ]; then
  echo "$WARNINGS"
fi

exit 0
