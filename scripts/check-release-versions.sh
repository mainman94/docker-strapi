#!/usr/bin/env bash
# A push to anything under release-versions/ triggers publish-docker-images.yml,
# which builds and publishes both variants and cuts a GitHub release. A typo
# here therefore publishes a broken image, so the format is checked first.
set -euo pipefail

status=0
dir=release-versions

check() {
  local file=$1 pattern=$2 what=$3
  [ -f "$file" ] || return 0
  local value
  value=$(tr -d '[:space:]' <"$file")
  if ! printf '%s' "$value" | grep -qE "$pattern"; then
    printf '%s: %s\n' "$file" "$what" >&2
    printf '  got: %s\n' "$value" >&2
    status=1
  fi
}

check "$dir/strapi-latest.txt" '^[0-9]+\.[0-9]+\.[0-9]+$' \
  'expected a bare semver version, e.g. 5.52.3 (no leading v)'
check "$dir/node-alpine-digest.txt" '^sha256:[0-9a-f]{64}$' \
  'expected a sha256 image digest'
check "$dir/node-debian-digest.txt" '^sha256:[0-9a-f]{64}$' \
  'expected a sha256 image digest'

exit "$status"
