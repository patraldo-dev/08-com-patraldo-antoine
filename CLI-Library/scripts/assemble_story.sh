#!/bin/bash
# assemble_story.sh - Assemble video from cuts.tsv, optionally add audio
# Usage:
#   assemble_story.sh cuts.tsv [output.mp4]
#   assemble_story.sh cuts.tsv audio.m4a output.mp4

set -e  # Exit on error

CUTS_FILE="$1"
AUDIO_FILE=""
OUTPUT_FILE=""

# Parse arguments
if [[ $# -eq 2 ]]; then
  if [[ "$2" == *.@(mp3|m4a|wav|aac) ]]; then
    echo "❌ Error: If providing audio, you must also specify output filename."
    echo "Usage: $0 cuts.tsv [audio.m4a output.mp4]"
    exit 1
  else
    OUTPUT_FILE="$2"
  fi
elif [[ $# -eq 3 ]]; then
  AUDIO_FILE="$2"
  OUTPUT_FILE="$3"
  if [[ ! -f "$AUDIO_FILE" ]]; then
    echo "❌ Audio file not found: $AUDIO_FILE"
    exit 1
  fi
elif [[ $# -ne 1 ]]; then
  echo "Usage: $0 cuts.tsv [audio.m4a output.mp4]"
  echo "Example: $0 cuts.tsv voice_es.m4a final-es.mp4"
  exit 1
fi

# Validate cuts file
if [[ ! -f "$CUTS_FILE" ]]; then
  echo "❌ Cuts file not found: $CUTS_FILE"
  exit 1
fi

# Auto-generate output name if not given
if [[ -z "$OUTPUT_FILE" ]]; then
  OUTPUT_FILE="${CUTS_FILE%.*}_output.mp4"
fi

# Create temp dir for clips
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "🎬 Assembling from: $CUTS_FILE"
echo "💾 Output: $OUTPUT_FILE"
echo "----------------------------------------"

# Step 1: Trim clips based on cuts.tsv
declare -a trimmed_clips
clip_index=1

while IFS=$'\t' read -r scene path in_time out_time notes; do
  # Skip comments and empty lines
  [[ "$scene" =~ ^#.*$ || -z "$scene" ]] && continue
  [[ ! -f "$path" ]] && { echo "⚠️  File not found: $path"; continue; }

  trimmed="clip_$(printf "%03d" $clip_index).mp4"
  trimmed_path="$TEMP_DIR/$trimmed"
  
  echo "✂️  Trim $scene → $trimmed ($in_time → $out_time)"
  ffmpeg -y -i "$path" -ss "$in_time" -to "$out_time" -c copy "$trimmed_path"
  
  trimmed_clips+=("$trimmed_path")
  ((clip_index++))
done < "$CUTS_FILE"

if [[ ${#trimmed_clips[@]} -eq 0 ]]; then
  echo "❌ No valid clips found in $CUTS_FILE"
  exit 1
fi

# Step 2: Create concat list
LIST_FILE="$TEMP_DIR/concat_list.txt"
> "$LIST_FILE"
for clip in "${trimmed_clips[@]}"; do
  echo "file '$clip'" >> "$LIST_FILE"
done

# Step 3: Concatenate
CONCAT_FILE="$TEMP_DIR/concatenated.mp4"
echo "🔗 Concatenating ${#trimmed_clips[@]} clips..."
ffmpeg -y -f concat -safe 0 -i "$LIST_FILE" -c copy "$CONCAT_FILE"

# Step 4: Add audio (if provided)
if [[ -n "$AUDIO_FILE" ]]; then
  echo "🔊 Adding audio: $AUDIO_FILE"
  ffmpeg -y -i "$CONCAT_FILE" -i "$AUDIO_FILE" \
    -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -shortest \
    "$OUTPUT_FILE"
else
  mv "$CONCAT_FILE" "$OUTPUT_FILE"
fi

echo "✅ Done: $OUTPUT_FILE"
