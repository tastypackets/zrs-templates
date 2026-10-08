#!/usr/bin/env bash
set -euo pipefail

script=$(realpath scripts/changed-catalogs.sh)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
git init -q "$scratch"
cd "$scratch"
git config user.name Test
git config user.email test@example.test
mkdir -p catalogs/{core,networking,media,development,gaming} scripts
printf 'initial' > README.md
printf 'old' > catalogs/core/manifest.json
git add .
git commit -qm initial
base=$(git rev-parse HEAD)
all=$'networking\nmedia\ndevelopment\ngaming'
test "$(bash "$script")" = "$all"
test "$(bash "$script" 0000000000000000000000000000000000000000 HEAD)" = "$all"
test -z "$(bash "$script" "$base" HEAD)"

printf 'docs' >> README.md
git commit -qam docs
test -z "$(bash "$script" "$base" HEAD)"

printf 'gaming' > catalogs/gaming/manifest.json
git add .
git commit -qm gaming
test "$(bash "$script" "$base" HEAD)" = gaming

printf 'media' > catalogs/media/manifest.json
git add .
git commit -qm media
test "$(bash "$script" "$base" HEAD)" = $'media\ngaming'

before=$(git rev-parse HEAD)
git mv catalogs/core/manifest.json catalogs/networking/manifest.json
git commit -qm rename
test "$(bash "$script" "$before" HEAD)" = networking

before=$(git rev-parse HEAD)
git rm -q catalogs/gaming/manifest.json
git commit -qm deletion
test "$(bash "$script" "$before" HEAD)" = gaming

printf 'shared' > scripts/download-cli.sh
git add .
git commit -qm shared
test "$(bash "$script" "$base" HEAD)" = "$all"
if bash "$script" invalid-ref HEAD; then
  echo 'Expected invalid diff to fail' >&2
  exit 1
fi
printf 'Catalog selection tests passed\n'
