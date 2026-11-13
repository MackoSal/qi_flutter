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

- `new_name` is used as the Dart application package name. The Rust FFI gateway crate remains named `qi_gateway` in product repositories so its technical role does not depend on the product name. Use lowercase letters, digits, and underscores, for example `my_app`.
- `application-id` is a unique native platform identifier in reverse-DNS notation, for example `com.yourcompany.myapp`. Choose a domain you control. Do not use `com.example` in a published product.

## 3. Preview the changes first

The script changes occurrences of the old application name in tracked project text files, replaces the example `com.example` identifiers with the application ID, sets the company name and copyright on Windows and macOS to the organization part of the ID (for example `com.yourcompany`), moves Android `MainActivity.kt` to the directory matching the new application ID, and renames paths containing the application name. It keeps the Rust crates `qi_gateway` and `qi_core` unchanged; the `qi_` crate prefix is the same in every project created from the template. It skips vendored Cargokit, build directories, its own regression tests under `scripts/tests/`, and this guide, and it keeps the rename command elsewhere unchanged so the docs still describe the template.

Start with a preview:

```bash
python3 scripts/rename_project.py qi_flutter my_app \
  --application-id com.yourcompany.myapp --dry-run
```

If the proposed changes look right, run it without `--dry-run`:

```bash
python3 scripts/rename_project.py qi_flutter my_app \
  --application-id com.yourcompany.myapp
```

The script updates text names and the Android package path automatically. It does not choose publisher information, icons, certificates, or signing configuration; those are product-owner decisions. Review the diff before committing.

## 4. Refresh dependencies and generated bindings

```bash
cd app/flutter
flutter clean
flutter pub get
(cd rust_builder/cargokit/build_tool && dart pub get)
flutter_rust_bridge_codegen generate
dart fix --apply --code=directives_ordering
cd ../..
```

`dart fix` re-sorts the `import` lines: a new package name that sorts before `flutter` (for example `acme_demo`) otherwise makes `flutter analyze` and the pre-commit hook fail. Review the diff after code generation. Do not edit `frb_generated*` files manually; commit generated changes if code generation updates the bindings.

## 5. Verify names and run checks

Check that old names and example identifiers are not left in project files:

```bash
rg -n 'qi_flutter|com\.example' --glob '!app/flutter/rust_builder/cargokit/**' .
```

Results may include the script itself, migration history, or documentation references explaining the template. Before considering the rename complete, check the Android/iOS/macOS/Linux/Windows configuration and Dart/Rust imports in particular.

Enable the pre-commit hook in the new clone; it is not copied with the repository:

```bash
git config core.hooksPath .githooks
```

Run the quality checks in the [guide](../app/flutter/README.md), then build for your platform. On Android, start with `flutter build apk --debug`; on Linux, `flutter build linux --debug`; on Windows, `flutter build windows --debug`; on macOS, `flutter build macos --debug`. For iOS, use macOS and `flutter build ios --simulator --no-codesign`.

CI requires only the Linux build. Android, iOS Simulator, and Windows builds run on demand (Actions tab → Manual Platform Build → Run workflow); macOS has no CI build. See the [platform verification matrix](../testing/README.md#platform-matrix-and-local-requirements) before treating a target as CI-verified.

## 6. Set product details

- Set the display name, icon, bundle ID, and application ID for your product brand.
- Configure release signing according to platform policy. The template uses debug signing for local Android release runs; configure your own key before distribution.
- Customize the release workflow and GitHub Actions secrets. The template's default releases create a Linux archive and Android APK.
- Choose and add a project license before redistributing the application. This template intentionally does not select a license on behalf of the product owner.
- Keep `ghcr.io/mackosal/qi_flutter-devcontainer:1` as the default image in `.devcontainer/devcontainer.json` and the Linux jobs in `.github/workflows/ci-cd.yml` and `manual-build.yml`. The rename script preserves this shared template image. It is public so new projects can pull it without credentials. The `Dev Container Image` workflow runs only in the template repository; remove the `docker` entry from `.github/dependabot.yml`. See [Development container](DEVELOPMENT_CONTAINER.md#publishing-project-specific-images) for a project-specific image.
- For shared toolchain and package updates, update the image definition in the template repository and publish a new version there. Projects using the `:1` tag receive those updates when they pull the image. If this product needs extra or different tools, build and publish a project-specific image to its own GHCR package, then point the Dev Container and Linux jobs to it; make that package public if collaborators need anonymous pulls.
- Replace the `@MackoSal` entry in `.github/CODEOWNERS` with the GitHub account or team that will own the new repository.
- Replace the quickstart screen and `greet` with the first product feature. Start with logic and tests in a new `qi_<name>` crate (see [Adding a micro-app crate](../rust/crates/qi_gateway/README.md#adding-a-micro-app-crate)), then expose it through the FRB API.
- Update the product README and the “Creating a New Project” section in its `AGENTS.md` to describe the product.
