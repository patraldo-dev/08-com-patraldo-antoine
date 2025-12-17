#!/bin/bash
# Cascade random zoom: create multiple variations, concatenate, then zoom again
set -e

show_usage() {
  echo "❌ Usage error. Correct syntax:"
  echo
  echo "  $0 <input.mp4> <num_variations> <output.mp4>"
  echo
  echo "Example:"
  echo "  $0 ../Pipeline/video.mp4 6 ../Pipeline/final.mp4"
  echo
  echo "This will:"
  echo "  1. Create 6 random zoom variations"
  echo "  2. Concatenate them"
  echo "  3. Apply one more random zoom to the concatenated result"
  exit 1
}

INPUT="$1"
NUM_VARIATIONS="${2:-6}"
OUTPUT="${3:-cascaded_$(basename "$INPUT")}"

if [[ -z "$INPUT" ]] || [[ ! -f "$INPUT" ]]; then
  echo "❌ Input file not found: $INPUT"
  show_usage
fi

if [[ "$OUTPUT" != *.mp4 ]]; then
  echo "⚠️  CRITICAL: Output must have .mp4 extension"
  show_usage
fi

# Get duration of input video
DURATION=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT" 2>/dev/null || echo 10)

echo "🎬 Starting cascade random zoom process"
echo "📹 Input: $INPUT (${DURATION}s)"
echo "🎲 Creating ${NUM_VARIATIONS} random variations..."

# Create temporary directory for clips
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Step 1: Create multiple random variations
CLIP_LIST=""
for i in $(seq 1 $NUM_VARIATIONS); do
  CLIP="${TEMP_DIR}/clip_${i}.mp4"
  echo "  ⏳ Generating variation $i/$NUM_VARIATIONS..."
  
  # Run zoom script and wait for completion
  ./scripts/dynamic-random-video-zoom.sh "$INPUT" "$DURATION" "$CLIP"
  
  if [[ ! -f "$CLIP" ]]; then
    echo "❌ Failed to create clip $i"
    exit 1
  fi
  
  CLIP_LIST="${CLIP_LIST}file '${CLIP}'
"
  echo "  ✅ Variation $i complete"
done

# Step 2: Concatenate all clips
CONCAT_FILE="${TEMP_DIR}/concat_list.txt"
echo "$CLIP_LIST" > "$CONCAT_FILE"

COMBINED="${TEMP_DIR}/combined.mp4"
TOTAL_DURATION=$(awk "BEGIN {print $DURATION * $NUM_VARIATIONS}")

echo "🔗 Concatenating ${NUM_VARIATIONS} clips (total: ${TOTAL_DURATION}s)..."
ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c copy "$COMBINED" 2>&1 | grep -v "^frame=" || true

if [[ ! -f "$COMBINED" ]]; then
  echo "❌ Concatenation failed"
  exit 1
fi

echo "✅ Concatenation complete"

# Step 3: Apply final random zoom to concatenated video
echo "🌀 Applying final random zoom to entire ${TOTAL_DURATION}s video..."
./scripts/dynamic-random-video-zoom.sh "$COMBINED" "$TOTAL_DURATION" "$OUTPUT"

if [[ ! -f "$OUTPUT" ]]; then
  echo "❌ Final zoom failed"
  exit 1
fi

echo ""
echo "🎉 SUCCESS! Cascade complete!"
echo "📹 Output: $OUTPUT"
echo "⏱️  Total duration: ${TOTAL_DURATION}s"
echo "🎲 Used ${NUM_VARIATIONS} random variations + 1 final zoom"
