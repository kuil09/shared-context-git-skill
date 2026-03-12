#!/usr/bin/env bash
set -euo pipefail

# Run all BATS tests from the project root.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="${script_dir%/tests}"
bats_bin="${script_dir}/lib/bats-core/bin/bats"

if [[ ! -x "$bats_bin" ]]; then
  echo "BATS not found. Run: git submodule update --init --recursive" >&2
  exit 1
fi

exec "$bats_bin" "$@" "$script_dir"/*.bats
