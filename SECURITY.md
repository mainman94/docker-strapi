# Security Policy

## Supported versions

Only the most recently published tags are supported:
`alpine-latest`, `debian-slim-latest` and the matching
`alpine-<strapi-version>` / `debian-slim-<strapi-version>` tags. Older
version tags stay on Docker Hub but receive no fixes.

Images are rebuilt whenever the upstream Strapi release or the pinned
`node:24` base image digest changes, so `-latest` carries current base-image
patches.

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

- The alpine variant runs as the non-root user `appuser`; the debian variant
  runs as root by design. Prefer alpine, or override with `--user`.
- These images scaffold a project on first boot and run `strapi develop` by
  default. For production, build your own image from your project (see the
  root README) rather than shipping a bind-mounted scaffold.
- Published images carry SBOM and max-mode provenance attestations.
