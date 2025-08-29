#!/bin/bash
set -e
TODO: --extract-tag-from-file

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
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ORIGIN=""
LOCATION=""
PERSON=""
TAGS=""
EXTRACT_TS_FILE=false
EXTRACT_TS_PHOTO=false

# Function to display help
function show_help() {
    info "Usage:   $0 [OPTIONS] file1 file2 ... fileN"
    info  "Example: $0 --src iphone --loc london --usr me --tags my-kids --extract-photo-ts --extract-file-ts 1.JPG 2.JPG 3.JPG"
    echo
    echo "┌────────────────────┬──────────────────────────────────────────────────────────────────┬────────────────────┐"
    echo "│ Option             │ Description                                                      │ Example            │"
    echo "├────────────────────┼──────────────────────────────────────────────────────────────────┼────────────────────┤"
    echo "│ --src SOURCE       │ File source (inet, iphone, hdd, usb, fb, vk, twitter, etc.)      │ --src phone        │"
    echo "│ --loc LOCATION     │ Location (home, work, college, la, nyc, paris, usa, china, etc.) │ --loc work         │"
    echo "│ --usr PERSON       │ Person or group of people (me, wife, parents, colleagues, etc.)  │ --usr wife         │"
    echo "│ --tags TAG1-TAG2   │ Dash-separated-tags (my-wedding-photos, my-dogs-video, etc.)     │ --tags my-kids     │"
    echo "│ --extract-file-ts  │ Extract file creation time from the file system                  │ --extract-file-ts  │"
    echo "│ --extract-photo-ts │ Extract photo creation time from the EXIF data (if exists)       │ --extract-photo-ts │"
    echo "│ --help             │ Show this help message                                           │ --help             │"
    echo "│ --                 │ End of options marker                                            │ --                 │"
    echo "└────────────────────┴──────────────────────────────────────────────────────────────────┴────────────────────┘"
    echo
    echo 'If both "--extract-file-ts" and "--extract-photo-ts" specified, then tries to extract from photo, then from FS'
    echo
}

# Check tools
if ! command -v exif &> /dev/null
then
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
                exit 2
            fi
            ;;
        --loc)
            if [[ -n $2 && $2 != --* ]]; then
                LOCATION="$2"
                shift 2
            else
                error "Error: --loc requires a value"
                show_help
                exit 3
            fi
            ;;
        --usr)
            if [[ -n $2 && $2 != --* ]]; then
                PERSON="$2"
                shift 2
            else
                error "Error: --usr requires a value"
                show_help
                exit 4
            fi
            ;;
        --tags)
            if [[ -n $2 && $2 != --* ]]; then
                TAGS="$2"
                shift 2
            else
                error "Error: --tags requires a value"
                show_help
                exit 5
            fi
            ;;
        --extract-file-ts)
            EXTRACT_TS_FILE=true
            shift
            ;;
        --extract-photo-ts)
            EXTRACT_TS_PHOTO=true
            shift
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
            exit 6
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
    exit 7
fi

if [[ -z "$LOCATION" ]]; then
    error "Error: --loc required"
    show_help
    exit 8
fi

if [[ -z "$PERSON" ]]; then
    error "Error: --usr required"
    show_help
    exit 9
fi

if [[ -z "$TAGS" ]]; then
    error "Error: --tags required"
    show_help
    exit 10
fi

# Check remaining positional arguments
if [[ $# == 0 ]]; then
    error "Error: No files specified in argument list"
    show_help
    exit 11
fi

# Main loop
function main() {
  for filename in "$@"; do
    if [[ -s "$filename" ]]; then
        local extension="${filename##*.}"
        local extLower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')    # toLowerCase
        local now=$(date +%Y-%m-%dT%H:%M:%S)                                # TODO Linux?
        if [[ $EXTRACT_TS_PHOTO == true ]]; then
            local d=$(exif --machine-readable --tag 0x9003 "$filename" 2>/dev/null)
            if [[ -n "$d" ]]; then
                now=$(date -j -f "%Y:%m:%d %H:%M:%S" "$d" +"%Y-%m-%dT%H:%M:%S") # TODO Linux: date -d"${d//:/-}" +"%Y-%m-%dT%H:%M:%S"
                EXTRACT_TS_FILE=false
                log "Extracted original photo creation time: $now"
            else
                echo "Cannot extract photo creation time for $filename"
            fi
        fi
        if [[ $EXTRACT_TS_FILE == true ]]; then
            now=$(stat -f %SB -t %Y-%m-%dT%H:%M:%S "$filename")             # TODO Linux?
            log "Extracted original file creation time: $now"
        fi
        local year="${now:0:4}"
        local newName="${now}_${ORIGIN}_${LOCATION}_${PERSON}_${TAGS}.$extLower"

        info "Storage name: $newName"
        sleep 1                                                             # to have diff time for diff files

        mkdir -p "$SCRIPT_DIR/$year"
        mv -v "$filename" "$SCRIPT_DIR/$year/$newName"
        echo
    else
        error "Error: File missing or empty: $1" >&2
        show_help
        exit 12
    fi
  done
}

# Main program
echo "  Files:    $@"
echo "  --src:    $ORIGIN"
echo "  --loc:    $LOCATION"
echo "  --usr:    $PERSON"
echo "  --tags:   $TAGS"

main "$@"
log "Done..."
