"""Regression tests for the template project rename helper."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = SOURCE_ROOT / "scripts/rename_project.py"


class RenameProjectTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "scripts").mkdir()
        shutil.copy2(SCRIPT, self.root / "scripts/rename_project.py")
        self._write("app/flutter/pubspec.yaml", 'name: qi_flutter\ndependencies:\n  rust_lib_qi_flutter:\n    path: rust_builder\n')
        self._write("rust/Cargo.toml", '[workspace]\nmembers = ["crates/rust_lib_qi_flutter"]\n')
        self._write("rust/crates/rust_lib_qi_flutter/Cargo.toml", 'name = "rust_lib_qi_flutter"\n')
        self._write("rust/crates/rust_lib_qi_flutter/src/lib.rs", "pub fn name() {}\n")
        self._write("app/flutter/android/app/build.gradle.kts", 'applicationId = "com.example.qi_flutter"\n')
        self._write("app/flutter/android/app/src/main/kotlin/com/example/qi_flutter/MainActivity.kt", "package com.example.qi_flutter\n")
        self._write("app/flutter/ios/Runner.xcodeproj/project.pbxproj", 'PRODUCT_BUNDLE_IDENTIFIER = "com.example.qiFlutter";\nPRODUCT_BUNDLE_IDENTIFIER = "com.example.qiFlutter.RunnerTests";\n')
        self._write("app/flutter/macos/Runner/Configs/AppInfo.xcconfig", "PRODUCT_BUNDLE_IDENTIFIER = com.example.qiFlutter\n")
        self._write("app/flutter/macos/Runner.xcodeproj/project.pbxproj", "PRODUCT_BUNDLE_IDENTIFIER = com.example.qiFlutter.RunnerTests;\n")
        self._write("app/flutter/linux/CMakeLists.txt", 'set(BINARY_NAME "qi_flutter")\nset(APPLICATION_ID "com.example.qi_flutter")\n')
        self._write("app/flutter/windows/CMakeLists.txt", 'set(BINARY_NAME "qi_flutter")\n')
        self._write("app/flutter/windows/runner/main.cpp", 'window.Create(L"qi_flutter", origin, size);\n')
        self._write("app/flutter/rust_builder/cargokit/README.md", "qi_flutter should remain vendored\n")
        self._write("scripts/tests/test_fixture.py", 'OLD_PROJECT = "qi_flutter"\n')
        subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _write(self, relative: str, content: str) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def _run(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", "scripts/rename_project.py", *args],
            cwd=self.root,
            check=False,
            text=True,
            capture_output=True,
        )

    def test_dry_run_reports_changes_without_writing(self) -> None:
        result = self._run("qi_flutter", "qi_wellness", "--application-id", "pl.example.qiwellness", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Text files to update:", result.stdout)
        self.assertIn("move rust/crates/rust_lib_qi_flutter -> rust/crates/rust_lib_qi_wellness", result.stdout)
        self.assertIn("qi_flutter", (self.root / "app/flutter/pubspec.yaml").read_text())

    def test_rename_updates_names_and_platform_ids(self) -> None:
        result = self._run("qi_flutter", "qi_wellness", "--application-id", "pl.example.qiwellness")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            (self.root / "app/flutter/pubspec.yaml").read_text(),
            'name: qi_wellness\ndependencies:\n  rust_lib_qi_wellness:\n    path: rust_builder\n',
        )
        self.assertIn("rust_lib_qi_wellness", (self.root / "rust/Cargo.toml").read_text())
        self.assertTrue((self.root / "rust/crates/rust_lib_qi_wellness/Cargo.toml").is_file())
        self.assertEqual(
            (self.root / "app/flutter/android/app/src/main/kotlin/pl/example/qiwellness/MainActivity.kt").read_text(),
            "package pl.example.qiwellness\n",
        )
        self.assertIn('"pl.example.qiwellness"', (self.root / "app/flutter/android/app/build.gradle.kts").read_text())
        ios = (self.root / "app/flutter/ios/Runner.xcodeproj/project.pbxproj").read_text()
        self.assertIn('"pl.example.qiwellness";', ios)
        self.assertIn('"pl.example.qiwellness.RunnerTests";', ios)
        self.assertIn("pl.example.qiwellness", (self.root / "app/flutter/macos/Runner/Configs/AppInfo.xcconfig").read_text())
        self.assertIn("pl.example.qiwellness.RunnerTests", (self.root / "app/flutter/macos/Runner.xcodeproj/project.pbxproj").read_text())
        self.assertIn('set(BINARY_NAME "qi_wellness")', (self.root / "app/flutter/linux/CMakeLists.txt").read_text())
        self.assertIn('set(APPLICATION_ID "pl.example.qiwellness")', (self.root / "app/flutter/linux/CMakeLists.txt").read_text())
        self.assertIn('set(BINARY_NAME "qi_wellness")', (self.root / "app/flutter/windows/CMakeLists.txt").read_text())
        self.assertIn('window.Create(L"qi_wellness"', (self.root / "app/flutter/windows/runner/main.cpp").read_text())
        self.assertIn("qi_flutter", (self.root / "app/flutter/rust_builder/cargokit/README.md").read_text())
        self.assertEqual((self.root / "scripts/tests/test_fixture.py").read_text(), 'OLD_PROJECT = "qi_flutter"\n')

    def test_rejects_invalid_names_and_application_id(self) -> None:
        invalid_new_name = self._run("qi_flutter", "QiWellness", "--application-id", "pl.example.qiwellness")
        invalid_old_name = self._run("QiFlutter", "qi_wellness", "--application-id", "pl.example.qiwellness")
        invalid_id = self._run("qi_flutter", "qi_wellness", "--application-id", "pl..qiwellness")
        self.assertEqual(invalid_new_name.returncode, 2)
        self.assertEqual(invalid_old_name.returncode, 2)
        self.assertEqual(invalid_id.returncode, 2)

    def test_refuses_path_conflict_before_modifying_files(self) -> None:
        (self.root / "rust/crates/rust_lib_qi_wellness").mkdir(parents=True)
        before = (self.root / "app/flutter/pubspec.yaml").read_text()
        result = self._run("qi_flutter", "qi_wellness", "--application-id", "pl.example.qiwellness")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Refusing to overwrite existing paths", result.stderr)
        self.assertEqual((self.root / "app/flutter/pubspec.yaml").read_text(), before)


if __name__ == "__main__":
    unittest.main()
