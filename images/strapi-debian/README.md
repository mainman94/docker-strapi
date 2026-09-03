# Strapi v5 — Debian slim variant

Published as `dockerha08/strapi:debian-slim-<strapi-version>` and
`dockerha08/strapi:debian-slim-latest`. Platforms: `linux/amd64`,
`linux/arm64`.

Base image: `node:24-trixie-slim`. Larger than the Alpine variant, but glibc-
based — use it when a native dependency does not build or run on musl. No
compiler toolchain is installed; native modules come from prebuilt binaries.

## Build args

| Arg | Default | Description |
| --- | --- | --- |
| `NODE_VERSION` | `24` | Node.js major, picks the `node:<v>-trixie-slim` base |
| `STRAPI_VERSION` | `5.52.2` | Strapi CLI version; published images use `release-versions/strapi-latest.txt` |
| `VCS_REF` | `unknown` | Commit SHA, written to `org.opencontainers.image.revision` |
| `BUILD_DATE` | – | RFC 3339 timestamp, written to `org.opencontainers.image.created` |

## User

Runs as **root** — unlike the Alpine variant, no non-root user is set up.
`/srv/app` is owned by `1000:1000`, so `--user 1000:1000` (or `user:` in
Compose) works if you want to drop privileges.

## Admin panel build

With `NODE_ENV=production`, the entrypoint builds the admin panel when
`dist/build/index.html` is missing. The build uses a 2048 MB Node.js heap;
raise it with `STRAPI_BUILD_MAX_OLD_SPACE_SIZE` if the build is OOM-killed.

Everything else — env vars, first-boot scaffolding, running an existing
project — is documented in the
[root README](https://github.com/mainman94/docker-strapi#readme).
