# BASE
ARG NODE_VERSION=24
ARG STRAPI_VERSION=5.52.2

FROM node:${NODE_VERSION}-alpine
ARG NODE_VERSION
ARG STRAPI_VERSION
ARG VCS_REF=unknown
ARG BUILD_DATE
ENV STRAPI_VERSION=${STRAPI_VERSION}

LABEL org.opencontainers.image.title="Strapi (Alpine)" \
      org.opencontainers.image.description="Strapi v5 on Alpine — creates a new project on first boot or runs an existing one mounted at /srv/app." \
      org.opencontainers.image.version="${STRAPI_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.url="https://hub.docker.com/r/dockerha08/strapi" \
      org.opencontainers.image.source="https://github.com/mainman94/docker-strapi" \
      org.opencontainers.image.documentation="https://github.com/mainman94/docker-strapi/blob/main/images/strapi-alpine/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="mainman94" \
      org.opencontainers.image.base.name="docker.io/library/node:${NODE_VERSION}-alpine"

# Patch OS packages (CVE hygiene)
RUN apk upgrade --no-cache

# Patch npm's bundled deps (CVE hygiene: npm vendors these below its fix
# versions — bump the global npm, then drop in fixed tarballs over its
# vendored copies; `npm install` inside npm's own tree would instead try to
# reconcile npm's whole internal workspace and fail).
RUN npm install -g npm@latest && \
    NPM_DIR="$(npm root -g)/npm/node_modules" && \
    TMP="$(mktemp -d)" && \
    npm pack --pack-destination "${TMP:?}" \
      undici@^6.28.0 tar@^7.5.21 ip-address@^10.3.1 brace-expansion@^5.0.9 && \
    for pkg in undici tar ip-address brace-expansion; do \
      rm -rf "${NPM_DIR:?}/$pkg" && mkdir -p "${NPM_DIR:?}/$pkg" && \
      tar -xzf "$TMP/$pkg"-*.tgz -C "${NPM_DIR:?}/$pkg" --strip-components=1 ; \
    done && \
    rm -rf "${TMP:?}"

EXPOSE 1337

RUN addgroup -S appuser && adduser -S -G appuser appuser && \
    mkdir -p /srv/app && chown appuser:appuser -R /srv/app

WORKDIR /srv/app
VOLUME /srv/app

COPY --chown=appuser:appuser docker-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

USER appuser

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["strapi"]
