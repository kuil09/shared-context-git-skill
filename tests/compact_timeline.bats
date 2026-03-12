#!/usr/bin/env bats

load test_helper

setup() { setup_tmpdir; }
teardown() { teardown_tmpdir; }

# Helper: create a TIMELINE.md with entries at specific dates
create_timeline_with_entries() {
  local old_date="$1"
  local recent_date="$2"
  cat > "$TEST_TMPDIR/TIMELINE.md" <<EOF
# Timeline

Use this file as an append-only record of meaningful context changes.

## Entry Template

\`\`\`markdown
### 2026-03-12T09:15:00Z | agent-name
- Timestamp: 2026-03-12T09:15:00Z
- Actor: agent-name
- Trigger: What prompted this update
- Applied Changes:
  - Summarize the facts, decisions, or context that changed
- Unresolved Items:
  - List remaining uncertainty, or write \`- None\`
\`\`\`

## Entries

### ${old_date}T10:00:00Z | old-bot
- Timestamp: ${old_date}T10:00:00Z
- Actor: old-bot
- Trigger: Old work
- Applied Changes:
  - Established baseline architecture
  - Chose PostgreSQL as database
- Unresolved Items:
  - None

### ${recent_date}T10:00:00Z | new-bot
- Timestamp: ${recent_date}T10:00:00Z
- Actor: new-bot
- Trigger: Recent work
- Applied Changes:
  - Added caching layer
- Unresolved Items:
  - Cache invalidation strategy TBD
EOF
}

@test "compact_timeline --help prints usage" {
  run "$SCRIPTS_DIR/compact_timeline.sh" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "compact_timeline reports nothing to compact when all entries are recent" {
  bootstrap_context
  local today
  today="$(date +%Y-%m-%d)"
  create_timeline_with_entries "$today" "$today"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30

  [ "$status" -eq 0 ]
  [[ "$output" == *"No entries older than 30 days to compact"* ]]
}

@test "compact_timeline dry-run shows entries that would be compacted" {
  bootstrap_context
  local old_date recent_date
  old_date="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
  recent_date="$(date +%Y-%m-%d)"
  create_timeline_with_entries "$old_date" "$recent_date"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30 --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"1 entry/entries older than 30 days"* ]]
  [[ "$output" == *"Established baseline architecture"* ]]
  [[ "$output" == *"Chose PostgreSQL as database"* ]]
  [[ "$output" == *"dry-run"* ]]
}

@test "compact_timeline with --yes compacts old entries and updates files" {
  bootstrap_context
  local old_date recent_date
  old_date="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
  recent_date="$(date +%Y-%m-%d)"
  create_timeline_with_entries "$old_date" "$recent_date"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30 --yes

  [ "$status" -eq 0 ]
  [[ "$output" == *"Compacted 1 entry/entries"* ]]
  [[ "$output" == *"2 fact(s) added to Stable Facts"* ]]

  # Verify CONTEXT.md has new facts
  run grep "Established baseline architecture" "$TEST_TMPDIR/CONTEXT.md"
  [ "$status" -eq 0 ]

  run grep "Chose PostgreSQL as database" "$TEST_TMPDIR/CONTEXT.md"
  [ "$status" -eq 0 ]

  # Verify old entry removed from TIMELINE.md
  run grep "old-bot" "$TEST_TMPDIR/TIMELINE.md"
  [ "$status" -ne 0 ]

  # Verify recent entry still in TIMELINE.md
  run grep "new-bot" "$TEST_TMPDIR/TIMELINE.md"
  [ "$status" -eq 0 ]
}

@test "compact_timeline fails when TIMELINE.md is missing" {
  bootstrap_context
  rm "$TEST_TMPDIR/TIMELINE.md"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing TIMELINE.md"* ]]
}

@test "compact_timeline fails when CONTEXT.md is missing" {
  bootstrap_context
  rm "$TEST_TMPDIR/CONTEXT.md"
  cat > "$TEST_TMPDIR/TIMELINE.md" <<'EOF'
# Timeline

## Entry Template

## Entries
EOF

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing CONTEXT.md"* ]]
}

@test "compact_timeline rejects invalid --days value" {
  run "$SCRIPTS_DIR/compact_timeline.sh" --days abc

  [ "$status" -ne 0 ]
  [[ "$output" == *"non-negative integer"* ]]
}

@test "compact_timeline preserves TIMELINE.md structure after compaction" {
  bootstrap_context
  local old_date recent_date
  old_date="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
  recent_date="$(date +%Y-%m-%d)"
  create_timeline_with_entries "$old_date" "$recent_date"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30 --yes
  [ "$status" -eq 0 ]

  # Validate the resulting TIMELINE.md still passes validation
  run "$SCRIPTS_DIR/validate_context.sh" --repo "$TEST_TMPDIR"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Shared context structure is valid"* ]]
}

@test "compact_timeline rejects unknown argument" {
  run "$SCRIPTS_DIR/compact_timeline.sh" --bogus-flag

  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown argument"* ]]
}

@test "compact_timeline rejects --days with missing value" {
  run "$SCRIPTS_DIR/compact_timeline.sh" --days

  [ "$status" -ne 0 ]
}

@test "compact_timeline with --days 0 compacts all entries" {
  bootstrap_context
  local today
  today="$(date +%Y-%m-%d)"
  create_timeline_with_entries "$today" "$today"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 0 --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"2 entry/entries older than 0 days"* ]]
}

@test "compact_timeline entry with no Applied Changes bullets compacts cleanly" {
  bootstrap_context
  local old_date
  old_date="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
  cat > "$TEST_TMPDIR/TIMELINE.md" <<EOF
# Timeline

Use this file as an append-only record of meaningful context changes.

## Entry Template

\`\`\`markdown
### 2026-03-12T09:15:00Z | agent-name
- Timestamp: 2026-03-12T09:15:00Z
- Actor: agent-name
- Trigger: What prompted this update
- Applied Changes:
  - Summarize the facts, decisions, or context that changed
- Unresolved Items:
  - List remaining uncertainty, or write \`- None\`
\`\`\`

## Entries

### ${old_date}T10:00:00Z | empty-bot
- Timestamp: ${old_date}T10:00:00Z
- Actor: empty-bot
- Trigger: Nothing notable
- Applied Changes:
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30 --yes

  [ "$status" -eq 0 ]
  [[ "$output" == *"Compacted 1 entry/entries"* ]]
  [[ "$output" == *"0 fact(s) added to Stable Facts"* ]]
}

@test "compact_timeline with all old entries removes all from TIMELINE.md" {
  bootstrap_context
  local old_date
  old_date="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
  create_timeline_with_entries "$old_date" "$old_date"

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30 --yes

  [ "$status" -eq 0 ]
  [[ "$output" == *"Compacted 2 entry/entries"* ]]
  # Neither old entry should remain
  run grep "old-bot" "$TEST_TMPDIR/TIMELINE.md"
  [ "$status" -ne 0 ]
  run grep "new-bot" "$TEST_TMPDIR/TIMELINE.md"
  [ "$status" -ne 0 ]
}

@test "compact_timeline rejects --repo with missing value" {
  run "$SCRIPTS_DIR/compact_timeline.sh" --repo

  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing value for --repo"* ]]
}

@test "compact_timeline aborts when user answers no to interactive prompt" {
  bootstrap_context
  local old_date recent_date
  old_date="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
  recent_date="$(date +%Y-%m-%d)"
  create_timeline_with_entries "$old_date" "$recent_date"

  run bash -c "printf 'n\n' | \"$SCRIPTS_DIR/compact_timeline.sh\" --repo \"$TEST_TMPDIR\" --days 30"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted."* ]]
  # Old entry should still be in TIMELINE.md
  run grep "old-bot" "$TEST_TMPDIR/TIMELINE.md"
  [ "$status" -eq 0 ]
}

@test "compact_timeline treats entry with unparseable timestamp as recent" {
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

### not-a-date | some-bot
- Timestamp: not-a-date
- Actor: some-bot
- Trigger: Unparseable timestamp test
- Applied Changes:
  - Some important fact
- Unresolved Items:
  - None
EOF

  run "$SCRIPTS_DIR/compact_timeline.sh" --repo "$TEST_TMPDIR" --days 30 --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"No entries older than 30 days to compact"* ]]
}
