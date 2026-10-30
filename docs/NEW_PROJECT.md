# Create an application from the template

This guide walks through creating a copy, naming the application, and setting native identifiers. Run commands from the root of the new repository.

## 1. Create a repository from the template

On GitHub, choose **Use this template** and create a separate product repository. Clone it and enter the directory:

```bash
git clone <your-repository-address>
cd <repository-directory>
```

Do not develop product-specific logic in the template repository. A separate repository lets you update the base template and product independently.

## 2. Choose names and an identifier

- `new_name` is used as the Dart package name and Rust bridge crate name. Use lowercase letters, digits, and underscores, for example `qi_wellness`.
- `application-id` is a unique native platform identifier in reverse-DNS notation, for example `com.yourcompany.qiwellness`. Choose a domain you control. Do not use `com.example` in a published product.

## 3. Preview the changes first

The script changes occurrences of the old name in tracked project text files, updates example `com.example` identifiers, moves Android `MainActivity.kt` to the directory matching the new application ID, and renames paths containing the project name. It skips vendored Cargokit, build directories, and its own regression tests under `scripts/tests/`.

Start with a preview:

```bash
python3 scripts/rename_project.py qi_flutter qi_wellness \
  --application-id com.yourcompany.qiwellness --dry-run
```

If the proposed changes look right, run it without `--dry-run`:

```bash
python3 scripts/rename_project.py qi_flutter qi_wellness \
  --application-id com.yourcompany.qiwellness
```

The script updates text names and the Android package path automatically. It does not choose publisher information, icons, certificates, or signing configuration; those are product-owner decisions. Review the diff before committing.

## 4. Refresh dependencies and generated bindings

```bash
cd app/flutter
flutter clean
flutter pub get
flutter_rust_bridge_codegen generate
cd ../..
```

Review the diff after code generation. Do not edit `frb_generated*` files manually; commit generated changes if code generation updates the bindings.

## 5. Verify names and run checks

Check that old names and example identifiers are not left in project files:

```bash
rg -n 'qi_flutter|com\.example' --glob '!app/flutter/rust_builder/cargokit/**' .
```

Results may include the script itself, migration history, or documentation references explaining the template. Before considering the rename complete, check the Android/iOS/macOS/Linux/Windows configuration and Dart/Rust imports in particular.

Run the quality checks in the [guide](../app/flutter/README.md), then build for your platform. On Android, start with `flutter build apk --debug`; on Linux, `flutter build linux --debug`; on Windows, `flutter build windows --debug`; on macOS, `flutter build macos --debug`. For iOS, use macOS and `flutter build ios --simulator --no-codesign`.

The required native CI builds cover Linux and Android. The iOS Simulator build is optional and non-blocking; Windows and macOS builds are local checks and are currently disabled in CI. See the [platform verification matrix](../testing/README.md#platform-matrix-and-local-requirements) before treating a target as CI-verified.

## 6. Set product details

- Set the display name, icon, bundle ID, and application ID for your product brand.
- Configure release signing according to platform policy. The template uses debug signing for local Android release runs; configure your own key before distribution.
- Customize the release workflow and GitHub Actions secrets. The template's default releases create a Linux archive and Android APK.
- Replace the quickstart screen and `greet` with the first product feature. Start with logic and tests in `qi_core`, then expose it through the FRB API.
- Update the product README and the “Creating a New Project” section in its `AGENTS.md` to describe the product.
