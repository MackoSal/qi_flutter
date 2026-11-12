# Release and Branching Strategy

This document describes the collaboration rules using Git version control and the CI/CD release cycle for the `qi_flutter` project.

## 1. Branching Strategy (GitHub Flow)

We use a simplified **GitHub Flow** model. This is an ideal compromise between safety and avoiding excessive bureaucracy in a small team.

### Main Rules:
- **`master` is sacred**: The `master` branch must always be in a state that allows the application to be built and run (it must always pass all CI tests). The repository maintainer can work directly on `master`, but for larger changes, using feature branches is highly recommended.
- **Other Developers (Collaborators)**: Anyone else contributing to the project must **NEVER** push code directly to `master`.
- **Feature Branches**: Every new feature or bug fix should be created on a new branch branched off from `master` (e.g., `git checkout -b feature/settings-screen` or `fix/startup-crash`).
- **Pull Requests (PR)**: When the work on a branch is ready, the developer creates a Pull Request to `master`. At this point, **GitHub Actions automatically tests the code**.
- **Code Review**: The branch is merged into `master` only after the Pull Request is approved by the repository maintainer and when the CI/CD pipeline turns green.

## 2. Release Strategy (Tagging and Release)

The management of official releases for clients is automated thanks to GitHub Actions. To create an official installer downloadable from GitHub, you simply need to tag a commit following SemVer and push it to the server.

Release builds run only for tags. Pull requests and regular pushes run the required Linux build; they do not repeat the release-mode builds. Android, iOS, and Windows can be built on demand (Actions tab → Manual Platform Build). Android is built only for smartphones (`arm64-v8a`), in on-demand builds and tagged releases.

### Standard Release (Linux and Android)
By default, pushing a full version tag compiles and uploads packages for both **Android** and **Linux**.

```bash
git tag 1.0.0
git push origin 1.0.0
```

### Selective Releases (Specific Platform Only)
If you found a minor visual bug on Android and there is no point in wasting CI server time recompiling Linux, you can use the defined release suffixes.

* **Android Only Release**: Add the `-a` suffix at the end of the version (e.g., `1.0.1-a`).
  ```bash
  git tag 1.0.1-a
  git push origin 1.0.1-a
  ```
  *(The pipeline will skip building Linux and create a Release containing only the .apk file)*

* **Linux Only Release**: Add the `-l` suffix at the end of the version (e.g., `1.0.1-l`).
  ```bash
  git tag 1.0.1-l
  git push origin 1.0.1-l
  ```
  *(The pipeline will skip building Android and create a Release containing only the .tar.gz file)*

The template's Android release build currently uses the debug signing configuration from `app/flutter/android/app/build.gradle.kts`. This is suitable for a template smoke release, not for publishing a production app. Configure a private upload key and CI signing secrets before distributing an app to users. Never commit signing keys or passwords.
