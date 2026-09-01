# Strapi v5

Based on debian.

Uses Node.js 24 by default (configurable via `NODE_VERSION` build arg).

Strapi version is configurable via `STRAPI_VERSION` build arg (default: 5.52.2).

Runs as root — unlike the alpine variant, no non-root user is set up.

Published as `dockerha08/strapi:debian-slim-<version>` / `debian-slim-latest`.
