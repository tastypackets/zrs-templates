#!/usr/bin/env bash
set -euo pipefail

script=$(realpath scripts/run-action.sh)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export RUNNER_OS=Linux RUNNER_ARCH=X64 RUNNER_TEMP="$scratch"
export GITHUB_OUTPUT="$scratch/output" ZRS_CLI_VERSION=v1
export ZRS_MANIFEST='' ZRS_OUTPUT='' ZRS_LINT_ONLY=false ZRS_FILES=''
export ZRS_WORKING_DIRECTORY="$scratch/catalog with spaces" ZRS_STRICT=true ZRS_ALLOW=unpinned_image
export ACTION_TEST_ROOT="$scratch"
mkdir -p "$scratch/bin" "$ZRS_WORKING_DIRECTORY"
cat > "$scratch/binary" <<'BIN'
#!/usr/bin/env bash
printf '%s\n' "$PWD" "$@" > "$ACTION_TEST_ROOT/invocation"
BIN
revision=cc7197fff9bb8d6e4107661e4f903a59dfe3476e
release="0.1.39-$revision"
checksum=$(sha256sum "$scratch/binary" | cut -d ' ' -f 1)
jq -n --arg release "$release" --arg revision "$revision" --arg checksum "$checksum" \
  '{schema_version:1, cli_major:1, release:$release, reader_version:"0.1.39", revision:$revision, sha256:{amd64:$checksum,arm64:$checksum}}' > "$scratch/descriptor"
cat > "$scratch/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
while [ "$#" -gt 0 ]; do
  case "$1" in
    https://*) url=$1 ;;
    --output) shift; output=$1 ;;
  esac
  shift
done
printf '%s\n' "$url" >> "$ACTION_TEST_ROOT/requests"
case "$url" in
  *.json) cp "$ACTION_TEST_ROOT/descriptor" "$output" ;;
  *) cp "$ACTION_TEST_ROOT/binary" "$output" ;;
esac
CURL
chmod +x "$scratch/bin/curl"
export PATH="$scratch/bin:$PATH"

bash "$script"
test "$(head -1 "$scratch/invocation")" = "$ZRS_WORKING_DIRECTORY"
grep -Fx -- '--lint-only=false' "$scratch/invocation"
grep -Fx "release=$release" "$GITHUB_OUTPUT"
grep -F '/current.json' "$scratch/requests"

ZRS_CLI_VERSION="$release" RUNNER_ARCH=ARM64 ZRS_LINT_ONLY=true \
  ZRS_FILES=$'templates/**/*.json\npacks/**/*.json' bash "$script"
grep -F "/releases/$release/release.json" "$scratch/requests"
grep -F '/zrs-template-linux-arm64' "$scratch/requests"
grep -Fx -- '--lint-only=true' "$scratch/invocation"
grep -Fx -- '--patterns=templates/**/*.json' "$scratch/invocation"

expect_failure() {
  rm -f "$scratch/invocation"
  if "$@"; then echo 'Expected failure' >&2; exit 1; fi
  test ! -e "$scratch/invocation"
}
expect_failure env RUNNER_OS=Windows bash "$script"
expect_failure env RUNNER_ARCH=RISCV64 bash "$script"
expect_failure env ZRS_CLI_VERSION=../../invalid bash "$script"
expect_failure env ZRS_CLI_VERSION="0.1.40-$revision" bash "$script"
printf 'tampered' >> "$scratch/binary"
expect_failure bash "$script"
printf '{}' > "$scratch/descriptor"
expect_failure bash "$script"
printf 'Action tests passed\n'
