#!/bin/bash
# Apply smooth zoom/pan to video (Chromebook-compatible)
set -e

show_usage() {
  echo "❌ Usage error. Correct syntax:"
  echo
  echo "Example 1 (random pattern):"
  echo "  $0 ../Pipeline/video.mp4 5 ../Pipeline/zoomed.mp4"
  echo
  echo "Example 2 (reproducible pattern):"
  echo "  ZOOM_SEED=42 $0 ../Pipeline/video.mp4 8 ../Pipeline/zoomed2.mp4"
  echo
  echo "💡 Tips:"
  echo "  • Output MUST end with .mp4"
  echo "  • Duration defaults to input video length if omitted"
  echo "  • Omit ZOOM_SEED for random pattern each run"
  echo "  • Set ZOOM_SEED for reproducible results"
  exit 1
}

INPUT="$1"
DURATION="${2:-$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT" 2>/dev/null || echo 10)}"
OUTPUT="${3:-zoomed_$(basename "$INPUT")}"

if [[ -z "$INPUT" ]] || [[ ! -f "$INPUT" ]]; then
  show_usage
fi

if [[ "$OUTPUT" != *.mp4 ]]; then
  echo "⚠️  CRITICAL: Output must have .mp4 extension"
  show_usage
fi

echo "🌀 Applying random zoom/pan: $INPUT"
echo "⏱️  Duration: ${DURATION}s → $OUTPUT"

SEED="${ZOOM_SEED:-$RANDOM}"

# 🔑 Using 'on' (frame number) instead of 't' (time) for compatibility
# on/24 converts frame number to seconds at 24fps
# SEED creates dramatic phase shifts AND different frequencies for unique patterns
ZOOM_FREQ=$(awk "BEGIN {print 0.2 + (${SEED} % 10) * 0.05}")
PAN_FREQ=$(awk "BEGIN {print 0.15 + (${SEED} % 7) * 0.03}")
PHASE=$(awk "BEGIN {print (${SEED} % 360) * 3.14159 / 180}")

zoom_expr="1+0.5*sin(on/24*${ZOOM_FREQ}+${PHASE})"
pan_x_expr="iw/2-iw/8+iw/4*sin(on/24*${PAN_FREQ}+${PHASE}*1.3)"
pan_y_expr="ih/2-ih/8+ih/4*cos(on/24*${PAN_FREQ}*0.8+${PHASE}*0.7)"

echo "🎲 Using seed: ${SEED} (zoom_freq=${ZOOM_FREQ}, pan_freq=${PAN_FREQ}, phase=${PHASE})"

ffmpeg -y -i "$INPUT" \
  -vf "scale=1280:720,zoompan=z='${zoom_expr}':x='${pan_x_expr}':y='${pan_y_expr}':d=1:fps=24:s=1280x720,minterpolate=fps=24:mi_mode=mci" \
  -t "$DURATION" \
  -c:v libx264 -crf 23 -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  "$OUTPUT" 2>&1 | grep -v "^frame=" || true

if [[ ! -f "$OUTPUT" ]]; then
  echo "❌ FFmpeg failed to create output"
  exit 1
fi

echo "✅ Success! $OUTPUT"
echo "🎲 Used seed ${SEED} (save this to reproduce exact pattern)"
echo "💡 Pro tip: Try different ZOOM_SEED values for varied motion styles"
