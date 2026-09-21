# Testing (E2E & Integration)

This project uses **Patrol** (`patrol`) for native UI integration testing. 
Since the Web platform is explicitly not supported, Web-based testing tools like Playwright are not included.

## Running tests

To run the integration tests via Patrol locally (assuming an Android emulator or device is running):

```bash
cd app/flutter
patrol test -t integration_test/example_test.dart
```

*Note: You need to have the `patrol_cli` installed globally on your machine:*
```bash
dart pub global activate patrol_cli
```
