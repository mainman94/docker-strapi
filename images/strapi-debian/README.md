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
| `NODE_DIGEST` | – (required) | Base image digest; published images use `release-versions/node-debian-digest.txt` |
| `NODE_VERSION` | `24` | Node.js major, picks the `node:<v>-trixie-slim` base |
| `STRAPI_VERSION` | `5.52.2` | Strapi CLI version; published images use `release-versions/strapi-latest.txt` |
| `VCS_REF` | `unknown` | Commit SHA, written to `org.opencontainers.image.revision` |
| `BUILD_DATE` | – | RFC 3339 timestamp, written to `org.opencontainers.image.created` |

## User

Runs as the base image's non-root user `node`, uid `1000` / gid `1000`, which
owns `/srv/app`. A bind-mounted host directory must be writable by it —
`sudo chown -R 1000:1000 ./app` — or override with `--user` to match the
mount's owner. If `/srv/app` is not writable, the entrypoint stops with the
`chown` to run.

Images published before the switch ran as root, so a volume they created is
root-owned. Hand it over once:

```shell
docker run --rm -v <volume>:/srv/app alpine chown -R 1000:1000 /srv/app
```

## Admin panel build

With `NODE_ENV=production`, the entrypoint builds the admin panel when
`dist/build/index.html` is missing. The build uses a 2048 MB Node.js heap;
raise it with `STRAPI_BUILD_MAX_OLD_SPACE_SIZE` if the build is OOM-killed.

Everything else — env vars, first-boot scaffolding, running an existing
project — is documented in the
[root README](https://github.com/mainman94/docker-strapi#readme).
