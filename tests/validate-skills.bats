#!/usr/bin/env bats
# Tests for tests/validate-skills.sh

setup() {
  export TEST_DIR="$(mktemp -d)"
  SCRIPT="$BATS_TEST_DIRNAME/validate-skills.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

create_valid_skill() {
  local name="$1"
  mkdir -p "$TEST_DIR/skills/$name"
  cat > "$TEST_DIR/skills/$name/SKILL.md" <<'MD'
---
context: fork
allowed-tools:
  - Read
  - Glob
---

# Skill: TestSkill

A test skill.
MD
}

# ── Valid skills ─────────────────────────────────────────────────

@test "passes with valid skill" {
  create_valid_skill "test-skill"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 skill(s) validated successfully"* ]]
}

@test "passes with multiple valid skills" {
  create_valid_skill "skill-a"
  create_valid_skill "skill-b"
  create_valid_skill "skill-c"

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"3 skill(s) validated successfully"* ]]
}

# ── Missing frontmatter ─────────────────────────────────────────

@test "fails when frontmatter missing" {
  mkdir -p "$TEST_DIR/skills/bad-skill"
  cat > "$TEST_DIR/skills/bad-skill/SKILL.md" <<'MD'
# Skill: BadSkill

No frontmatter here.
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing YAML frontmatter"* ]]
}

@test "fails when closing frontmatter delimiter missing" {
  mkdir -p "$TEST_DIR/skills/bad-skill"
  cat > "$TEST_DIR/skills/bad-skill/SKILL.md" <<'MD'
---
context: fork
allowed-tools:
  - Read

# Skill: BadSkill
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing closing frontmatter"* ]]
}

# ── Missing context: fork ────────────────────────────────────────

@test "fails when context: fork missing" {
  mkdir -p "$TEST_DIR/skills/no-fork"
  cat > "$TEST_DIR/skills/no-fork/SKILL.md" <<'MD'
---
allowed-tools:
  - Read
---

# Skill: NoFork
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing 'context: fork'"* ]]
}

# ── Missing allowed-tools ────────────────────────────────────────

@test "fails when allowed-tools missing" {
  mkdir -p "$TEST_DIR/skills/no-tools"
  cat > "$TEST_DIR/skills/no-tools/SKILL.md" <<'MD'
---
context: fork
---

# Skill: NoTools
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing 'allowed-tools'"* ]]
}

@test "fails when allowed-tools list is empty" {
  mkdir -p "$TEST_DIR/skills/empty-tools"
  cat > "$TEST_DIR/skills/empty-tools/SKILL.md" <<'MD'
---
context: fork
allowed-tools:
---

# Skill: EmptyTools
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"list is empty"* ]]
}

# ── Missing title ────────────────────────────────────────────────

@test "fails when skill title missing" {
  mkdir -p "$TEST_DIR/skills/no-title"
  cat > "$TEST_DIR/skills/no-title/SKILL.md" <<'MD'
---
context: fork
allowed-tools:
  - Read
---

Just some text without a title.
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing skill title"* ]]
}

# ── Missing skills directory ─────────────────────────────────────

@test "fails when skills directory does not exist" {
  run bash "$SCRIPT" "$TEST_DIR/nonexistent"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Skills directory not found"* ]]
}

# ── Error count ──────────────────────────────────────────────────

@test "reports correct error count with multiple issues" {
  mkdir -p "$TEST_DIR/skills/bad-a"
  cat > "$TEST_DIR/skills/bad-a/SKILL.md" <<'MD'
---
allowed-tools:
  - Read
---

# Skill: BadA
MD

  mkdir -p "$TEST_DIR/skills/bad-b"
  cat > "$TEST_DIR/skills/bad-b/SKILL.md" <<'MD'
---
context: fork
---

# Skill: BadB
MD

  run bash "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FAILED"* ]]
  [[ "$output" == *"2 skill(s)"* ]]
}

# ── Real skills validation ───────────────────────────────────────

@test "validates actual project skills successfully" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"10 skill(s) validated successfully"* ]]
}
