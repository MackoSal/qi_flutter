# qi_flutter - System Knowledge Base

This document is the single source of truth for AI agents and developers working on this repository. It describes the architecture, the platform constraints, and the rules every change must follow.

## 1. Project Goal

This repository is a reusable template for fully native applications built with **Flutter (UI)** and **Rust (logic)**. All substantial logic lives in Rust; Flutter only renders the UI and manages view state.

## 2. Platform Constraints

- **Native project targets:** Linux, Windows, macOS, Android, and iOS. CI-required builds cover Linux and arm64 Android. The iOS Simulator job is currently commented out in `.github/workflows/ci-cd.yml` (lines 181–210); Windows and macOS also have no CI jobs. Their builds need dedicated host jobs outside the Linux container. Local build guidance remains in `app/flutter/README.md`.
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
  - Pure Rust domain rules, state, and calculations. Keep operating-system, hardware, and external I/O behind explicit adapters so core behavior remains easy to test.
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
5. FRB currently generates a web-specific binding file even though Web is not a supported application target. Keep it in sync with codegen; its presence does not add Web support.
6. Call every exposed function from application code under `app/flutter/lib/`. The FRB API usage check (`dart run tool/check_frb_api_usage.dart`) warns about functions that are not used. If one must stay unused for now, add `frb-api-usage: allow-unused (<reason>)` to its Rust doc comment.

The FRB version must stay identical in `rust/crates/rust_lib_qi_flutter/Cargo.toml`, `app/flutter/pubspec.yaml`, and `.devcontainer/Dockerfile`.

### Documentation language

- Preserve the existing language of each documentation file when editing it. Do not translate a file or change its language unless the user explicitly asks for that change.
- Write new repository documentation in English by default, matching this repository’s established documentation language, unless the user requests another language.

### Git identity

- For commits in this repository, use `Maciej Salwa <macieks1515@wp.pl>`, matching the repository owner's existing commit history. Never use `maciej.salwa.ext@qorix.ai` for this repository.
- Before creating or amending a commit, verify the repository-local identity with `git config --local user.name` and `git config --local user.email`.

### Commit and push policy

- Use a short, single-line Conventional Commit subject: `type(scope): imperative summary`. The scope is optional when the type makes the change clear; for example, `docs: clarify setup` or `fix(rename): validate identifiers`.
- Choose the subject from the staged diff and repository context. It must accurately describe the change contained in the commit and make sense as a durable entry in the project history, without relying on this chat, the reason a change was requested, or an earlier mistaken state unless that correction is itself visible in the diff.
- Do not push commits or tags unless the user explicitly asks for the push.

For detailed commit-subject guidance, see [`.claude/skills/commit-message/SKILL.md`](.claude/skills/commit-message/SKILL.md).

### Quality gates

The pre-commit hook (`.githooks/pre-commit`) runs the local Rust and Flutter quality checks that CI also runs. It only warns about unused FRB API functions. CI adds FRB binding verification, dependency auditing, and native target builds. Enable the hook once per clone:

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
| Rename script tests | `python3 -m unittest discover -s scripts/tests -v` (repository root) |
| Native builds | `flutter build linux --debug`, `windows`, `macos`, `apk --profile --target-platform android-arm64`, or `ios --simulator --no-codesign` (`app/flutter/`, target-dependent; CI requires Linux and arm64 Android; iOS CI is commented out) |
| Integration tests | `patrol test` (`app/flutter/`, requires a device, see `testing/README.md`) |

CI runs Linux jobs in the pinned public GHCR toolchain image, verifies generated FRB bindings, reports unused FRB API functions in a non-blocking job, tests the rename helper against a repository fixture, and requires Linux and arm64 Android builds. Tagged Android releases build all four configured ABIs. The release job only runs for tags. The iOS Simulator job is commented out (see the marked block at lines 181–210 of `.github/workflows/ci-cd.yml`); Windows and macOS app builds are also disabled in CI. Device execution and Patrol tests still require a local device/emulator. Android CI uploads disk-usage diagnostics even if its build fails.

### Documentation layout

- `README.md` - setup and running the app.
- `app/flutter/README.md` - beginner setup, commands, platform prerequisites, and troubleshooting.
- `docs/START_HERE.md` - repository path map and Flutter-to-Rust example workflow.
- `docs/NEW_PROJECT.md` - creating a product repository and renaming identifiers.
- `RELEASES_AND_BRANCHING.md` - branching model and tag-driven releases.
- `app/flutter/ANDROID_AGP9_MIGRATION.md` - Android Gradle Plugin version policy.
- `testing/README.md` - local checks, CI target builds, and device testing.
- `docs/DEVELOPMENT_CONTAINER.md` - shared GHCR toolchain image and Dev Container setup.
- `CONTRIBUTING.md` and `SECURITY.md` - contribution and vulnerability reporting guidance.
- `design/` - design-system workspace (no design has been created yet).
- `AI_TOOLS_HELPERS.md` - AI roles and skills under `.gemini/`.

## 5. Development Environment

- Required tools: `rustc`, `cargo`, `flutter`, `dart`, and `flutter_rust_bridge_codegen` (versions are pinned in `.devcontainer/Dockerfile`). The recommended Dev Container uses the same toolchain as Linux CI.
- Linux desktop dependencies: `libgtk-3-dev`, `cmake`, `ninja-build`, `pkg-config`, and C++ development libraries.
- Android builds require the Android SDK and NDK; the shared toolchain image contains the pinned SDK, NDK, and required Rust targets.
- A Dev Container is recommended to standardize the environment and avoid local system package conflicts.

## 6. Creating a New Project from This Template

1. Follow `docs/NEW_PROJECT.md`; preview and rename with `python3 scripts/rename_project.py qi_flutter <new_name> --application-id <reverse-DNS-id>`.
2. Set product-specific publisher information, icons, signing, and release secrets.
3. Replace the demo `greet` API and the quickstart screen with the first real feature.
4. Replace this section of `AGENTS.md` with the product-specific goals and roadmap.
