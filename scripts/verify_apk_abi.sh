#!/usr/bin/env bash
# Checks that an APK contains native libraries for exactly the expected
# Android ABIs (for example arm64-v8a). Only checks; never changes files.
#
# Usage: bash scripts/verify_apk_abi.sh <apk> <abi> [<abi> ...]
# Exit code: 0 the ABIs match, 1 they differ or the APK is missing.
#
# Used by the Android job of .github/workflows/manual-build.yml.

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: bash scripts/verify_apk_abi.sh <apk> <abi> [<abi> ...]" >&2
  exit 1
fi

apk="$1"
shift
if [ ! -f "$apk" ]; then
  echo "APK not found: $apk" >&2
  exit 1
fi

actual="$(unzip -Z1 "$apk" | sed -n 's#^lib/\([^/]*\)/.*#\1#p' | sort -u | tr '\n' ' ')"
expected="$(printf '%s\n' "$@" | sort -u | tr '\n' ' ')"

if [ "$actual" != "$expected" ]; then
  echo "APK ABIs: ${actual:-none}; expected: $expected" >&2
  exit 1
fi
echo "Verified APK ABIs: $actual"
