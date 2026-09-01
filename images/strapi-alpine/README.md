# Strapi v5

Alpine-based Docker image for Strapi v5.

Uses Node.js 24 by default (configurable via `NODE_VERSION` build arg).

Strapi version is configurable via `STRAPI_VERSION` build arg (default: 5.52.2).

Runs as non-root user `appuser` for security. `appuser`'s UID/GID isn't
pinned by the image — override it at runtime with `docker run --user
<uid>:<gid>` (or `user:` in Compose) to match your bind-mounted volume's
ownership.

Published as `dockerha08/strapi:alpine-<version>` / `alpine-latest`.
