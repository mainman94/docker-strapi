<div align="center">

<img src="https://raw.githubusercontent.com/mainman94/docker-strapi/main/assets/PNG.logo.purple.dark.png" alt="Strapi" width="180">

# docker-strapi

**Docker images for [Strapi](https://strapi.io) v5 — Alpine and Debian slim, multi-arch, rebuilt on every upstream release.**

[![Docker Pulls](https://img.shields.io/docker/pulls/dockerha08/strapi?logo=docker&logoColor=white)](https://hub.docker.com/r/dockerha08/strapi)
[![Image Size](https://img.shields.io/docker/image-size/dockerha08/strapi/alpine-latest?label=alpine%20size&logo=docker&logoColor=white)](https://hub.docker.com/r/dockerha08/strapi/tags)
[![Strapi Version](https://img.shields.io/docker/v/dockerha08/strapi/alpine-latest?label=strapi&logo=strapi&logoColor=white)](https://hub.docker.com/r/dockerha08/strapi/tags)
[![CI](https://github.com/mainman94/docker-strapi/actions/workflows/ci.yml/badge.svg)](https://github.com/mainman94/docker-strapi/actions/workflows/ci.yml)
[![Publish](https://github.com/mainman94/docker-strapi/actions/workflows/publish-docker-images.yml/badge.svg)](https://github.com/mainman94/docker-strapi/actions/workflows/publish-docker-images.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/mainman94/docker-strapi/blob/main/LICENSE)

[Docker Hub](https://hub.docker.com/r/dockerha08/strapi) · [GitHub](https://github.com/mainman94/docker-strapi) · [Strapi docs](https://docs.strapi.io/)

</div>

---

## Quick start

```shell
docker run -d -p 1337:1337 -e NODE_ENV=development dockerha08/strapi:alpine-latest
```

Open <http://localhost:1337/admin>. The container scaffolds a fresh Strapi
project with an SQLite database on first boot and starts it.

With Compose, and a bind mount so the project survives the container:

```yaml
services:
  strapi:
    image: dockerha08/strapi:alpine-latest
    environment:
      NODE_ENV: development # or production
    ports:
      - "1337:1337"
    volumes:
      - ./app:/srv/app # scaffolded here on first boot, reused after
```

Runnable examples: [SQLite](https://github.com/mainman94/docker-strapi/tree/main/examples/strapi-sqlite) · [PostgreSQL](https://github.com/mainman94/docker-strapi/tree/main/examples/strapi-postgres).

## Tags

| Tag | Base | Runs as | Notes |
| --- | --- | --- | --- |
| `alpine-latest` | `node:24-alpine` | `appuser` (non-root) | Smallest. Recommended. |
| `alpine-<version>` | `node:24-alpine` | `appuser` (non-root) | Pinned to a Strapi release. |
| `debian-slim-latest` | `node:24-trixie-slim` | `root` | glibc, for native modules Alpine trips on. |
| `debian-slim-<version>` | `node:24-trixie-slim` | `root` | Pinned to a Strapi release. |

`<version>` is the upstream Strapi version, e.g. `alpine-5.52.3`.

Platforms: `linux/amd64`, `linux/arm64`. Every published image carries an
SBOM and provenance attestation, plus OCI labels:

```shell
docker buildx imagetools inspect dockerha08/strapi:alpine-latest
docker inspect dockerha08/strapi:alpine-latest --format '{{json .Config.Labels}}' | jq
```

Variant details: [alpine](https://github.com/mainman94/docker-strapi/blob/main/images/strapi-alpine/README.md) ·
[debian](https://github.com/mainman94/docker-strapi/blob/main/images/strapi-debian/README.md).

## How it works

On start, the entrypoint looks at `/srv/app`:

- **No `package.json`** → runs
  [`create-strapi-app`](https://docs.strapi.io/dev-docs/cli#strapi-new) to
  scaffold a project, configured from the `DATABASE_*` env vars below.
- **Project present, no `node_modules`** → installs dependencies with yarn if
  a `yarn.lock` exists, otherwise npm.
- Then starts Strapi:
  [`strapi develop`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-develop)
  when `NODE_ENV=development`,
  [`strapi start`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-start)
  when `NODE_ENV=production` (building the admin panel first if
  `dist/build/index.html` is missing).

> The [Content-Type Builder](https://strapi.io/features/content-types-builder)
> is disabled when `NODE_ENV=production` — that is Strapi's behaviour, not the
> image's.

To run an **existing** project, mount it at `/srv/app`. Anything other than
the default command is executed as-is, so `docker run ... dockerha08/strapi:alpine-latest sh`
gives you a shell.

## Environment variables

Used when scaffolding a new project:

| Variable | Default | Description |
| --- | --- | --- |
| `DATABASE_CLIENT` | `sqlite` | `sqlite`, `postgres` or `mysql` |
| `DATABASE_HOST` | – | Database host |
| `DATABASE_PORT` | – | Database port |
| `DATABASE_NAME` | – | Database name |
| `DATABASE_USERNAME` | – | Database user |
| `DATABASE_PASSWORD` | – | Database password |
| `DATABASE_SSL` | – | `true` / `false` |
| `EXTRA_ARGS` | – | Extra flags passed to `create-strapi-app` |

Used at runtime:

| Variable | Default | Description |
| --- | --- | --- |
| `NODE_ENV` | `development` | `development` → `strapi develop`, `production` → `strapi start` |
| `STRAPI_BUILD_MAX_OLD_SPACE_SIZE` | `2048` | Node.js heap (MB) for the admin panel build |

Strapi's own variables (`APP_KEYS`, `JWT_SECRET`, `ADMIN_JWT_SECRET`, …) are
read from the project's `.env`; set them explicitly for anything long-lived.

## Deploying to production

These images are built for scaffolding and development. For production, build
an image **from your project** on top of [`node:24`](https://hub.docker.com/_/node):

```dockerfile
FROM node:24

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY favicon.ico ./favicon.ico
COPY src/ src/
COPY public/ public/
COPY database/ database/
COPY config/ config/

RUN yarn build

EXPOSE 1337
CMD ["yarn", "start"]
```

## Building locally

```shell
docker build -t strapi-alpine-test \
  --build-arg STRAPI_VERSION="$(cat release-versions/strapi-latest.txt)" \
  images/strapi-alpine
./smoke-test.sh strapi-alpine-test
```

Build args: `NODE_VERSION` (default `24`), `STRAPI_VERSION`, plus `VCS_REF`
and `BUILD_DATE` for the OCI labels.

## Releases

A daily workflow reads the latest Strapi version and the pinned `node:24`
digests into `release-versions/`. Any change there triggers a build of both
variants for both platforms, a smoke test on amd64, a push to Docker Hub and a
GitHub release. Nothing is pushed that did not boot successfully first.

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](https://github.com/mainman94/docker-strapi/blob/main/CONTRIBUTING.md),
[SECURITY.md](https://github.com/mainman94/docker-strapi/blob/main/SECURITY.md) and the
[Code of Conduct](https://github.com/mainman94/docker-strapi/blob/main/CODE_OF_CONDUCT.md).

## License

[MIT](https://github.com/mainman94/docker-strapi/blob/main/LICENSE). Fork of [naskio/docker-strapi](https://github.com/naskio/docker-strapi),
which remains under its original copyright. Strapi is a trademark of Strapi
Solutions SAS; this project is not affiliated with or endorsed by Strapi.
