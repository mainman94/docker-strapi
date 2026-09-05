#!/usr/bin/env bash
# The two variants' entrypoints are byte-identical on purpose: the Alpine and
# Debian images differ only in base, so a fix applied to one and not the other
# is a silent behaviour split between published tags. CI enforces this with a
# plain `diff`; this catches it before the push.
set -euo pipefail

alpine=images/strapi-alpine/docker-entrypoint.sh
debian=images/strapi-debian/docker-entrypoint.sh

if ! diff -u "$alpine" "$debian"; then
  cat >&2 <<'MSG'

The two docker-entrypoint.sh files have diverged.

They are byte-identical on purpose — change one, then copy it to the other:

  cp images/strapi-alpine/docker-entrypoint.sh images/strapi-debian/
MSG
  exit 1
fi
