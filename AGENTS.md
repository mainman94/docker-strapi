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
| `make tools`                | Install the pinned toolchain from `mise.toml`   |
| `make hooks`                | Install the git pre-commit hook (do this once)  |
| `make check`                | What CI runs: lint, build both variants, smoke both |
| `make build VARIANT=alpine` | Build one variant at the pinned Strapi version  |
| `make smoke VARIANT=alpine` | Boot it and wait for a clean start               |
| `make versions`             | Show what `release-versions/` currently pins     |
| `make scan`                 | CVE scan the built images (advisory, same as CI) |
| `make example-up EXAMPLE=strapi-postgres` | Run an example stack           |

`.devcontainer/` provides Docker; everything else comes from mise.

**Tool versions live in `mise.toml` and nowhere else** — python, pre-commit,
shellcheck, actionlint, trivy. The dev container's post-create runs
`mise install`; CI installs from the same file with `jdx/mise-action`. The
shellcheck that lints the entrypoints in CI is therefore the same binary the
hook uses locally.

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

Two hooks cover the workflows themselves, which matters here because a
workflow in this repo publishes public images: **`actionlint`** (schema,
expressions, and the shell in `run:` blocks, using the pinned shellcheck) and
**`zizmor`** (CI/CD security patterns). zizmor's ignores live in
`.github/zizmor.yml` with their reasons — the two PAT-checkout workflows have
to persist credentials, because git-auto-commit-action pushes with them.

Every action reference is pinned to a **commit SHA** with the tag in a
trailing comment; `helpers:pinGitHubActionDigests` keeps the digests current.
Do not "tidy" a pin back to `@v7`.

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

The publish workflow emits an SBOM and max-mode provenance (`sbom: true`,
`provenance: mode=max`), so consumers can scan a published tag themselves.

It also **signs what it pushes**. cosign signs the multi-arch index by digest,
keylessly: the signature carries this workflow's OIDC identity and lands in
Rekor, so there is no signing key to store or rotate, and a consumer can prove
an image came from this repo:

```shell
cosign verify docker.io/dockerha08/strapi:alpine-latest \
  --certificate-identity-regexp '^https://github.com/mainman94/docker-strapi/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

`actions/attest-build-provenance` additionally writes a SLSA provenance
statement to this repository's attestation store
(`gh attestation verify oci://docker.io/dockerha08/strapi:alpine-latest -R mainman94/docker-strapi`).
Signing is by digest, never by tag: a tag can be moved, a digest cannot.

## Agent tooling

`.claude/` is checked in, so every agent working here starts from the same
setup:

- **`agents/image-reviewer.md`** — reviews Dockerfile, entrypoint and
  publish-path changes for what actually reaches Docker Hub: image size,
  provenance, the two-variant contract. These images are public, so a mistake
  here ships to other people's machines.
- **`skills/release/SKILL.md`** — the release path.
- **Hooks** (`settings.json`): `check-entrypoints.sh` fires when either
  `docker-entrypoint.sh` is written and catches the two drifting apart at the
  edit rather than in CI; `guard-release-versions.sh` guards writes to
  `release-versions/`, because a change there is what triggers a publish.

## Merge requirements

Four checks are required: `lint (alpine)`, `lint (debian)`, `build (alpine)`
and `build (debian)`. The contexts are **job names** including the matrix leg —
the ruleset lives in the `homelab` repo, so renaming a job or a matrix value in
`ci.yml` without updating it there leaves every PR permanently `blocked`.

Repository admins bypass the ruleset, on purpose:
`auto-check-new-releases.yml` and `manual-release.yml` push straight to `main`
with a PAT, and that push is what triggers a publish. A required status check
would reject it — the checks cannot have run for a commit that does not exist
yet. Pull requests are still fully gated.

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
