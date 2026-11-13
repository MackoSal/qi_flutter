# Development container

The repository publishes a shared Linux toolchain image to GHCR. The same image is used by Linux and Android GitHub Actions jobs and by the Dev Container configuration.

## Open the repository in the container

1. Install Docker Desktop or Docker Engine and the VS Code Dev Containers extension.
2. Open this repository in VS Code.
3. Run **Dev Containers: Reopen in Container** from the Command Palette.
4. Wait for Flutter and Cargokit dependencies to finish installing, then run `flutter doctor -v`.

The container provides Flutter 3.47.9 (including Dart 3.13.7), Rust 1.94.1, flutter_rust_bridge_codegen 2.13.0, Java 17, Android SDK 36, and Android NDK 28.2.13676358. It includes the Rust Android targets needed for CI and release builds. Application source remains in the mounted checkout.

Android emulators and physical devices remain host-side tools. To run an app on a device, connect or start it on the host and configure Docker/VS Code device forwarding for your operating system. iOS builds require macOS and Xcode and run outside this Linux container.

## Image maintenance

The image definition is `.devcontainer/Dockerfile`; this template publishes it as `ghcr.io/mackosal/qi_flutter-devcontainer`. The Dev Container and Linux CI jobs use the public `:1` tag. The `Dev Container Image` workflow builds and smoke-checks Dockerfile changes on pull requests. After a change lands on `master`, it publishes the versioned `:1` tag and a commit-SHA tag. Keep these tool versions aligned with CI and update the versioned image when a shared toolchain change is intentional.

The image is large because it contains Android SDK/NDK and Rust cross-compilation targets. It standardizes installed tools but does not add disk capacity to GitHub-hosted runners.

Applications created from this template should keep using the shared public image by default. Update shared tool versions and publish them from the template repository so all projects can use the same maintained toolchain. A project should publish its own GHCR image only when it needs additional or different tools; then change the image path in its Dev Container and Linux CI jobs and maintain that project image separately. Make a project image **Public** if collaborators need anonymous pulls. Teams that need an immutable environment can pin a commit-SHA tag or image digest instead of the mutable `:1` tag.

### Publishing project-specific images

A project created from the template already contains `.devcontainer/Dockerfile` and the `Dev Container Image` workflow. The workflow runs only in the template repository (it checks the repository ID), so a project does not publish an image by default. Also remove the `docker` entry from the project's `.github/dependabot.yml`, because the shared image is updated in the template repository.

If a project needs its own toolchain:

1. Replace the repository ID in the `if:` line of `.github/workflows/publish-devcontainer.yml` with the project's ID (`gh api repos/<owner>/<repo> -q .id`).
2. Point `image` in `.devcontainer/devcontainer.json` and the `container.image` settings in `.github/workflows/ci-cd.yml` and `.github/workflows/manual-build.yml` to `ghcr.io/<owner>/<repo>-devcontainer:1`.
3. Run **Actions → Dev Container Image → Run workflow** on the default branch, and set the GHCR package to **Public** if collaborators need anonymous pulls.

If the shared template image is made private later, projects can pull it only after logging in: add `credentials` with a token that can read packages to each `container:` block, and give the project repositories read access in the package settings (**Manage Actions access**).
