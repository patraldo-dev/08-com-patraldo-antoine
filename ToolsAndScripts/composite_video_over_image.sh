#!/bin/bash
# Composite alpha video over static image background with better color

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <background_image.jpg|png> <alpha_foreground_video>"
  exit 1
fi

background="$1"
foreground="$2"

if [[ ! -f "$background" ]] || [[ ! -f "$foreground" ]]; then
  echo "One or both files not found!"
  exit 1
fi

# Get dimensions
bg_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$background")
bg_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$background")
fg_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$foreground")
fg_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$foreground")
fg_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$foreground")

echo "Background image: ${bg_width}x${bg_height}"
echo "Foreground video: ${fg_width}x${fg_height}, ${fg_duration}s"
echo ""

# Ask about alpha inversion
read -p "Invert alpha channel? (Y/n - choose Y if character appears in white box): " invert_choice
invert_alpha=true
if [[ "$invert_choice" == "n" || "$invert_choice" == "N" ]]; then
  invert_alpha=false
fi

# Scaling options
echo ""
echo "Foreground scaling:"
echo "1) Keep original size"
echo "2) Scale to percentage of background width"
echo "3) Scale to specific width (maintain aspect ratio)"
echo "4) Scale to fit background (full screen)"
read -p "Select scaling option (1-4): " scale_option

case $scale_option in
  1)
    scale_filter=""
    scaled_width=$fg_width
    scaled_height=$fg_height
    ;;
  2)
    read -p "Scale to what percentage of background width? (e.g., 50 for 50%): " percent
    scale_filter="scale=iw*${percent}/100:-1,"
    scaled_width=$(awk "BEGIN {printf \"%d\", $fg_width * $percent / 100}")
    scaled_height=$(awk "BEGIN {printf \"%d\", $fg_height * $percent / 100}")
    ;;
  3)
    read -p "Enter desired width in pixels: " target_width
    scale_filter="scale=${target_width}:-1,"
    scaled_width=$target_width
    scaled_height=$(awk "BEGIN {printf \"%d\", $fg_height * $target_width / $fg_width}")
    ;;
  4)
    scale_filter="scale=${bg_width}:${bg_height},"
    scaled_width=$bg_width
    scaled_height=$bg_height
    ;;
  *)
    echo "Invalid option, keeping original size"
    scale_filter=""
    scaled_width=$fg_width
    scaled_height=$fg_height
    ;;
esac

echo ""
echo "Foreground will be: ${scaled_width}x${scaled_height}"
echo ""

# Position options
echo "Foreground position:"
echo "1) Center"
echo "2) Top-left"
echo "3) Top-center"
echo "4) Top-right"
echo "5) Bottom-left"
echo "6) Bottom-center"
echo "7) Bottom-right"
echo "8) Custom X,Y position"
read -p "Select position (1-8): " position

case $position in
  1)
    x="(W-w)/2"
    y="(H-h)/2"
    ;;
  2)
    x="0"
    y="0"
    ;;
  3)
    x="(W-w)/2"
    y="0"
    ;;
  4)
    x="W-w"
    y="0"
    ;;
  5)
    x="0"
    y="H-h"
    ;;
  6)
    x="(W-w)/2"
    y="H-h"
    ;;
  7)
    x="W-w"
    y="H-h"
    ;;
  8)
    read -p "Enter X position (0 = left, or formula like '(W-w)/2'): " x
    read -p "Enter Y position (0 = top, or formula like '(H-h)/2'): " y
    ;;
  *)
    echo "Invalid option, centering"
    x="(W-w)/2"
    y="(H-h)/2"
    ;;
esac

echo ""
echo "Position: x=$x, y=$y"
echo ""

# Build filter with optional alpha negation and better color preservation
if [ "$invert_alpha" = true ]; then
  # Split RGB and Alpha, negate alpha, recombine - preserves color better
  filter_complex="[0:v]loop=loop=-1:size=1:start=0,scale=${bg_width}:${bg_height}[bg];[1:v]format=yuva444p,split[rgb][a];[a]alphaextract,negate[alpha];[rgb][alpha]alphamerge,${scale_filter}format=yuva444p[fg];[bg][fg]overlay=${x}:${y}"
else
  filter_complex="[0:v]loop=loop=-1:size=1:start=0,scale=${bg_width}:${bg_height}[bg];[1:v]${scale_filter}format=yuva444p[fg];[bg][fg]overlay=${x}:${y}"
fi

# Output filename
output_dir=$(dirname "$foreground")
bg_base=$(basename "$background" | sed 's/\.[^.]*$//')
fg_base=$(basename "$foreground" | sed 's/\.[^.]*$//')
outputfile="${output_dir}/composite_${bg_base}_${fg_base}.mp4"

echo "Filter: $filter_complex"
echo ""
echo "Creating composite video..."

ffmpeg -loop 1 -i "$background" -i "$foreground" \
  -filter_complex "$filter_complex" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p \
  -t "$fg_duration" \
  -c:a copy \
  "$outputfile"

echo ""
echo "Done! Output file: $outputfile"

# Optional: Ask before playing
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
    ffplay "$outputfile"
fi
