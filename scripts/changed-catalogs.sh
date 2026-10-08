#!/usr/bin/env bash
set -euo pipefail

before=${1:-}
after=${2:-HEAD}
catalogs=(networking media development gaming)
if [ -z "$before" ] || [[ "$before" =~ ^0+$ ]]; then
  printf '%s\n' "${catalogs[@]}"
  exit
fi

changes=$(git diff --name-only --no-renames "$before" "$after" --)
if grep -Eq '^(action\.yml$|scripts/|\.github/workflows/(publish|validate)\.yml$)' <<< "$changes"; then
  printf '%s\n' "${catalogs[@]}"
  exit
fi
for catalog in "${catalogs[@]}"; do
  if grep -q "^catalogs/$catalog/" <<< "$changes"; then
    printf '%s\n' "$catalog"
  fi
done
