#!/usr/bin/env bash
# Provision the dev container. The toolchain is pinned in mise.toml — python,
# pre-commit, shellcheck, actionlint, trivy — so this installs mise, lets it
# do the rest, then wires up the git hook with its environments warmed so the
# first commit is not a long wait. CI installs from the same file.
set -euo pipefail

echo "==> installing mise"
curl -fsSL https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Activate for interactive shells so the pinned binaries are on PATH.
for shell in bash zsh; do
  rc="$HOME/.${shell}rc"
  [ -f "$rc" ] || continue
  grep -q "mise activate" "$rc" || echo "eval \"\$(mise activate $shell)\"" >> "$rc"
done

echo "==> installing the pinned toolchain (python, pre-commit, shellcheck, actionlint, trivy)"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mise trust
mise install

echo "==> installing the git hook"
mise exec -- pre-commit install

echo "==> warming hook environments (downloads hadolint, shfmt, yamlfmt, gitleaks)"
mise exec -- pre-commit install-hooks

cat <<'MSG'

docker-strapi dev container ready.

  make help                    list every target
  make check                   lint, build both variants, smoke both
  make build VARIANT=alpine    one variant
  make versions                what release-versions/ currently pins

Tool versions come from mise.toml — the same file CI installs from.

A build pulls node and installs Strapi, so the first one takes a few minutes.
MSG
