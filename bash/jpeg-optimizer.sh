#!/usr/bin/env bash
set -euo pipefail

if [[ ! $(command -v jpegoptim) ]]; then
  echo "Please install jpegoptim"
  exit
fi

if [[ ! $(command -v pngquant) ]]; then
  echo "Please install pngquant"
  exit
fi

if [[ ! $(command -v mogrify) ]]; then
  echo "Please install imagemagick"
  exit
fi

shopt -s nocaseglob           # case-insensitive
jpegoptim -m25 *.jpg  2>/dev/null
jpegoptim -m25 *.jpeg 2>/dev/null
mogrify -verbose -quality 25 *.png 2>/dev/null && pngquant *.png --ext .png --force
shopt -u nocaseglob
