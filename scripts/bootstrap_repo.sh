#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bootstrap_repo.sh [--target DIR] [--with-handoff] [--with-policy] [--force]

Create the shared-context document set in DIR (default: current directory).
Existing files are never overwritten unless --force is provided.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_dir="${script_dir%/scripts}/assets/templates"

target_dir="."
with_handoff=0
with_policy=0
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || { echo "Missing value for --target" >&2; exit 1; }
      target_dir="$2"
      shift 2
      ;;
    --with-handoff)
      with_handoff=1
      shift
      ;;
    --with-policy)
      with_policy=1
      shift
      ;;
    --force)
      force=1
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

mkdir -p "$target_dir"

copy_template() {
  local source_name="$1"
  local destination_name="$2"
  local source_path="${template_dir}/${source_name}"
  local destination_path="${target_dir}/${destination_name}"

  [[ -f "$source_path" ]] || { echo "Template not found: $source_path" >&2; exit 1; }

  if [[ -e "$destination_path" && "$force" -ne 1 ]]; then
    echo "Refusing to overwrite existing file: $destination_path" >&2
    echo "Re-run with --force if you want to replace it." >&2
    exit 1
  fi

  cp "$source_path" "$destination_path"
  echo "Created ${destination_path}"
}

copy_template "CONTEXT.md" "CONTEXT.md"

if [[ "$with_handoff" -eq 1 ]]; then
  copy_template "HANDOFF.md" "HANDOFF.md"
fi

if [[ "$with_policy" -eq 1 ]]; then
  copy_template "POLICY.md" "POLICY.md"
fi

if [[ ! -d "${target_dir}/.git" ]]; then
  echo "Warning: ${target_dir} does not look like a Git repository yet." >&2
  echo "Bootstrap completed, but you should initialize or clone a repo before sharing changes." >&2
fi
