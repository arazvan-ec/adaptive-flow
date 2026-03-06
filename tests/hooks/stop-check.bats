#!/usr/bin/env bats
# Tests for hooks/stop-check.sh
# Verifies compound-capture enforcement for gravity 3+ tasks

setup() {
  export TEST_DIR="$(mktemp -d)"
  export CLAUDE_PLUGIN_ROOT="$TEST_DIR"
  mkdir -p "$TEST_DIR/memory/current-task"
  mkdir -p "$TEST_DIR/hooks"
  cp "$BATS_TEST_DIRNAME/../../hooks/lib.sh" "$TEST_DIR/hooks/lib.sh"

  HOOK="$BATS_TEST_DIRNAME/../../hooks/stop-check.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset CLAUDE_PLUGIN_ROOT
}

# ── No active task ───────────────────────────────────────────────

@test "allows stop when no meta.yaml exists" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── Low gravity tasks ────────────────────────────────────────────

@test "allows stop for gravity 1 tasks" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: small-fix
gravity: 1
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

@test "allows stop for gravity 2 tasks" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: medium-task
gravity: 2
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── High gravity tasks without compound-capture ──────────────────

@test "blocks stop for gravity 3 without retrospective" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"decision": "block"'* ]]
  [[ "$output" == *"compound-capture"* ]]
  [[ "$output" == *"gravity 3"* ]]
}

@test "blocks stop for gravity 4 without retrospective" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: complex-refactor
gravity: 4
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"decision": "block"'* ]]
  [[ "$output" == *"gravity 4"* ]]
}

# ── High gravity with compound-capture done ──────────────────────

@test "allows stop for gravity 3 when retrospective exists" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML
  touch "$TEST_DIR/memory/current-task/retrospective.md"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]
}

# ── Infinite loop prevention ─────────────────────────────────────

@test "blocks first and second stop attempt" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML

  # First block
  run bash "$HOOK"
  [[ "$output" == *'"decision": "block"'* ]]

  # Second block
  run bash "$HOOK"
  [[ "$output" == *'"decision": "block"'* ]]
}

@test "allows stop after 2 blocks (infinite loop prevention)" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML
  # Simulate 2 previous blocks with session-aware counter format
  SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"
  printf '%s\n%s\n' "$SESSION_ID" "2" > "$TEST_DIR/memory/current-task/.stop-block-count"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == "{}" ]]
}

@test "cleans up counter file after allowing forced stop" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: big-feature
gravity: 3
YAML
  SESSION_ID="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"
  printf '%s\n%s\n' "$SESSION_ID" "2" > "$TEST_DIR/memory/current-task/.stop-block-count"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ ! -f "$TEST_DIR/memory/current-task/.stop-block-count" ]
}

# ── Malformed meta.yaml ──────────────────────────────────────────
# These bugs were fixed in Track A (lib.sh refactor with parse_yaml_field).
# Missing gravity now defaults to 3 (enforce), non-numeric gravity also defaults to 3.

@test "defaults to gravity 3 when gravity field missing (fixed in Track A)" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: unknown-task
status: in_progress
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Should block (defaults to gravity 3, no retrospective)
  [[ "$output" == *'"decision"'*'"block"'* ]]
}

@test "defaults to gravity 3 when gravity is non-numeric (fixed in Track A)" {
  cat > "$TEST_DIR/memory/current-task/meta.yaml" <<'YAML'
task: broken
gravity: high
YAML

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  # Should block (defaults to gravity 3, no retrospective)
  [[ "$output" == *'"decision"'*'"block"'* ]]
}
