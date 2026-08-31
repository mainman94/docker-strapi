# BASE
ARG NODE_VERSION=24
ARG STRAPI_VERSION=5.52.2

# Build stage: install CLI with build deps
FROM node:${NODE_VERSION}-alpine AS builder
ARG STRAPI_VERSION

RUN apk add --no-cache python3 make g++ && \
    npm install -g --force yarn @strapi/strapi@${STRAPI_VERSION}

# Production stage: copy only what's needed
FROM node:${NODE_VERSION}-alpine
ARG STRAPI_VERSION
ENV STRAPI_VERSION=${STRAPI_VERSION}

# Copy entire /usr/local from builder (preserves symlinks)
COPY --from=builder /usr/local /usr/local

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
