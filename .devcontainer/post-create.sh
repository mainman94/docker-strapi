#!/usr/bin/env bash
# Provision the dev container: pre-commit plus the git hook, with the hook
# environments warmed so the first commit is not a long wait.
set -euo pipefail

echo "==> installing pre-commit"
pipx install pre-commit 2>/dev/null || pip install --user --break-system-packages pre-commit
export PATH="$HOME/.local/bin:$PATH"

echo "==> installing the git hook"
pre-commit install

echo "==> warming hook environments (downloads hadolint, shellcheck, shfmt, yamlfmt, gitleaks)"
pre-commit install-hooks

cat <<'MSG'

docker-strapi dev container ready.

  make help                    list every target
  make check                   lint, build both variants, smoke both
  make build VARIANT=alpine    one variant
  make versions                what release-versions/ currently pins

A build pulls node and installs Strapi, so the first one takes a few minutes.
MSG
