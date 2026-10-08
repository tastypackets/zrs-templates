#!/usr/bin/env bash
set -euo pipefail

scratch=$(mktemp -d "$RUNNER_TEMP/zrs-action.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
binary="$scratch/zrs-template"
bash "$(dirname "$0")/download-cli.sh" "$binary"

args=("--strict=$ZRS_STRICT" "--allow=$ZRS_ALLOW" "--lint-only=$ZRS_LINT_ONLY")
if [ -n "$ZRS_FILES" ]; then args+=("--patterns=$ZRS_FILES"); fi
if [ -n "$ZRS_MANIFEST" ]; then args+=("--manifest=$ZRS_MANIFEST"); fi
if [ -n "$ZRS_OUTPUT" ]; then args+=("--output=$ZRS_OUTPUT"); fi
cd "$ZRS_WORKING_DIRECTORY"
"$binary" "${args[@]}"
