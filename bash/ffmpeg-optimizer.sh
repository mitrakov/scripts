#!/bin/bash
set -e
shopt -s nocaseglob           # case-insensitive

if ! [ `which ffmpeg` ]; then
  echo "Please install ffmpeg"
  exit
fi

#for i in *.avi *.mp4 *.mpg *.mov *.mkv *.flv *.webm; do
for i in *.mp4 *.mpg *.mov *.mkv *.webm; do
  [ -f "$i" ] || continue     # guard for empty array
  extension="${i##*.}"        # https://stackoverflow.com/a/965072/2212849
  echo
  echo "Converting: $i -> $i.$extension"
  ffmpeg -i "$i" "$i.$extension"
  mv -f "$i.$extension" "$i"
done
