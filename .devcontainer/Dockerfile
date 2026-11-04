# Keep tool versions in sync with the Dev Container documentation.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.47.9
ARG RUST_VERSION=1.94.1
ARG FRB_CODEGEN_VERSION=2.13.0
ARG CARGO_AUDIT_VERSION=0.22.2
ARG ANDROID_CMDLINE_TOOLS_REVISION=11076708
ARG ANDROID_PLATFORM=android-36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK_VERSION=28.2.13676358

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/opt/flutter/bin:/usr/local/cargo/bin:/opt/android-sdk/cmdline-tools/current/bin:/opt/android-sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PUB_CACHE=/opt/dart-pub-cache \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      build-essential \
      clang \
      cmake \
      curl \
      file \
      git \
      libglu1-mesa \
      libgtk-3-dev \
      liblzma-dev \
      libstdc++6 \
      libx11-dev \
      libxkbcommon-dev \
      libsecret-1-dev \
      lld \
      make \
      ninja-build \
      openjdk-17-jdk-headless \
      pkg-config \
      python3 \
      unzip \
      xz-utils \
      zip \
      zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C /opt \
    && git config --system --add safe.directory /opt/flutter \
    && flutter config --no-analytics --android-sdk "$ANDROID_HOME" \
    && flutter precache --linux --android \
    && chown -R ubuntu:ubuntu /opt/flutter

RUN mkdir -p "$ANDROID_HOME/cmdline-tools" /tmp/android-cmdline-tools \
    && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_REVISION}_latest.zip" -o /tmp/android-cmdline-tools.zip \
    && unzip -q /tmp/android-cmdline-tools.zip -d /tmp/android-cmdline-tools \
    && mv /tmp/android-cmdline-tools/cmdline-tools "$ANDROID_HOME/cmdline-tools/current" \
    && rm -rf /tmp/android-cmdline-tools /tmp/android-cmdline-tools.zip \
    && yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null \
    && sdkmanager --sdk_root="$ANDROID_HOME" \
      "platform-tools" \
      "platforms;${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK_VERSION}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain "$RUST_VERSION" --profile minimal \
    && rustup component add rustfmt clippy \
    && rustup target add \
      aarch64-linux-android \
      armv7-linux-androideabi \
      i686-linux-android \
      x86_64-linux-android \
    && cargo install flutter_rust_bridge_codegen --version "$FRB_CODEGEN_VERSION" --locked \
    && cargo install cargo-audit --version "$CARGO_AUDIT_VERSION" --locked \
    && rm -rf "$CARGO_HOME/registry" "$CARGO_HOME/git" \
    && chown -R ubuntu:ubuntu "$CARGO_HOME" "$RUSTUP_HOME"

RUN mkdir -p "$PUB_CACHE" \
    && chown -R ubuntu:ubuntu /home/ubuntu "$PUB_CACHE"

WORKDIR /workspace

LABEL org.opencontainers.image.title="qi_flutter development toolchain" \
      org.opencontainers.image.description="Pinned Flutter, Rust, Android and Linux toolchain for qi_flutter CI and Dev Containers"
