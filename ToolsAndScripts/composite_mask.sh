#!/bin/bash
# Usage: ./composite_wan.sh wan_output.mp4 background.mp4 output.mp4

set -e  # Exit on error

WAN_VIDEO="$1"
BG_VIDEO="$2"
OUTPUT="$3"

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <wan_output.mp4> <background.mp4> <output.mp4>"
  exit 1
fi

# --- CONFIGURE THIS ---
# Point to your pre-enhanced mask (generated once per character)
MASK="character_mask_enhanced.png"  # <-- put this in your current dir

if [ ! -f "$MASK" ]; then
  echo "Error: $MASK not found. Create it first from your original drawing."
  exit 1
fi

# --- STEP 1: Extract frames from Wan output ---
echo "📦 Extracting frames..."
mkdir -p frames
ffmpeg -i "$WAN_VIDEO" -f image2 -pix_fmt rgb24 frames/%06d.png

# --- STEP 2: Apply enhanced mask to all frames ---
echo "🎨 Applying mask to all frames..."
mkdir -p frames_alpha
for f in frames/*.png; do
  convert "$f" "$MASK" -alpha off -compose CopyOpacity -composite "frames_alpha/$(basename "$f")"
done

# --- STEP 3: Choose compositing method ---
# OPTION A: Direct composite (faster, less disk)
echo "🎬 Compositing directly over background..."
ffmpeg -i "$BG_VIDEO" -framerate 30 -i frames_alpha/%06d.png \
  -filter_complex "[0][1]overlay=shortest=1" \
  -c:v libx264 -pix_fmt yuv420p -y "$OUTPUT"

# OPTIONAL: Uncomment below instead if you want reusable alpha video (Option B)
# echo "📽️  Creating alpha video..."
# ffmpeg -framerate 30 -i frames_alpha/%06d.png -c:v libx264 -pix_fmt yuva420p wan_with_alpha.mp4
# echo "🎬 Compositing from alpha video..."
# ffmpeg -i "$BG_VIDEO" -i wan_with_alpha.mp4 -filter_complex "[0][1]overlay=shortest=1" -y "$OUTPUT"

echo "✅ Done: $OUTPUT"
