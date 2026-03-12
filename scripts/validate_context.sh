#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: validate_context.sh [--repo DIR] [--strict]

Validate required shared-context files and basic document structure.

Options:
  --repo DIR   Path to the repository directory (default: .)
  --strict     Enable strict validation (non-empty fields)
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

echo "Shared context structure is valid"
