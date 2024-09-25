#!/bin/bash
set -e

if ! [ `which jpegoptim` ]; then
  echo "Please install jpegoptim"
  exit
fi

if ! [ `which pngquant` ]; then
  echo "Please install pngquant"
  exit
fi

if ! [ `which mogrify` ]; then
  echo "Please install imagemagick"
  exit
fi

jpegoptim -m25 *.JPG 2>/dev/null
jpegoptim -m25 *.jpg 2>/dev/null
jpegoptim -m25 *.JPEG 2>/dev/null
jpegoptim -m25 *.jpeg 2>/dev/null
mogrify -verbose -quality 25 *.PNG 2>/dev/null && pngquant *.PNG --ext .png --force
mogrify -verbose -quality 25 *.png 2>/dev/null && pngquant *.png --ext .png --force
