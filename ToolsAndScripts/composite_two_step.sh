#!/bin/bash
# Generate transparent foreground from Wan video and composite over any background
# Usage:
#   ./composite_two_step.sh wan_video.mp4 background.jpg
#   ./composite_two_step.sh  # (interactive mode)

REMBG_PATH="/home/patrouch/rembg/venv/bin/rembg"

# === ARGUMENT PARSING ===
if [[ $# -eq 2 ]]; then
  wan_video="$1"
  bg_file="$2"
elif [[ $# -eq 0 ]]; then
  read -p "Enter Wan output video (e.g., cancanman10loop2.mp4): " wan_video
  read -p "Enter background file (MP4, JPG, or PNG): " bg_file
else
  echo "Usage: $0 [<wan_video> <background>]"
  echo "  Example: $0 video.mp4 bg.jpg"
  exit 1
fi

# === VALIDATION ===
if [[ ! -f "$wan_video" ]]; then
  echo "❌ Wan video not found: $wan_video"
  exit 1
fi

if [[ ! -f "$bg_file" ]]; then
  echo "❌ Background not found: $bg_file"
  exit 1
fi

# === MASKING METHOD ===
if [[ $# -eq 0 ]]; then
  echo ""
  echo "Masking method:"
  echo "1) Use rembg (AI-based, best for isolated characters)"
  echo "2) Use luminance threshold (best for dark-on-light pencil art)"
  read -p "Choose (1 or 2): " mask_method
  if [[ ! "$mask_method" =~ ^[12]$ ]]; then
    mask_method=1
  fi
else
  # Default to rembg in non-interactive mode
  mask_method=1
fi

# === SETUP ===
tmpdir=$(mktemp -d)
frames="$tmpdir/frames"
rgba="$tmpdir/rgba"
mkdir -p "$frames" "$rgba"

base_name=$(basename "$wan_video" | sed 's/\.[^.]*$//')
output="${base_name}_on_bg.mp4"

# === EXTRACT FRAMES ===
echo "📦 Extracting frames..."
ffmpeg -loglevel error -i "$wan_video" "$frames/%04d.png" || { echo "❌ Frame extraction failed"; exit 1; }

# === GENERATE RGBA FRAMES ===
echo "🎨 Generating transparent foreground..."
if [[ "$mask_method" == "1" ]]; then
  if [[ ! -x "$REMBG_PATH" ]]; then
    echo "❌ rembg not found at $REMBG_PATH"
    exit 1
  fi
  for f in "$frames"/*.png; do
    "$REMBG_PATH" i "$f" "$rgba/$(basename "$f")"
  done
else
  ref_frame="$frames/0001.png"
  convert "$ref_frame" -colorspace Gray -contrast-stretch 1% -threshold 80% -negate "$tmpdir/mask.png"
  convert "$tmpdir/mask.png" -morphology dilate disk:2 "$tmpdir/mask_enhanced.png"
  for f in "$frames"/*.png; do
    convert "$f" "$tmpdir/mask_enhanced.png" -alpha off -compose CopyOpacity -composite "$rgba/$(basename "$f")"
  done
fi

# === DETECT BACKGROUND TYPE ===
bg_ext="${bg_file##*.}"
if [[ "${bg_ext,,}" =~ ^(mp4|m4v|mov|avi|webm)$ ]]; then
  bg_input=("$bg_file")
  bg_stream="[0:v]"
else
  bg_input=("-stream_loop" "-1" "-i" "$bg_file")
  bg_stream="[0:v]"
fi

# === COMPOSITE ===
echo "🎬 Compositing..."
ffmpeg -loglevel error \
  "${bg_input[@]}" \
  -framerate 15 -i "$rgba/%04d.png" \
  -filter_complex "${bg_stream}[1:v]overlay=shortest=1" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -y "$output" || { echo "❌ Compositing failed"; exit 1; }

# === CLEANUP ===
rm -rf "$tmpdir"

echo ""
echo "✅ Done! Output: $output"

if [[ $# -eq 0 ]]; then
  read -p "Play video? (Y/n): " play
  if [[ "$play" != "n" && "$play" != "N" ]]; then
    ffplay "$output"
  fi
fi
