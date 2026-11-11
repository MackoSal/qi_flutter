#!/usr/bin/env bash
# Runs all checks of the Flutter <-> Rust (FRB) boundary, in this order:
#   1. scripts/check_frb_bindings.sh       bindings match the Rust API       error
#   2. flutter analyze                     app code compiles against them    error
#   3. flutter test                        app tests pass                    error
#   4. tool/check_frb_api_usage.dart       app uses every exposed function   warning
# Every step runs even when an earlier one fails, so one run shows all
# problems. Only checks; never changes files.
#
# Exit code: 0 all passed, 1 at least one error, 3 only warnings (step 4).
# --allow-warnings: exit 0 instead of 3. CI uses it; the warnings stay visible
# there as annotations.
#
# Used by .githooks/pre-commit and the flutter-checks CI job.

set -uo pipefail

allow_warnings=false
if [ "${1:-}" = "--allow-warnings" ]; then
  allow_warnings=true
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

errors=()
warnings=()

echo "== 1/4 FRB bindings match the Rust API"
bash scripts/check_frb_bindings.sh || errors+=("FRB bindings out of date (step 1)")

echo "== 2/4 flutter analyze"
(cd app/flutter && flutter analyze) || errors+=("flutter analyze (step 2)")

echo "== 3/4 flutter test"
(cd app/flutter && flutter test) || errors+=("flutter test (step 3)")

echo "== 4/4 FRB API usage"
usage_status=0
(cd app/flutter && dart run tool/check_frb_api_usage.dart) || usage_status=$?
case "$usage_status" in
  0) ;;
  1) warnings+=("unused FRB API functions (step 4)") ;;
  *) errors+=("FRB API usage check failed to run (step 4)") ;;
esac

echo
for problem in "${errors[@]}"; do
  echo "ERROR: $problem" >&2
done
for problem in "${warnings[@]}"; do
  echo "WARNING: $problem" >&2
done

if [ "${#errors[@]}" -gt 0 ]; then
  exit 1
fi
if [ "${#warnings[@]}" -gt 0 ]; then
  [ "$allow_warnings" = true ] && exit 0
  exit 3
fi
echo "All FRB checks passed."
