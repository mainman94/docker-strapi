# AGENTS

Docker images for Strapi v5, in two variants: Alpine and Debian-slim. There is
no application code here — only Dockerfiles, entrypoints, examples and CI.

`release-versions/` drives releases: a push to any file in it triggers
`publish-docker-images.yml`, which builds both variants for amd64 and arm64,
smoke-tests amd64, pushes to Docker Hub and cuts a GitHub release. A typo in
those files therefore publishes a broken image.

`CONTRIBUTING.md` is the human-facing version of this; it covers PR etiquette
and the release flow in more detail.

## Layout

| Path                    | What it is                                              |
| ----------------------- | ------------------------------------------------------- |
| `images/strapi-alpine/` | Alpine variant: Dockerfile, entrypoint, README          |
| `images/strapi-debian/` | Debian-slim variant: the same three files               |
| `release-versions/`     | Version and digest pins that trigger a publish          |
| `smoke-test.sh`         | Boots a built image and waits for a clean start         |
| `examples/`             | Runnable `docker compose` setups                        |

## Local workflow

| Command                     | What it does                                    |
| --------------------------- | ------------------------------------------------ |
| `make help`                 | List every target                               |
| `make hooks`                | Install the git pre-commit hook (do this once)  |
| `make check`                | What CI runs: lint, build both variants, smoke both |
| `make build VARIANT=alpine` | Build one variant at the pinned Strapi version  |
| `make smoke VARIANT=alpine` | Boot it and wait for a clean start               |
| `make versions`             | Show what `release-versions/` currently pins     |
| `make scan`                 | CVE scan the built images (advisory, same as CI) |
| `make example-up EXAMPLE=strapi-postgres` | Run an example stack           |

`.devcontainer/` provides Docker and the hook toolchain.

## Automated checks

`.pre-commit-config.yaml` runs CI's lint job locally — `hadolint` against
`.hadolint.yaml` at the warning threshold, and `shellcheck` with the same
`-e SC2086,SC2269` suppressions — plus `shfmt`, `yamlfmt`, `gitleaks` and
hygiene hooks. Two hooks are repo-specific:

- **`entrypoints-identical`** — the two `docker-entrypoint.sh` files are
  byte-identical on purpose. A fix applied to one and not the other is a
  silent behaviour split between published tags. CI enforces it with `diff`;
  the hook catches it before the push.
- **`release-versions-format`** — `strapi-latest.txt` must be a bare semver
  (no leading `v`) and the digest files must be `sha256:` followed by 64 hex
  characters. These files trigger a publish, so the format is checked before
  they can.

The build and the smoke test stay out of the hooks: they need a daemon and a
few minutes. `make check` runs them.

## Scanning

`ci.yml` scans both built variants with trivy after the smoke test and
uploads SARIF to the Security tab, one category per variant so the matrix
legs do not overwrite each other. `make scan` runs the same scan locally
against the images `make build` produced.

It is **advisory on purpose**. The base images are pinned by digest in
`release-versions/` and rebuilt on every upstream Strapi release precisely so
a rebuild picks up current patches — failing the build on an unpatched
upstream CVE would only stop that rebuild from shipping, which is backwards.
`--ignore-unfixed` for the same reason.

The publish workflow already emits an SBOM (`sbom: true`), so consumers can
scan a published tag themselves.

## Conventions

- **Change one entrypoint, copy it to the other.** `cp
  images/strapi-alpine/docker-entrypoint.sh images/strapi-debian/`.
- **Base images are pinned by digest in `release-versions/` and rebuilt on
  every upstream release**, which is why `.hadolint.yaml` ignores the
  package-pinning rules (DL3018, DL3008, DL3016): a rebuild is *supposed* to
  pick up current security patches. Strapi itself is pinned, via
  `STRAPI_VERSION`.
- **The Debian variant runs as root by design** (DL3002 ignored); the Alpine
  variant runs as `appuser`.
- **A behaviour change — a new env var, a new default — updates the variant
  README and the root README in the same PR.**
- Commit messages: imperative mood, one line.
