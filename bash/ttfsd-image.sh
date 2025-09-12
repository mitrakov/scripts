#!/bin/bash
set -e

# Function to display usage
usage() {
    echo "Usage: $0 <file1> [file2] [file3] ..."
    echo ""
    echo "Optimize specific image files:"
    echo "  - JPEG/JPG files: compressed to 25% quality using jpegoptim"
    echo "  - PNG files: compressed using imagemagick + pngquant"
    echo ""
    echo "Required tools: jpegoptim, pngquant, imagemagick (mogrify)"
    echo ""
    echo "Example:"
    echo "  $0 photo1.jpg photo2.png"
    echo "  $0 /path/to/image.jpeg"
}

# Check required tools
if ! command -v jpegoptim >/dev/null 2>&1; then
    echo "Error: Please install jpegoptim"
    exit 1
fi

if ! command -v pngquant >/dev/null 2>&1; then
    echo "Error: Please install pngquant"
    exit 1
fi

if ! command -v mogrify >/dev/null 2>&1; then
    echo "Error: Please install imagemagick"
    exit 1
fi

# Check if at least one file argument is provided
if [ $# -eq 0 ]; then
    echo "Error: No files specified"
    usage
    exit 1
fi

echo "Processing $# image file(s)..."

# Separate files by type for batch processing
jpeg_files=()
png_files=()

# Classify files by extension
for file in "$@"; do
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Warning: File '$file' does not exist, skipping..."
        continue
    fi
    
    # Get the file extension (case insensitive)
    extension="${file##*.}"
    case "${extension,,}" in
        jpg|jpeg)
            jpeg_files+=("$file")
            ;;
        png)
            png_files+=("$file")
            ;;
        *)
            echo "Warning: Unsupported file format '$extension' for file '$file', skipping..."
            ;;
    esac
done

# Process JPEG files
if [ ${#jpeg_files[@]} -gt 0 ]; then
    echo
    echo "Optimizing ${#jpeg_files[@]} JPEG file(s) with jpegoptim (25% quality)..."
    for file in "${jpeg_files[@]}"; do
        echo "  Processing: $file"
        if jpegoptim -m25 "$file" 2>/dev/null; then
            echo "  Completed: $file"
        else
            echo "  Error: Failed to optimize $file"
        fi
    done
fi

# Process PNG files
if [ ${#png_files[@]} -gt 0 ]; then
    echo
    echo "Optimizing ${#png_files[@]} PNG file(s) with imagemagick + pngquant..."
    
    # First pass: mogrify (imagemagick)
    for file in "${png_files[@]}"; do
        echo "  Processing with mogrify: $file"
        if mogrify -quality 25 "$file" 2>/dev/null; then
            echo "  Mogrify completed: $file"
        else
            echo "  Error: Mogrify failed for $file"
        fi
    done
    
    # Second pass: pngquant
    for file in "${png_files[@]}"; do
        echo "  Processing with pngquant: $file"
        if pngquant "$file" --ext .png --force 2>/dev/null; then
            echo "  Pngquant completed: $file"
        else
            echo "  Error: Pngquant failed for $file"
        fi
    done
fi

echo
echo "All image optimizations completed."

# Summary
total_processed=$((${#jpeg_files[@]} + ${#png_files[@]}))
echo "Summary: $total_processed files processed (${#jpeg_files[@]} JPEG, ${#png_files[@]} PNG)"
