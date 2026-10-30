# Testing and platform verification

## Quick local checks

Before committing, run Rust checks from `rust`:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --workspace
```

Then run Flutter checks from `app/flutter`:

```bash
dart format --set-exit-if-changed lib/ test/
flutter analyze
flutter test
```

CI runs these checks and verifies that FRB code generation does not change the committed bindings.

Run the project-rename regression tests from the repository root:

```bash
python3 -m unittest discover -s scripts/tests -v
```

These tests use temporary Git repositories and do not rename the current checkout.

## What CI checks for each target

Rust, Flutter, FRB binding, and rename-helper checks are required. The native build matrix requires Linux and Android. The iOS Simulator build is optional: its result remains visible, but a failure does not fail the workflow or block dependent release jobs. Windows and macOS builds are currently disabled in CI; their Flutter project files and local build instructions remain available.

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
| iOS | Optional, non-blocking Simulator build | macOS and Xcode; a physical device requires signing setup |
| Windows | Build disabled in CI | Windows and Visual Studio 2022 with the C++ workload |
| macOS | Build disabled in CI | macOS and Xcode |
| Web | Not supported | Not supported |

A build and a runtime test are separate steps. After a successful build, run the application or integration test on a locally available device if the change affects native behavior. To restore Windows/macOS CI builds or disable the optional iOS build, edit the native-build matrix and matching steps in `.github/workflows/ci-cd.yml`.
