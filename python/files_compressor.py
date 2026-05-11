#!/usr/bin/env python3
# Takes files in a folder by mask(s) and copies their content into a single output stream.
import re
import sys
import argparse
from pathlib import Path

def compress_sql(content):
    """Condense all whitespace into single spaces to reduce token count."""
    content = re.sub(r'\s+', ' ', content)
    return content.strip()

def process_folder(folder_path, masks):
    folder = Path(folder_path)

    if not folder.exists() or not folder.is_dir():
        sys.stderr.write(f"Error: {folder_path} is not a valid directory.\n")
        return

    # Split masks by comma and remove whitespace
    patterns = [p.strip() for p in masks.split(',')]
    
    # Use a set to avoid duplicates if multiple patterns match the same file
    files = set()
    for pattern in patterns:
        files.update(folder.rglob(pattern))

    if not files:
        sys.stderr.write(f"No files found matching patterns: {masks} in {folder_path}\n")
        return

    # Sort files by path for deterministic, readable output
    for file_path in sorted(files):
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
    parser = argparse.ArgumentParser(
        description="Compress text files in a directory into a single file",
        epilog="""
Example usage:
  %(prog)s ./my_project --mask "*.scala,*.java,*.sql"
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument("path", help="Path to the folder containing files")
    parser.add_argument(
        "--mask", 
        default="*", 
        help="Comma-separated file masks (e.g., '*.scala,*.sql'). Default is '*'"
    )
    
    args = parser.parse_args()
    process_folder(args.path, args.mask)

if __name__ == "__main__":
    main()
