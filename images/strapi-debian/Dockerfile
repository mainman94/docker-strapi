# check=skip=InvalidDefaultArgInFrom
# BASE
ARG NODE_VERSION=24
# The base image is pinned by digest. There is deliberately no default: the
# build passes release-versions/node-debian-digest.txt, and a build without it
# fails instead of silently floating on the tag.
ARG NODE_DIGEST
ARG STRAPI_VERSION=5.52.2

FROM node:${NODE_VERSION}-trixie-slim@${NODE_DIGEST}
ARG NODE_VERSION
ARG NODE_DIGEST
ARG STRAPI_VERSION
ARG VCS_REF=unknown
ARG BUILD_DATE
ENV STRAPI_VERSION=${STRAPI_VERSION}

LABEL org.opencontainers.image.title="Strapi (Debian slim)" \
      org.opencontainers.image.description="Strapi v5 on Debian slim — creates a new project on first boot or runs an existing one mounted at /srv/app." \
      org.opencontainers.image.version="${STRAPI_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.url="https://hub.docker.com/r/dockerha08/strapi" \
      org.opencontainers.image.source="https://github.com/mainman94/docker-strapi" \
      org.opencontainers.image.documentation="https://github.com/mainman94/docker-strapi/blob/main/images/strapi-debian/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="mainman94" \
      org.opencontainers.image.base.name="docker.io/library/node:${NODE_VERSION}-trixie-slim" \
      org.opencontainers.image.base.digest="${NODE_DIGEST}"

# Patch OS packages (CVE hygiene). No compiler toolchain: native modules come
# from prebuilt binaries, same as the Alpine variant.
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Patch npm's bundled deps (CVE hygiene: npm vendors these below their fix
# versions — pin npm, then drop fixed tarballs over its vendored copies;
# `npm install` inside npm's own tree would instead try to reconcile npm's
# whole internal workspace and fail). Every version is exact, so a rebuild
# installs what was reviewed rather than whatever the registry serves that
# day. Renovate bumps both lines (see renovate.json).
# renovate: datasource=npm depName=npm
ARG NPM_VERSION=12.2.0
ARG NPM_PATCHES="undici@6.29.0 tar@7.5.22 ip-address@10.7.3 brace-expansion@5.0.12 postcss-selector-parser@7.1.6"
RUN npm install -g "npm@${NPM_VERSION}" && \
    NPM_DIR="$(npm root -g)/npm/node_modules" && \
    TMP="$(mktemp -d)" && \
    for spec in ${NPM_PATCHES}; do \
      pkg="${spec%@*}" && \
      npm pack --pack-destination "${TMP:?}" "$spec" && \
      rm -rf "${NPM_DIR:?}/$pkg" && mkdir -p "${NPM_DIR:?}/$pkg" && \
      tar -xzf "$TMP/$pkg"-*.tgz -C "${NPM_DIR:?}/$pkg" --strip-components=1 ; \
    done && \
    rm -rf "${TMP:?}"

# Clean cache
RUN yarn cache clean && npm cache clean --force && rm -rf /usr/local/share/.cache

EXPOSE 1337

RUN mkdir -p /srv/app && chown 1000:1000 -R /srv/app

WORKDIR /srv/app
VOLUME /srv/app

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

# The node base image ships an unprivileged `node` user (uid 1000), which owns
# /srv/app above. Strapi is a network-facing service; it does not run as root.
USER node

# Strapi answers /_health with 204 once it is up. The long start period
# covers the first boot, which scaffolds a project and builds the admin panel.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10m --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:1337/_health').then(r => process.exit(r.ok ? 0 : 1), () => process.exit(1))"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["strapi"]
