#!/usr/bin/env bash

root_dir="$1"
TTFS_DIR="$2"

if [[ -z "$root_dir" || -z "$TTFS_DIR" ]]; then
    echo "Usage: $0 <root_dir> ttfs-dir"
    exit 1
fi

# Remove trailing slash if present
root_dir="${root_dir%/}"

# Resolve path to ttfs.sh (same dir as this script)
script_dir="$(cd "$(dirname "$0")" && pwd)"
ttfs="$script_dir/ttfs.sh"

# Convert root_dir to absolute path
root_dir_abs="$(cd "$root_dir" && pwd)"

# Traverse files safely
find "$root_dir_abs" -type f -print0 | while IFS= read -r -d '' file; do
    # Absolute path is already $file

    # Relative path to root_dir
    rel_path="${file#$root_dir_abs/}"

    # Directory part of relative path
    rel_dir=$(dirname "$rel_path")

    # Normalize directory: replace / with -
    if [[ "$rel_dir" == "." ]]; then
        norm_dir="none"
    else
        norm_dir="${rel_dir//\//-}"
    fi

    # Call ttfs.sh safely with absolute file path
    "$ttfs" --tags "$norm_dir" --extract-ts --out "$TTFS_DIR" "$file"
done
