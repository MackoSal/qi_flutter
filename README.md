# qiWELLNESS (Flutter + Rust)

This repository contains the modern rewrite of the **qiWELLNESS** desktop application, transitioning from the legacy Lazarus/Free Pascal codebase to a high-performance **Flutter** (UI) and **Rust** (Logic) stack.

The application communicates directly with bioresonance/electroacupuncture hardware devices (via serial/USB ports). Due to the hardware requirements, **the Web platform is explicitly not supported**. This is a 100% native application for Desktop (Windows/Linux/macOS) and Mobile (Android/iOS).

---

## 1. System Dependencies

To compile and run this project, you need the following tools installed:

### Global Requirements
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   [Rust Toolchain](https://rustup.rs/) (including `cargo` and `rustup`)
*   **flutter_rust_bridge_codegen** (v2): 
    Run `cargo install flutter_rust_bridge_codegen`

### Platform-Specific Requirements
*   **Linux (Desktop)**: `sudo apt-get install -y libgtk-3-dev ninja-build pkg-config cmake build-essential`
*   **Windows (Desktop)**: Visual Studio 2022 with the "Desktop development with C++" workload installed.
*   **macOS / iOS**: Xcode and CocoaPods.
*   **Android**: Android Studio with the Android SDK and NDK installed (Cargokit will attempt to automatically locate or download the required NDK version).

---

## 2. Project Structure

The repository is organized using an advanced Multi-crate Workspace pattern:

```text
qi_flutter/
├── app/
│   └── flutter/                  # The main Flutter Application (Presentation Layer)
│       ├── lib/                  # Dart UI code and state management
│       ├── android/, ios/, etc.  # Native runner projects
│       └── rust_builder/         # Cargokit plugin linking the Rust workspace to Flutter
├── rust/                         # The Rust Workspace (Logic Layer)
│   ├── Cargo.toml                # Workspace manifest
│   └── crates/
│       ├── qi_core/              # Pure Rust business logic, hardware comms (serialport), math. (Zero Flutter knowledge)
│       └── rust_lib_qi_flutter/  # FFI Bridge crate. Exposes `qi_core` to Dart via flutter_rust_bridge.
├── qiWELLNESS/                   # Legacy Lazarus/Pascal reference codebase (Ignored by Git)
├── AGENTS.md                     # AI System Knowledge Base, Milestones & Migration Rules
└── README.md                     # This file
```

---

## 3. How to Run

> **Important:** Because the Flutter project is nested inside the repository to keep the root clean, you must always navigate to `app/flutter` before running any Flutter commands!

### Step 1: Navigate to the app directory
```bash
cd app/flutter
```

### Step 2: Run on your target platform
You can use VS Code's built-in run/debug tools (F5) by selecting your device in the bottom right corner, or use the terminal:

*   **Android (Physical device or Emulator)**
    ```bash
    flutter run -d android
    # Or specify device ID if multiple are connected: flutter run -d "Pixel 3a"
    ```
*   **Linux Desktop**
    ```bash
    flutter run -d linux
    ```
*   **Windows Desktop**
    ```bash
    flutter run -d windows
    ```
*   **macOS Desktop**
    ```bash
    flutter run -d macos
    ```
*   **iOS (Simulator or physical device)**
    ```bash
    flutter run -d ios
    ```

*Note: The very first time you build for a new target (especially Android or iOS), the build process will take several minutes. This is because Cargokit must download the appropriate cross-compilation toolchains (`rustup target add...`) and compile the entire Rust logic layer from scratch.*

