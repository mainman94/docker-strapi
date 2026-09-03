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
