# Contributing

Thanks for contributing. This repository is a reusable Flutter + Rust application template; keep changes broadly useful to projects created from it.

## Before opening a pull request

1. Read [AGENTS.md](AGENTS.md) for the architecture and repository rules.
2. Run the relevant checks from [Testing and platform verification](testing/README.md).
3. Regenerate Flutter Rust Bridge bindings after changing the Rust API; never edit generated bindings by hand.
4. Update the beginner guides when a command, supported platform, workflow, or template setup changes.

Pull requests should explain the user-visible change, affected platforms, and checks performed. Keep unrelated formatting and generated-file changes out of the diff.

## Development environment

The recommended environment is the [Dev Container](docs/DEVELOPMENT_CONTAINER.md), which shares its pinned Linux and Android toolchain with CI. iOS work requires macOS and Xcode.
