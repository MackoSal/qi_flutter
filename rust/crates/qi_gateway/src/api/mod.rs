//! FRB API exposed to Dart: one module per micro-app crate.

pub mod core;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
