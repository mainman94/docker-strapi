#!/bin/sh
set -ea

if [ "$*" = "strapi" ]; then

  if [ ! -f "package.json" ]; then

    DATABASE_CLIENT=${DATABASE_CLIENT:-sqlite}
    EXTRA_ARGS=${EXTRA_ARGS}

    echo "Using strapi v$STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."

    if [ "${STRAPI_VERSION#5}" != "$STRAPI_VERSION" ]; then
      DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run --skip-cloud --non-interactive \
        --dbclient=$DATABASE_CLIENT \
        --dbhost=$DATABASE_HOST \
        --dbport=$DATABASE_PORT \
        --dbname=$DATABASE_NAME \
        --dbusername=$DATABASE_USERNAME \
        --dbpassword=$DATABASE_PASSWORD \
        --dbssl=$DATABASE_SSL \
        $EXTRA_ARGS
    else
      DOCKER=true strapi new . --no-run \
        --dbclient=$DATABASE_CLIENT \
        --dbhost=$DATABASE_HOST \
        --dbport=$DATABASE_PORT \
        --dbname=$DATABASE_NAME \
        --dbusername=$DATABASE_USERNAME \
        --dbpassword=$DATABASE_PASSWORD \
        --dbssl=$DATABASE_SSL \
        $EXTRA_ARGS
    fi

    # create-strapi-app writes DATABASE_FILENAME= (empty) into .env
    # regardless of DB client. Strapi's env() helper treats an explicitly
    # empty var as set, so the sqlite default (.tmp/data.db) never applies
    # and better-sqlite3 fails with a bare "unable to open database file".
    sed -i '/^DATABASE_FILENAME=$/d' .env

    # Recent npm blocks install/postinstall scripts by default, so
    # better-sqlite3's native binding (fetched via prebuild-install) never
    # gets installed and sqlite fails with a bare "unable to open database
    # file" at startup. Approve and rebuild once, right after scaffolding.
    npm install-scripts approve --all 2>/dev/null || true
    npm rebuild 2>/dev/null || true

  elif [ ! -d "node_modules" ] || [ ! "$(ls -qAL node_modules 2>/dev/null)" ]; then

    if [ -f "yarn.lock" ]; then

      echo "Node modules not installed. Installing using yarn ..."
      yarn install --prod || { echo "Yarn install failed"; exit 1; }

    else

      echo "Node modules not installed. Installing using npm ..."
      npm install --only=prod || { echo "NPM install failed"; exit 1; }

    fi

  fi

  if [ "$NODE_ENV" = "production" ]; then
    STRAPI_MODE="start"
  elif [ "$NODE_ENV" = "development" ]; then
    STRAPI_MODE="develop"
  fi

  mkdir -p .tmp

  echo "Starting your app (with ${STRAPI_MODE:-develop})..."
  exec ./node_modules/.bin/strapi "${STRAPI_MODE:-develop}"

else
  exec "$@"
fi