#!/usr/bin/env bash
# by DeepSeek AI
# this script will remove first N characters from all file names in a chosen directory
set -euo pipefail

# Check if parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage:   $0 <N> <directory>"
    echo "Example: $0 20 /Users/tommy/temp"
    exit 1
fi

N="$1"
target_dir="$2"

# Validate N is a positive integer
if ! [[ "$N" =~ ^[0-9]+$ ]] || [ "$N" -eq 0 ]; then
    echo "Error: N must be a positive integer"
    exit 1
fi

# Check if directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: Directory '$target_dir' does not exist"
    exit 1
fi

# Store current directory and change to target
current_dir="$(pwd)"
cd "$target_dir" || return 1

# Process files in the target directory
for file in *; do
    # Check if it's a regular file (not a directory)
    if [ -f "$file" ]; then
        # Get the filename without the first N characters
        newname="${file:$N}"
        
        # Check if the new name would be different and not empty
        if [ "$newname" != "$file" ] && [ -n "$newname" ]; then
            # Check if a file with the new name already exists
            if [ ! -e "$newname" ]; then
                mv -v "$file" "$newname"
            else
                echo "Warning: '$newname' already exists. Skipping '$file'"
            fi
        else
            if [ -z "$newname" ]; then
                echo "Warning: Skipping '$file' - new name would be empty"
            else
                echo "Warning: Skipping '$file' - name unchanged (too short?)"
            fi
        fi
    fi
done

# Return to original directory
cd "$current_dir"
