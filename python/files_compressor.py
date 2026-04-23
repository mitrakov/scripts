#!/usr/bin/env python3
# takes all files in folder and copies their content into a single file
import re
import sys
import argparse
from pathlib import Path

def compress_sql(content):
    content = re.sub(r'\s+', ' ', content)
    return content.strip()

def process_folder(folder_path):
    folder = Path(folder_path)

    if not folder.exists() or not folder.is_dir():
        print(f"Error: {folder_path} is not a valid directory.")
        return

    # Using rglob to catch all files in subfolders if they exist
    files = list(folder.rglob("*"))

    for file_path in files:
        if file_path.is_file():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    raw_content = f.read()
                    compressed = compress_sql(raw_content)

                    print(f"#!file: {file_path.absolute()}:")
                    print(compressed)
                    print()
            except Exception as e:
                sys.stderr.write(f"Skipping {file_path}: {e}\n")

def main():
    parser = argparse.ArgumentParser(description="Compress SQL/Text files for context sharing.")
    parser.add_argument("path", help="Path to the folder containing files")
    args = parser.parse_args()
    process_folder(args.path)

if __name__ == "__main__":
    main()
