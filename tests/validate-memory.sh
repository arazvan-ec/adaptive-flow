#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# validate-memory.sh — Validates memory YAML files
# ─────────────────────────────────────────────────────────────────────
# Checks each memory YAML for:
#   1. Valid YAML syntax (via python3 yaml.safe_load)
#   2. Required top-level key present
#   3. Required fields per entry (when entries exist)
#
# Usage: ./tests/validate-memory.sh [plugin_root]
# Exit 0 = all valid, Exit 1 = errors found
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

PLUGIN_ROOT="${1:-${CLAUDE_PLUGIN_ROOT:-.}}"
MEMORY_DIR="$PLUGIN_ROOT/memory"
ERRORS=0
CHECKED=0

if [ ! -d "$MEMORY_DIR" ]; then
  echo "ERROR: Memory directory not found: $MEMORY_DIR"
  exit 1
fi

# ── Helper: validate YAML syntax ────────────────────────────────
validate_yaml() {
  local file="$1"
  if command -v python3 &>/dev/null; then
    python3 -c "
import yaml, sys
try:
    with open('$file') as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f'YAML syntax error: {e}')
    sys.exit(1)
except Exception as e:
    print(f'Error reading file: {e}')
    sys.exit(1)
" 2>&1
    return $?
  else
    # Fallback: basic check that file is not empty garbage
    if ! head -1 "$file" | grep -qE '^(#|[a-z]|$)'; then
      echo "Cannot validate YAML (python3 not available)"
      return 1
    fi
    return 0
  fi
}

# ── Helper: check required fields in entries ─────────────────────
check_fields() {
  local file="$1"
  local top_key="$2"
  shift 2
  local required_fields=("$@")

  if ! command -v python3 &>/dev/null; then
    return 0
  fi

  local fields_json
  fields_json=$(printf '"%s",' "${required_fields[@]}")
  fields_json="[${fields_json%,}]"

  python3 -c "
import yaml, sys, json

required = json.loads('$fields_json')
with open('$file') as f:
    data = yaml.safe_load(f)

if not data or '$top_key' not in data:
    sys.exit(0)

entries = data['$top_key']
if not entries or not isinstance(entries, list):
    sys.exit(0)

errors = 0
for i, entry in enumerate(entries):
    if not isinstance(entry, dict):
        print(f'  Entry {i}: not a dict')
        errors += 1
        continue
    for field in required:
        if field not in entry:
            eid = entry.get('id', f'index-{i}')
            print(f'  Entry [{eid}]: missing required field \"{field}\"')
            errors += 1

sys.exit(1 if errors > 0 else 0)
" 2>&1
  return $?
}

# ── Validate: user-insights.yaml ─────────────────────────────────
FILE="$MEMORY_DIR/user-insights.yaml"
if [ -f "$FILE" ]; then
  CHECKED=$((CHECKED + 1))
  if ! validate_yaml "$FILE"; then
    echo "ERROR [user-insights.yaml]: Invalid YAML syntax"
    ERRORS=$((ERRORS + 1))
  elif ! grep -q '^insights:' "$FILE"; then
    echo "ERROR [user-insights.yaml]: Missing top-level 'insights' key"
    ERRORS=$((ERRORS + 1))
  else
    FIELD_ERRORS=$(check_fields "$FILE" "insights" "id" "observation" "influence" "status" || true)
    if [ -n "$FIELD_ERRORS" ]; then
      echo "ERROR [user-insights.yaml]: Missing required fields"
      echo "$FIELD_ERRORS"
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# ── Validate: learnings.yaml ────────────────────────────────────
FILE="$MEMORY_DIR/learnings.yaml"
if [ -f "$FILE" ]; then
  CHECKED=$((CHECKED + 1))
  if ! validate_yaml "$FILE"; then
    echo "ERROR [learnings.yaml]: Invalid YAML syntax"
    ERRORS=$((ERRORS + 1))
  elif ! grep -q '^learnings:' "$FILE"; then
    echo "ERROR [learnings.yaml]: Missing top-level 'learnings' key"
    ERRORS=$((ERRORS + 1))
  else
    FIELD_ERRORS=$(check_fields "$FILE" "learnings" "id" "type" "description" || true)
    if [ -n "$FIELD_ERRORS" ]; then
      echo "ERROR [learnings.yaml]: Missing required fields"
      echo "$FIELD_ERRORS"
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# ── Validate: patterns.yaml ────────────────────────────────────
FILE="$MEMORY_DIR/patterns.yaml"
if [ -f "$FILE" ]; then
  CHECKED=$((CHECKED + 1))
  if ! validate_yaml "$FILE"; then
    echo "ERROR [patterns.yaml]: Invalid YAML syntax"
    ERRORS=$((ERRORS + 1))
  elif ! grep -q '^patterns:' "$FILE"; then
    echo "ERROR [patterns.yaml]: Missing top-level 'patterns' key"
    ERRORS=$((ERRORS + 1))
  else
    FIELD_ERRORS=$(check_fields "$FILE" "patterns" "id" "name" "description" || true)
    if [ -n "$FIELD_ERRORS" ]; then
      echo "ERROR [patterns.yaml]: Missing required fields"
      echo "$FIELD_ERRORS"
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# ── Validate: discovered-insights.yaml ──────────────────────────
FILE="$MEMORY_DIR/discovered-insights.yaml"
if [ -f "$FILE" ]; then
  CHECKED=$((CHECKED + 1))
  if ! validate_yaml "$FILE"; then
    echo "ERROR [discovered-insights.yaml]: Invalid YAML syntax"
    ERRORS=$((ERRORS + 1))
  elif ! grep -q '^discovered:' "$FILE"; then
    echo "ERROR [discovered-insights.yaml]: Missing top-level 'discovered' key"
    ERRORS=$((ERRORS + 1))
  else
    FIELD_ERRORS=$(check_fields "$FILE" "discovered" "id" "observation" "confidence" "status" || true)
    if [ -n "$FIELD_ERRORS" ]; then
      echo "ERROR [discovered-insights.yaml]: Missing required fields"
      echo "$FIELD_ERRORS"
      ERRORS=$((ERRORS + 1))
    fi
  fi
fi

# ── Summary ─────────────────────────────────────────────────────
if [ "$CHECKED" -eq 0 ]; then
  echo "WARNING: No memory YAML files found in $MEMORY_DIR"
  exit 1
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "FAILED: $ERRORS error(s) in $CHECKED file(s)"
  exit 1
else
  echo "OK: $CHECKED memory file(s) validated successfully"
  exit 0
fi
