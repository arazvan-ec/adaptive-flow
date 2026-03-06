#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: bash-guard — Warns on dangerous shell commands
# ─────────────────────────────────────────────────────────────────────
# Triggered on PreToolUse(Bash).
# Detects destructive or high-risk commands and emits a warning
# via additionalContext. Does NOT block — the user has the final say.
#
# Receives tool input JSON on stdin.
# Exit 0 = allow (may emit warnings via additionalContext).
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract the command field from JSON
COMMAND=$(printf '%s' "$INPUT" | parse_json_field "command")

if [ -z "$COMMAND" ]; then
  echo "{}"
  exit 0
fi

WARNINGS=""

# ── Destructive file operations ────────────────────────────────────
if echo "$COMMAND" | grep -qE 'rm\s+-(r|f|rf|fr)\s|rm\s+--force|rm\s+--recursive'; then
  WARNINGS="${WARNINGS}WARNING: Destructive rm detected. Verify the target path is correct. "
fi

# ── Database destructive commands ──────────────────────────────────
if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE|INDEX|SCHEMA)|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\w+\s*;?\s*$'; then
  WARNINGS="${WARNINGS}WARNING: Destructive database command detected. Ensure this is intentional and you have backups. "
fi

# ── Git force operations ──────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f\b|git\s+reset\s+--hard|git\s+clean\s+-f'; then
  WARNINGS="${WARNINGS}WARNING: Destructive git operation detected (force push, hard reset, or clean). This may cause irreversible data loss. "
fi

# ── Dangerous permissions ──────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'chmod\s+(777|666|a\+w)|chown\s+-R'; then
  WARNINGS="${WARNINGS}WARNING: Overly permissive chmod/chown detected. Consider more restrictive permissions. "
fi

# ── Curl piped to shell ───────────────────────────────────────────
if echo "$COMMAND" | grep -qE 'curl\s+.*\|\s*(ba)?sh|wget\s+.*\|\s*(ba)?sh'; then
  WARNINGS="${WARNINGS}WARNING: Piping remote content to shell detected. Verify the source URL is trusted. "
fi

# ── Environment/secrets exposure ──────────────────────────────────
if echo "$COMMAND" | grep -qE 'printenv|env\s*$|echo\s+\$\{?(AWS|SECRET|TOKEN|PASSWORD|API_KEY)'; then
  WARNINGS="${WARNINGS}WARNING: Potential secrets exposure detected. Avoid printing sensitive environment variables. "
fi

# ── Output ─────────────────────────────────────────────────────────
if [ -n "$WARNINGS" ]; then
  json_context "$WARNINGS"
else
  echo "{}"
fi
