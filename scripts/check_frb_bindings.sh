#!/usr/bin/env bash
# Checks that the FRB bindings in the repository match the Rust API.
#
# The bindings are the files flutter_rust_bridge_codegen generates from
# rust/crates/qi_gateway/src/api/:
#   app/flutter/lib/src/rust/                     Dart side
#   rust/crates/qi_gateway/src/frb_generated.rs   Rust side
#
# This script only checks. It never changes files in the repository.
#
# How it works:
#   1. Copies the sources the generator needs into
#      scripts/check-frb-bindings-tmp/: rust/ without target/, plus the FRB and
#      pub configuration files of app/flutter/. The copy contains no bindings,
#      so the generator writes all of them from scratch.
#   2. Runs flutter_rust_bridge_codegen generate inside that copy.
#   3. Compares the fresh bindings with the ones in the repository (whitespace
#      is ignored) and prints the differences.
#
# Result:
#   exit 0  Bindings are up to date. The temporary directory is removed.
#   exit 1  Bindings differ. The diff is printed, and the fresh bindings stay in
#           scripts/check-frb-bindings-tmp/ for review.
#   exit 2  The generator failed, for example because of a Rust syntax error.
#
# Fix after exit 1: run `flutter_rust_bridge_codegen generate` in app/flutter/,
# `git rm` the files the diff marks with D, and commit the result.
#
# Called by scripts/check_frb.sh, which the pre-commit hook and CI run.
# See scripts/README.md.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# CI containers check out the repository as a different user.
g() { git -c safe.directory="$root" "$@"; }

tmp="scripts/check-frb-bindings-tmp"
dart_bindings="app/flutter/lib/src/rust"
rust_bindings="rust/crates/qi_gateway/src/frb_generated.rs"
app_config=(
  app/flutter/flutter_rust_bridge.yaml
  app/flutter/pubspec.yaml
  app/flutter/pubspec.lock
  app/flutter/analysis_options.yaml
)

# 1. Copy the sources: Rust files known to git (tracked or new, not ignored)
#    and the app configuration. Never copy the bindings themselves.
rm -rf "$tmp"
mkdir -p "$tmp"
while IFS= read -r -d '' file; do
  if [ -f "$file" ]; then
    mkdir -p "$tmp/$(dirname "$file")"
    cp "$file" "$tmp/$file"
  fi
done < <(g ls-files -z --cached --others --exclude-standard -- rust)
for file in "${app_config[@]}"; do
  mkdir -p "$tmp/$(dirname "$file")"
  cp "$file" "$tmp/$file"
done
rm -f "$tmp/$rust_bindings"

# 2. Generate fresh bindings in the copy. Reuse the repository's Cargo build
#    cache so the generator does not compile every dependency again.
if ! (cd "$tmp/app/flutter" &&
  CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$root/rust/target}" \
    flutter_rust_bridge_codegen generate); then
  echo "FRB codegen failed; see the output above. Nothing in the repository was changed." >&2
  exit 2
fi

# 3. Compare the repository bindings (a/) with the fresh ones (b/).
compare() {
  local status=0
  g diff --no-index --ignore-all-space --ignore-blank-lines "$@" -- \
    "$dart_bindings" "$tmp/$dart_bindings" || status=1
  g diff --no-index --ignore-all-space --ignore-blank-lines "$@" -- \
    "$rust_bindings" "$tmp/$rust_bindings" || status=1
  return "$status"
}

if compare --quiet; then
  rm -rf "$tmp"
  echo "FRB bindings are up to date."
  exit 0
fi

{
  echo "FRB bindings in the repository are out of date with the Rust API in"
  echo "rust/crates/qi_gateway/src/api/. Differences (a/ = repository, b/ = fresh):"
  echo
  compare --name-status || true
  echo
  compare || true
  echo
  echo "The fresh bindings are in $tmp/ for review."
  echo "To update the repository, run in app/flutter/: flutter_rust_bridge_codegen generate"
  echo "Files marked D are no longer generated; delete them with git rm."
} >&2

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  compare --name-only 2>/dev/null | sed "s#^$tmp/##" | sort -u |
    while IFS= read -r file; do
      echo "::error file=$file,title=FRB bindings out of date::$file differs from freshly generated bindings"
    done || true
fi
exit 1
