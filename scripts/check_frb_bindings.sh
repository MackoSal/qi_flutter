#!/usr/bin/env bash
# Regenerates the flutter_rust_bridge bindings and fails when the result differs
# from the git index: modified, new (untracked), or stale generated files.
#
# The generated Dart API directory is removed before codegen because FRB does
# not delete the Dart file of a removed Rust module. The regenerated bindings
# stay in the working tree, so after a failure `git add` the listed paths.
#
# Exit codes: 0 up to date, 1 bindings differ, 2 codegen failed.
# Used by .githooks/pre-commit and the frb-codegen-check CI job.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

# CI containers check out the repository as a different user.
g() { git -c safe.directory="$root" "$@"; }

api_dir="app/flutter/lib/src/rust/api"
generated=(
  "$api_dir"
  app/flutter/lib/src/rust/frb_generated.dart
  app/flutter/lib/src/rust/frb_generated.io.dart
  app/flutter/lib/src/rust/frb_generated.web.dart
  rust/crates/qi_gateway/src/frb_generated.rs
)

backup="$(mktemp -d)"
trap 'rm -rf "$backup"' EXIT
if [ -d "$api_dir" ]; then
  cp -a "$api_dir" "$backup/api"
  rm -rf "$api_dir"
fi

if ! (cd app/flutter && flutter_rust_bridge_codegen generate); then
  rm -rf "$api_dir"
  if [ -d "$backup/api" ]; then
    cp -a "$backup/api" "$api_dir"
  fi
  echo "FRB codegen failed; the generated API directory was restored." >&2
  exit 2
fi

modified="$(g diff --ignore-all-space --ignore-blank-lines --diff-filter=d --name-only -- "${generated[@]}")"
untracked="$(g ls-files --others --exclude-standard -- "${generated[@]}")"
deleted="$(g ls-files --deleted -- "${generated[@]}")"

if [ -z "$modified$untracked$deleted" ]; then
  echo "FRB bindings are up to date."
  exit 0
fi

report() {
  local title="$1" files="$2"
  if [ -n "$files" ]; then
    echo "$title:" >&2
    while IFS= read -r file; do
      echo "  $file" >&2
      if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
        echo "::error file=$file,title=Stale FRB bindings::$title: $file"
      fi
    done <<< "$files"
  fi
}

echo "FRB bindings differ from the staged files." >&2
report "Changed by codegen or not staged" "$modified"
report "Generated but not tracked" "$untracked"
report "Stale, no longer generated" "$deleted"
echo "The regenerated bindings are in the working tree. Review them and stage the" >&2
echo "result: git add -A ${generated[*]}" >&2
exit 1
