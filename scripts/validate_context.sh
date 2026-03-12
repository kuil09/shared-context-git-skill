#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: validate_context.sh [--repo DIR]

Validate required shared-context files and basic document structure.
EOF
}

repo_dir="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { echo "Missing value for --repo" >&2; exit 1; }
      repo_dir="$2"
      shift 2
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

  [[ "$line" =~ ^-\ Timestamp:\  ]] && has_timestamp=1
  [[ "$line" =~ ^-\ Actor:\  ]] && has_actor=1
  [[ "$line" =~ ^-\ Trigger:\  ]] && has_trigger=1
  [[ "$line" =~ ^-\ Applied\ Changes: ]] && has_applied=1
  [[ "$line" =~ ^-\ Unresolved\ Items: ]] && has_unresolved=1
done < TIMELINE.md

finish_entry

echo "Shared context structure is valid"
if [[ "$entry_count" -eq 0 ]]; then
  echo "No timeline entries yet; template-only state is allowed"
fi
