#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: validate_context.sh [--repo DIR] [--strict]

Validate required shared-context files and basic document structure.

Options:
  --repo DIR   Path to the repository directory (default: .)
  --strict     Enable strict validation (ISO 8601 timestamps, non-empty fields)
EOF
}

repo_dir="."
strict=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { echo "Missing value for --repo" >&2; exit 1; }
      repo_dir="$2"
      shift 2
      ;;
    --strict)
      strict=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$repo_dir"

[[ -f "CONTEXT.md" ]] || { echo "Missing CONTEXT.md" >&2; exit 1; }
[[ -f "TIMELINE.md" ]] || { echo "Missing TIMELINE.md" >&2; exit 1; }

required_context_headings=(
  "^## Overview$"
  "^## Stable Facts$"
  "^## Active Context$"
  "^## Decisions$"
  "^## Open Questions$"
)

for heading in "${required_context_headings[@]}"; do
  if ! grep -Eq "$heading" CONTEXT.md; then
    echo "CONTEXT.md is missing required heading matching: ${heading}" >&2
    exit 1
  fi
done

if ! grep -Eq '^# Timeline$' TIMELINE.md; then
  echo "TIMELINE.md is missing '# Timeline'" >&2
  exit 1
fi

if ! grep -Eq '^## Entry Template$' TIMELINE.md; then
  echo "TIMELINE.md is missing '## Entry Template'" >&2
  exit 1
fi

if ! grep -Eq '^## Entries$' TIMELINE.md; then
  echo "TIMELINE.md is missing '## Entries'" >&2
  exit 1
fi

entry_count=0
in_entry=0
has_timestamp=0
has_actor=0
has_trigger=0
has_applied=0
has_unresolved=0

finish_entry() {
  if [[ "$in_entry" -eq 1 ]]; then
    if [[ "$has_timestamp" -ne 1 || "$has_actor" -ne 1 || "$has_trigger" -ne 1 || "$has_applied" -ne 1 || "$has_unresolved" -ne 1 ]]; then
      echo "TIMELINE.md has an entry missing one of: Timestamp, Actor, Trigger, Applied Changes, Unresolved Items" >&2
      exit 1
    fi
  fi
}

while IFS= read -r line; do
  if [[ "$line" =~ ^###\  ]]; then
    finish_entry
    in_entry=1
    entry_count=$((entry_count + 1))
    has_timestamp=0
    has_actor=0
    has_trigger=0
    has_applied=0
    has_unresolved=0
    continue
  fi

  [[ "$in_entry" -eq 1 ]] || continue

  if [[ "$line" =~ ^-\ Timestamp: ]]; then
    has_timestamp=1
    if [[ "$strict" -eq 1 ]]; then
      local_val="${line#- Timestamp:}"
      local_val="${local_val#"${local_val%%[![:space:]]*}"}"
      if [[ -z "$local_val" || ! "$local_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        echo "TIMELINE.md has an entry with invalid ISO 8601 timestamp: '${local_val}'" >&2
        exit 1
      fi
    fi
  fi
  if [[ "$line" =~ ^-\ Actor: ]]; then
    has_actor=1
    if [[ "$strict" -eq 1 ]]; then
      local_val="${line#- Actor:}"
      local_val="${local_val#"${local_val%%[![:space:]]*}"}"
      if [[ -z "$local_val" ]]; then
        echo "TIMELINE.md has an entry with empty Actor field" >&2
        exit 1
      fi
    fi
  fi
  if [[ "$line" =~ ^-\ Trigger: ]]; then
    has_trigger=1
    if [[ "$strict" -eq 1 ]]; then
      local_val="${line#- Trigger:}"
      local_val="${local_val#"${local_val%%[![:space:]]*}"}"
      if [[ -z "$local_val" ]]; then
        echo "TIMELINE.md has an entry with empty Trigger field" >&2
        exit 1
      fi
    fi
  fi
  [[ "$line" =~ ^-\ Applied\ Changes: ]] && has_applied=1
  [[ "$line" =~ ^-\ Unresolved\ Items: ]] && has_unresolved=1
done < TIMELINE.md

finish_entry

echo "Shared context structure is valid"
if [[ "$entry_count" -eq 0 ]]; then
  echo "No timeline entries yet; template-only state is allowed"
fi
