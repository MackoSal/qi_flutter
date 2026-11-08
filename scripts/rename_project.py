#!/usr/bin/env python3
"""Rename a qi_flutter template checkout and set its native application ID."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKIP_PARTS = {".git", ".dart_tool", "build", "target", "Outputs"}
VENDORED_PARTS = {"cargokit"}
SHARED_TOOLCHAIN_IMAGE = "ghcr.io/mackosal/qi_flutter-devcontainer"


def project_files() -> list[Path]:
    """Return tracked text-file candidates, excluding vendored build tooling."""
    result = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, check=True, capture_output=True
    )
    paths = []
    for item in result.stdout.decode().split("\0"):
        if not item:
            continue
        path = Path(item)
        if SKIP_PARTS.intersection(path.parts) or VENDORED_PARTS.intersection(path.parts):
            continue
        if path.parts[:2] == ("scripts", "tests"):
            continue
        absolute = ROOT / path
        if absolute.is_file():
            paths.append(path)
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rename the template's project/package names and native app ID."
    )
    parser.add_argument("old_name", help="Current project name, usually qi_flutter")
    parser.add_argument("new_name", help="New Dart/Rust crate name, e.g. qi_wellness")
    parser.add_argument(
        "--application-id",
        required=True,
        help="Unique reverse-DNS ID, e.g. pl.example.qiwellness",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Show planned edits without writing files"
    )
    args = parser.parse_args()

    if not re.fullmatch(r"[a-z][a-z0-9_]*", args.old_name):
        parser.error("old_name must be a lowercase Dart/Rust name, e.g. qi_flutter")
    if not re.fullmatch(r"[a-z][a-z0-9_]*", args.new_name):
        parser.error("new_name must be a lowercase Dart/Rust name, e.g. qi_wellness")
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+", args.application_id):
        parser.error("--application-id must be a reverse-DNS ID, e.g. pl.example.app")
    if args.old_name == args.new_name:
        parser.error("old_name and new_name must be different")

    try:
        paths = project_files()
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"Could not list tracked project files: {error}", file=sys.stderr)
        return 1

    edits: list[tuple[Path, bytes]] = []
    moves: list[tuple[Path, Path]] = []
    moved_directories: set[Path] = set()
    for relative in paths:
        if relative == Path("scripts/rename_project.py"):
            continue
        source = ROOT / relative
        try:
            original = source.read_bytes()
            text = original.decode("utf-8")
        except (UnicodeDecodeError, OSError):
            continue

        app_id_token = "__TEMPLATE_APPLICATION_ID__"
        image_token = "__SHARED_TEMPLATE_TOOLCHAIN_IMAGE__"
        updated = text.replace(SHARED_TOOLCHAIN_IMAGE, image_token)
        updated = updated.replace("com.example.qi_flutter", app_id_token)
        updated = updated.replace("com.example.qiFlutter", app_id_token)
        updated = updated.replace("com.example", app_id_token)
        updated = updated.replace(args.old_name, args.new_name)
        updated = updated.replace(app_id_token, args.application_id)
        updated = updated.replace(image_token, SHARED_TOOLCHAIN_IMAGE)
        encoded = updated.encode("utf-8")
        if encoded != original:
            edits.append((relative, encoded))

        bridge_dir = Path("rust/crates") / f"rust_lib_{args.old_name}"
        if bridge_dir in relative.parents:
            if bridge_dir not in moved_directories:
                moves.append((bridge_dir, Path("rust/crates") / f"rust_lib_{args.new_name}"))
                moved_directories.add(bridge_dir)
            continue

        kotlin_dir = Path("app/flutter/android/app/src/main/kotlin/com/example") / args.old_name
        if kotlin_dir in relative.parents:
            if kotlin_dir not in moved_directories:
                target_dir = Path("app/flutter/android/app/src/main/kotlin") / Path(
                    *args.application_id.split(".")
                )
                moves.append((kotlin_dir, target_dir))
                moved_directories.add(kotlin_dir)
            continue

        renamed = Path(str(relative).replace(args.old_name, args.new_name))
        if renamed != relative:
            moves.append((relative, renamed))

    print(f"Project name: {args.old_name} -> {args.new_name}")
    print(f"Native application ID: -> {args.application_id}")
    print(f"Text files to update: {len(edits)}")
    print(f"Paths to move: {len(moves)}")
    if args.dry_run:
        for relative, _ in edits:
            print(f"  edit {relative}")
        for old_path, new_path in moves:
            print(f"  move {old_path} -> {new_path}")
        return 0

    conflicts = [
        new_path
        for old_path, new_path in moves
        if old_path != new_path and (ROOT / new_path).exists()
    ]
    if conflicts:
        print(
            "Refusing to overwrite existing paths: "
            + ", ".join(path.as_posix() for path in conflicts),
            file=sys.stderr,
        )
        return 1

    for relative, content in edits:
        (ROOT / relative).write_bytes(content)
    for old_path, new_path in moves:
        source = ROOT / old_path
        destination = ROOT / new_path
        if not source.exists():
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.rename(destination)

    kotlin_parent = ROOT / "app/flutter/android/app/src/main/kotlin/com/example"
    for directory in (kotlin_parent, kotlin_parent.parent):
        try:
            directory.rmdir()
        except OSError:
            break

    print("Rename complete. Next: flutter clean, flutter pub get, then regenerate FRB bindings.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
