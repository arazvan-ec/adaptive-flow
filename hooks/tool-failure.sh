#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# Hook: tool-failure — Logs and suggests recovery on tool failures
# ─────────────────────────────────────────────────────────────────────
# Triggered on PostToolUseFailure.
# Logs failure context and suggests recovery actions based on the
# tool type and error pattern.
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-.}"
# shellcheck source=lib.sh
source "$PLUGIN_ROOT/hooks/lib.sh"

# Read stdin (tool failure JSON)
INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | parse_json_field "tool_name")
TOOL_ERROR=$(printf '%s' "$INPUT" | parse_json_field "error")

SUGGESTIONS=""

# ── Suggest recovery based on tool type ────────────────────────────
case "${TOOL_NAME:-}" in
  Bash)
    SUGGESTIONS="Tool failure in Bash: ${TOOL_ERROR:-unknown error}. Check: command exists, correct working directory, permissions."
    ;;
  Write|Edit)
    SUGGESTIONS="Tool failure in ${TOOL_NAME}: ${TOOL_ERROR:-unknown error}. Check: file path exists, correct permissions, file not locked."
    ;;
  *)
    SUGGESTIONS="Tool ${TOOL_NAME:-unknown} failed: ${TOOL_ERROR:-unknown error}. Review the error and consider an alternative approach."
    ;;
esac

if [ -n "$SUGGESTIONS" ]; then
  json_context "$SUGGESTIONS"
else
  echo "{}"
fi
