# Development container

The repository publishes a shared Linux toolchain image to GHCR. The same image is used by Linux and Android GitHub Actions jobs and by the Dev Container configuration.

## Open the repository in the container

1. Install Docker Desktop or Docker Engine and the VS Code Dev Containers extension.
2. Open this repository in VS Code.
3. Run **Dev Containers: Reopen in Container** from the Command Palette.
4. Wait for Flutter and Cargokit dependencies to finish installing, then run `flutter doctor -v`.

The container provides Flutter 3.41.9 (including its bundled Dart), Rust 1.94.1, flutter_rust_bridge_codegen 2.13.0, Java 17, Android SDK 36, and Android NDK 28.2.13676358. It includes the Rust Android targets needed for CI and release builds. Application source remains in the mounted checkout.

Android emulators and physical devices remain host-side tools. To run an app on a device, connect or start it on the host and configure Docker/VS Code device forwarding for your operating system. iOS builds require macOS and Xcode and run outside this Linux container.

## Image maintenance

The image definition is `.devcontainer/Dockerfile`; `.devcontainer/devcontainer.json` selects the public GHCR image named `<lowercase-owner>/<lowercase-repository>-devcontainer`. The `Dev Container Image` workflow builds and smoke-checks Dockerfile changes on pull requests. After a change lands on `master`, it publishes the versioned `:1` tag and a commit-SHA tag. Keep these tool versions aligned with CI and update the versioned image when a toolchain change is intentional.

The image is large because it contains Android SDK/NDK and Rust cross-compilation targets. It standardizes installed tools but does not add disk capacity to GitHub-hosted runners. CI reports Android disk usage to help diagnose build failures.

After copying the template, change the image path in `.devcontainer/devcontainer.json` and all `container.image` entries in `.github/workflows/ci-cd.yml` to the new lowercase owner/repository. The image publishing workflow derives its package path from the repository automatically. The package must be set to **Public** in the repository owner's GitHub Packages settings after its first publication so users can pull it anonymously. If the package is private, CI and Dev Containers outside the owning account cannot pull it.

### First publication in a new repository

The first pull request cannot use an image that has not been published yet. On the default branch, run **Actions → Dev Container Image → Run workflow** once. Then change the new GHCR package visibility to **Public** in the repository owner's Packages settings. After that, pull request CI can start its jobs in the published image.
