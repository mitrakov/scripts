#!/bin/bash
set -e

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

function warn() {
    echo -e "${PURPLE}$1${NC}"
}

function error() {
    echo -e "${RED}$1${NC}"
}

# Variables
OUT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)     # script dir by default
TAGS=""
USE_FILENAME=false
EXTRACT_TS_FILE=false
EXTRACT_TS_PHOTO=false
COUNT=0

# Function to display help
function show_help() {
    info "Usage:   $0 [OPTIONS] file1 file2 ... fileN"
    info "Example: $0 --tags my-kids --extract-photo-ts --extract-file-ts --use-filename --out /Users/tommy/ttfs 1.JPG 2.JPG 3.JPG myDir"
    echo
    echo "┌───────────────────────┬──────────────────────────────────────────────────────────────────┬──────────────────────┐"
    echo "│ Option                │ Description                                                      │ Example              │"
    echo "├───────────────────────┼──────────────────────────────────────────────────────────────────┼──────────────────────┤"
    echo "│ --tags TAG1-TAG2-TAG3 │ Dash-separated-tags                                              │ --tags my-kids-party │"
    echo "│ --extract-file-ts     │ Extract file creation time from the file system                  │ --extract-file-ts    │"
    echo "│ --extract-photo-ts    │ Extract photo creation time from the EXIF data (if exists)       │ --extract-photo-ts   │"
    echo "│ --use-filename        │ Add current filename to storage name                             │ --use-filename       │"
    echo "│ --out FOLDER          │ Output folder (default is script directory)                      │ --out /Users/me/ttfs │"
    echo "│ --help                │ Show this help message                                           │ --help               │"
    echo "└───────────────────────┴──────────────────────────────────────────────────────────────────┴──────────────────────┘"
    echo
    echo 'If both "--extract-file-ts" and "--extract-photo-ts" specified, then it tries to extract from the photo, then from the FS'
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
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tags)
            if [[ -n $2 && $2 != --* ]]; then
                if [[ ! "$2" =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$ ]]; then
                    error "Error: --tags should be dash separated: $2"
                    show_help
                    exit 1
                else
                    TAGS="$2"
                    shift 2
                fi
            else
                error "Error: --tags requires a value"
                show_help
                exit 1
            fi
            ;;
        --use-filename)
            USE_FILENAME=true
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
        --*)
            error "Error: unknown option $1"
            exit 1
            ;;
        *)
            # Non-option argument - treat as positional argument
            break
            ;;
    esac
done

# Check main flags
if [[ -z "$TAGS" ]]; then
    error "Error: --tags required"
    show_help
    exit 1
fi

# Check remaining positional arguments
if [[ $# == 0 ]]; then
    error "Error: no files specified in argument list"
    show_help
    exit 1
fi

# Handles single file
function handle_file() {
    local filename=$1
    if [[ ! -s "$filename" ]]; then
        error "Error: empty file $filename"
        exit 1
    fi

    # date-time
    sleep 1                                                                       # to have diff time for diff files
    local now=$(date +%Y-%m-%d-%H-%M-%S)                                          # default timestamp.now() TODO Linux?
    local extracted=false
    if [[ $EXTRACT_TS_PHOTO == true && $extracted == false ]]; then
        local exif_data=$(exif --machine-readable --tag 0x9003 "$filename" 2>/dev/null || \
                          exif --machine-readable --tag 0x0132 "$filename" 2>/dev/null)
        if [[ -n "$exif_data" ]]; then
            now=$(date -j -f "%Y:%m:%d %H:%M:%S" "$exif_data" +"%Y-%m-%d-%H-%M-%S") # TODO Linux: date -d"${d//:/-}" +"%Y-%m-%d-%H-%M-%S"
            extracted=true
            log "Extracted original photo creation time: $now"
        else
            echo "Cannot extract photo creation time for: $filename"
        fi
    fi
    if [[ $EXTRACT_TS_FILE == true && $extracted == false ]]; then
        now=$(stat -f %SB -t %Y-%m-%d-%H-%M-%S "$filename")                       # TODO Linux: stat -c %w "$filename"
        extracted=true
        log "Extracted original file creation time: $now"
    fi
    local year="${now:0:4}"

    # extension
    local extension="${filename##*/}"                                             # remove any path
    extension="${extension##*.}"                                                  # get text after last dot
    [[ "$extension" == "$filename" ]] && extension="noext"                        # if nothing happened (files without dot) => use "noext"

    local extLower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')              # toLowerCase

    # additional filename
    local tags2=""
    if [[ $USE_FILENAME == true ]]; then
        local base=$(basename "$filename")                                        # base filename without paths
        local name="${base%.*}"                                                   # pure name without extension
        # sanitizing: toLowerCase; " " -> "_"; rm non-Windows chars, rm (),'!; squash -- and __; "._" -> "."
        tags2=$(echo "-$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -d "<>:\"/\\|?*(),'!" | sed "s/-\{2,\}/-/g" | sed "s/_\{2,\}/_/g" | sed 's/\._/\./g')
    fi

    # final name
    local newName="${now}-$TAGS$tags2.$extLower"

    # run
    mkdir -p "$OUT_DIR/$year"
    mv -v "$filename" "$OUT_DIR/$year/$newName"
    COUNT=$((COUNT + 1))
    echo
}

# Handles single directory
function handle_directory() {
    local dir="$1"

    shopt -s nullglob
    for item in "$dir"/*; do
        if [[ -f "$item" ]]; then              # if file
            handle_file "$item"
        elif [[ -d "$item" ]]; then            # if directory
            handle_directory "$item"
        fi
    done
    shopt -u nullglob

    if rmdir "$dir" 2>/dev/null; then
        warn "$dir removed"
        echo
    fi
}

# Main loop
function main() {
    for item in "$@"; do
        if [[ -f "$item" ]]; then              # if file
            handle_file "$item"
        elif [[ -d "$item" ]]; then            # if directory
            handle_directory "$item"
        else
            error "Error: file/directory does not exist: $path"
            show_help
            exit 1
        fi
    done
}

# Main program
echo "  Files and folders:     $@"
echo "  --tags:                $TAGS"
echo "  --out:                 $OUT_DIR"
echo "  --extract-photo-ts:    $EXTRACT_TS_PHOTO"
echo "  --extract-file-ts:     $EXTRACT_TS_FILE"
echo "  --use-filename:        $USE_FILENAME"

main "$@"
log "Success. $COUNT file(s) processed."

# Midnight commander:
# F9 -> Command -> Edit menu -> User: (examples for shortcuts "w" and "e")
#
# + t r | t d
# w       Upload to Tom-Trix File System (tags)
#         TAGS=%{TTFS tags. Enter tags:}
#         ttfs.sh --tags $TAGS --extract-photo-ts --extract-file-ts --out /Users/director/Yandex.Disk.localized/ttfs %s
# 
# + t r | t d
# e       Upload to Tom-Trix File System (tags + filename)
#         TAGS=%{TTFS tags with filename. Enter tags:}
#         ttfs.sh --tags $TAGS --extract-photo-ts --extract-file-ts --use-filename --out /Users/director/Yandex.Disk.localized/ttfs %s
#
# Usage: F2

# Nimble commander:
# Settings -> Tools -> + -> select "Startup mode: Terminal"
#
# ttfs.sh
# --tags %"TTFS tags. Enter tags"? --extract-photo-ts --extract-file-ts --out /Users/director/Yandex.Disk.localized/ttfs %P
# ttfs.sh
# --tags %"TTFS tags with filename. Enter tags"? --extract-photo-ts --extract-file-ts --use-filename --out /Users/director/Yandex.Disk.localized/ttfs %P
#
# Then add shortcuts manually in Settings
