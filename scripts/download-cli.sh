#!/usr/bin/env bash
set -euo pipefail

destination=${1:?binary destination required}

if [ "$RUNNER_OS" != Linux ]; then
  echo '::error::ZRS templates requires a Linux runner.'
  exit 1
fi
case "$RUNNER_ARCH" in
  X64) arch=amd64 ;;
  ARM64) arch=arm64 ;;
  *) echo "::error::Unsupported runner architecture: $RUNNER_ARCH"; exit 1 ;;
esac

base=https://templates.zrs.dev/cli/v1
requested=${ZRS_CLI_VERSION:-v1}
if [ "$requested" = v1 ]; then
  descriptor="$base/current.json"
elif [[ "$requested" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[a-f0-9]{40}$ ]]; then
  descriptor="$base/releases/$requested/release.json"
else
  echo '::error::version must be v1 or a retained release ID.'
  exit 1
fi

scratch=$(mktemp -d "$RUNNER_TEMP/zrs-template.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
curl --fail --silent --show-error --compressed --retry 3 --max-time 60 \
  "$descriptor" --output "$scratch/release.json"
jq -e --arg requested "$requested" --arg arch "$arch" '
  .schema_version == 1 and .cli_major == 1 and
  (.reader_version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and
  (.revision | test("^[a-f0-9]{40}$")) and
  .release == (.reader_version + "-" + .revision) and
  ($requested == "v1" or .release == $requested) and
  (.sha256[$arch] | test("^[a-f0-9]{64}$"))
' "$scratch/release.json" > /dev/null
release=$(jq -r .release "$scratch/release.json")
checksum=$(jq -r --arg arch "$arch" '.sha256[$arch]' "$scratch/release.json")
binary="$scratch/zrs-template"
curl --fail --silent --show-error --compressed --retry 3 --max-time 60 \
  "$base/releases/$release/zrs-template-linux-$arch" --output "$binary"
printf '%s  %s\n' "$checksum" "$binary" | sha256sum --check --status
chmod +x "$binary"
printf 'release=%s\n' "$release" >> "$GITHUB_OUTPUT"
printf 'Using zrs-template %s (%s)\n' "$release" "$arch"

mv "$binary" "$destination"
