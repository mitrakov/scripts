#!/bin/bash
set -e

if ! [ `which ffmpeg` ]; then
  echo "Please install ffmpeg"
  exit 1
fi

for f in *.mp4; do
  if [[ -f "$f" ]]; then            # if file
    echo
    echo "Processing: $f"
    ffmpeg -i "$f" "${f%.*}.mp3"    # replace extention with .mp3
    echo
  fi;
done
