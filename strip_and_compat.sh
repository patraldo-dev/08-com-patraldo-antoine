#!/bin/bash

for f in *.mp4; do
    [[ ! -e "$f" ]] && echo "No .mp4 files found in current directory." && exit 1
    ffmpeg -y -i "$f" -an -c:v libx264 -crf 23 -preset fast -pix_fmt yuv420p "${f%.mp4}_noaudio_compatible.mp4"
done

echo "✅ Done! Silent, compatible versions created."
