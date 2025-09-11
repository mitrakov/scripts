#!/bin/bash
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
EXTRACT_DATETIME=false
QUICK=false
COUNT=0

# Function to display help
function show_help() {
    info "Usage:   $0 [OPTIONS] <list of files and folders>"
    info "Example: $0 --tags my-kids --extract-ts --use-filename --out /Users/tommy/ttfs 1.JPG 2.JPG 3.JPG myDir"
    echo
    echo "┌───────────────────────┬───────────────────────────────────────────────────────────────────┬──────────────────────┐"
    echo "│ Option                │ Description                                                       │ Example              │"
    echo "├───────────────────────┼───────────────────────────────────────────────────────────────────┼──────────────────────┤"
    echo "│ --tags TAG1-TAG2-TAG3 │ Dash-separated-tags                                               │ --tags my-kids-party │"
    echo "│ --extract-ts          │ Try to extract datetime from file system, photo or video metadata │ --extract-ts         │"
    echo "│ --use-filename        │ Add current filename to storage name                              │ --use-filename       │"
    echo "│ --quick               │ Use small delay (may reduce time for large folders)               │ --quick              │"
    echo "│ --out FOLDER          │ Output folder (default is script directory)                       │ --out /Users/me/ttfs │"
    echo "└───────────────────────┴───────────────────────────────────────────────────────────────────┴──────────────────────┘"
    echo
}

# Basis checks
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "Currently this tool is available only for MacOS"
    exit 1
fi
if ! command -v exif &> /dev/null; then
    error "Error: The 'exif' utility could not be found. Please install: brew install exif"
    exit 1
fi
if ! command -v ffprobe &> /dev/null; then
    error "Error: The 'ffprobe' utility could not be found. Please install: brew install ffmpeg"
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
                    error "Error: --tags should be dash separated, and contain only digits and latin characters: $2"
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
        --extract-ts)
            EXTRACT_DATETIME=true
            shift
            ;;
        --quick)
            QUICK=true
            shift
            ;;
        --out)
            if [[ -n $2 && $2 != --* ]]; then
                OUT_DIR="$2"
                OUT_DIR="${OUT_DIR%/}"    # remove trailing slash, if present
                shift 2
            else
                error "Error: --out requires a value"
                show_help
                exit 1
            fi
            ;;
        --*)
            error "Error: unknown option $1"
            show_help
            exit 1
            ;;
        *)
            # non-option argument - treat as positional argument
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

# Check that quick=T => use-filename=T
if [[ $QUICK == true && $USE_FILENAME == false ]]; then
    error "Error: --quick must be used with --use-filename"
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
        show_help
        exit 1
    fi

    # sleep
    if [[ $QUICK == true ]]; then
        sleep 0.2
    else
        sleep 1
    fi

    # date-time
    local now=$(date +%Y-%m-%d-%H-%M-%S)                                # default timestamp.now() TODO Linux?
    if [[ $EXTRACT_DATETIME == true ]]; then
        local exif_data=$(exif --machine-readable --tag 0x9003 "$filename" 2>/dev/null || \
                          exif --machine-readable --tag 0x0132 "$filename" 2>/dev/null)
        if [[ -n "$exif_data" ]]; then
            now=$(date -j -f "%Y:%m:%d %H:%M:%S" "$exif_data" +%Y-%m-%d-%H-%M-%S) # TODO Linux: date -d"${d//:/-}" +"%Y-%m-%d-%H-%M-%S"
            log "Extracted original photo creation time: $now"
        else
            echo "Cannot extract photo creation time for: $filename"
            local video_data=$(ffprobe -v quiet -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 "$filename")
            if [[ -n "$video_data" ]]; then
                now=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$video_data" +%Y-%m-%d-%H-%M-%S)
                log "Extracted original video creation time: $now"
            else
                echo "Cannot extract video creation time for: $filename"
                now=$(stat -f %SB -t %Y-%m-%d-%H-%M-%S "$filename")     # TODO Linux: stat -c %w "$filename"
                info "Extracted file creation time: $now"
            fi
        fi
    fi
    local year="${now:0:4}"

    # extension
    local extension="${filename##*/}"                                   # remove any path
    extension="${extension##*.}"                                        # get text after last dot
    [[ "$extension" == "$filename" ]] && extension="noext"              # if nothing happened (files without dot) => use "noext"

    local extLower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')    # toLowerCase

    # additional filename
    local tags2=""
    if [[ $USE_FILENAME == true ]]; then
        local base=$(basename "$filename")                              # base filename without paths
        local name="${base%.*}"                                         # pure name without extension
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
            error "Error: file/directory does not exist: $item"
            show_help
            exit 1
        fi
    done
}

# Main program
echo "  Files and folders:     $@"
echo "  --tags:                $TAGS"
echo "  --out:                 $OUT_DIR"
echo "  --extract-ts:          $EXTRACT_DATETIME"
echo "  --use-filename:        $USE_FILENAME"
echo "  --quick:               $QUICK"

main "$@"
log "Success. $COUNT file(s) processed."

# Midnight commander:
# F9 -> Command -> Edit menu -> User: (examples for shortcuts "w" and "e")
#
# + t r | t d
# w       Upload to Tom-Trix File System (tags)
#         TAGS=%{TTFS tags. Enter tags:}
#         ttfs.sh --tags $TAGS --extract-ts --out /Users/director/Yandex.Disk.localized/ttfs %s
# 
# + t r | t d
# e       Upload to Tom-Trix File System (tags + filename)
#         TAGS=%{TTFS tags with filename. Enter tags:}
#         ttfs.sh --tags $TAGS --extract-ts --use-filename --out /Users/director/Yandex.Disk.localized/ttfs %s
#
# Usage: F2

# Nimble commander:
# Settings -> Tools -> + -> select "Startup mode: Terminal"
#
# ttfs.sh
# --tags %"TTFS tags. Enter tags"? --extract-ts --out /Users/director/Yandex.Disk.localized/ttfs %P
# ttfs.sh
# --tags %"TTFS tags with filename. Enter tags"? --extract-ts --use-filename --out /Users/director/Yandex.Disk.localized/ttfs %P
#
# Then add shortcuts manually in Settings
