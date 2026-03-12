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

@test "validate_context --strict accepts valid ISO 8601 timestamp" {
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

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR" --strict

  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}

@test "validate_context --strict rejects invalid timestamp format" {
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

### bad-timestamp | bot
- Timestamp: not-a-date
- Actor: bot
- Trigger: Test invalid timestamp
- Applied Changes:
  - Added a test case
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR" --strict

  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid ISO 8601 timestamp"* ]]
}

@test "validate_context --strict rejects empty Actor field" {
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

### 2026-03-12T10:00:00Z |
- Timestamp: 2026-03-12T10:00:00Z
- Actor:
- Trigger: Test empty actor
- Applied Changes:
  - Added a test case
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR" --strict

  [ "$status" -ne 0 ]
  [[ "$output" == *"empty Actor field"* ]]
}

@test "validate_context --strict rejects empty Trigger field" {
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
- Trigger:
- Applied Changes:
  - Added a test case
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR" --strict

  [ "$status" -ne 0 ]
  [[ "$output" == *"empty Trigger field"* ]]
}

@test "validate_context rejects unknown argument" {
  run "$SCRIPTS_DIR/validate_context.sh" --unknown-flag

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "validate_context fails when CONTEXT.md is missing" {
  setup_tmpdir
  cp "$TEMPLATES_DIR/TIMELINE.md" "$TEST_TMPDIR/TIMELINE.md"

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing CONTEXT.md"* ]]
}

@test "validate_context fails when TIMELINE.md is missing" {
  setup_tmpdir
  cp "$TEMPLATES_DIR/CONTEXT.md" "$TEST_TMPDIR/CONTEXT.md"

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing TIMELINE.md"* ]]
}

@test "validate_context fails when TIMELINE.md is missing '# Timeline' heading" {
  bootstrap_context
  # Remove the top-level heading
  sed 's/^# Timeline$//' "$TEST_TMPDIR/TIMELINE.md" > "$TEST_TMPDIR/TIMELINE.md.tmp"
  mv "$TEST_TMPDIR/TIMELINE.md.tmp" "$TEST_TMPDIR/TIMELINE.md"

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"missing '# Timeline'"* ]]
}

@test "validate_context fails when TIMELINE.md is missing '## Entries' section" {
  bootstrap_context
  sed 's/^## Entries$//' "$TEST_TMPDIR/TIMELINE.md" > "$TEST_TMPDIR/TIMELINE.md.tmp"
  mv "$TEST_TMPDIR/TIMELINE.md.tmp" "$TEST_TMPDIR/TIMELINE.md"

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"missing '## Entries'"* ]]
}

@test "validate_context rejects --repo with missing value" {
  run "$SCRIPTS_DIR/validate_context.sh" --repo

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --repo"* ]]
}

@test "validate_context rejects missing Stable Facts heading" {
  bootstrap_context
  python3 - <<'PY' "$TEST_TMPDIR/CONTEXT.md"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("## Stable Facts\n\n", "", 1))
PY

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"CONTEXT.md is missing required heading matching: ^## Stable Facts$"* ]]
}

@test "validate_context fails when TIMELINE.md is missing Entry Template section" {
  bootstrap_context
  sed 's/^## Entry Template$//' "$TEST_TMPDIR/TIMELINE.md" > "$TEST_TMPDIR/TIMELINE.md.tmp"
  mv "$TEST_TMPDIR/TIMELINE.md.tmp" "$TEST_TMPDIR/TIMELINE.md"

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"missing '## Entry Template'"* ]]
}

@test "validate_context without --strict passes invalid timestamp (backward compat)" {
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

### bad-timestamp | bot
- Timestamp: not-a-date
- Actor: bot
- Trigger: Test backward compat
- Applied Changes:
  - Added a test case
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}
