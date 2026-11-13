"""Regression tests against a temporary copy of this repository checkout."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = SOURCE_ROOT / "scripts/rename_project.py"
OLD_NAME = "qi_flutter"
NEW_NAME = "my_app"
NEW_ID = "pl.example.myapp"


class RenameProjectTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name) / "checkout"
        self.root.mkdir()

        result = subprocess.run(
            # GitHub Actions runs this test inside a container where the
            # checkout can be owned by a different UID. Mark only this
            # source checkout as safe for this read-only Git command; do not
            # change the runner's global Git configuration.
            [
                "git",
                "-c",
                f"safe.directory={SOURCE_ROOT}",
                "ls-files",
                "-co",
                "--exclude-standard",
                "-z",
            ],
            cwd=SOURCE_ROOT,
            check=True,
            capture_output=True,
        )
        for item in result.stdout.decode().split("\0"):
            if not item:
                continue
            relative = Path(item)
            source = SOURCE_ROOT / relative
            if not source.is_file():
                continue
            try:
                source.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

        subprocess.run(["git", "init", "-q"], cwd=self.root, check=True)
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _run(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", "scripts/rename_project.py", *args],
            cwd=self.root,
            check=False,
            text=True,
            capture_output=True,
        )

    def _text_files(self) -> list[Path]:
        return [path for path in self.root.rglob("*") if path.is_file() and ".git" not in path.parts]

    def test_dry_run_reports_changes_without_writing(self) -> None:
        before = {
            path.relative_to(self.root): path.read_bytes()
            for path in self._text_files()
        }
        result = self._run(
            OLD_NAME,
            NEW_NAME,
            "--application-id",
            NEW_ID,
            "--dry-run",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Text files to update:", result.stdout)
        self.assertIn("Paths to move: 1", result.stdout)
        after = {
            path.relative_to(self.root): path.read_bytes()
            for path in self._text_files()
        }
        self.assertEqual(after, before)

    def test_rename_updates_names_and_all_native_platform_identifiers(self) -> None:
        result = self._run(OLD_NAME, NEW_NAME, "--application-id", NEW_ID)
        self.assertEqual(result.returncode, 0, result.stderr)

        self.assertTrue((self.root / "app/flutter/pubspec.yaml").is_file())
        self.assertIn(NEW_NAME, (self.root / "app/flutter/pubspec.yaml").read_text())
        self.assertTrue((self.root / "rust/crates/qi_gateway/Cargo.toml").is_file())
        self.assertFalse((self.root / "rust/crates/rust_lib_qi_flutter").exists())
        self.assertIn(
            'name = "qi_gateway"',
            (self.root / "rust/crates/qi_gateway/Cargo.toml").read_text(),
        )
        for path in [
            self.root / ".devcontainer/devcontainer.json",
            self.root / ".github/workflows/ci-cd.yml",
        ]:
            self.assertIn(
                "ghcr.io/mackosal/qi_flutter-devcontainer:1",
                path.read_text(encoding="utf-8"),
                path,
            )
        self.assertTrue(
            (
                self.root
                / "app/flutter/android/app/src/main/kotlin/pl/example/myapp/MainActivity.kt"
            ).is_file()
        )

        platform_paths = [
            self.root / "app/flutter/android/app/build.gradle.kts",
            self.root / "app/flutter/ios/Runner.xcodeproj/project.pbxproj",
            self.root / "app/flutter/macos/Runner/Configs/AppInfo.xcconfig",
            self.root / "app/flutter/macos/Runner.xcodeproj/project.pbxproj",
            self.root / "app/flutter/linux/CMakeLists.txt",
        ]
        for path in platform_paths:
            self.assertTrue(path.is_file(), path)
            contents = path.read_text(encoding="utf-8")
            self.assertIn(NEW_ID, contents, path)
            self.assertNotIn("com.example", contents, path)
            self.assertNotIn("com.example.qiFlutter", contents, path)

        for path in [
            self.root / "app/flutter/windows/CMakeLists.txt",
            self.root / "app/flutter/windows/runner/main.cpp",
        ]:
            contents = path.read_text(encoding="utf-8")
            self.assertIn(NEW_NAME, contents, path)

        leftovers = []
        for path in self._text_files():
            if path == self.root / "scripts/rename_project.py" or {
                "scripts",
                "tests",
            }.issubset(path.parts):
                continue
            if "cargokit" in path.parts:
                continue
            try:
                contents = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            contents = contents.replace(
                "ghcr.io/mackosal/qi_flutter-devcontainer", ""
            )
            if OLD_NAME in contents or "com.example" in contents:
                leftovers.append(path.relative_to(self.root).as_posix())
        self.assertEqual(leftovers, [])

    def test_rejects_invalid_names_and_application_id(self) -> None:
        cases = [
            ("MyApp", NEW_ID),
            (NEW_NAME, "pl..myapp"),
        ]
        for new_name, app_id in cases:
            with self.subTest(new_name=new_name, app_id=app_id):
                result = self._run(OLD_NAME, new_name, "--application-id", app_id)
                self.assertEqual(result.returncode, 2)

        invalid_old_name = self._run("QiFlutter", NEW_NAME, "--application-id", NEW_ID)
        self.assertEqual(invalid_old_name.returncode, 2)

    def test_refuses_path_conflict_before_modifying_files(self) -> None:
        conflict = self.root / "app/flutter/android/app/src/main/kotlin/pl/example/myapp"
        conflict.mkdir(parents=True)
        before = (self.root / "app/flutter/pubspec.yaml").read_bytes()
        result = self._run(OLD_NAME, NEW_NAME, "--application-id", NEW_ID)
        self.assertEqual(result.returncode, 1)
        self.assertIn("Refusing to overwrite existing paths", result.stderr)
        self.assertEqual((self.root / "app/flutter/pubspec.yaml").read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
