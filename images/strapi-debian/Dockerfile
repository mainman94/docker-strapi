# BASE
ARG NODE_VERSION=24
ARG STRAPI_VERSION=5.52.2

# Build stage: install CLI only
FROM node:${NODE_VERSION}-trixie-slim AS builder
ARG STRAPI_VERSION

RUN npm install -g --force yarn @strapi/strapi@${STRAPI_VERSION}

# Production stage: copy CLI, install build deps
FROM node:${NODE_VERSION}-trixie-slim
ARG STRAPI_VERSION
ENV STRAPI_VERSION=${STRAPI_VERSION}

# Install build deps for npm install to work in mounted projects
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++ make python3 && \
    rm -rf /tmp/* /var/tmp/*

# Copy npm packages from builder
COPY --from=builder /usr/local /usr/local

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
