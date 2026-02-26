#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: pre-commit-guard — PreToolUse hook for Bash tool
# ─────────────────────────────────────────────────────────────────────
# Registered in .claude/settings.json as PreToolUse matcher: "Bash"
# Receives JSON on stdin with tool_input.command
# Blocks git commits that include sensitive files.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Extract the command being run
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

# Only check git commit commands
if ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# Check for sensitive files in staged changes
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

SENSITIVE_PATTERNS=('.env' 'credentials' 'secret' '.key' '.pem' 'token')
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  MATCHES=$(echo "$STAGED_FILES" | grep -i "$pattern" || true)
  if [ -n "$MATCHES" ]; then
    echo '{"decision": "block", "reason": "BLOCKED: Potentially sensitive file staged: '"$MATCHES"'. Unstage the file or confirm it is safe before committing."}'
    exit 0
  fi
done

# Allow the commit
exit 0
