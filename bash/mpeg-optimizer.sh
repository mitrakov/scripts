#!/usr/bin/env bash
set -euo pipefail

function require() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: required command '$cmd' not found in PATH ($PATH)"
        exit 1
    fi
}

require ffmpeg

shopt -s nocaseglob           # case-insensitive
for i in *.avi *.mp4 *.mpg *.mov *.mkv *.flv *.webm; do
  [ -f "$i" ] || continue     # guard for empty array
  extension="${i##*.}"        # https://stackoverflow.com/a/965072/2212849
  echo
  echo "Converting: $i -> $i.$extension"
  ffmpeg -i "$i" -map_metadata 0 "$i.$extension" # "-map_metadata 0" keeps metadata
  mv -f "$i.$extension" "$i"
done
shopt -u nocaseglob
