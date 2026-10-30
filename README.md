# Flutter + Rust: native application template

A ready starting point for desktop and mobile applications. Flutter renders the UI, Rust contains the application logic, and `flutter_rust_bridge` connects them directly through FFI. Web is not supported.

## Start here

1. [Install the tools and run the application](app/flutter/README.md).
2. [Explore the repository and learn where to make changes](docs/START_HERE.md).
3. [Create a project from the template and rename it](docs/NEW_PROJECT.md).

The repository includes a working `greet` demo. Use it as an example of the Flutter → Rust flow, not as product logic.

## Platforms

| Platform | Flutter project | CI verification | Run/device testing |
| --- | --- | --- | --- |
| Linux | Yes | Required build | Locally on Linux |
| Android | Yes | Required build | Android emulator or device |
| iOS | Yes | Optional iOS Simulator build; a failure does not block later CI jobs | iOS Simulator or device; a device requires macOS and signing |
| Windows | Yes | CI build disabled | Locally on Windows with Visual Studio C++ tools |
| macOS | Yes | CI build disabled | Locally on macOS with Xcode |
| Web | No | Not supported | Not supported |

Windows and macOS targets remain in the Flutter project, but CI does not build them. Their matrix entries and build steps are commented out in `.github/workflows/ci-cd.yml`. CI requires Linux and Android native builds; the iOS Simulator build is informational and non-blocking. CI builds do not replace testing on physical devices.

## Quality, testing, and releases

Local quality checks and integration test commands are in the [Flutter guide](app/flutter/README.md) and [testing documentation](testing/README.md). CI also checks that generated FRB bindings are up to date. Do not manually edit `frb_generated*` files or vendored code under `app/flutter/rust_builder/cargokit/`.

Agent rules and architecture are documented in [AGENTS.md](AGENTS.md). The branching and release strategy is in [RELEASES_AND_BRANCHING.md](RELEASES_AND_BRANCHING.md), and the Android Gradle Plugin policy is in [ANDROID_AGP9_MIGRATION.md](app/flutter/ANDROID_AGP9_MIGRATION.md).
