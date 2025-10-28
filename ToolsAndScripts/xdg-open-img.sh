#!/bin/bash

# Interactive image viewer with resize options for ImageMagick display

if [ -z "$1" ]; then
  echo "Usage: $0 imagefile"
  exit 1
fi

imagefile="$1"

echo "Choose window size to open image:"
echo "1) 800x600"
echo "2) 1024x768"
echo "3) 1280x960"
echo "4) Full size"
read -p "Select an option [1-4]: " choice

case $choice in
  1) size="800x600" ;;
  2) size="1024x768" ;;
  3) size="1280x960" ;;
  4) size="" ;;
  *) echo "Invalid choice, opening full size"; size="" ;;
esac

if [ -n "$size" ]; then
  display -resize "$size" "$imagefile"
else
  display "$imagefile"
fi

