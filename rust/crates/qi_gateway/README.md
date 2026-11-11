# qi_gateway

`qi_gateway` is the only Rust crate that Flutter calls. It is the FFI boundary built with [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/) (FRB) v2: every public function in `src/api/` becomes a Dart function in `app/flutter/lib/src/rust/api/`.

The gateway collects the Rust API from micro-app crates and decides which driver crates those micro-apps get. Micro-app and driver crates can live in this workspace under `rust/crates/` or come from other repositories as ordinary Cargo dependencies (git or crates.io). The gateway itself holds no business logic. It converts types, calls the micro-app, and maps errors. See the architecture diagram in the [root README](../../../README.md#architecture).

“Gateway” here means the Flutter-to-Rust FFI boundary, not a hardware driver.

## Organizing `src/api/`

The recommended layout is one API module per micro-app crate:

| Rust module | Micro-app crate | Generated Dart file |
| --- | --- | --- |
| `src/api/core.rs` | `qi_core` (empty example) | `lib/src/rust/api/core.dart` |
| `src/api/<name>.rs` | your micro-app crate | `lib/src/rust/api/<name>.dart` |

`src/api/mod.rs` only registers the modules and holds `init_app` (`#[frb(init)]`), which belongs to the gateway rather than to a micro-app. Register each module there (`pub mod <name>;`) and regenerate the bindings from `app/flutter/` with `flutter_rust_bridge_codegen generate`. Each Dart file is a separate library, so two modules may use the same function name. A Dart file that imports both then needs an import prefix (`import '...api/core.dart' as core;`).

Keep each function thin:

```rust
#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    qi_core::greeting(&name)
}
```

Functions are asynchronous by default: Dart receives a `Future<T>`, and the work runs off the UI isolate. `#[frb(sync)]` returns `T` directly but blocks the Flutter UI isolate while Rust runs, so use it only for short calls.

## Choosing drivers

A micro-app talks to hardware only through a trait it defines (for example `Transport`). Driver crates implement that trait for one link, such as UART, BLE, or USB. The gateway depends on the driver crates it needs, creates the driver, and passes it to the micro-app. Pick the crates in `qi_gateway/Cargo.toml` in one of two ways. They can also be combined.

### Per platform: `cfg(target_os)`

Use this when the platform decides the link, for example BLE on Android and iOS and UART on desktop:

```toml
[target.'cfg(any(target_os = "android", target_os = "ios"))'.dependencies]
driver_ble = { path = "../driver_ble" }

[target.'cfg(not(any(target_os = "android", target_os = "ios")))'.dependencies]
driver_uart = { path = "../driver_uart" }
```

```rust
#[cfg(any(target_os = "android", target_os = "ios"))]
fn transport() -> driver_ble::BleTransport { driver_ble::BleTransport::new() }

#[cfg(not(any(target_os = "android", target_os = "ios")))]
fn transport() -> driver_uart::UartTransport { driver_uart::UartTransport::new() }
```

Each Flutter platform build compiles only its own driver. No extra configuration is needed.

### Per product variant: Cargo features

Use this when the same platform ships with different hardware, for example a USB and a BLE edition of a desktop app:

```toml
[features]
default = ["uart"]
uart = ["dep:driver_uart"]
ble = ["dep:driver_ble"]

[dependencies]
driver_uart = { path = "../driver_uart", optional = true }
driver_ble = { path = "../driver_ble", optional = true }
```

Gate the code with `#[cfg(feature = "uart")]`. The Flutter build compiles the crate through Cargokit, which uses the `default` features unless told otherwise. To build a different variant without editing `default`, add `cargokit.yaml` next to `qi_gateway/Cargo.toml`. Flags are set per build configuration (`debug`, `profile`, `release`):

```yaml
cargo:
  release:
    extra_flags:
      - --no-default-features
      - --features
      - ble
```

The pre-commit hook and CI run `cargo clippy --all-features`, so all driver features must compile together on Linux. Platform-only drivers belong behind `cfg(target_os)`, not behind a feature.

## Rust ↔ Dart type mapping

FRB converts every argument from Dart to Rust and every return value from Rust to Dart. The rows below were checked against FRB 2.13 codegen output. For the complete reference, see the FRB guides:

- [Types overview](https://cjycode.com/flutter_rust_bridge/guides/types/overview)
- [Simple type correspondence](https://cjycode.com/flutter_rust_bridge/guides/types/translatable/simple-correspondence)
- [Opaque (arbitrary) types](https://cjycode.com/flutter_rust_bridge/guides/types/arbitrary)
- [Zero-copy byte buffers](https://cjycode.com/flutter_rust_bridge/guides/types/translatable/zero-copy)

### API items

The last column shows whether the [FRB API usage check](../../../testing/README.md) reports the item when no code under `app/flutter/lib/` uses it.

| Rust (in `src/api/`) | Dart | Usage checked |
| --- | --- | --- |
| `pub fn f(..) -> T` | top-level `Future<T> f(..)` | Yes |
| `#[frb(sync)] pub fn f(..) -> T` | top-level `T f(..)` | Yes |
| `impl S { pub fn m(&self) }` | method `m()` on class `S` | Yes |
| `impl S { pub fn new(..) -> S }` | `static Future<S> newInstance(..)`; with `#[frb(sync)]` a `factory S(..)` constructor | Yes |
| `pub` field of an opaque struct | getter and setter on the Dart class | Yes, each separately |
| `#[frb(init)] pub fn init_app()` | not exposed; `RustLib.init()` calls it | No |
| `pub struct` with `pub` fields of translatable types | class with `final` fields, `==`, and `hashCode` | No (types are not checked) |
| `#[frb(opaque)]` struct, or a type FRB cannot translate (for example `std::time::Duration`) | abstract class implementing `RustOpaqueInterface`: a handle to memory that stays in Rust | No (its methods are) |
| `enum` without data | Dart `enum` | No |
| `enum` with data | `sealed class` generated with `freezed` (codegen fails with `MissingDep` until `freezed` is added to `pubspec.yaml`) | No |

A method that takes `&mut self` requires the struct to be opaque.

### Values

| Rust | Dart | Notes |
| --- | --- | --- |
| `i8`, `i16`, `i32`, `u8`, `u16`, `u32` | `int` | |
| `i64`, `isize` | `PlatformInt64` | an `int` on native platforms |
| `u64`, `usize` | `BigInt` | values can exceed Dart's signed 64-bit `int` |
| `f32`, `f64` | `double` | |
| `bool` | `bool` | |
| `char` | `String` | a single character |
| `String`, `&str` | `String` | always copied; see below |
| `Vec<u8>`, `&[u8]` | argument: `List<int>`, return: `Uint8List` | copied |
| `Vec<T>` of other numbers | argument: `List<int>` or `List<double>`, return: typed list such as `Int64List` | copied |
| `Vec<String>` | `List<String>` | copied |
| `Option<T>` | `T?` | an `Option` argument becomes an optional named parameter |
| `HashMap<K, V>` | `Map<K, V>` | copied |
| `(A, B)` | record `(A, B)` | |
| `()` | `void` | |
| `Result<T, anyhow::Error>` | returns `T`; the error is thrown as `AnyhowException` | |
| `Result<T, E>` | returns `T`; the `E` value is thrown | for example a `String` |
| `StreamSink<T>` argument | the function returns `Stream<T>` | the sink argument disappears in Dart |

### `String` vs `&str`

Dart has no borrowed slices that Rust could use. A Dart `String` lives on the Dart heap in UTF-16, and Rust needs UTF-8, so FRB always builds a new Rust `String` for every call, in both directions. A gateway function may declare `&str`, and FRB accepts it, but FRB still creates the `String` and only lends it to the function. That saves nothing.

Recommended split:

- **Gateway function:** take `String`. The signature then shows that a copy from Dart exists.
- **Micro-app crate:** take `&str` when the function only reads the text, and `String` only when it keeps it. The gateway then passes `&name` without a second copy, as `greet` does with `qi_core::greeting(&name)`.

The same applies to `Vec<u8>` and `&[u8]`. For large byte buffers returned to Dart, see the zero-copy guide linked above.

## Unused API functions

`dart run tool/check_frb_api_usage.dart` (in `app/flutter/`, also run by the pre-commit hook, which blocks the commit unless it runs with `FRB_ALLOW_UNUSED=1`, and by CI as a warning) reports API items from the table above that nothing in `app/flutter/lib/` uses. To keep one on purpose, add a marker with a reason to its Rust doc comment:

```rust
/// frb-api-usage: allow-unused (diagnostics screen, issue #12)
#[flutter_rust_bridge::frb(sync)]
pub fn diagnostics() -> String {
    qi_core::diagnostics()
}
```

FRB copies the doc comment into the generated Dart code, and the check lists the function as intentionally unused instead of reporting it. A marker without a reason, or a marker on a function that is used, is reported. Details are in [testing/README.md](../../../testing/README.md).
