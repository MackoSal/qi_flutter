# qi_flutter - System Knowledge Base

This document is the single source of truth for AI agents and developers working on this repository. It describes the architecture, the platform constraints, and the rules every change must follow.

## 1. Project Goal

This repository is a reusable template for fully native applications built with **Flutter (UI)** and **Rust (logic)**. All substantial logic lives in Rust; Flutter only renders the UI and manages view state.

## 2. Platform Constraints

- **Native project targets:** Linux, Windows, macOS, Android, and iOS. CI requires only the Linux build. Android, iOS Simulator, and Windows builds run on demand in `.github/workflows/manual-build.yml`; macOS has no CI build. Local build guidance remains in `app/flutter/README.md`.
- **The Web platform is not supported.** Do not add a `web/` target, Web-only packages, or Web-based testing tools.
- **No WebSocket or local server architecture.** Flutter and Rust communicate only through in-memory FFI.

## 3. Architecture (Multi-crate Rust Workspace)

```text
Flutter UI (app/flutter)  ──FFI (flutter_rust_bridge)──►  qi_gateway  ──►  qi_core
```

- **Presentation layer - `app/flutter/`:**
  - Owns UI widgets and view state only. No business rules, calculations, or I/O logic.
  - Calls Rust exclusively through the generated bindings in `lib/src/rust/`.
- **Bridge layer - `rust/crates/qi_gateway/`:**
  - Thin FFI adapter built with **flutter_rust_bridge (FRB) v2**. Public functions in `src/api/` are exposed to Dart, with one module per micro-app crate (`api/core.rs` for `qi_core`).
  - Composition root: depends on the micro-app crates and selects their driver crates (per platform with `cfg(target_os)` or per product variant with Cargo features). See [`rust/crates/qi_gateway/README.md`](rust/crates/qi_gateway/README.md), which also documents the Rust ↔ Dart type mapping.
  - Converts between FFI-friendly types and `qi_core` types. It must not contain business logic.
  - “Gateway” means the Flutter-to-Rust FFI boundary here; it is not a hardware or device driver.
- **Core layer - `rust/crates/qi_core/`:**
  - Pure Rust domain rules, state, and calculations. Keep operating-system, hardware, and external I/O behind explicit adapters so core behavior remains easy to test.
  - Has **no dependency on Flutter or FRB** and must be testable with plain `cargo test`.
- **Native build glue - `app/flutter/rust_builder/`:**
  - Cargokit plugin that compiles the Rust workspace for every Flutter target. Treat `cargokit/` as vendored code.

## 4. Working Rules

### Changing the Rust API exposed to Dart

1. Implement the logic in `qi_core` with unit tests.
2. Expose it through a function in the matching module of `qi_gateway/src/api/` (for example `api/core.rs` for `qi_core`). Check how its types map to Dart in [`rust/crates/qi_gateway/README.md`](rust/crates/qi_gateway/README.md). Dart first: [stub the signature](app/flutter/README.md#dart-before-the-rust-logic-exists).
3. Regenerate the bindings from `app/flutter/`:

   ```bash
   flutter_rust_bridge_codegen generate
   ```

4. Commit the regenerated files. Never edit `frb_generated*.dart`, `frb_generated.rs`, or other `@generated` files by hand; the pre-commit hook and CI fail if the committed bindings differ from a fresh generation (`bash scripts/check_frb_bindings.sh`).
5. FRB currently generates a web-specific binding file even though Web is not a supported application target. Keep it in sync with codegen; its presence does not add Web support.
6. Call every exposed function from application code under `app/flutter/lib/`. The FRB API usage check (`dart run tool/check_frb_api_usage.dart`) warns about functions that are not used. If one must stay unused for now, add `frb-api-usage: allow-unused (<reason>)` to its Rust doc comment.

The FRB version must stay identical in `rust/crates/qi_gateway/Cargo.toml`, `app/flutter/pubspec.yaml`, and `.devcontainer/Dockerfile`.

### Documentation language

- Preserve the existing language of each documentation file when editing it. Do not translate a file or change its language unless the user explicitly asks for that change.
- Write new repository documentation in English by default, matching this repository’s established documentation language, unless the user requests another language.

### Git identity

- When a new repository is created from this template, ask the user which git account (name and e-mail) to use for its commits, and set it with `git config --local user.name` and `git config --local user.email`. Do not assume an identity.
- Before creating or amending a commit, verify the repository-local identity with `git config --local user.name` and `git config --local user.email`.

### Commit and push policy

- Use a short, single-line Conventional Commit subject: `type(scope): imperative summary`. The scope is optional when the type makes the change clear; for example, `docs: clarify setup` or `fix(rename): validate identifiers`.
- Choose the subject from the staged diff and repository context. It must accurately describe the change contained in the commit and make sense as a durable entry in the project history, without relying on this chat, the reason a change was requested, or an earlier mistaken state unless that correction is itself visible in the diff.
- Do not push commits or tags unless the user explicitly asks for the push.

For detailed commit-subject guidance, see [`.claude/skills/commit-message/SKILL.md`](.claude/skills/commit-message/SKILL.md).

### Scripts and CI

- CI workflow steps are one-line calls, for example `run: bash scripts/check_frb.sh --allow-warnings`. Anything with conditions, loops, or several commands belongs in a script under `scripts/`, not inline in `.github/workflows/`.
- Every script works the same locally and in CI: it is non-interactive, reports its result through the exit code, describes itself at the top of the file, and is listed in [`scripts/README.md`](scripts/README.md).
- A script either changes files on purpose or only checks them. A check never changes repository files.
- Tests of the scripts themselves (`scripts/tests/`) are run by hand only. Do not add them to CI or the pre-commit hook.
- AI agents commit with `FRB_ALLOW_UNUSED=1` by default. Whenever the hook then prints the unused FRB API warning, the agent must explicitly ask the user whether keeping those functions unused is a deliberate decision, and fix the commit before pushing if it is not.
- Keep scripts modular: a check that can run on its own is its own script, and an aggregate script calls it (for example, `check_frb.sh` calls `check_frb_bindings.sh`). The pre-commit hook calls the same scripts as CI.

### Quality gates

The pre-commit hook (`.githooks/pre-commit`) runs the local Rust and Flutter quality checks that CI also runs. Through `scripts/check_frb.sh` it also blocks out-of-date FRB bindings and unused FRB API functions; commit unused functions on purpose with `FRB_ALLOW_UNUSED=1 git commit` (CI only warns about them). CI adds dependency auditing and native target builds. Enable the hook once per clone:

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
| Native builds | `flutter build linux --debug`, `windows`, `macos`, `apk --profile --target-platform android-arm64`, or `ios --simulator --no-codesign` (`app/flutter/`, target-dependent; CI requires Linux; Android, iOS, and Windows are built on demand) |
| Integration tests | `patrol test` (`app/flutter/`, requires a device, see `testing/README.md`) |

CI runs Linux jobs in the pinned public GHCR toolchain image, runs `scripts/check_frb.sh` (FRB bindings, analyze, tests; unused FRB API functions only as warning annotations), and requires the Linux build. Android (arm64 profile APK), iOS Simulator, and Windows builds run on demand: Actions tab → **Manual Platform Build** → **Run workflow**, then pick the branch and platform. Android is built only for smartphones (`arm64-v8a`), in on-demand builds and tagged releases. The release job only runs for tags. Device execution and Patrol tests still require a local device/emulator.

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
