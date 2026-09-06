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
| `scripts/`              | The consistency checks CI and the hooks both run        |
| `examples/`             | Runnable `docker compose` setups                        |
| `Makefile`              | `make help` lists every target                          |
| `mise.toml`             | The toolchain — one source of truth for versions        |
| `.github/workflows/`    | CI (lint + build + smoke test) and publishing           |

The two `docker-entrypoint.sh` files are **byte-identical on purpose** and CI
enforces it. Change one, copy it to the other.

## Local development

```shell
make tools   # install the pinned toolchain from mise.toml
make hooks   # install the git pre-commit hook, once
make check   # what CI runs: lint, build both variants, smoke-test both
```

`make help` lists the rest. One variant at a time:

```shell
make build smoke VARIANT=alpine
make shell VARIANT=alpine      # poke around inside the built image
make scan  VARIANT=alpine      # the same advisory CVE scan CI runs
make example-up EXAMPLE=strapi-postgres
```

**Tool versions live in `mise.toml` and nowhere else** — python, pre-commit,
shellcheck, actionlint and trivy; pre-commit builds the rest (hadolint, shfmt,
yamlfmt, gitleaks) into its own cached envs. The dev container, the git hooks
and CI all install from that one file, so a bump lands in all three at once and
a lint that passes locally passes in CI.

`shellcheck` is pinned there rather than left to the hook's own env because
`actionlint` shells out to it for `run:` blocks, and `smoke-test.sh` and the two
entrypoints need checking with the same binary CI uses.

The hooks (`make lint`) also run `actionlint` and `zizmor` over
`.github/workflows/`, so a workflow change is checked before it ever runs.

## Pull requests

- One topic per PR, branch off `main`.
- Touching a Dockerfile or entrypoint? Say which variants you built and
  smoke-tested locally. CI does both anyway, but say it.
- Behaviour change (new env var, new default)? Update the variant README and
  the root README in the same PR.
- Commit messages: imperative mood, one line ("Fix sqlite path in entrypoint").

Four checks must pass before a PR can merge: `lint (alpine)`, `lint (debian)`,
`build (alpine)` and `build (debian)`. The build jobs include the smoke test, so
nothing merges that did not boot.

The release workflows push straight to `main` with a PAT — that push is what
triggers a publish, and a required check cannot have run for a commit that does
not exist yet — so repository admins bypass the ruleset. Every pull request is
still gated.

## Releases

`release-versions/strapi-latest.txt` drives everything. A daily workflow
bumps it from upstream Strapi; a push to any file in `release-versions/`
triggers `publish-docker-images.yml`, which builds both variants for
`linux/amd64` and `linux/arm64`, smoke-tests amd64, pushes to Docker Hub and
cuts a GitHub release. Use the **Create new release manually** workflow to pin
a specific Strapi version.

Every published image is signed with cosign (keyless) and carries an SBOM and a
provenance attestation. The verify command is in
[SECURITY.md](SECURITY.md).

## Agent tooling

`.claude/` is checked in, so every agent working here starts from the same
setup:

- **`agents/image-reviewer.md`** — reviews Dockerfile, entrypoint and
  publish-path changes for what actually reaches Docker Hub: image size,
  provenance, and the two-variant contract.
- **`skills/release/SKILL.md`** — the release path, which is easy to get wrong
  by hand.
- **Hooks** (`settings.json`): `check-entrypoints.sh` catches the two
  entrypoints drifting apart the moment one is edited, rather than at CI;
  `guard-release-versions.sh` guards edits to `release-versions/`, since a write
  there triggers a publish.
