# BASE
ARG NODE_VERSION=24
ARG STRAPI_VERSION=5.52.2

FROM node:${NODE_VERSION}-trixie-slim
ARG NODE_VERSION
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
      org.opencontainers.image.base.name="docker.io/library/node:${NODE_VERSION}-trixie-slim"

# Patch OS packages (CVE hygiene). No compiler toolchain: native modules come
# from prebuilt binaries, same as the Alpine variant.
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clean cache
RUN yarn cache clean && npm cache clean --force && rm -rf /usr/local/share/.cache

EXPOSE 1337

RUN mkdir -p /srv/app && chown 1000:1000 -R /srv/app

WORKDIR /srv/app
VOLUME /srv/app

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["strapi"]
