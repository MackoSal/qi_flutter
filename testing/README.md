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

## What CI checks for each target

The workflow builds the application and Rust FFI library for Linux, Windows, macOS, Android, and the iOS Simulator. A CI build confirms that the native target compiles; it does not confirm behavior on every device model or vendor configuration.

## Device integration tests

| File | Command | Requirements |
| --- | --- | --- |
| `app/flutter/integration_test/simple_test.dart` | `flutter test integration_test/simple_test.dart -d <device-id>` | Native target/device listed by `flutter devices` |
| `app/flutter/integration_test/example_test.dart` | `patrol test -t integration_test/example_test.dart` | Patrol CLI and Android/iOS emulator or device |

Patrol does not support Linux or Windows desktop. Use the first Flutter integration test for a basic native test run; Patrol is for mobile device-specific interactions.

## Platform matrix and local requirements

| Platform | CI build | Local build / runtime test |
| --- | --- | --- |
| Linux | Yes | Linux with GTK 3, CMake, Ninja, pkg-config, and a C/C++ compiler |
| Windows | Yes | Windows and Visual Studio 2022 with the C++ workload |
| macOS | Yes | macOS and Xcode |
| Android | Yes | Android SDK/NDK; emulator or device to run |
| iOS | Yes, Simulator target | macOS and Xcode; a physical device requires signing setup |

A build and a runtime test are separate steps. After a successful build, run the application or integration test on a locally available device if the change affects native behavior.
