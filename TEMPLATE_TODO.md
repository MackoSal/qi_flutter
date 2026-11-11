# Potential template improvements

This list records possible follow-up work. These items are not commitments or current requirements.

1. **Review the number of Markdown files.** Identify opportunities to reduce or consolidate documentation while keeping instructions easy to find for people and AI agents.
2. **Test and improve the Dev Container.** Try the documented setup from a clean checkout, verify the development workflow, and address any issues found.
3. **Design the release process.** Define how changes move from CI checks to the CI/CD release workflow, including when and how releases are created.
4. **Using Python script as logic (instead or adding to rust logic).** Support integrating Python helper scripts for visualizing data (such as laboratory instrument and measurement readouts) in internal or utility tools rather than production applications. Possible implementation approaches:
   - **Flet:** Build Flutter-rendered UIs directly in Python for quick standalone visualization tools.
   - **Dart–Python FFI (`python_ffi_dart`):** Invoke Python functions and modules directly from Dart over `dart:ffi` on desktop platforms.
   - **`serious_python`:** Embed a CPython runtime inside the Flutter application to run Python scripts in background threads.
   - **PyO3:** Bridge Python scripts through Rust behind the existing `flutter_rust_bridge` layer. A dedicated crate for this would allow reusing existing Python utility scripts first and migrating them step by step into production Rust code when needed. *this opption looks worthy to try!*
