# Run the Flutter + Rust application

This guide assumes that you have already cloned the repository. Run Flutter commands from `app/flutter` and Rust commands from `rust`.

## 1. Install the required tools

Install the Flutter SDK (which includes Dart), Rust using rustup, and Git. You also need `flutter_rust_bridge_codegen` at the version used by this project (`2.13.0`):

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0
```

For a preconfigured Flutter, Rust, and Android environment, use the [repository Dev Container](../../docs/DEVELOPMENT_CONTAINER.md). Local host setup remains supported.

Check your installation:

```bash
flutter doctor -v
rustc --version
cargo --version
flutter_rust_bridge_codegen --version
```

Resolve items marked as required by `flutter doctor -v` for your target platform. You do not need to install tools for every operating system at once.

## 2. Install platform tools

| Target | Required tools |
| --- | --- |
| Linux desktop | GTK 3, CMake, Ninja, pkg-config, and a C/C++ compiler (for example, `sudo apt-get install libgtk-3-dev cmake ninja-build pkg-config build-essential`) |
| Windows desktop | Visual Studio 2022 with the “Desktop development with C++” workload |
| macOS desktop / iOS | Xcode; CocoaPods is also needed for iOS |
| Android | Android Studio, Android SDK, accepted SDK licenses; Cargokit uses the Android NDK and adds the required Rust targets |

iOS and macOS local builds require a Mac. Android and Windows can be built on their respective operating systems. CI requires Linux and an arm64 Android profile build; tagged Android releases build all four configured ABIs. The iOS Simulator job is currently commented out in `.github/workflows/ci-cd.yml` (lines 141–170). Uncomment the complete marked block to enable it. CI currently skips Windows and macOS builds.

## 3. Fetch dependencies

From the repository root:

```bash
cd app/flutter
flutter pub get
```

On the first build, Cargokit may download and compile Rust tools for the target. This can take a few minutes.

## 4. Run the application

List available devices and targets:

```bash
flutter devices
```

Run the appropriate target:

```bash
flutter run -d linux
flutter run -d windows
flutter run -d macos
flutter run -d android
flutter run -d ios
```

The command must match a platform and device available on your computer. If multiple devices are connected, use the identifier shown by `flutter devices`.

Build without running:

```bash
flutter build linux --debug
flutter build windows --debug
flutter build macos --debug
flutter build apk --debug
flutter build ios --simulator --no-codesign
```

## 5. Test and check changes

Run Rust checks from the repository root:

```bash
cd rust
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --workspace
```

Run Flutter checks from `app/flutter`:

```bash
cd ../app/flutter
dart format --set-exit-if-changed lib/ test/
flutter analyze
flutter test
```

From the repository root, also run the template rename helper checks:

```bash
python3 -m unittest discover -s scripts/tests -v
```

Integration tests require an available target:

```bash
flutter test integration_test/simple_test.dart -d linux
patrol test -t integration_test/example_test.dart
```

Patrol tests require the Patrol CLI and an Android/iOS device or emulator. See [testing/README.md](../../testing/README.md) for details.

### Automatic pre-commit checks

Enable the hook from the repository root:

```bash
git config core.hooksPath .githooks
```

The hook runs formatting, linting, analysis, and Rust/Flutter tests before a commit. If this repository was created from the template, configure the hook again in your local clone.

## Where should I change code?

- Screens and widgets: `lib/main.dart` and `lib/`.
- Rust logic: `../../rust/crates/qi_core/src/`.
- Public functions exposed to Flutter: `../../rust/crates/qi_gateway/src/api/`.
- Rust tests: next to the logic in `qi_core` or in the crate's `tests/` directory.
- Flutter tests: `test/`; integration tests: `integration_test/`.

See [START_HERE.md](../../docs/START_HERE.md) for the repository map and call flow. FFI API changes require regenerating bindings from `app/flutter`:

```bash
flutter_rust_bridge_codegen generate
```

Do not manually edit `lib/src/rust/frb_generated*.dart` or `rust/crates/qi_gateway/src/frb_generated.rs`. Commit the regenerated files together with the Rust change. The pre-commit hook blocks the commit when they are out of date; run the same check manually with `bash scripts/check_frb_bindings.sh` from the repository root (see [scripts/README.md](../../scripts/README.md)).

## Common problems

- **`flutter doctor` reports missing tools:** install the requirements for your chosen platform from the table above, then run `flutter doctor -v` again.
- **Android cannot find the SDK/NDK or reports unaccepted licenses:** open Android Studio → SDK Manager, install the SDK/NDK requested by Flutter, and accept licenses with `flutter doctor --android-licenses`.
- **The first Rust build is slow:** Cargokit prepares the target and compiles the library; check your network connection and retry the build.
- **Dependencies or project names changed:** from `app/flutter`, run `flutter clean`, then `flutter pub get`.
- **FRB codegen fails:** check that `flutter_rust_bridge_codegen --version` reports `2.13.0` and that `flutter doctor -v` reports no Flutter/Dart issues.
- **The iOS build fails on Linux/Windows:** local iOS builds require macOS and Xcode; use a Mac or CI.

## Android Gradle Plugin

The repository currently uses AGP 8.x. Do not upgrade to AGP 9 without checking compatibility with the Flutter SDK and plugins. See [ANDROID_AGP9_MIGRATION.md](ANDROID_AGP9_MIGRATION.md) for details.
