# Flutter + Rust: native application template

A ready starting point for desktop and mobile applications. Flutter renders the UI, Rust contains the application logic, and `flutter_rust_bridge` connects them directly through FFI. Web is not supported.

## Start here

1. [Install the tools and run the application](app/flutter/README.md).
2. [Explore the repository and learn where to make changes](docs/START_HERE.md).
3. [Create a project from the template and rename it](docs/NEW_PROJECT.md).

The repository includes a working `greet` demo. Use it as an example of the Flutter → Rust flow, not as product logic.

## Platforms

| Platform | Built in CI | Run/device testing |
| --- | --- | --- |
| Linux | Yes | Locally on Linux |
| Windows | Yes | Locally on Windows |
| macOS | Yes | Locally on macOS |
| Android | Yes | Android emulator or device |
| iOS | Yes, simulator | iOS Simulator or device; a device requires macOS and signing |

CI builds check that the native project and Rust FFI compile for each target. They do not replace testing on a physical device.

## Quality, testing, and releases

Local quality checks and integration test commands are in the [Flutter guide](app/flutter/README.md) and [testing documentation](testing/README.md). CI also checks that generated FRB bindings are up to date. Do not manually edit `frb_generated*` files or vendored code under `app/flutter/rust_builder/cargokit/`.

Agent rules and architecture are documented in [AGENTS.md](AGENTS.md). The branching and release strategy is in [RELEASES_AND_BRANCHING.md](RELEASES_AND_BRANCHING.md), and the Android Gradle Plugin policy is in [ANDROID_AGP9_MIGRATION.md](app/flutter/ANDROID_AGP9_MIGRATION.md).
