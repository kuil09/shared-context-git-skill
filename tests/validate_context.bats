#!/usr/bin/env bats

load test_helper

setup() { setup_tmpdir; }
teardown() { teardown_tmpdir; }

@test "validate_context accepts bootstrapped template state" {
  bootstrap_context

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}

@test "validate_context rejects missing required context heading" {
  bootstrap_context
  python3 - <<'PY' "$TEST_TMPDIR/CONTEXT.md"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("## Decisions\n\n", "", 1))
PY

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"CONTEXT.md is missing required heading matching: ^## Decisions$"* ]]
}

@test "validate_context rejects timeline entry missing required fields" {
  bootstrap_context
  cat > "$TEST_TMPDIR/TIMELINE.md" <<'EOF'
# Timeline

Use this file as an append-only record of meaningful context changes.

## Entry Template

```markdown
### 2026-03-12T09:15:00Z | agent-name
- Timestamp: 2026-03-12T09:15:00Z
- Actor: agent-name
- Trigger: What prompted this update
- Applied Changes:
  - Summarize the facts, decisions, or context that changed
- Unresolved Items:
  - List remaining uncertainty, or write `- None`
```

## Entries

### 2026-03-12T10:00:00Z | bot
- Timestamp: 2026-03-12T10:00:00Z
- Actor: bot
- Trigger: Test broken entry
- Applied Changes:
  - Added an invalid test case
EOF

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"TIMELINE.md has an entry missing one of"* ]]
}

@test "validate_context accepts a complete timeline entry" {
  bootstrap_context
  cat > "$TEST_TMPDIR/TIMELINE.md" <<'EOF'
# Timeline

Use this file as an append-only record of meaningful context changes.

## Entry Template

```markdown
### 2026-03-12T09:15:00Z | agent-name
- Timestamp: 2026-03-12T09:15:00Z
- Actor: agent-name
- Trigger: What prompted this update
- Applied Changes:
  - Summarize the facts, decisions, or context that changed
- Unresolved Items:
  - List remaining uncertainty, or write `- None`
```

## Entries

### 2026-03-12T10:00:00Z | bot
- Timestamp: 2026-03-12T10:00:00Z
- Actor: bot
- Trigger: Test valid entry
- Applied Changes:
  - Added a valid test case
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}

@test "validate_context --help prints usage" {
  run "$SCRIPTS_DIR/validate_context.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}
