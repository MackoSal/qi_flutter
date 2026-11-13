#!/usr/bin/env bash
# Decides whether a release tag builds a given target, and prints `true` or
# `false`. A tag ending in `-a` builds only Android, a tag ending in `-l` only
# Linux, and any other tag builds both. Only checks; never changes files.
#
# Usage: bash scripts/release_should_build.sh <linux|android> <tag>
# Example: bash scripts/release_should_build.sh android 1.2.0-a   # prints true
#
# Used by the build-and-release job of .github/workflows/ci-cd.yml.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: bash scripts/release_should_build.sh <linux|android> <tag>" >&2
  exit 1
fi

target="$1"
tag="$2"

if [[ "$tag" == *-a && "$target" != "android" ]] ||
  [[ "$tag" == *-l && "$target" != "linux" ]]; then
  echo false
else
  echo true
fi
