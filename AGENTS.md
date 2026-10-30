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

### Documentation language

- Preserve the existing language of each documentation file when editing it. Do not translate a file or change its language unless the user explicitly asks for that change.
- Write new repository documentation in English by default, matching this repository’s established documentation language, unless the user requests another language.

### Git identity

- For commits in this repository, use `Maciej Salwa <macieks1515@wp.pl>`, matching the repository owner's existing commit history. Never use `maciej.salwa.ext@qorix.ai` for this repository.
- Before creating or amending a commit, verify the repository-local identity with `git config --local user.name` and `git config --local user.email`.

### Quality gates

The pre-commit hook (`.githooks/pre-commit`) runs the local Rust and Flutter quality checks that CI also runs. CI adds FRB binding verification, dependency auditing, and native target builds. Enable the hook once per clone:

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
| Native builds | `flutter build linux --debug`, `windows`, `macos`, `apk`, or `ios --simulator --no-codesign` (`app/flutter/`, target-dependent) |
| Integration tests | `patrol test` (`app/flutter/`, requires a device, see `testing/README.md`) |

CI runs the Rust and Flutter checks, verifies generated FRB bindings, and builds Linux, Windows, macOS, Android, and the iOS Simulator target. Device execution and Patrol tests still require a local device/emulator.

### Documentation layout

- `README.md` - setup and running the app.
- `app/flutter/README.md` - beginner setup, commands, platform prerequisites, and troubleshooting.
- `docs/START_HERE.md` - repository path map and Flutter-to-Rust example workflow.
- `docs/NEW_PROJECT.md` - creating a product repository and renaming identifiers.
- `RELEASES_AND_BRANCHING.md` - branching model and tag-driven releases.
- `app/flutter/ANDROID_AGP9_MIGRATION.md` - Android Gradle Plugin version policy.
- `testing/README.md` - local checks, CI target builds, and device testing.
- `design/` - design-system workspace (no design has been created yet).
- `AI_TOOLS_HELPERS.md` - AI roles and skills under `.gemini/`.

## 5. Development Environment

- Required tools: `rustc`, `cargo`, `flutter`, `dart`, and `flutter_rust_bridge_codegen` (the version pinned in CI).
- Linux desktop dependencies: `libgtk-3-dev`, `cmake`, `ninja-build`, `pkg-config`, and C++ development libraries.
- Android builds require the Android SDK and NDK; Cargokit installs the required Rust targets.
- A Dev Container is recommended to standardize the environment and avoid local system package conflicts.

## 6. Creating a New Project from This Template

1. Follow `docs/NEW_PROJECT.md`; preview and rename with `python3 scripts/rename_project.py qi_flutter <new_name> --application-id <reverse-DNS-id>`.
2. Set product-specific publisher information, icons, signing, and release secrets.
3. Replace the demo `greet` API and the quickstart screen with the first real feature.
4. Replace this section of `AGENTS.md` with the product-specific goals and roadmap.
