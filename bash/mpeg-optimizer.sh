#!/usr/bin/env bash
set -euo pipefail

if [[ ! $(command -v ffmpeg) ]]; then
  echo "Please install ffmpeg"
  exit
fi

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
