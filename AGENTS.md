# qi_flutter - System Knowledge Base

This document is the single source of truth for AI agents and developers working on this repository. It describes the architecture, the platform constraints, and the rules every change must follow.

## 1. Project Goal

This repository is a reusable template for fully native applications built with **Flutter (UI)** and **Rust (logic)**. All substantial logic lives in Rust; Flutter only renders the UI and manages view state.

## 2. Platform Constraints

- **Supported targets:** desktop (Linux, Windows, macOS) and mobile (Android, iOS).
- **The Web platform is not supported.** Do not add a `web/` target, Web-only packages, or Web-based testing tools.
- **No WebSocket or local server architecture.** Flutter and Rust communicate only through in-memory FFI.

## 3. Architecture (Multi-crate Rust Workspace)

```text
Flutter UI (app/flutter)  ──FFI (flutter_rust_bridge)──►  rust_lib_qi_flutter  ──►  qi_core
```

- **Presentation layer - `app/flutter/`:**
  - Owns UI widgets and view state only. No business rules, calculations, or I/O logic.
  - Calls Rust exclusively through the generated bindings in `lib/src/rust/`.
- **Bridge layer - `rust/crates/rust_lib_qi_flutter/`:**
  - Thin FFI adapter built with **flutter_rust_bridge (FRB) v2**. Public functions in `src/api/` are exposed to Dart.
  - Converts between FFI-friendly types and `qi_core` types. It must not contain business logic.
- **Core layer - `rust/crates/qi_core/`:**
  - Pure Rust domain logic, state, calculations, and platform or hardware access.
  - Has **no dependency on Flutter or FRB** and must be testable with plain `cargo test`.
- **Native build glue - `app/flutter/rust_builder/`:**
  - Cargokit plugin that compiles the Rust workspace for every Flutter target. Treat `cargokit/` as vendored code.

## 4. Working Rules

### Changing the Rust API exposed to Dart

1. Implement the logic in `qi_core` with unit tests.
2. Expose it through a function in `rust_lib_qi_flutter/src/api/`.
3. Regenerate the bindings from `app/flutter/`:

   ```bash
   flutter_rust_bridge_codegen generate
   ```

4. Commit the regenerated files. Never edit `frb_generated*.dart`, `frb_generated.rs`, or other `@generated` files by hand; CI fails if the committed bindings differ from a fresh generation.

The FRB version must stay identical in `rust/crates/rust_lib_qi_flutter/Cargo.toml`, `app/flutter/pubspec.yaml`, and `.github/workflows/ci-cd.yml`.

### Quality gates

The pre-commit hook (`.githooks/pre-commit`) and CI (`.github/workflows/ci-cd.yml`) run the same checks. Enable the hook once per clone:

```bash
git config core.hooksPath .githooks
```

| Area | Command (working directory) |
| --- | --- |
| Rust formatting | `cargo fmt --all -- --check` (`rust/`) |
| Rust lints | `cargo clippy --all-targets --all-features -- -D warnings` (`rust/`) |
| Rust tests | `cargo test --workspace` (`rust/`) |
| Dart formatting | `dart format --set-exit-if-changed lib/ test/` (`app/flutter/`) |
| Dart analysis | `flutter analyze` (`app/flutter/`) |
| Flutter tests | `flutter test` (`app/flutter/`) |
| Integration tests | `patrol test` (`app/flutter/`, requires a device, see `testing/README.md`) |

### Documentation layout

- `README.md` - setup and running the app.
- `RELEASES_AND_BRANCHING.md` - branching model and tag-driven releases.
- `app/flutter/ANDROID_AGP9_MIGRATION.md` - Android Gradle Plugin version policy.
- `design/` - design-system workspace (no design has been created yet).
- `AI_TOOLS_HELPERS.md` - AI roles and skills under `.gemini/`.

## 5. Development Environment

- Required tools: `rustc`, `cargo`, `flutter`, `dart`, and `flutter_rust_bridge_codegen` (the version pinned in CI).
- Linux desktop dependencies: `libgtk-3-dev`, `cmake`, `ninja-build`, `pkg-config`, and C++ development libraries.
- Android builds require the Android SDK and NDK; Cargokit installs the required Rust targets.
- A Dev Container is recommended to standardize the environment and avoid local system package conflicts.

## 6. Creating a New Project from This Template

1. Rename the project: `python3 scripts/rename_project.py qi_flutter <new_name>`.
2. Set a real Android `applicationId` and iOS/macOS bundle identifiers.
3. Replace the demo `greet` API and the quickstart screen with the first real feature.
4. Replace this section of `AGENTS.md` with the product-specific goals and roadmap.
