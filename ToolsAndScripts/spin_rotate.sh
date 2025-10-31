#!/bin/bash

input="$1"
if [[ ! -f "$input" ]]; then
  echo "Input file not found!"
  exit 1
fi

# Create a temporary directory for frames
tempdir=$(mktemp -d)
echo "Using temp dir: $tempdir"

# Extract frames (all frames from input video)
ffmpeg -i "$input" -q:v 2 "$tempdir/frame_%03d.png"

# Get total number of extracted frames
framecount=$(ls "$tempdir" | wc -l)
echo "Extracted $framecount frames."

# Create manifest directory if missing
manifest_dir="SpinRotateManifest"
mkdir -p "$manifest_dir"
manifest="$manifest_dir/manifest.tsv"

# Generate rotated frames directory
mkdir "$tempdir/rotated"

i=0
for frame in "$tempdir"/frame_*.png; do
  # Calculate rotation angle incrementally (degree per frame)
  angle=$(( (i * 360 / framecount) % 360 ))
  # Rotate frame via FFmpeg (using rotate filter)
  ffmpeg -y -i "$frame" -vf "rotate=${angle}*PI/180:ow=rotw(iw):oh=roth(ih):c=none" \
    "$tempdir/rotated/rotated_$(printf '%03d' $i).png"
  ((i++))
done

# Output video from rotated frames (using 30 fps by default, adjust as needed)
output="spinning_$(basename "${input%.*}").mp4"
ffmpeg -framerate 30 -i "$tempdir/rotated/rotated_%03d.png" -c:v libx264 -pix_fmt yuv420p "$output"

# Log manifest entry with timestamp, input filename, frame count, output filename
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
logline="$timestamp\t$input\t$framecount\t$output"
echo -e "$logline" >> "$manifest"
echo -e "Saved to manifest: $logline"

# Cleanup temp dir
rm -r "$tempdir"

echo "Created spinning video: $output"

# Optional: Ask before playing
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
    ffplay "$outputfile"
fi
