#!/bin/bash
set -e

# Function to display usage
usage() {
    echo "Usage: $0 <file1> [file2] [file3] ..."
    echo ""
    echo "Process specific video files with ffmpeg optimization."
    echo "Supports: .avi .mp4 .mpg .mov .mkv .flv .webm"
    echo ""
    echo "Example:"
    echo "  $0 video1.mp4 video2.avi"
    echo "  $0 /path/to/video.mp4"
}

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: Please install ffmpeg"
    exit 1
fi

# Check if at least one file argument is provided
if [ $# -eq 0 ]; then
    echo "Error: No files specified"
    usage
    exit 1
fi

# Create temporary directory
temp_dir=$(mktemp -d)
trap "rm -rf '$temp_dir'" EXIT  # Clean up temp dir on exit

echo "Using temp directory: $temp_dir"
echo "Processing $# file(s)..."

# Process each file passed as argument
for file in "$@"; do
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Warning: File '$file' does not exist, skipping..."
        continue
    fi
    
    # Get the file extension
    extension="${file##*.}"
    
    # Check if it's a supported video format (case insensitive)
    case "${extension,,}" in
        avi|mp4|mpg|mov|mkv|flv|webm)
            echo
            echo "Converting: $file"
            
            # Get absolute path for the file
            abs_file=$(realpath "$file")
            filename=$(basename "$file")
            
            # Use temp directory for intermediate file
            temp_file="$temp_dir/$filename"
            
            echo "  $abs_file -> $temp_file -> $abs_file"
            
            # Convert to temporary file in temp directory
            if ffmpeg -i "$abs_file" -map_metadata 0 "$temp_file"; then
                # Replace original with converted file
                mv "$temp_file" "$abs_file"
                echo "  Completed: $file"
            else
                echo "  Error: Failed to convert $file"
            fi
            ;;
        *)
            echo "Warning: Unsupported file format '$extension' for file '$file', skipping..."
            ;;
    esac
done

echo
echo "All conversions completed. Temp directory will be cleaned up automatically."
