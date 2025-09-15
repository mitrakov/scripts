#!/usr/bin/env bash
set -euo pipefail

# Logger
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

function log() {
    echo -e "${GREEN}$1${NC}"
}

function info() {
    echo -e "${BLUE}$1${NC}"
}

function msg() {
    echo -e "${YELLOW}$1${NC}"
}

function warn() {
    echo -e "${PURPLE}$1${NC}"
}

function error() {
    echo -e "${RED}$1${NC}"
}



# BASIC CHECKS
if ! [ `which jpegoptim` ]; then
    error "Please install jpegoptim"
    exit 1
fi

if ! [ `which pngquant` ]; then
    error "Please install pngquant"
    exit 1
fi

if ! [ `which mogrify` ]; then
    error "Please install imagemagick"
    exit 1
fi

if ! [ `which ffmpeg` ]; then
    error "Please install ffmpeg"
    exit 1
fi

if [[ $# -eq 0 ]]; then
    error "Usage: $0 <START_DIR> <TTFS_DIR>"
    exit 0
fi



# CHECKING DIRECTORIES
ROOT_DIR="$1"
TTFS_DIR="$2"

ROOT_DIR="${ROOT_DIR%/}"                # remove trailing slash if present
TTFS_DIR="${TTFS_DIR%/}"

if [[ ! -d "$ROOT_DIR" ]]; then
  error "Error: Directory '$ROOT_DIR' not found"
  exit 1
fi

if [[ ! -d "$TTFS_DIR" ]]; then
  error "Error: Directory '$TTFS_DIR' not found"
  exit 1
fi

ROOT_DIR="$(cd "$ROOT_DIR" && pwd)"     # convert to absolute path
TTFS_DIR="$(cd "$TTFS_DIR" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TTFS="$SCRIPT_DIR/ttfs.sh"              # resolve path to ttfs.sh (same dir as this script)

if [[ ! -x "$TTFS" ]]; then
  error "Error: script '$TTFS' not found or is not executable"
  exit 1
fi



# STEP 1: collect all files into an array (to avoid possible issues in working directory)
files=()
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find "$ROOT_DIR" -type f -print0)
if [[ ${#files[@]} -eq 0 ]]; then
    warn "Success: no new files found"
    exit 0
else
    log "Found ${#files[@]} file(s). Start processing..."
fi



# STEP 2: process the collected files
for file in "${files[@]}"; do
    echo
    echo
    info "Processing: $file"
    
    # compress photo and video files
    shopt -s nocasematch
    extension="${file##*.}"
    case "$extension" in
      mp4|mov|avi|mkv|wmv|flv|webm|mpg)
        info "Compressing video file..."
        echo "Converting: $file -> $file.$extension"
        ffmpeg -i "$file" -map_metadata 0 "$file.$extension" # "-map_metadata 0" keeps metadata
        mv -f "$file.$extension" "$file"
        ;;
      jpg|jpeg)
        info "Compressing JPEG file..."
        jpegoptim -m25 "$file"
        ;;
      png)
        info "Compressing PNG file..."
        mogrify -verbose -quality 25 "$file" && pngquant "$file" --ext .png --force
        ;;
      *)
        echo "No compression done"
        ;;
    esac
    shopt -u nocasematch
    
    # creating tags from directory path
    rel_path="${file#$ROOT_DIR/}"     # relative path to ROOT_DIR
    rel_dir=$(dirname "$rel_path")    # directory part of relative path
    if [[ "$rel_dir" == "." ]]; then
        tags="none"
    else
        tags="${rel_dir//\//-}"       # replace / with -
    fi

    "$TTFS" --tags "$tags" --extract-ts --out "$TTFS_DIR" "$file"
done

warn "Success: ttfsd.sh: ${#files[@]} file(s) completed"
