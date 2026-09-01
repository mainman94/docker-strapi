# Strapi v5

Based on debian.

Uses Node.js 24 by default (configurable via `NODE_VERSION` build arg).

Strapi version is configurable via `STRAPI_VERSION` build arg (default: 5.52.2).

Runs as root — unlike the alpine variant, no non-root user is set up.

Published as `dockerha08/strapi:debian-slim-<version>` / `debian-slim-latest`.

In production, the entrypoint builds the admin panel when
`dist/build/index.html` is missing. The build uses a 2048 MB Node.js heap by
default; override it with `STRAPI_BUILD_MAX_OLD_SPACE_SIZE` when needed.
