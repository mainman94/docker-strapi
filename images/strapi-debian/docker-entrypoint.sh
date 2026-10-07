#!/bin/sh
set -ea

if [ "$*" = "strapi" ]; then

  # Both variants run unprivileged. A volume populated by an older image that
  # ran as root is not writable any more; say so instead of failing halfway
  # through an install with a bare EACCES.
  if [ ! -w . ] || { [ -e package.json ] && [ ! -w package.json ]; }; then
    echo "error: /srv/app is not writable by uid $(id -u) (gid $(id -g))." >&2
    echo "The image runs as an unprivileged user. Hand the volume over once:" >&2
    echo "  docker run --rm -v <volume>:/srv/app alpine chown -R $(id -u):$(id -g) /srv/app" >&2
    exit 1
  fi

  if [ ! -f "package.json" ]; then

    DATABASE_CLIENT=${DATABASE_CLIENT:-sqlite}
    EXTRA_ARGS=${EXTRA_ARGS}

    echo "Using strapi v$STRAPI_VERSION"
    echo "No project found at /srv/app. Creating a new strapi project ..."

    DOCKER=true npx create-strapi-app@${STRAPI_VERSION} . --no-run --skip-cloud --non-interactive \
      --dbclient="$DATABASE_CLIENT" \
      --dbhost="$DATABASE_HOST" \
      --dbport="$DATABASE_PORT" \
      --dbname="$DATABASE_NAME" \
      --dbusername="$DATABASE_USERNAME" \
      --dbpassword="$DATABASE_PASSWORD" \
      --dbssl="$DATABASE_SSL" \
      $EXTRA_ARGS

    # create-strapi-app writes DATABASE_FILENAME= (empty) into .env
    # regardless of DB client. Strapi's env() helper treats an explicitly
    # empty var as set, so the sqlite default (.tmp/data.db) never applies
    # and better-sqlite3 fails with a bare "unable to open database file".
    sed -i '/^DATABASE_FILENAME=$/d' .env

    # Recent npm blocks install/postinstall scripts by default, so
    # better-sqlite3's native binding (fetched via prebuild-install) never
    # gets installed and sqlite fails with a bare "unable to open database
    # file" at startup. Approve exactly that package and rebuild it, right
    # after scaffolding. Approving --all would hand every transitive
    # dependency the install-script access npm now withholds by default.
    # With a non-sqlite client better-sqlite3 is absent and both are no-ops.
    npm install-scripts approve better-sqlite3 2>/dev/null || true
    npm rebuild better-sqlite3 2>/dev/null || true

  elif [ ! -d "node_modules" ] || [ ! "$(ls -qAL node_modules 2>/dev/null)" ]; then

    if [ -f "yarn.lock" ]; then

      echo "Node modules not installed. Installing using yarn ..."
      yarn install --prod || { echo "Yarn install failed"; exit 1; }

    else

      echo "Node modules not installed. Installing using npm ..."
      npm install --omit=dev || { echo "NPM install failed"; exit 1; }

    fi

  fi

  if [ "$NODE_ENV" = "production" ]; then
    STRAPI_MODE="start"

    if [ ! -f "dist/build/index.html" ]; then
      echo "Admin panel build not found. Building with a ${STRAPI_BUILD_MAX_OLD_SPACE_SIZE:-2048} MB Node.js heap ..."
      NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--max-old-space-size=${STRAPI_BUILD_MAX_OLD_SPACE_SIZE:-2048}" \
        npm run build || { echo "Admin panel build failed"; exit 1; }
    fi
  elif [ "$NODE_ENV" = "development" ]; then
    STRAPI_MODE="develop"
  fi

  mkdir -p .tmp

  echo "Starting your app (with ${STRAPI_MODE:-develop})..."
  exec ./node_modules/.bin/strapi "${STRAPI_MODE:-develop}"

else
  exec "$@"
fi
