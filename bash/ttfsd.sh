#!/usr/bin/env bash

ROOT_DIR="$1"
TTFS_DIR="$2"

if [[ -z "$ROOT_DIR" || -z "$TTFS_DIR" ]]; then
    echo "Usage: $0 <START_DIR> <TTFS_DIR>"
    exit 1
fi

# Remove trailing slash if present
ROOT_DIR="${ROOT_DIR%/}"
TTFS_DIR="${TTFS_DIR%/}"

# Resolve path to ttfs.sh (same dir as this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TTFS="$SCRIPT_DIR/ttfs.sh"
JPEG_OPT="$SCRIPT_DIR/jpeg-optimizer.sh"
MPEG_OPT="$SCRIPT_DIR/mpeg-optimizer.sh"

# Convert ROOT_DIR to absolute path
ROOT_DIR_abs="$(cd "$ROOT_DIR" && pwd)"



















# Script paths
MPEG_OPT="/path/to/your/mpeg-optimizer.sh"
IMAGE_OPT="/path/to/your/image-optimizer.sh"
ROOT_DIR_abs="/path/to/your/directory"

echo "Starting media optimization in: $ROOT_DIR_abs"

# Process video files
echo "=== VIDEO OPTIMIZATION ==="
echo "Collecting video files..."

video_files=()
while IFS= read -r -d '' file; do
    video_files+=("$file")
done < <(find "$ROOT_DIR_abs" -type f \( -name "*.avi" -o -name "*.mp4" -o -name "*.mpg" -o -name "*.mov" -o -name "*.mkv" -o -name "*.flv" -o -name "*.webm" \) -print0)

echo "Found ${#video_files[@]} video files."

if [ ${#video_files[@]} -gt 0 ]; then
    echo "Starting video optimization..."
    "$MPEG_OPT" "${video_files[@]}"
else
    echo "No video files found to process."
fi

echo

# Process image files
echo "=== IMAGE OPTIMIZATION ==="
echo "Collecting image files..."

image_files=()
while IFS= read -r -d '' file; do
    image_files+=("$file")
done < <(find "$ROOT_DIR_abs" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -print0)

echo "Found ${#image_files[@]} image files."

if [ ${#image_files[@]} -gt 0 ]; then
    echo "Starting image optimization..."
    "$IMAGE_OPT" "${image_files[@]}"
else
    echo "No image files found to process."
fi

echo
echo "=== OPTIMIZATION COMPLETE ==="
echo "Processed:"
echo "  - ${#video_files[@]} video files"
echo "  - ${#image_files[@]} image files"


# Step 1: Collect all files into an array
files=()
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find "$ROOT_DIR_abs" -type f -print0)

echo "Found ${#files[@]} files. Starting processing..."

# Step 2: Process the collected files (find is no longer running)
for file in "${files[@]}"; do
    echo "Processing: $file"              
    dir_path=$(dirname "$file")
    (cd "$dir_path" && "$MPEG_OPT")
done

NEXT: uncomment this:
# # Traverse files safely
# find "$ROOT_DIR_abs" -type f -print0 | while IFS= read -r -d '' file; do
#     echo "Found: $file"

#     #dir_path=$(dirname "$file")
#     dir_path=$(realpath "$(dirname "$file")")

#     # # Relative path to ROOT_DIR
#     # rel_path="${file#$ROOT_DIR_abs/}"

#     # # Directory part of relative path
#     # rel_dir=$(dirname "$rel_path")

#     # # Normalize directory: replace / with -
#     # if [[ "$rel_dir" == "." ]]; then
#     #     norm_dir="none"
#     # else
#     #     norm_dir="${rel_dir//\//-}"
#     # fi

#     # Call ttfs.sh safely with absolute file path
#     (cd "$dir_path" && "$MPEG_OPT")
#     ##"$TTFS" --tags "$norm_dir" --extract-ts --out "$TTFS_DIR" "$file"
# done

