#!/usr/bin/env python3
import os
import sys

def replace_in_file(filepath, old_str, new_str):
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            
        if old_str in content:
            content = content.replace(old_str, new_str)
            with open(filepath, 'w', encoding='utf-8') as file:
                file.write(content)
            print(f"Updated: {filepath}")
    except Exception as e:
        print(f"Could not read/write {filepath}: {e}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python rename_project.py <old_name> <new_name>")
        print("Example: python rename_project.py qi_flutter awesome_app")
        sys.exit(1)

    old_name = sys.argv[1]
    new_name = sys.argv[2]
    
    # Define directories to scan (avoiding hidden dirs and target/build folders)
    scan_dirs = ['.github', 'app/flutter', 'rust', 'design', 'testing', 'scripts']
    root_files = ['README.md', 'AGENTS.md', 'GEMINI.md', 'RELEASES_AND_BRANCHING.md']

    for d in scan_dirs:
        for root, dirs, files in os.walk(d):
            # Skip build/target/hidden directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['build', 'target', '.dart_tool', 'Outputs']]
            
            for file in files:
                if not file.startswith('.'):
                    filepath = os.path.join(root, file)
                    replace_in_file(filepath, old_name, new_name)

    for file in root_files:
        if os.path.exists(file):
            replace_in_file(file, old_name, new_name)
            
    print("\nText replacement complete!")
    print(f"NOTE: You may still need to manually rename the Android package (com.example.{old_name})")
    print("and run `flutter clean` & `flutter pub get`.")

if __name__ == '__main__':
    main()

