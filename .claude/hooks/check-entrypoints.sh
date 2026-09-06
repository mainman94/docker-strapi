#!/usr/bin/env bash
# PostToolUse: the two docker-entrypoint.sh files are byte-identical on
# purpose. A fix applied to one and not the other is a silent behaviour split
# between published tags — the kind of thing nobody notices until an image
# behaves differently from its sibling.
#
# Warns rather than copies: which direction the fix should travel is the
# author's call.
set -uo pipefail
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0
case "$f" in
  *docker-entrypoint.sh) ;;
  *) exit 0 ;;
esac
root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null) || exit 0
a="$root/images/strapi-alpine/docker-entrypoint.sh"
b="$root/images/strapi-debian/docker-entrypoint.sh"
[ -f "$a" ] && [ -f "$b" ] || exit 0
if ! diff -q "$a" "$b" >/dev/null 2>&1; then
  echo "The two entrypoints have diverged. Copy the fix across before committing:" >&2
  echo "  cp $a $root/images/strapi-debian/" >&2
  diff "$a" "$b" | head -20 >&2
fi
exit 0
