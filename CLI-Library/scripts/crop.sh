#!/bin/bash

# Enable history for read command
HISTFILE=~/.ffmpeg_crop_history
HISTSIZE=1000
history -r "$HISTFILE"  # Read history from file

# Input filename with history support
read -e -p "Enter input video filename: " inputfile
history -s "$inputfile"  # Save to history
history -w "$HISTFILE"   # Write history to file

if [[ ! -f "$inputfile" ]]; then
  echo "File not found!"
  exit 1
fi

# Function to read and validate crop percentages
read_crop_percent() {
  local side_name="$1"
  local value
  read -p "Enter crop percentage for $side_name (0-50, 0 = none): " value
  if [[ ! "$value" =~ ^[0-9]+$ ]] || (( value < 0 )) || (( value > 50 )); then
    echo "Invalid input for $side_name, defaulting to 0."
    value=0
  fi
  echo "$value"
}

# User input for crop
percent_top=$(read_crop_percent "top")
percent_right=$(read_crop_percent "right")
percent_bottom=$(read_crop_percent "bottom")
percent_left=$(read_crop_percent "left")

echo "Percentages entered:"
echo "  Top: $percent_top%, Right: $percent_right%, Bottom: $percent_bottom%, Left: $percent_left%"

# Get video resolution
width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$inputfile")
height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$inputfile")

echo "Original dimensions: ${width}x${height}"

# Validate that width and height were obtained
if [[ -z "$width" ]] || [[ -z "$height" ]]; then
  echo "Error: Could not determine video dimensions"
  exit 1
fi

# Calculate crop dimensions and offsets using awk for reliable integer arithmetic
crop_width=$(awk "BEGIN {printf \"%d\", $width * (100 - $percent_left - $percent_right) / 100}")
crop_height=$(awk "BEGIN {printf \"%d\", $height * (100 - $percent_top - $percent_bottom) / 100}")
x_offset=$(awk "BEGIN {printf \"%d\", $width * $percent_left / 100}")
y_offset=$(awk "BEGIN {printf \"%d\", $height * $percent_top / 100}")

echo "Calculated crop values:"
echo "  New dimensions: ${crop_width}x${crop_height}"
echo "  Offset: x=$x_offset, y=$y_offset"
echo ""

# Check if cropping is actually needed
if [[ "$crop_width" == "$width" ]] && [[ "$crop_height" == "$height" ]]; then
  echo "Warning: No cropping needed (resulting dimensions equal original). Exiting..."
  exit 0
fi

# Validate crop dimensions
if [[ "$crop_width" -le 0 ]] || [[ "$crop_height" -le 0 ]]; then
  echo "Error: Invalid crop dimensions (width: $crop_width, height: $crop_height)"
  echo "Crop percentages are too large!"
  exit 1
fi

# Output file in same folder
input_dir=$(dirname "$inputfile")
input_base=$(basename "$inputfile")
input_name="${input_base%.*}"
input_ext="${input_base##*.}"
outputfile="${input_dir}/cropped_${input_name}.${input_ext}"

# Build the crop filter string
crop_filter="crop=${crop_width}:${crop_height}:${x_offset}:${y_offset}"
echo "FFmpeg crop filter: $crop_filter"
echo ""

# Log to manifest
manifest="manifest.tsv"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
logline="$timestamp\t$inputfile\t$percent_top\t$percent_right\t$percent_bottom\t$percent_left"
echo -e "$logline" >> "$manifest"
echo -e "Saved to manifest: $logline"

# Run FFmpeg
echo "Running FFmpeg..."
ffmpeg -i "$inputfile" -vf "$crop_filter" -c:a copy "$outputfile"

echo ""
echo "Done! Output file: $outputfile"

# Optional: Ask before playing
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
    ffplay "$outputfile"
fi


