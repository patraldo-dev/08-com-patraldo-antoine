#!/bin/bash
# Generate 5 randomized zoom/pan videos from a single still image
set -e

INPUT="$1"
DURATION="${2:-10}"
PREFIX="${3:-zoom}"

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
  echo "❌ Input file not found: $INPUT"
  echo "Usage: $0 input.jpg [duration] [output_prefix]"
  exit 1
fi

# ✅ Validate input is an image, not a video
if [[ "$INPUT" =~ \.(mp4|mov|avi|webm|mkv)$ ]]; then
  echo "❌ ERROR: This script requires an IMAGE input (jpg, png, etc.)"
  echo "   You provided a video file: $INPUT"
  echo ""
  echo "💡 For video inputs, use: ./scripts/cascade-random-zoom.sh"
  exit 1
fi

# Validate it's an image format
if [[ ! "$INPUT" =~ \.(jpg|jpeg|png|gif|bmp|tiff)$ ]]; then
  echo "⚠️  Warning: File extension not recognized as image"
  echo "   Supported: .jpg, .jpeg, .png, .gif, .bmp, .tiff"
  echo "   Proceeding anyway..."
fi

# Clean JPEG metadata if it's a JPEG
CLEAN_INPUT="$INPUT"
if [[ "$INPUT" =~ \.(jpg|jpeg)$ ]]; then
  CLEAN_INPUT="/tmp/$(basename "$INPUT" .jpg)_clean.jpg"
  echo "🧹 Sanitizing JPEG metadata..."
  if command -v jpegtran >/dev/null 2>&1; then
    jpegtran -copy none -outfile "$CLEAN_INPUT" "$INPUT" 2>/dev/null || CLEAN_INPUT="$INPUT"
  else
    echo "⚠️  jpegtran not installed. Using raw image (may fail on EXIF-heavy files)."
    CLEAN_INPUT="$INPUT"
  fi
fi

echo "🎨 Generating 5 zoom variations from: $CLEAN_INPUT"
echo "⏱️  Duration: ${DURATION}s | Prefix: $PREFIX"

WIDTH=1280
HEIGHT=720
MIN_ZOOM=1.0
MAX_ZOOM=3.5

for seed in {1..5}; do
  OUTPUT="${PREFIX}_${seed}.mp4"
  echo "  🔢 Variation $seed → $OUTPUT"
  
  ffmpeg -y -loop 1 -i "$CLEAN_INPUT" -vf "
    scale=${WIDTH}:${HEIGHT},
    zoompan=
      z='if(eq(on,0),${MIN_ZOOM},min(max(prev_zoom+random(1)*0.04-0.02,${MIN_ZOOM}),${MAX_ZOOM}))':
      x='if(eq(on,0),iw/2,min(max(prev_x+random(1)*160-80,0),iw-iw/zoom))':
      y='if(eq(on,0),ih/2,min(max(prev_y+random(1)*80-40,0),ih-ih/zoom))':
      d=1:
      fps=24,
    minterpolate=fps=24:mi_mode=mci
  " -t "$DURATION" -c:v libx264 -crf 23 -pix_fmt yuv420p "$OUTPUT"
done

[[ "$CLEAN_INPUT" != "$INPUT" ]] && rm -f "$CLEAN_INPUT" 2>/dev/null

echo "✅ Done! Files:"
ls -lh ${PREFIX}_*.mp4
