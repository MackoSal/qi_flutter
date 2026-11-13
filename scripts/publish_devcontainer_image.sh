#!/usr/bin/env bash
# Publishes the image built by scripts/build_devcontainer_image.sh to GHCR as
# ghcr.io/<owner>/<repo>-devcontainer with the tags `1` and the commit SHA.
# Requires `docker login ghcr.io` first. Changes no repository files.
#
# Usage: bash scripts/publish_devcontainer_image.sh <owner/repo> <commit-sha>
# Exit code: 0 both tags pushed, non-zero otherwise.
#
# Used by .github/workflows/publish-devcontainer.yml.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: bash scripts/publish_devcontainer_image.sh <owner/repo> <commit-sha>" >&2
  exit 1
fi

repository="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
image="ghcr.io/${repository}-devcontainer"

for tag in 1 "$2"; do
  docker tag devcontainer:test "$image:$tag"
  docker push "$image:$tag"
done
