# Testing and platform verification

## Quick local checks

Before committing, run Rust checks from `rust`:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --workspace
```

Check that the committed FRB bindings match the Rust API (from the repository
root):

```bash
bash scripts/check_frb_bindings.sh
```

It removes the generated Dart API directory, regenerates the bindings, and fails
when generated files are changed, untracked, or stale. FRB does not delete the
Dart file of a removed Rust module, so a stale file is reported too. The
regenerated bindings stay in the working tree; stage them with `git add`. The
pre-commit hook and the `frb-codegen-check` CI job run the same script and block
on a failure.

Then run Flutter checks from `app/flutter`:

```bash
dart format --set-exit-if-changed lib/ test/
flutter analyze
dart run tool/check_frb_api_usage.dart
flutter test
```

The FRB API usage check reports endpoints that Rust exposes to Dart and that
application code under `lib/` never references: top-level functions, plus
methods, constructors, and field accessors of generated classes that call into
Rust. It ignores generated files and does not count test-only references. Plain
Dart members of mirrored structs (`==`, `hashCode`, const constructors) and
standalone exported types are not checked.

To keep an unused function or method on purpose, add a marker with a reason to its Rust
doc comment:

```rust
/// frb-api-usage: allow-unused (diagnostics screen, issue #12)
pub fn diagnostics() -> String { ... }
```

FRB copies the doc comment into the generated Dart code, and the check lists the
function as intentionally unused. A marker without a reason, or a marker on a
function that is used, is reported too. The Rust ↔ Dart type mapping table in
[`rust/crates/qi_gateway/README.md`](../rust/crates/qi_gateway/README.md) shows
which generated items the check covers. The pre-commit hook and the
`frb-api-usage` CI job report unused functions as a warning only: the CI job
turns red and lists each function as an annotation and in the job summary, but
it does not fail the workflow or block a release.

Run the project-rename regression tests from the repository root:

```bash
python3 -m unittest discover -s scripts/tests -v
```

These tests use temporary Git repositories and do not rename the current checkout.

## What CI checks for each target

Rust, Flutter, FRB binding, and rename-helper checks are required. The native build matrix requires Linux and Android. The Android PR check builds a profile APK for arm64 and verifies its ABI contents. Tagged Android releases build the four configured Android ABIs. The iOS Simulator job is currently commented out in `.github/workflows/ci-cd.yml` (lines 180–209). To re-enable it, uncomment the complete block between the `BEGIN DISABLED` and `END DISABLED` markers. Windows and macOS builds are also disabled in CI; their Flutter project files and local build instructions remain available.

All Linux CI jobs and the VS Code Dev Container use the public GHCR toolchain image. See [Development container](../docs/DEVELOPMENT_CONTAINER.md) for the pinned versions and setup. An iOS CI build requires a macOS runner and Xcode; that job is currently commented out.

The Android build job records free disk space and the size of major SDK, NDK, Rust, Gradle, and build directories before and after the build. It uploads this report even if the build fails. Compare these measurements before adding or expanding CI caches; caching whole build directories can consume runner space and hide the actual source of pressure.

A successful CI build confirms that the native target compiles; it does not confirm behavior on every device model or vendor configuration.

## Device integration tests

| File | Command | Requirements |
| --- | --- | --- |
| `app/flutter/integration_test/simple_test.dart` | `flutter test integration_test/simple_test.dart -d <device-id>` | Native target/device listed by `flutter devices` |
| `app/flutter/integration_test/example_test.dart` | `patrol test -t integration_test/example_test.dart` | Patrol CLI and Android/iOS emulator or device |

Patrol does not support Linux or Windows desktop. Use the first Flutter integration test for a basic native test run; Patrol is for mobile device-specific interactions.

## Platform matrix and local requirements

| Platform | CI verification | Local build / runtime test |
| --- | --- | --- |
| Linux | Required build | Linux with GTK 3, CMake, Ninja, pkg-config, and a C/C++ compiler |
| Android | Required build | Android SDK/NDK; emulator or device to run |
| iOS | CI build commented out; see `.github/workflows/ci-cd.yml` lines 180–209 | macOS and Xcode; a physical device requires signing setup |
| Windows | Build disabled in CI | Windows and Visual Studio 2022 with the C++ workload |
| macOS | Build disabled in CI | macOS and Xcode |
| Web | Not supported | Not supported |

A build and a runtime test are separate steps. After a successful build, run the application or integration test on a locally available device if the change affects native behavior. To restore Windows/macOS CI builds, add dedicated native host jobs outside the Linux container. To restore the iOS build, uncomment the marked block at lines 180–209 in `.github/workflows/ci-cd.yml`.
