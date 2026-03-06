#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# hooks/lib.sh — Shared utility functions for adaptive-flow hooks
# ─────────────────────────────────────────────────────────────────────
# Source this file from any hook:
#   source "${BASH_SOURCE[0]%/*}/lib.sh"
#
# Requires: jq (for reliable JSON generation)
# Fallback: python3+yaml (for YAML parsing), grep (last resort)
# ─────────────────────────────────────────────────────────────────────

# ── json_context() ─────────────────────────────────────────────────
# Produces JSON output with additionalContext field.
# Uses jq for reliable escaping (no manual sed/tr hacks).
#
# Usage:
#   json_context "Some context string"
#   → {"additionalContext": "Some context string"}
#
#   json_context ""
#   → {}
json_context() {
  local ctx="${1:-}"
  if [ -z "$ctx" ]; then
    echo "{}"
    return 0
  fi
  if command -v jq &>/dev/null; then
    jq -n --arg ctx "$ctx" '{"additionalContext": $ctx}'
  else
    # Fallback: manual escaping (less reliable, but functional)
    local escaped
    escaped=$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
    echo "{\"additionalContext\": \"$escaped\"}"
  fi
}

# ── json_decision_block() ─────────────────────────────────────────
# Produces JSON output with decision:block and reason fields.
#
# Usage:
#   json_decision_block "reason text"
#   → {"decision": "block", "reason": "reason text"}
json_decision_block() {
  local reason="${1:-}"
  if command -v jq &>/dev/null; then
    jq -n --arg r "$reason" '{"decision": "block", "reason": $r}'
  else
    local escaped
    escaped=$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '\a' | sed 's/\a/\\n/g')
    echo "{\"decision\": \"block\", \"reason\": \"$escaped\"}"
  fi
}

# ── parse_json_field() ─────────────────────────────────────────────
# Extracts a field value from JSON on stdin using jq.
# Falls back to grep-based extraction if jq is unavailable.
#
# Usage:
#   echo '{"file_path": "/src/main.ts"}' | parse_json_field "file_path"
#   → /src/main.ts
parse_json_field() {
  local field="${1:?parse_json_field requires a field name}"
  local input
  input=$(cat)

  if command -v jq &>/dev/null; then
    printf '%s' "$input" | jq -r ".[\"$field\"] // empty" 2>/dev/null || true
  else
    # Fallback: grep-based extraction (handles simple cases)
    printf '%s' "$input" | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed "s/.*\"${field}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/" || true
  fi
}

# ── parse_yaml_insights() ──────────────────────────────────────────
# Extracts insights from user-insights.yaml filtered by influence level.
# Returns formatted list: "- [id] observation"
#
# Usage:
#   parse_yaml_insights "/path/to/user-insights.yaml" "high"
#   parse_yaml_insights "/path/to/user-insights.yaml" "high,medium"
parse_yaml_insights() {
  local file="${1:?parse_yaml_insights requires a file path}"
  local influence="${2:-high}"

  if [ ! -f "$file" ]; then
    return 0
  fi

  local result=""

  if command -v python3 &>/dev/null; then
    result=$(python3 -c "
import sys
try:
    import yaml
    with open('$file') as f:
        data = yaml.safe_load(f)
    if data and 'insights' in data:
        levels = [l.strip() for l in '$influence'.split(',')]
        for i in data['insights']:
            if i.get('influence') in levels and i.get('status') == 'active':
                print(f\"- [{i['id']}] {i['observation']}\")
except ImportError:
    pass
except Exception:
    pass
" 2>/dev/null || true)
  fi

  # Fallback: grep-based extraction (less precise but functional)
  if [ -z "$result" ]; then
    local levels
    IFS=',' read -ra levels <<< "$influence"
    for level in "${levels[@]}"; do
      level=$(echo "$level" | tr -d ' ')
      local matches
      matches=$(grep -B2 "influence: ${level}" "$file" 2>/dev/null | grep 'observation:' | sed 's/.*observation: *"\?\(.*\)"\?/- \1/' || true)
      if [ -n "$matches" ]; then
        result="${result}${matches}
"
      fi
    done
  fi

  printf '%s' "$result"
}

# ── parse_yaml_field() ─────────────────────────────────────────────
# Extracts a simple top-level or known field from a YAML file.
# For simple key: value pairs only.
#
# Usage:
#   parse_yaml_field "/path/to/meta.yaml" "gravity"
#   → 3
parse_yaml_field() {
  local file="${1:?parse_yaml_field requires a file path}"
  local field="${2:?parse_yaml_field requires a field name}"

  if [ ! -f "$file" ]; then
    return 0
  fi

  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | awk '{print $2}' || true
}
