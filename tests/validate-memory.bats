#!/usr/bin/env bats
# Tests for tests/validate-memory.sh

setup() {
  export TEST_DIR="$(mktemp -d)"
  mkdir -p "$TEST_DIR/memory"
  SCRIPT="$BATS_TEST_DIRNAME/validate-memory.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

create_valid_memory() {
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: test-insight
    observation: "Test observation"
    influence: high
    status: active
YAML
  cat > "$TEST_DIR/memory/learnings.yaml" <<'YAML'
learnings: []
YAML
  cat > "$TEST_DIR/memory/patterns.yaml" <<'YAML'
patterns: []
YAML
  cat > "$TEST_DIR/memory/discovered-insights.yaml" <<'YAML'
discovered: []
YAML
}

# ── Valid files ──────────────────────────────────────────────────

@test "passes with all valid memory files" {
  create_valid_memory

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"4 memory file(s) validated successfully"* ]]
}

@test "passes with empty lists" {
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights: []
YAML
  cat > "$TEST_DIR/memory/learnings.yaml" <<'YAML'
learnings: []
YAML
  cat > "$TEST_DIR/memory/patterns.yaml" <<'YAML'
patterns: []
YAML
  cat > "$TEST_DIR/memory/discovered-insights.yaml" <<'YAML'
discovered: []
YAML

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
}

# ── Missing top-level key ────────────────────────────────────────

@test "fails when user-insights.yaml missing insights key" {
  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
data:
  - id: foo
YAML
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing top-level 'insights' key"* ]]
}

@test "fails when learnings.yaml missing learnings key" {
  echo "insights: []" > "$TEST_DIR/memory/user-insights.yaml"
  cat > "$TEST_DIR/memory/learnings.yaml" <<'YAML'
data: []
YAML
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing top-level 'learnings' key"* ]]
}

@test "fails when patterns.yaml missing patterns key" {
  echo "insights: []" > "$TEST_DIR/memory/user-insights.yaml"
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  cat > "$TEST_DIR/memory/patterns.yaml" <<'YAML'
stuff: []
YAML
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing top-level 'patterns' key"* ]]
}

@test "fails when discovered-insights.yaml missing discovered key" {
  echo "insights: []" > "$TEST_DIR/memory/user-insights.yaml"
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  cat > "$TEST_DIR/memory/discovered-insights.yaml" <<'YAML'
items: []
YAML

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing top-level 'discovered' key"* ]]
}

# ── Missing required fields ──────────────────────────────────────

@test "fails when insight entry missing required fields" {
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: test-insight
    observation: "Missing influence and status"
YAML
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing required field"* ]]
  [[ "$output" == *"influence"* ]]
}

@test "fails when learning entry missing required fields" {
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  echo "insights: []" > "$TEST_DIR/memory/user-insights.yaml"
  cat > "$TEST_DIR/memory/learnings.yaml" <<'YAML'
learnings:
  - id: learn-1
    type: pattern
YAML
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"description"* ]]
}

@test "fails when pattern entry missing required fields" {
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  echo "insights: []" > "$TEST_DIR/memory/user-insights.yaml"
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  cat > "$TEST_DIR/memory/patterns.yaml" <<'YAML'
patterns:
  - id: pat-1
YAML
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"name"* ]]
}

@test "fails when discovered insight missing required fields" {
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  echo "insights: []" > "$TEST_DIR/memory/user-insights.yaml"
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  cat > "$TEST_DIR/memory/discovered-insights.yaml" <<'YAML'
discovered:
  - id: disc-1
    observation: "Something"
YAML

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"confidence"* ]]
}

# ── Invalid YAML syntax ─────────────────────────────────────────

@test "fails on invalid YAML syntax" {
  if ! python3 -c "import yaml" 2>/dev/null; then
    skip "python3 with pyyaml not available"
  fi

  cat > "$TEST_DIR/memory/user-insights.yaml" <<'YAML'
insights:
  - id: bad
    observation: [unclosed bracket
YAML
  echo "learnings: []" > "$TEST_DIR/memory/learnings.yaml"
  echo "patterns: []" > "$TEST_DIR/memory/patterns.yaml"
  echo "discovered: []" > "$TEST_DIR/memory/discovered-insights.yaml"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid YAML syntax"* ]]
}

# ── Missing directory ────────────────────────────────────────────

@test "fails when memory directory does not exist" {
  run bash "$SCRIPT" "$TEST_DIR/nonexistent"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Memory directory not found"* ]]
}

@test "fails when no YAML files present" {
  rm -f "$TEST_DIR/memory/"*.yaml

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No memory YAML files found"* ]]
}

# ── Real project validation ──────────────────────────────────────

@test "validates actual project memory files" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"4 memory file(s) validated successfully"* ]]
}
