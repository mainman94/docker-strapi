---
name: release
description: Cut a Strapi image release, or check that a pending release is safe. Use when asked to release, bump the Strapi version, or when release-versions/ has changed.
---

# release

A push to any file under `release-versions/` publishes to Docker Hub. There is no staging
tag and no undo — a bad value ships an image built from `create-strapi-app@<typo>`.

## Before changing release-versions/

1. `make versions` — see what is pinned now.
2. Confirm the target Strapi version exists upstream:
   `curl -sSfL https://raw.githubusercontent.com/strapi/strapi/main/packages/core/strapi/package.json | jq -r .version`
3. Formats, enforced by `scripts/check-release-versions.sh` and by the workflows
   themselves: `strapi-latest.txt` is a bare semver (no leading `v`); the digest files are
   `sha256:` plus 64 hex characters.

## Then

4. `make check` — lint, build both variants, smoke both. This is the last gate that runs
   locally; CI repeats it, and the publish workflow smoke-tests amd64 again before pushing.
5. Commit. Say in the message which upstream version this tracks.
6. On merge, `publish-docker-images.yml` builds amd64+arm64, smoke-tests, pushes both
   variants, signs each pushed digest with cosign keylessly, attaches a provenance
   attestation, and cuts a GitHub release.

## Prefer the automation

`auto-check-new-releases.yml` runs daily: it reads the upstream version, validates it, and
commits. A manual release is for pinning a specific version — use `manual-release.yml`
(workflow_dispatch) rather than hand-editing, since it validates the input the same way.

## Verifying afterwards

```shell
cosign verify docker.io/dockerha08/strapi:alpine-<version> \
  --certificate-identity-regexp '^https://github.com/mainman94/docker-strapi/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```
