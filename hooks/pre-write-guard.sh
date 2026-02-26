#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: pre-write-guard — Validates files before writing
# ─────────────────────────────────────────────────────────────────────
# Triggered on PreToolUse(Write|Edit).
# Checks for sensitive files and suggests relevant core guides.
#
# Receives tool input JSON on stdin.
# Exit 0 = allow, Exit 1 = block.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract file_path from the JSON input
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)

if [ -z "$FILE_PATH" ]; then
  # No file path found, allow
  exit 0
fi

FILENAME=$(basename "$FILE_PATH")
DIRPATH=$(dirname "$FILE_PATH")

# ── Check for sensitive files ──────────────────────────────────────
SENSITIVE_PATTERNS=('.env' 'credentials' 'secret' '.key' '.pem' 'token' 'password')
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$FILENAME" | grep -qi "$pattern"; then
    echo "WARNING: Writing to potentially sensitive file: $FILE_PATH"
    echo "Ensure this is intentional and no secrets are being hardcoded."
    # Warn but don't block — the user may need to write config files
    break
  fi
done

# ── Suggest relevant core guides ───────────────────────────────────
SUGGESTIONS=""

# Auth/security files → security guide
if echo "$FILE_PATH" | grep -qiE '(auth|security|login|session|token|jwt|oauth|permission|rbac)'; then
  SUGGESTIONS="${SUGGESTIONS}Consider reviewing: core/security-guide.md (security-related file detected). "
fi

# API/controller/route files → API patterns guide
if echo "$FILE_PATH" | grep -qiE '(controller|route|api|endpoint|handler|middleware)'; then
  SUGGESTIONS="${SUGGESTIONS}Consider reviewing: core/api-patterns.md (API-related file detected). "
fi

# Test files → testing guide
if echo "$FILE_PATH" | grep -qiE '\.(test|spec)\.(ts|js|py|rb|go|rs)$|_test\.(go|py|rb)$|test_.*\.py$'; then
  SUGGESTIONS="${SUGGESTIONS}Consider reviewing: core/testing-guide.md (test file detected). "
fi

if [ -n "$SUGGESTIONS" ]; then
  ESCAPED=$(echo "$SUGGESTIONS" | sed 's/\\/\\\\/g; s/"/\\"/g')
  echo "{\"additionalContext\": \"$ESCAPED\"}"
else
  echo "{}"
fi
