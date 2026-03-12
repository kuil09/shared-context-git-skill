#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: compact_timeline.sh [--repo DIR] [--days N] [--dry-run] [--yes]

Compact old TIMELINE.md entries by moving their Applied Changes into
CONTEXT.md Stable Facts and removing the original entries.

Options:
  --repo DIR   Repository path (default: .)
  --days N     Compact entries older than N days (default: 30)
  --dry-run    Show what would change without modifying files
  --yes        Skip confirmation prompt
  -h, --help   Show this help message
EOF
}

repo_dir="."
max_days=30
dry_run=false
auto_yes=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { echo "Missing value for --repo" >&2; exit 1; }
      repo_dir="$2"
      shift 2
      ;;
    --days)
      [[ $# -ge 2 ]] || { echo "Missing value for --days" >&2; exit 1; }
      max_days="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --yes)
      auto_yes=true
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

if ! [[ "$max_days" =~ ^[0-9]+$ ]]; then
  echo "--days must be a non-negative integer" >&2
  exit 1
fi

cd "$repo_dir"

[[ -f "TIMELINE.md" ]] || { echo "Missing TIMELINE.md" >&2; exit 1; }
[[ -f "CONTEXT.md" ]] || { echo "Missing CONTEXT.md" >&2; exit 1; }

cutoff_epoch=$(( $(date +%s) - max_days * 86400 ))

# Parse TIMELINE.md entries and classify as old or recent
old_facts=()
old_entry_headings=()
entries_section_started=0
in_entry=0
current_heading=""
current_timestamp=""
in_applied=0
entry_is_old=0

classify_timestamp() {
  local ts="$1"
  # Extract date part: YYYY-MM-DDTHH:MM:SS...
  local date_part="${ts%%T*}"
  if [[ ! "$date_part" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    # Cannot parse — treat as recent (keep it)
    return 1
  fi
  local entry_epoch
  if date --version >/dev/null 2>&1; then
    # GNU date
    entry_epoch=$(date -d "$date_part" +%s 2>/dev/null) || return 1
  else
    # BSD/macOS date
    entry_epoch=$(date -j -f "%Y-%m-%d" "$date_part" +%s 2>/dev/null) || return 1
  fi
  (( entry_epoch < cutoff_epoch ))
}

flush_entry() {
  if [[ "$in_entry" -eq 1 && "$entry_is_old" -eq 1 ]]; then
    old_entry_headings+=("$current_heading")
  fi
  in_entry=0
  in_applied=0
  entry_is_old=0
  current_heading=""
  current_timestamp=""
}

while IFS= read -r line; do
  # Detect ## Entries section
  if [[ "$line" == "## Entries" ]]; then
    entries_section_started=1
    continue
  fi

  [[ "$entries_section_started" -eq 1 ]] || continue

  # Entry heading: ### <timestamp> | <actor>
  if [[ "$line" =~ ^###\  ]]; then
    flush_entry
    in_entry=1
    current_heading="$line"
    # Extract timestamp from heading
    local_ts="${line#\#\#\# }"
    local_ts="${local_ts%% |*}"
    local_ts="${local_ts%% *}"
    current_timestamp="$local_ts"
    if classify_timestamp "$current_timestamp"; then
      entry_is_old=1
    fi
    continue
  fi

  [[ "$in_entry" -eq 1 ]] || continue

  # Track Applied Changes section
  if [[ "$line" =~ ^-\ Applied\ Changes: ]]; then
    in_applied=1
    continue
  fi

  # End of Applied Changes when we hit another top-level field
  if [[ "$line" =~ ^-\  && ! "$line" =~ ^\ \  ]]; then
    in_applied=0
  fi

  # Collect applied change bullets from old entries
  if [[ "$in_applied" -eq 1 && "$entry_is_old" -eq 1 && "$line" =~ ^\ \ -\  ]]; then
    local_fact="${line#  - }"
    if [[ -n "$local_fact" ]]; then
      old_facts+=("$local_fact")
    fi
  fi
done < TIMELINE.md

flush_entry

if [[ ${#old_entry_headings[@]} -eq 0 ]]; then
  echo "No entries older than ${max_days} days to compact."
  exit 0
fi

echo "Found ${#old_entry_headings[@]} entry/entries older than ${max_days} days."

if [[ ${#old_facts[@]} -gt 0 ]]; then
  echo "Facts to add to Stable Facts:"
  for fact in "${old_facts[@]}"; do
    echo "  - $fact"
  done
fi

echo ""
echo "Entries to remove:"
for heading in "${old_entry_headings[@]}"; do
  echo "  $heading"
done

if $dry_run; then
  echo ""
  echo "[dry-run] No files modified."
  exit 0
fi

if ! $auto_yes; then
  printf '\nProceed? [y/N] '
  read -r answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# Step 1: Append facts to CONTEXT.md under ## Stable Facts
if [[ ${#old_facts[@]} -gt 0 ]]; then
  tmpfile="$(mktemp)"
  found_stable=0
  while IFS= read -r line; do
    echo "$line" >> "$tmpfile"
    if [[ "$found_stable" -eq 0 && "$line" == "## Stable Facts" ]]; then
      found_stable=1
      # Read next line (expect blank or first bullet)
      if IFS= read -r next_line; then
        echo "$next_line" >> "$tmpfile"
      fi
      # Append new facts
      for fact in "${old_facts[@]}"; do
        echo "- $fact" >> "$tmpfile"
      done
    fi
  done < CONTEXT.md
  mv "$tmpfile" CONTEXT.md
fi

# Step 2: Remove old entries from TIMELINE.md
tmpfile="$(mktemp)"
entries_section_started=0
in_old_entry=0
skip_until_next=0
current_heading=""

while IFS= read -r line; do
  if [[ "$line" == "## Entries" ]]; then
    entries_section_started=1
    echo "$line" >> "$tmpfile"
    continue
  fi

  if [[ "$entries_section_started" -eq 1 && "$line" =~ ^###\  ]]; then
    # Check if this heading is in old_entry_headings
    skip_until_next=0
    for old_heading in "${old_entry_headings[@]}"; do
      if [[ "$line" == "$old_heading" ]]; then
        skip_until_next=1
        break
      fi
    done
    if [[ "$skip_until_next" -eq 1 ]]; then
      continue
    fi
  fi

  if [[ "$skip_until_next" -eq 1 ]]; then
    # Skip lines until next ### heading or EOF
    if [[ "$line" =~ ^###\  ]]; then
      # New entry — check if it's also old
      skip_until_next=0
      for old_heading in "${old_entry_headings[@]}"; do
        if [[ "$line" == "$old_heading" ]]; then
          skip_until_next=1
          break
        fi
      done
      if [[ "$skip_until_next" -eq 1 ]]; then
        continue
      fi
    else
      continue
    fi
  fi

  echo "$line" >> "$tmpfile"
done < TIMELINE.md

mv "$tmpfile" TIMELINE.md

echo "Compacted ${#old_entry_headings[@]} entry/entries. ${#old_facts[@]} fact(s) added to Stable Facts."
