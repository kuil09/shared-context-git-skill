#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: summarize_context.sh [--repo DIR]

Print a compact summary of the shared context and simple compaction hints.
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

extract_section() {
  local section_name="$1"
  awk -v header="## ${section_name}" '
    $0 == header { in_section=1; next }
    in_section && /^## / { exit }
    in_section { print }
  ' CONTEXT.md
}

count_bullets() {
  grep -Ec '^- ' || true
}

print_section_summary() {
  local section_name="$1"
  local section_content
  section_content="$(extract_section "$section_name")"
  local bullet_count
  bullet_count="$(printf '%s\n' "$section_content" | count_bullets)"
  echo "## ${section_name}"
  echo "Bullet count: ${bullet_count}"
  printf '%s\n' "$section_content" | sed '/^[[:space:]]*$/d' | head -n 5
  echo
}

context_lines="$(wc -l < CONTEXT.md | tr -d ' ')"
duplicate_bullets="$(grep -E '^- ' CONTEXT.md | sort | uniq -d || true)"

echo "# Shared Context Summary"
echo
echo "CONTEXT.md lines: ${context_lines}"
echo

print_section_summary "Overview"
print_section_summary "Stable Facts"
print_section_summary "Active Context"
print_section_summary "Decisions"
print_section_summary "Open Questions"

echo "## Compaction Hints"

hint_emitted=0
if [[ "$context_lines" -gt 120 ]]; then
  echo "- CONTEXT.md is longer than 120 lines; consider compressing repeated narrative."
  hint_emitted=1
fi

if [[ -n "$duplicate_bullets" ]]; then
  echo "- Duplicate bullets detected in CONTEXT.md:"
  printf '%s\n' "$duplicate_bullets" | sed 's/^/  /'
  hint_emitted=1
fi

if [[ "$hint_emitted" -eq 0 ]]; then
  echo "- No obvious compaction issues detected."
fi
