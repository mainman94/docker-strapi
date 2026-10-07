# Security Policy

## Supported versions

Only the most recently published tags are supported:
`alpine-latest`, `debian-slim-latest` and the matching
`alpine-<strapi-version>` / `debian-slim-<strapi-version>` tags. Older
version tags stay on Docker Hub but receive no fixes.

Images are rebuilt whenever the upstream Strapi release or the pinned
`node:24` base image digest changes, so `-latest` and the version tags carry
current base-image patches. Each rebuild also gets an immutable
`-<strapi-version>-r<run>` tag.

## Reporting a vulnerability

Report privately via GitHub's
[security advisories](https://github.com/mainman94/docker-strapi/security/advisories/new).
Please do not open a public issue for anything exploitable.

Expect an acknowledgement within a few days. Include the image tag, digest
(`docker inspect --format '{{index .RepoDigests 0}}' <image>`) and steps to
reproduce.

Vulnerabilities in Strapi itself belong to
[strapi/strapi](https://github.com/strapi/strapi/security); ones in the Node.js
base image to [nodejs/docker-node](https://github.com/nodejs/docker-node).
Report here only what these images add on top: the Dockerfiles, the
entrypoint, and the published tags.

## Hardening notes

- Both variants run unprivileged: alpine as `appuser` (uid 100), debian-slim
  as `node` (uid 1000).
- The base image is pinned by digest, and npm plus the dependencies patched
  into it are pinned to exact versions, so a rebuild installs what was
  reviewed.
- On first boot the entrypoint scaffolds a project with
  `create-strapi-app@<version>` from npm. npm withholds install scripts by
  default; the entrypoint approves exactly one package, `better-sqlite3`,
  whose native binding SQLite needs.
- These images scaffold a project on first boot and run `strapi develop` by
  default. For production, build your own image from your project (see the
  root README) rather than shipping a bind-mounted scaffold.
- Published images carry SBOM and max-mode provenance attestations, and are
  signed with cosign keylessly (Sigstore, no long-lived key). Verify before
  you run one:

  ```shell
  cosign verify docker.io/dockerha08/strapi:alpine-latest \
    --certificate-identity https://github.com/mainman94/docker-strapi/.github/workflows/publish-docker-images.yml@refs/heads/main \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com
  ```

  Pin the exact identity, not a prefix: it proves the image was signed by the
  publish workflow on `main`, not by any workflow on any branch of this repo.
