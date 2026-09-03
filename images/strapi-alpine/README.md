# Strapi v5 — Alpine variant

Published as `dockerha08/strapi:alpine-<strapi-version>` and
`dockerha08/strapi:alpine-latest`. Platforms: `linux/amd64`, `linux/arm64`.

Base image: `node:24-alpine`. Smaller than the Debian variant; use it unless a
native dependency of your project needs glibc.

## Build args

| Arg | Default | Description |
| --- | --- | --- |
| `NODE_VERSION` | `24` | Node.js major, picks the `node:<v>-alpine` base |
| `STRAPI_VERSION` | `5.52.2` | Strapi CLI version; published images use `release-versions/strapi-latest.txt` |
| `VCS_REF` | `unknown` | Commit SHA, written to `org.opencontainers.image.revision` |
| `BUILD_DATE` | – | RFC 3339 timestamp, written to `org.opencontainers.image.created` |

## User

Runs as the non-root user `appuser`. Its UID/GID is **not pinned** by the
image, so a bind-mounted host directory will usually not be writable by it.
Override at runtime to match the mount's owner:

```shell
docker run --user "$(id -u):$(id -g)" -v ./app:/srv/app dockerha08/strapi:alpine-latest
```

or `user: "1000:1000"` in Compose. Named volumes need no such workaround.

## Admin panel build

With `NODE_ENV=production`, the entrypoint builds the admin panel when
`dist/build/index.html` is missing. The build uses a 2048 MB Node.js heap;
raise it with `STRAPI_BUILD_MAX_OLD_SPACE_SIZE` if the build is OOM-killed.

Everything else — env vars, first-boot scaffolding, running an existing
project — is documented in the
[root README](https://github.com/mainman94/docker-strapi#readme).
