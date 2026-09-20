# Release and Branching Strategy

This document describes the collaboration rules using Git version control and the CI/CD release cycle for the `qi_flutter` project.

## 1. Branching Strategy (GitHub Flow)

We use a simplified **GitHub Flow** model. This is an ideal compromise between safety and avoiding excessive bureaucracy in a small team.

### Main Rules:
- **`master` is sacred**: The `master` branch must always be in a state that allows the application to be built and run (it must always pass all CI tests). The main developer (MackoSal) can work directly on `master`, but for larger changes, using feature branches is highly recommended.
- **Other Developers (Collaborators)**: Anyone else contributing to the project must **NEVER** push code directly to `master`.
- **Feature Branches**: Every new feature or bug fix should be created on a new branch branched off from `master` (e.g., `git checkout -b feature/new-reading` or `fix/serial-port-crash`).
- **Pull Requests (PR)**: When the work on a branch is ready, the developer creates a Pull Request to `master`. At this point, **GitHub Actions automatically tests the code**.
- **Code Review**: The branch is merged into `master` only after the Pull Request is approved (e.g., by MackoSal) and when the CI/CD pipeline turns green.

## 2. Release Strategy (Tagging and Release)

The management of official releases for clients is automated thanks to GitHub Actions. To create an official installer downloadable from GitHub, you simply need to tag a commit following SemVer and push it to the server.

### Standard Release (All Platforms)
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
