# Contributing

Thanks for helping out. This repo builds and publishes Docker images for
Strapi v5 — there is no application code, only Dockerfiles, entrypoints and CI.

## Layout

| Path                    | What it is                                              |
| ----------------------- | ------------------------------------------------------- |
| `images/strapi-alpine/` | Alpine variant: Dockerfile, entrypoint, README          |
| `images/strapi-debian/` | Debian-slim variant: same three files                   |
| `release-versions/`     | Version/digest pins that trigger a publish when changed |
| `smoke-test.sh`         | Boots a built image and waits for a clean start         |
| `examples/`             | Runnable `docker compose` setups                        |
| `.github/workflows/`    | CI (lint + build + smoke test) and publishing           |

The two `docker-entrypoint.sh` files are **byte-identical on purpose** and CI
enforces it. Change one, copy it to the other.

## Local development

Build and smoke-test a variant:

```shell
docker build -t strapi-alpine-test \
  --build-arg STRAPI_VERSION="$(cat release-versions/strapi-latest.txt)" \
  images/strapi-alpine
./smoke-test.sh strapi-alpine-test
```

Run the linters CI runs:

```shell
docker run --rm -i hadolint/hadolint < images/strapi-alpine/Dockerfile
shellcheck --severity=warning -e SC2086,SC2269 \
  smoke-test.sh images/strapi-alpine/docker-entrypoint.sh
```

## Pull requests

- One topic per PR, branch off `main`.
- Touching a Dockerfile or entrypoint? Say which variants you built and
  smoke-tested locally. CI does both anyway, but say it.
- Behaviour change (new env var, new default)? Update the variant README and
  the root README in the same PR.
- Commit messages: imperative mood, one line ("Fix sqlite path in entrypoint").

## Releases

`release-versions/strapi-latest.txt` drives everything. A daily workflow
bumps it from upstream Strapi; a push to any file in `release-versions/`
triggers `publish-docker-images.yml`, which builds both variants for
`linux/amd64` and `linux/arm64`, smoke-tests amd64, pushes to Docker Hub and
cuts a GitHub release. Use the **Create new release manually** workflow to pin
a specific Strapi version.
