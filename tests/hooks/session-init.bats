#!/usr/bin/env bats
# Tests for hooks/session-init.sh
# Verifies Tier 1 memory loading and JSON output

setup() {
  # Create temporary plugin root
  export TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_DIR"
  mkdir -p "$TEST_DIR/memory/current-task"

  # Path to the hook under test
  HOOK="$BATS_TEST_DIRNAME/../../hooks/session-init.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_PLUGIN_ROOT CLAUDE_PERMISSION_MODE
}

# ── Empty state ──────────────────────────────────────────────────

@test "outputs empty JSON when no memory files exist" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── High-influence insights ──────────────────────────────────────

@test "loads high-influence active insights" {
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: INS-001
    observation: "Prefer small PRs"
    influence: high
    status: active
  - id: INS-002
    observation: "Use TypeScript strict"
    influence: medium
    status: active
  - id: INS-003
    observation: "Always write tests"
    influence: high
    status: active
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Should contain high-influence insights
  [[ "$output" == *"INS-001"* ]]
  [[ "$output" == *"Prefer small PRs"* ]]
  [[ "$output" == *"INS-003"* ]]
  [[ "$output" == *"Always write tests"* ]]
  # Should NOT contain medium-influence
  [[ "$output" != *"INS-002"* ]]
  # Should be valid JSON with additionalContext
  [[ "$output" == *'"additionalContext"'* ]]
}

@test "grep fallback does not filter by status (known limitation, fix in Track A)" {
  # BUG: When python3 correctly returns empty for deprecated insights,
  # the grep fallback runs and matches influence:high without checking status.
  # Track A (lib.sh refactor) will fix this by centralizing YAML parsing.
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: INS-001
    observation: "Old insight"
    influence: high
    status: deprecated
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Currently the grep fallback leaks deprecated insights — this documents the bug
  [[ "$output" == *"Old insight"* ]]
}

# ── Architecture profile ─────────────────────────────────────────

@test "loads architecture profile" {
  cat > "$TEST_DIR/memory/architecture-profile.yaml" <<'YAML'
language: typescript
framework: nextjs
architecture: monorepo
test_runner: jest
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"language: typescript"* ]]
  [[ "$output" == *"framework: nextjs"* ]]
  [[ "$output" == *"architecture: monorepo"* ]]
  [[ "$output" == *"test_runner: jest"* ]]
  [[ "$output" == *'"additionalContext"'* ]]
}

# ── Plan mode detection ──────────────────────────────────────────

@test "detects plan mode from CLAUDE_PERMISSION_MODE" {
  export CLAUDE_PERMISSION_MODE="plan"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"plan_mode: true"* ]]
  [[ "$output" == *"planner skill redundant"* ]]
}

@test "does not inject plan mode when not set" {
  unset CLAUDE_PERMISSION_MODE

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"plan_mode"* ]]
}

# ── Current task meta ────────────────────────────────────────────

@test "loads current task meta.yaml" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: implement-auth
gravity: 3
status: in_progress
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"task: implement-auth"* ]]
  [[ "$output" == *"gravity: 3"* ]]
  [[ "$output" == *'"additionalContext"'* ]]
}

# ── Combined output ──────────────────────────────────────────────

@test "combines all context parts into single JSON" {
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: INS-001
    observation: "Test first"
    influence: high
    status: active
YAML
  cat > "$TEST_DIR/memory/architecture-profile.yaml" <<'YAML'
language: python
framework: django
YAML
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: add-api
gravity: 2
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # All sections present
  [[ "$output" == *"Test first"* ]]
  [[ "$output" == *"language: python"* ]]
  [[ "$output" == *"task: add-api"* ]]
  # Valid JSON structure
  [[ "$output" == *'"additionalContext"'* ]]
  [[ "$output" == "{"* ]]
  [[ "$output" == *"}" ]]
}

# ── JSON output validity ─────────────────────────────────────────

@test "output is parseable JSON" {
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: INS-001
    observation: 'Quotes "inside" observation'
    influence: high
    status: active
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Should be parseable by jq if available, or at least start/end with braces
  [[ "$output" == "{"* ]]
  [[ "$output" == *"}" ]]
  if command -v jq &>/dev/null; then
    echo "$output" | jq . >/dev/null 2>&1
  fi
}
