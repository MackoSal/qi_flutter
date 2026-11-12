# Testing and platform verification

## Quick local checks

Before committing, run Rust checks from `rust`:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --workspace
```

Then run the Flutter checks from the repository root:

```bash
(cd app/flutter && dart format --set-exit-if-changed lib/ test/)
bash scripts/check_frb.sh
```

`scripts/check_frb.sh` checks that the committed FRB bindings match the Rust
API, runs `flutter analyze` and `flutter test`, and reports unused FRB API
functions. Only the last one is a warning; the others block. The pre-commit hook
and the `flutter-checks` CI job run the same script. Each step is described at
the top of the script.

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
which generated items the check covers.

Unused functions only add warnings in CI; for the pre-commit hook, see
[Committing unused FRB API functions](../README.md#committing-unused-frb-api-functions).

Run the project-rename regression tests from the repository root:

```bash
python3 -m unittest discover -s scripts/tests -v
```

These tests use temporary Git repositories and do not rename the current checkout.

## What CI checks for each target

Rust, Flutter, and FRB binding checks are required. The rename-helper tests are not automated; run them by hand after changing `scripts/rename_project.py`. Only the Linux build is required. Android, iOS Simulator, and Windows builds run on demand: Actions tab → **Manual Platform Build** → **Run workflow**, then pick the branch and platform. The Android build makes an arm64 profile APK and verifies its ABI contents with `scripts/verify_apk_abi.sh`. Android is built only for smartphones (`arm64-v8a`), in on-demand builds and tagged releases. macOS has no CI build.

All Linux CI jobs and the VS Code Dev Container use the public GHCR toolchain image. See [Development container](../docs/DEVELOPMENT_CONTAINER.md) for the pinned versions and setup. The iOS and Windows builds run on GitHub-hosted macOS and Windows runners, which use more paid minutes than Linux in private repositories.

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
| Android | Build on demand | Android SDK/NDK; emulator or device to run |
| iOS | Simulator build on demand | macOS and Xcode; a physical device requires signing setup |
| Windows | Build on demand | Windows and Visual Studio 2022 with the C++ workload |
| macOS | No CI build | macOS and Xcode |
| Web | Not supported | Not supported |

A build and a runtime test are separate steps. After a successful build, run the application or integration test on a locally available device if the change affects native behavior.
