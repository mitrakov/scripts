#!/usr/bin/env bash
set -euo pipefail

function require() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found in PATH ($PATH)"
    echo "Pleae install jpegoptim, pngquant and imagemagick"
    exit 1
  fi
}

require jpegoptim
require pngquant
require mogrify

shopt -s nocaseglob           # case-insensitive
jpegoptim -m25 *.jpg  2>/dev/null
jpegoptim -m25 *.jpeg 2>/dev/null
mogrify -verbose -quality 25 *.png 2>/dev/null && pngquant *.png --ext .png --force
shopt -u nocaseglob
