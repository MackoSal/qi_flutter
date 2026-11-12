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
5. **Speed up CI builds.** The on-demand Android build takes about 8 minutes: about 100 s to pull the 3.7 GB Dev Container image and about 6 minutes for `flutter build apk`, which starts from scratch every time. Possible improvements:
   - **Gradle cache:** keep `~/.gradle` between runs so Android dependencies are not downloaded again.
   - **Rust build cache:** keep the Cargokit build output under `app/flutter/build/` between runs so Rust is only recompiled after a code change.
   - **iOS build (about 6 minutes):** `Install Flutter` (95 s) and `Post Install Flutter` (53 s) were measured on the first run, when the Flutter SDK cache was still empty. Check on a second run whether `cache: true` makes these steps shorter. The `flutter build ios --simulator` step (191 s) would benefit from a Rust build cache and a CocoaPods cache.
   - **Self-hosted runner:** run jobs on an own machine, where the image and build caches survive between runs. This is the fastest option, but the machine has to be maintained and secured. That can helps only for Android and Linux targets, but that is most used. 
