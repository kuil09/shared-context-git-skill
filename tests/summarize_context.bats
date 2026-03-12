#!/usr/bin/env bats

load test_helper

setup() { setup_tmpdir; }
teardown() { teardown_tmpdir; }

@test "summarize_context prints section counts and no-issue hint for template files" {
  bootstrap_context

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"# Shared Context Summary"* ]]
  [[ "$output" == *"## Overview"* ]]
  [[ "$output" == *"- No obvious compaction issues detected."* ]]
}

@test "summarize_context reports duplicate bullets" {
  bootstrap_context
  cat > "$TEST_TMPDIR/CONTEXT.md" <<'EOF'
# Shared Context

## Overview

- Same bullet

## Stable Facts

- Same bullet

## Active Context

- Active item

## Decisions

- Decision item

## Open Questions

- Question item
EOF

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Duplicate bullets detected in CONTEXT.md"* ]]
  [[ "$output" == *"- Same bullet"* ]]
}

@test "summarize_context warns when TIMELINE.md has more than 20 entries" {
  bootstrap_context
  # Append 21 ### entries to TIMELINE.md
  for i in $(seq 1 21); do
    printf '\n### 2026-03-12T10:%02d:00Z | bot\n- Entry %d\n' "$i" "$i" >> "$TEST_TMPDIR/TIMELINE.md"
  done

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"more than 20 entries"* ]]
}

@test "summarize_context warns when CONTEXT.md exceeds 120 lines" {
  bootstrap_context
  {
    echo "# Shared Context"
    echo ""
    echo "## Overview"
    for i in $(seq 1 30); do echo "- Fact $i"; done
    echo ""
    echo "## Stable Facts"
    for i in $(seq 1 30); do echo "- Stable $i"; done
    echo ""
    echo "## Active Context"
    for i in $(seq 1 30); do echo "- Active $i"; done
    echo ""
    echo "## Decisions"
    for i in $(seq 1 15); do echo "- Decision $i"; done
    echo ""
    echo "## Open Questions"
    for i in $(seq 1 15); do echo "- Question $i"; done
  } > "$TEST_TMPDIR/CONTEXT.md"

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"longer than 120 lines"* ]]
}

@test "summarize_context fails when CONTEXT.md is missing" {
  cp "$TEMPLATES_DIR/TIMELINE.md" "$TEST_TMPDIR/TIMELINE.md"

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing CONTEXT.md"* ]]
}

@test "summarize_context fails when TIMELINE.md is missing" {
  cp "$TEMPLATES_DIR/CONTEXT.md" "$TEST_TMPDIR/CONTEXT.md"

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing TIMELINE.md"* ]]
}

@test "summarize_context --help prints usage" {
  run "$SCRIPTS_DIR/summarize_context.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "summarize_context rejects unknown argument" {
  run "$SCRIPTS_DIR/summarize_context.sh" --bogus-flag

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "summarize_context rejects --repo with missing value" {
  run "$SCRIPTS_DIR/summarize_context.sh" --repo

  [ "$status" -ne 0 ]
}

@test "summarize_context handles CONTEXT.md with no bullets in any section" {
  bootstrap_context
  cat > "$TEST_TMPDIR/CONTEXT.md" <<'EOF'
# Shared Context

## Overview

## Stable Facts

## Active Context

## Decisions

## Open Questions
EOF

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"# Shared Context Summary"* ]]
  # Should not report duplicate bullets (there are none)
  [[ "$output" != *"Duplicate bullets"* ]]
}

@test "summarize_context emits all three hints when all conditions are met" {
  bootstrap_context
  {
    echo "# Shared Context"
    echo ""
    echo "## Overview"
    echo "- Same bullet"
    for i in $(seq 1 30); do echo "- Fact $i"; done
    echo ""
    echo "## Stable Facts"
    echo "- Same bullet"
    for i in $(seq 1 30); do echo "- Stable $i"; done
    echo ""
    echo "## Active Context"
    for i in $(seq 1 30); do echo "- Active $i"; done
    echo ""
    echo "## Decisions"
    for i in $(seq 1 15); do echo "- Decision $i"; done
    echo ""
    echo "## Open Questions"
    for i in $(seq 1 15); do echo "- Question $i"; done
  } > "$TEST_TMPDIR/CONTEXT.md"

  for i in $(seq 1 21); do
    printf '\n### 2026-03-12T10:%02d:00Z | bot\n- Entry %d\n' "$i" "$i" >> "$TEST_TMPDIR/TIMELINE.md"
  done

  run "$SCRIPTS_DIR/summarize_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"longer than 120 lines"* ]]
  [[ "$output" == *"more than 20 entries"* ]]
  [[ "$output" == *"Duplicate bullets detected in CONTEXT.md"* ]]
}
