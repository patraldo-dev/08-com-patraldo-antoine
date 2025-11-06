#!/bin/bash
# Composite alpha video over background with positioning, scaling, looping, and alpha inversion

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <background_video> <alpha_foreground_video>"
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

bg_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$background")
fg_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$foreground")

echo "Background: ${bg_width}x${bg_height}, ${bg_duration}s"
echo "Foreground: ${fg_width}x${fg_height}, ${fg_duration}s"
echo ""

# Ask about alpha inversion
read -p "Invert alpha channel? (Y/n - choose Y if character appears as cutout): " invert_choice
invert_alpha=true
if [[ "$invert_choice" == "n" || "$invert_choice" == "N" ]]; then
  invert_alpha=false
fi

# Duration matching
echo ""
echo "Duration options:"
echo "1) Use foreground duration (${fg_duration}s) - loop background if needed"
echo "2) Use background duration (${bg_duration}s) - loop foreground if needed"
echo "3) Use longest duration"
echo "4) Use shortest duration"
read -p "Select duration option (1-4): " duration_option

case $duration_option in
  1)
    target_duration=$fg_duration
    loop_bg=true
    loop_fg=false
    ;;
  2)
    target_duration=$bg_duration
    loop_bg=false
    loop_fg=true
    ;;
  3)
    if (( $(awk "BEGIN {print ($bg_duration > $fg_duration)}") )); then
      target_duration=$bg_duration
      loop_fg=true
      loop_bg=false
    else
      target_duration=$fg_duration
      loop_bg=true
      loop_fg=false
    fi
    ;;
  4)
    target_duration=$(awk "BEGIN {print ($bg_duration < $fg_duration) ? $bg_duration : $fg_duration}")
    loop_bg=false
    loop_fg=false
    ;;
  *)
    echo "Invalid option, using foreground duration"
    target_duration=$fg_duration
    loop_bg=true
    loop_fg=false
    ;;
esac

echo "Output will be ${target_duration}s"
echo "Loop background: $loop_bg"
echo "Loop foreground: $loop_fg"
echo ""

# Scaling options
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

# Build foreground filter chain
fg_filter="[1:v]"

# Add looping if needed
if [ "$loop_fg" = true ]; then
  fg_filter="${fg_filter}loop=-1:1:0,"
fi

# Alpha inversion (no forced pixel format — works with RGBA/YUVA)
if [ "$invert_alpha" = true ]; then
  fg_filter="${fg_filter}split[rgb][a];[a]alphaextract,negate[alpha];[rgb][alpha]alphamerge,"
fi

# Apply scaling and ensure high-quality alpha for overlay
fg_filter="${fg_filter}${scale_filter}format=yuva444p[fg]"

# Build background filter chain
bg_filter="[0:v]"
if [ "$loop_bg" = true ]; then
  bg_filter="${bg_filter}loop=-1:1:0,"
fi
bg_filter="${bg_filter}format=yuv420p[bg]"

# Combine with high-quality blending
filter_complex="${bg_filter};${fg_filter};[bg][fg]overlay=${x}:${y}:shortest=1:format=auto,format=yuv420p"

# Audio handling: only copy if background has audio
if ffprobe -v quiet -select_streams a -show_entries stream=codec_type -of csv=p=0 "$background" >/dev/null 2>&1; then
  audio_args="-c:a copy"
else
  audio_args="-an"
fi

# Output filename
output_dir=$(dirname "$background")
bg_base=$(basename "$background" | sed 's/\.[^.]*$//')
fg_base=$(basename "$foreground" | sed 's/\.[^.]*$//')
outputfile="${output_dir}/composite_${bg_base}_${fg_base}.mp4"

echo "Filter: $filter_complex"
echo ""
echo "Creating composite video..."

ffmpeg -i "$background" -i "$foreground" \
  -filter_complex "$filter_complex" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p \
  $audio_args \
  -t "$target_duration" \
  "$outputfile"

echo ""
echo "✅ Done! Output file: $outputfile"

# Optional playback
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
  ffplay "$outputfile"
fi
