#!/usr/bin/env bash
# deprecated; there is a bug on iOS
# cron example every 2 min: */2 * * * * /root/y.disk-updater.sh /root/yandex-disk/sync /root/yandex-disk/db
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

# Main logic
function move_files() {
  local input_dir="$1"
  local output_dir="$2"

  if [ ! -d "$input_dir" ]; then                                 # check if input directory exists
    error "Error: Input directory '$input_dir' does not exist"
    return 1
  fi

  mkdir -p "$output_dir"                                         # create output directory if it doesn't exist

  find "$input_dir" -type f | while read -r file; do
    local rel_path="${file#$input_dir/}"                         # get relative path from input directory
    local dest_file="$output_dir/$rel_path"                      # construct destination path
    local dest_dir=$(dirname "$dest_file")                       # create destination directory if needed
    mkdir -p "$dest_dir"

    log "\nMove: $rel_path"
    mv -vf "$file" "$dest_file"                                  # move file (replacing if exists)
  done

  info "Move completed!"
}

# Checks
if [[ $# -ne 2 ]]; then
  error "Usage: $0 INPUT_DIR OUTPUT_DIR"
  exit 1
fi

# Entry point
move_files "$@"
