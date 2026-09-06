#!/usr/bin/env bash
# PostToolUse: a write under release-versions/ is what triggers a publish to
# Docker Hub — the format is checked before the commit hook gets a chance, so
# a malformed value cannot sit in the worktree unnoticed.
#
# Prints to stderr (visible to Claude) and always exits 0: this is a warning
# about a real consequence, not a veto on a legitimate edit.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0
case "$f" in
  *release-versions/*) ;;
  *) exit 0 ;;
esac
root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null) || exit 0
if ! out=$(cd "$root" && scripts/check-release-versions.sh 2>&1); then
  echo "release-versions is malformed — a commit here publishes an image:" >&2
  echo "$out" >&2
else
  echo "Note: release-versions/ changed. Pushing this to main triggers publish-docker-images.yml." >&2
fi
exit 0
