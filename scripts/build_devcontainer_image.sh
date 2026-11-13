#!/usr/bin/env bash
# Builds the Dev Container toolchain image from .devcontainer/Dockerfile as
# `devcontainer:test` and checks that the expected tools are inside it.
# Changes no repository files; it only creates a local Docker image.
#
# Usage: bash scripts/build_devcontainer_image.sh
# Exit code: 0 image built and tools found, non-zero otherwise.
#
# Used by .github/workflows/publish-devcontainer.yml; publish the image with
# scripts/publish_devcontainer_image.sh.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

docker build --file .devcontainer/Dockerfile --tag devcontainer:test .
docker run --rm devcontainer:test bash -lc '
  flutter --version --machine >/tmp/flutter-version.json &&
  rustc --version &&
  flutter_rust_bridge_codegen --version &&
  cargo audit --version &&
  java -version &&
  sdkmanager --version &&
  test -d "$ANDROID_HOME/ndk/28.2.13676358" &&
  test -d "$ANDROID_HOME/platforms/android-36"
'
