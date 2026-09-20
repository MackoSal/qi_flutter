# qi_flutter - System Knowledge Base and Migration Guide

This document is the single source of truth for current and future AI agents and developers working on this project. It documents the legacy system analysis and guidelines for the new architecture.

## 1. Project Goal

Migrate the **qiWELLNESS** desktop application from Lazarus/Free Pascal to a modern **Flutter (UI) + Rust (logic)** stack.

The application is a control panel for a bioresonance/electroacupuncture device. It currently communicates over a serial port, with a future migration to native USB or BLE planned.

## 2. Legacy System Analysis (Pascal)

The legacy code is located in the `qiWELLNESS/` directory and excluded from Git tracking by `.gitignore`.

Primary application domains:

- **Hardware communication:** Serial/USB communication through `TLazSerial` in `unitmain.pas`. Short text commands include `eap`, `ion`, `freq 100 100`, and `calib`.
- **Web integration (REST):** `biorest.pas` and the `AtlasSearchBAP` function in `unitmain.pas` retrieve data from `http://biotronics.eu`.
- **Database:** No local SQL database exists.
- **Therapy and diagnostic modalities:** Ryodoraku, EAV, VEG, EAP, and ION.

## 3. Target Architecture (Multi-crate Workspace)

Use a modular Rust Workspace pattern inspired by `crispy-tivi`, with one important constraint: **do not support the Web platform and do not use a WebSocket server architecture**.

The application is fully native. All substantial logic, including mathematics, machine state, and direct port communication, resides in Rust, isolated from the UI and connected only through in-memory FFI.

- **Presentation layer (Flutter/Dart native app):**
  - Compiled exclusively as desktop applications for Linux, Windows, and macOS, and mobile applications for Android and iOS.
  - Owns only UI and view state management. Recreate the controls from `unitmain.lfm`.
- **Logic layer (Rust Workspace):**
  - `crates/qi_core`: Pure business and hardware logic, including `serialport`, future native USB/BLE APIs, machine state, and calculations. It has no knowledge of Flutter.
  - `crates/rust_lib_qi_flutter`: The in-memory FFI bridge. It uses **flutter_rust_bridge (FRB)** to expose `qi_core` functionality to Flutter.

## 4. Delivery Plan

### Milestone 1: UI Replication and Architecture Skeleton

**Primary goal:** A working native UI on desktop and mobile, connected to Rust mocks. No Web support.

1. Initialize the Flutter project without the Web target.
2. Set up the Rust Workspace (`qi_core`, `rust_lib_qi_flutter`) and `flutter_rust_bridge_codegen`.
3. Build a layout corresponding to the legacy main window.
4. Create Rust contracts (`pub fn` called from Flutter) that return mock data, such as random points for a Ryodoraku chart, enabling complete UI testing.

### Milestone 2: Full Logic and Hardware Integration

**Primary goal:** Move device communication and API integration to Rust.

1. Implement `serialport` in `qi_core`, laying the foundation for future raw USB and BLE protocols.
2. Translate the binary/text logic from Pascal's `SerialRxData` into a Rust parser.
3. Enable the native application to control the device live.

### Milestone 3: Database and Archiving

**Primary goal:** Store diagnostic history and patient profiles.

1. Add local storage, such as `rusqlite` in `qi_core`, for desktop and mobile platforms, or prepare for cloud synchronization.

## 5. Development Environment

- Required tools: `rustc`, `cargo`, `flutter`, and `dart`.
- Linux desktop dependencies: `libgtk-3-dev`, `cmake`, `ninja-build`, `pkg-config`, and C++ development libraries.
- A Dev Container is recommended to standardize the environment and avoid local system package conflicts.
