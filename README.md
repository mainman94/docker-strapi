# strapi containerized

> Docker images for Strapi v5, fork of [naskio/docker-strapi](https://github.com/naskio/docker-strapi)

API creation made simple, secure and fast. The most advanced open-source Content Management Framework to build powerful
API with no effort.

[GitHub repository](https://github.com/mainman94/docker-strapi)

[Docker Hub](https://hub.docker.com/r/dockerha08/strapi)

Two variants: `images/strapi-alpine` (published as `dockerha08/strapi:alpine-<version>` /
`alpine-latest`) and `images/strapi-debian` (published as `dockerha08/strapi:debian-slim-<version>`
/ `debian-slim-latest`). See each variant's own README for specifics.

---

# Example

Using Docker Compose, create `docker-compose.yml` file with the following content:

```yaml
services:
  strapi:
    image: dockerha08/strapi:alpine-latest
    environment:
      NODE_ENV: development # or production
    ports:
      - "1337:1337"
    # volumes:
    #   - ./app:/srv/app # mount an existing strapi project
```

or using Docker:

```shell
docker run -d -p 1337:1337 -e NODE_ENV=development dockerha08/strapi:alpine-latest
```

---

# How to use ?

This image allows you to create a new strapi project or run an existing strapi project.

- for `$NODE_ENV = development`: The command that will run in your project
  is [`strapi develop`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-develop).
- for `$NODE_ENV = production`: The command that will run in your project
  is [`strapi start`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-start).

> The [Content-Type Builder](https://strapi.io/features/content-types-builder) plugin is disabled WHEN `$NODE_ENV = production`.

## Creating a new strapi project

When running this image, strapi will check if there is a project in the `/srv/app` folder of the container. If there is
nothing then it will run
[`create-strapi-app`](https://docs.strapi.io/dev-docs/cli#strapi-new) (v5) or
[`strapi new`](https://docs.strapi.io/developer-docs/latest/developer-resources/cli/CLI.html#strapi-new) (pre-v5)
in the container's `/srv/app` folder.

This command creates a project with an SQLite database by default. Then starts it on port `1337`.

**Environment variables**

When creating a new project with this image you can pass database configuration via these environment variables:

- `DATABASE_CLIENT` a database provider supported by Strapi: `sqlite`, `postgres`, or `mysql`.
- `DATABASE_HOST` database host.
- `DATABASE_PORT` database port.
- `DATABASE_NAME` database name.
- `DATABASE_USERNAME` database username.
- `DATABASE_PASSWORD` database password.
- `DATABASE_SSL` boolean for SSL.
- `EXTRA_ARGS` pass extra args to
  the [`strapi new`](https://strapi.io/documentation/developer-docs/latest/developer-resources/cli/CLI.html#strapi-new).

## Running an existing strapi project

To run an existing project, you can mount the project folder in the container at `/srv/app`.

---

# Recommended way to deploy an existing strapi project to production using Docker

To deploy an existing strapi project to production using Docker, it is recommended to build an image for your project
based on [node v24](https://hub.docker.com/_/node).

Example of Dockerfile:

```dockerfile
FROM node:24
# alternatively you can use FROM strapi/base:latest

# Set up working directory
WORKDIR /app

# Copy package.json to root directory
COPY package.json .

# Copy yarn.lock to root directory
COPY yarn.lock .

# Install dependencies, but not generate a yarn.lock file and fail if an update is needed
RUN yarn install --frozen-lockfile

# Copy strapi project files
COPY favicon.ico ./favicon.ico
COPY src/ src/
COPY public/ public/
COPY database/ database/
COPY config/ config/
# ...

# Build admin panel
RUN yarn build

# Run on port 1337
EXPOSE 1337

# Start strapi server
CMD ["yarn", "start"]
```

# Official Documentation

- The official documentation of strapi is available on [https://docs.strapi.io/](https://docs.strapi.io/).

- The official strapi docker image is available on [GitHub](https://github.com/strapi/strapi-docker) (not yet upgraded
  to v4).
