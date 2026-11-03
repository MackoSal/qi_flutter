# Repository map: where to make changes

This guide helps you find the right file, even if you are new to Flutter and Rust. The guiding principle is: **Flutter handles appearance and view state; Rust handles product logic.**

## Main directories

| Location | Contents | When to work here |
| --- | --- | --- |
| `app/flutter/lib/` | Flutter screens, widgets, and UI state | When changing what users see and interact with |
| `app/flutter/lib/src/rust/` | Generated Dart bindings to Rust | Do not edit manually; regenerate with FRB codegen |
| `app/flutter/test/` | Widget and UI behavior tests | When adding or changing a view |
| `app/flutter/integration_test/` | Running-app tests on native targets | When checking UI, Rust, and system integration |
| `app/flutter/android/`, `ios/`, `linux/`, `macos/`, `windows/` | Native Flutter platform configuration and entry points | When configuring a specific operating system |
| `app/flutter/rust_builder/` | Plugin that builds and links Rust through Cargokit | Usually not needed for product code changes |
| `app/flutter/rust_builder/cargokit/` | Vendored Cargokit tool | Do not edit manually; treat it as a dependency |
| `rust/crates/qi_core/src/` | Domain logic, calculations, and state in plain Rust | When implementing product behavior |
| `rust/crates/rust_lib_qi_flutter/src/api/` | Thin layer of functions exposed to Flutter | When new logic must be callable from Dart |
| `rust/crates/rust_lib_qi_flutter/src/frb_generated.rs` | Generated Rust FRB code | Do not edit manually |
| `scripts/` | Tools for preparing a project from this template | When creating a new product based on this repository |
| `testing/`, `.github/workflows/` | Test instructions and automated checks/builds | When changing project verification |
| `design/` | Place for design tokens, assets, and design-system documentation | When the project starts work on a shared visual system |

## How a Flutter → Rust call works

```text
app/flutter/lib/main.dart
    │ imports and calls a function
    ▼
app/flutter/lib/src/rust/api/simple.dart       generated Dart interface
    │ FFI, flutter_rust_bridge
    ▼
rust/crates/rust_lib_qi_flutter/src/api/simple.rs  thin adapter
    │ calls the logic
    ▼
rust/crates/qi_core/src/lib.rs                 Rust logic and unit test
```

`main.dart` should not implement business rules. A function in the `api` layer should pass data to `qi_core` and return a value that FRB can expose to Dart.

## Example: change the demo `greet`

The current screen calls `greet(name: "Tom")`. This example shows the complete function-change cycle; you can keep it in the template or replace it with the first product feature.

`greet` is intentionally a minimal synchronous happy-path example of the Flutter-to-Rust bridge. Add async behavior and domain error handling with the first feature that needs those patterns, so the template does not imply one policy for every product.

1. **Change the logic in `rust/crates/qi_core/src/lib.rs`.** Add or modify a domain function. If its behavior changes, add a unit test next to the logic in a `#[cfg(test)]` block.
2. **Run the Rust tests.** From `rust`, run `cargo test --workspace`. `qi_core` can be tested without starting Flutter.
3. **Expose the logic through the adapter.** Add a function in `rust/crates/rust_lib_qi_flutter/src/api/` that calls `qi_core`. Keep product calculations and rules out of the adapter.
4. **Generate bindings.** From `app/flutter`, run `flutter_rust_bridge_codegen generate`. FRB updates files under `app/flutter/lib/src/rust/` and the Rust glue. Do not edit these generated files by hand.
5. **Call the API from the UI.** Import the generated API file in `app/flutter/lib/` and use the function in a widget. UI can manage presentation state, while product logic remains in Rust.
6. **Add tests.** Cover logic with Rust tests, the view with a test in `app/flutter/test/`, and Rust–Flutter integration with a test in `app/flutter/integration_test/` on a native device/target.
7. **Run checks before committing.** See the [run guide](../app/flutter/README.md) for commands; CI also checks that regenerating FRB does not change committed bindings.

## Files not to edit manually

- `app/flutter/lib/src/rust/frb_generated*.dart` and other `@generated` files: regenerate them with FRB.
- `rust/crates/rust_lib_qi_flutter/src/frb_generated.rs`: regenerate it with FRB.
- `app/flutter/rust_builder/cargokit/`: vendored Cargokit; update it as a dependency, not as application code.

## Other guides

- Environment setup and running the app: [app/flutter/README.md](../app/flutter/README.md).
- Creating a new project and changing identifiers: [NEW_PROJECT.md](NEW_PROJECT.md).
- Integration testing: [testing/README.md](../testing/README.md).
- Architecture and working rules: [AGENTS.md](../AGENTS.md).
