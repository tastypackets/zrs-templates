#!/usr/bin/env bash
set -euo pipefail

script=$(realpath scripts/publish-catalog.sh)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export CATALOG_TEST_ROOT="$scratch"
export R2_ACCOUNT_ID=test-account R2_TEMPLATES_BUCKET=templates
export AWS_ACCESS_KEY_ID=test-key AWS_SECRET_ACCESS_KEY=test-secret
export GITHUB_SHA=0123456789012345678901234567890123456789
export GITHUB_RUN_ID=123 GITHUB_RUN_ATTEMPT=1
mkdir -p "$scratch/bin" "$scratch/catalogs/networking"
cat > "$scratch/bin/aws" <<'AWS'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$CATALOG_TEST_ROOT/upload-args"
if [ "${FAIL_UPLOAD:-false}" = true ]; then exit 1; fi
while [ "$#" -gt 0 ]; do
  if [ "$1" = --body ]; then shift; cp "$1" "$CATALOG_TEST_ROOT/uploaded"; fi
  shift
done
AWS
cat > "$scratch/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "$CATALOG_TEST_ROOT/download-args"
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output ]; then shift; output=$1; fi
  shift
done
if [ "${STALE_DOWNLOAD:-false}" = true ]; then
  printf '{}' > "$output"
else
  cp "$CATALOG_TEST_ROOT/uploaded" "$output"
fi
CURL
chmod +x "$scratch/bin/aws" "$scratch/bin/curl"
export PATH="$scratch/bin:$PATH"
cd "$scratch"
printf '{"format_version":1,"kind":"template-source","id":"zrs-networking","templates":[]}' \
  > catalogs/networking/templates.source.json
bash "$script" networking
cmp catalogs/networking/templates.source.json uploaded
grep -Fx 'v1/networking/templates.source.json' upload-args
grep -Fx 'application/json' upload-args
grep -Fx 'public, max-age=300, must-revalidate' upload-args
grep -F 'https://templates.zrs.dev/v1/networking/templates.source.json?revision=' download-args

expect_failure() {
  if "$@"; then echo 'Expected failure' >&2; exit 1; fi
}
expect_failure env STALE_DOWNLOAD=true bash "$script" networking
rm -f download-args
expect_failure env FAIL_UPLOAD=true bash "$script" networking
test ! -e download-args
rm -f upload-args
expect_failure bash "$script" ../invalid
test ! -e upload-args
printf '{"format_version":1,"kind":"template-source","id":"zrs-media"}' \
  > catalogs/networking/templates.source.json
expect_failure bash "$script" networking
test ! -e upload-args
printf 'Catalog publishing tests passed\n'
