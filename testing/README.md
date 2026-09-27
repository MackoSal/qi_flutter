# Testing (E2E & Integration)

This project uses **Patrol** (`patrol`) for native UI integration testing. 
Since the Web platform is explicitly not supported, Web-based testing tools like Playwright are not included.

## Test suites

| File | Framework | Platforms |
| --- | --- | --- |
| `app/flutter/test/` | `flutter_test` (widget tests, no Rust) | host, runs in CI |
| `app/flutter/integration_test/simple_test.dart` | `integration_test` | any device, including Linux/Windows/macOS desktop |
| `app/flutter/integration_test/example_test.dart` | Patrol | Android and iOS devices or emulators only |

Patrol does not support Linux or Windows desktop; running a Patrol test with
`flutter test -d linux` fails with `Unsupported operation: Unkown platform`.

## Running desktop integration tests

```bash
cd app/flutter
flutter test integration_test/simple_test.dart -d linux
```

## Running Patrol tests

To run the integration tests via Patrol locally (assuming an Android emulator or device is running):

```bash
cd app/flutter
patrol test -t integration_test/example_test.dart
```

*Note: You need to have the `patrol_cli` installed globally on your machine:*
```bash
dart pub global activate patrol_cli
```
