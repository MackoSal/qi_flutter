# scripts

Helper scripts, run from the repository root. Some also run in the pre-commit hook and in CI (`.github/workflows/ci-cd.yml`), but every script must work locally too. A script either changes files on purpose or (mostly) only checks sth. Each script describes itself at the top of the file and is listed here. Tests of the scripts themselves (`tests/`) are run by hand only, never in CI or the pre-commit hook.

| File | Purpose |
| --- | --- |
| `check_frb.sh` | Runs all Flutter ↔ Rust checks: `check_frb_bindings.sh`, `flutter analyze`, `flutter test`, and the unused FRB API check (warning only). Runs in the pre-commit hook and the `flutter-checks` CI job. |
| `check_frb_bindings.sh` | Checks that the committed FRB bindings match the Rust API. Only checks. Called by `check_frb.sh`. |
| `verify_apk_abi.sh` | Checks that an APK contains exactly the expected Android ABIs. Only checks. Used by the Android job of `manual-build.yml`. |
| `rename_project.py` | Renames the template for a new project, see [docs/NEW_PROJECT.md](../docs/NEW_PROJECT.md). |
| `tests/` | Tests for `rename_project.py`. Not automated; run by hand: `python3 -m unittest discover -s scripts/tests -v`. |

Directories that may appear here are ignored by git and safe to delete:

| Directory | Created by |
| --- | --- |
| `check-frb-bindings-tmp/` | `check_frb_bindings.sh`: fresh bindings, kept only when the check fails |
| `__pycache__/` | Python |
