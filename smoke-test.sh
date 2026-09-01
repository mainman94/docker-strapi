#!/bin/sh
# Boots a built image with sqlite, waits for a clean start or a known
# failure signature for up to three minutes, then tears down.
# Usage: ./smoke-test.sh <image-tag>
set -eu

image="$1"
name="strapi-smoke-$$"
cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$name" \
  -e DATABASE_CLIENT=sqlite \
  -e NODE_ENV=production \
  "$image" >/dev/null

for _ in $(seq 1 90); do
  logs=$(docker logs "$name" 2>&1)
  if echo "$logs" | grep -qE "Strapi started successfully|Welcome back"; then
    if ! docker exec "$name" test -f /srv/app/dist/build/index.html; then
      echo "smoke test failed: production admin panel was not built"
      echo "$logs"
      exit 1
    fi
    echo "smoke test passed"
    exit 0
  fi
  if echo "$logs" | grep -qE "EACCES|Cannot find module|npm error|ERROR"; then
    echo "smoke test failed:"
    echo "$logs"
    exit 1
  fi
  sleep 2
done

echo "smoke test timed out, logs:"
docker logs "$name" 2>&1
exit 1
