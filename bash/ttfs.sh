#!/bin/bash
set -e

# Colours for output
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

function error() {
    echo -e "${RED}$1${NC}"
}

# Variables
OUT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)     # script dir
ORIGIN=""
LOCATION=""
PERSON=""
TAGS=""
TAGS_FROM_FILENAME=false
EXTRACT_TS_FILE=false
EXTRACT_TS_PHOTO=false

# Function to display help
function show_help() {
    info "Usage:   $0 [OPTIONS] file1 file2 ... fileN"
    info  "Example: $0 --src iphone --loc london --usr me --tags my-kids --extract-photo-ts --extract-file-ts --out /Users/tommy/ttfs 1.JPG 2.JPG 3.JPG myDir"
    echo
    echo "┌──────────────────────┬──────────────────────────────────────────────────────────────────┬──────────────────────┐"
    echo "│ Option               │ Description                                                      │ Example              │"
    echo "├──────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────┤"
    echo "│ --src SOURCE         │ File source (inet, iphone, hdd, usb, fb, vk, twitter, etc.)      │ --src phone          │"
    echo "│ --loc LOCATION       │ Location (home, work, college, la, nyc, paris, usa, china, etc.) │ --loc work           │"
    echo "│ --usr PERSON         │ Person or group of people (me, wife, parents, colleagues, etc.)  │ --usr wife           │"
    echo "│ --tags TAG1-TAG2     │ Dash-separated-tags (my-wedding-photos, my-dogs-video, etc.)     │ --tags my-kids       │"
    echo "│ --tags-from-filename │ Convert filename to tags                                         │ --tags-from-filename │"
    echo "│ --extract-file-ts    │ Extract file creation time from the file system                  │ --extract-file-ts    │"
    echo "│ --extract-photo-ts   │ Extract photo creation time from the EXIF data (if exists)       │ --extract-photo-ts   │"
    echo "│ --out FOLDER         │ Output folder (default is script directory)                      │ --out /Users/me/ttfs │"
    echo "│ --help               │ Show this help message                                           │ --help               │"
    echo "│ --                   │ End of options marker                                            │ --                   │"
    echo "└──────────────────────┴──────────────────────────────────────────────────────────────────┴──────────────────────┘"
    echo
    echo 'If both "--extract-file-ts" and "--extract-photo-ts" specified, then tries to extract from photo, then from FS'
    echo
}

# Basis checks
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "Currently this tool is available only for MacOS"
    exit 1
fi
if ! command -v exif &> /dev/null; then
    error "Error: The 'exif' utility could not be found. Please install it via Homebrew: brew install exif"   # TODO: Linux?
    exit 1
fi



# Show help if no arguments provided
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --src)
            if [[ -n $2 && $2 != --* ]]; then
                ORIGIN="$2"
                shift 2
            else
                error "Error: --src requires a value"
                show_help
                exit 1
            fi
            ;;
        --loc)
            if [[ -n $2 && $2 != --* ]]; then
                LOCATION="$2"
                shift 2
            else
                error "Error: --loc requires a value"
                show_help
                exit 1
            fi
            ;;
        --usr)
            if [[ -n $2 && $2 != --* ]]; then
                PERSON="$2"
                shift 2
            else
                error "Error: --usr requires a value"
                show_help
                exit 1
            fi
            ;;
        --tags)
            if [[ -n $2 && $2 != --* ]]; then
                TAGS="$2"
                shift 2
            else
                error "Error: --tags requires a value"
                show_help
                exit 1
            fi
            ;;
        --tags-from-filename)
            TAGS_FROM_FILENAME=true
            shift
            ;;
        --extract-file-ts)
            EXTRACT_TS_FILE=true
            shift
            ;;
        --extract-photo-ts)
            EXTRACT_TS_PHOTO=true
            shift
            ;;
        --out)
            if [[ -n $2 && $2 != --* ]]; then
                OUT_DIR="$2"
                shift 2
            else
                error "Error: --out requires a value"
                show_help
                exit 1
            fi
            ;;
        --help)
            show_help
            exit 0
            ;;
        --)
            # End of options marker
            shift
            break
            ;;
        --*)
            error "Error: Unknown option $1"
            exit 1
            ;;
        *)
            # Non-option argument - treat as positional argument
            break
            ;;
    esac
done

# Check main flags
if [[ -z "$ORIGIN" ]]; then
    error "Error: --src required"
    show_help
    exit 1
fi

if [[ -z "$LOCATION" ]]; then
    error "Error: --loc required"
    show_help
    exit 1
fi

if [[ -z "$PERSON" ]]; then
    error "Error: --usr required"
    show_help
    exit 1
fi

if [[ -z "$TAGS" && $TAGS_FROM_FILENAME == false ]]; then
    error "Error: --tags or --tags-from-filename required"
    show_help
    exit 1
fi

if [[ -n $TAGS && $TAGS_FROM_FILENAME == true ]]; then
    error "Only one flag should be set: --tags or --tags-from-filename"
    show_help
    exit 1
fi

# Check remaining positional arguments
if [[ $# == 0 ]]; then
    error "Error: No files specified in argument list"
    show_help
    exit 1
fi

# Handles single file
function handle_file() {
  filename=$1
  # date-time
  local now=$(date +%Y-%m-%d-%H-%M-%S)                                # TODO Linux?
  if [[ $EXTRACT_TS_PHOTO == true ]]; then
    local exif_data=$(exif --machine-readable --tag 0x9003 "$filename" 2>/dev/null || \
                      exif --machine-readable --tag 0x0132 "$filename" 2>/dev/null)
    if [[ -n "$exif_data" ]]; then
      now=$(date -j -f "%Y:%m:%d %H:%M:%S" "$exif_data" +"%Y-%m-%d-%H-%M-%S") # TODO Linux: date -d"${d//:/-}" +"%Y-%m-%d-%H-%M-%S"
      EXTRACT_TS_FILE=false
      log "Extracted original photo creation time: $now"
    else
      echo "Cannot extract photo creation time for $filename"
    fi
  fi
  if [[ $EXTRACT_TS_FILE == true ]]; then
    now=$(stat -f %SB -t %Y-%m-%d-%H-%M-%S "$filename")             # TODO Linux: stat -c %w "$filename"
    log "Extracted original file creation time: $now"
  fi
  local year="${now:0:4}"
  # tags and extension
  local extension=""
  if [[ "$filename" == *.* && "$filename" != .* ]]; then
    extension="${filename##*.}"
  fi
  local extLower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')    # toLowerCase
  if [[ $TAGS_FROM_FILENAME == true ]]; then
    local base=$(basename "$filename")
    local name="${base%.*}"                                           # extract pure name without extension
    TAGS=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')    # toLowerCase, replace ' ' with -
  fi
  # final name
  local newName="${now}_${ORIGIN}_${LOCATION}_${PERSON}_${TAGS}.$extLower"
  info "Storage name: $newName"
  sleep 1                                                             # to have diff time for diff files
  # run
  mkdir -p "$OUT_DIR/$year"
  mv -v "$filename" "$OUT_DIR/$year/$newName"
  echo
}

# Main loop
function main() {
  for path in "$@"; do
    if [[ -f "$path" ]]; then                                       # if file
      if [[ -s "$path" ]]; then                                     # -s = sized file
        handle_file "$path"
      else
        error "Error: file is empty: $1"
        show_help
        exit 1
      fi
    elif [[ -d "$path" ]]; then                                     # if directory
      shopt -s nullglob
        for file in "$path"/*; do
          if [ -f "$file" ]; then
            handle_file "$file"
          fi
        done
      shopt -u nullglob

      if rmdir "$path" 2>/dev/null; then
        info "$path removed"
        echo
      fi
    else
      error "Error: Path does not exist or is not a file/directory: $path"
      show_help
      exit 1
    fi
  done
}

# Main program
echo "  Files:    $@"
echo "  --src:    $ORIGIN"
echo "  --loc:    $LOCATION"
echo "  --usr:    $PERSON"
echo "  --tags:   $TAGS"
echo "  --out:    $OUT_DIR"

main "$@"
log "Done..."
