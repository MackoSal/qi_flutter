# Flutter Android: AGP 9+ and Built-in Kotlin Migration

## Current State

This project intentionally uses **Android Gradle Plugin (AGP) 8.11.1** and **Kotlin 2.2.20**, while the Gradle wrapper is already on **Gradle 9.1.0**.

Flutter's Android Gradle integration and third-party Flutter plugins must support the AGP 9 APIs before AGP is upgraded. A premature upgrade can fail inside a Gradle plugin, for example with a `ClassCastException` caused by the removal of `AbstractAppExtension`.

The versions currently in use are defined in `android/settings.gradle.kts`:

```kotlin
id("com.android.application") version "8.11.1" apply false
id("org.jetbrains.kotlin.android") version "2.2.20" apply false
```

The app module uses Java 17 and Kotlin's Java 17 toolchain:

```kotlin
kotlin {
    jvmToolchain(17)
}
```

## When to Migrate

Do not migrate merely because a newer Gradle, AGP, or Kotlin version is available. Start only after the Flutter SDK version used by this project and every Android-facing Flutter plugin support AGP 9 and built-in Kotlin. Check the Flutter release notes, plugin changelogs, and `flutter pub outdated` first.

## Migration Procedure

1. Record the working baseline:

   ```bash
   flutter doctor -v
   flutter pub get
   flutter build apk --debug
   flutter build apk --release
   ```

2. Upgrade the Flutter SDK and Flutter packages as needed, then resolve all package compatibility issues:

   ```bash
   flutter pub outdated
   flutter pub upgrade
   ```

3. Update the AGP and Kotlin versions in `android/settings.gradle.kts` to a mutually compatible, currently supported pair. Also update the Gradle wrapper in `android/gradle/wrapper/gradle-wrapper.properties` if that AGP version requires it. Use the AGP release notes as the compatibility source of truth; do not copy the versions from this document blindly.

4. When the selected Gradle and AGP releases document support for the new DSL and built-in Kotlin, add or update these entries in `android/gradle.properties`:

   ```properties
   android.newDsl=true
   android.builtInKotlin=true
   ```

   Keep these properties absent or set to `false` while compatibility is incomplete. They are not currently present in this repository.

5. Confirm that the Java and Kotlin toolchains remain on a version supported by the selected AGP. This project currently uses JDK 17 in `android/app/build.gradle.kts`.

6. Build and run the complete Android matrix:

   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   flutter build apk --release
   flutter build appbundle --release
   flutter run -d <device-id>
   ```

7. Test Android-only integrations on a physical device or emulator, especially native Rust builds supplied by Cargokit. A successful Gradle configuration alone does not prove that the full Android application is working.

## Troubleshooting

- A failure mentioning `AbstractAppExtension`, a Gradle plugin cast, or Flutter's Gradle plugin normally indicates that the Flutter SDK or a plugin is not yet compatible with AGP 9. Revert the AGP/Kotlin/Gradle changes as one set and wait for compatible releases.
- If the failure is related to the Android SDK, NDK, JDK, or a Rust target, it is an environment or native-toolchain issue rather than proof of AGP incompatibility. Start with `flutter doctor -v` and the full build log.
- Keep the resulting working version set documented here after every upgrade: Flutter SDK, AGP, Kotlin, Gradle, JDK, and any temporary compatibility properties.
