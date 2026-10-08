#!/usr/bin/env bash
set -euo pipefail

catalog=${1:?catalog required}
case "$catalog" in
  networking|media|development|gaming) ;;
  *) echo 'Unknown catalog' >&2; exit 1 ;;
esac
: "${R2_ACCOUNT_ID:?missing R2_ACCOUNT_ID}"
: "${R2_TEMPLATES_BUCKET:?missing R2_TEMPLATES_BUCKET}"
: "${AWS_ACCESS_KEY_ID:?missing AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY:?missing AWS_SECRET_ACCESS_KEY}"
: "${GITHUB_SHA:?missing GITHUB_SHA}"
: "${GITHUB_RUN_ID:?missing GITHUB_RUN_ID}"
: "${GITHUB_RUN_ATTEMPT:?missing GITHUB_RUN_ATTEMPT}"

file="catalogs/$catalog/templates.source.json"
key="v1/$catalog/templates.source.json"
jq -e --arg id "zrs-$catalog" \
  '.format_version == 1 and .kind == "template-source" and .id == $id' "$file" > /dev/null
aws --endpoint-url "https://$R2_ACCOUNT_ID.r2.cloudflarestorage.com" s3api put-object \
  --bucket "$R2_TEMPLATES_BUCKET" --key "$key" --body "$file" \
  --content-type application/json --cache-control 'public, max-age=300, must-revalidate' \
  > /dev/null

scratch=$(mktemp)
trap 'rm -f "$scratch"' EXIT
curl --fail --silent --show-error --compressed --retry 3 --max-time 60 \
  "https://templates.zrs.dev/$key?revision=$GITHUB_SHA&run=$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT" \
  --output "$scratch"
cmp "$file" "$scratch"
printf 'Published https://templates.zrs.dev/%s\n' "$key"
