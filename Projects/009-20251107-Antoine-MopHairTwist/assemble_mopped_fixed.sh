#!/bin/bash
set -e

PROJECT_DIR="$HOME/AGRia-Video-Studio/Projects/009-20251107-Antoine-MopHairTwist"
cd "$PROJECT_DIR"

# Target resolution (9:16)
WIDTH=1080
HEIGHT=1920

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Step 1: Process each clip to standard size
declare -a trimmed_clips
i=1

while IFS=$'\t' read -r scene path in_time out_time notes; do
  [[ "$scene" =~ ^#.*$ || -z "$scene" ]] && continue
  [[ ! -f "$path" ]] && { echo "⚠️  Missing: $path"; continue; }

  trimmed="clip_$(printf "%03d" $i).mp4"
  trimmed_path="$TEMP_DIR/$trimmed"

  echo "✂️  Processing $scene → $trimmed ($in_time → $out_time)"
  ffmpeg -y -i "$path" -ss "$in_time" -to "$out_time" \
    -vf "scale=$WIDTH:$HEIGHT:force_original_aspect_ratio=decrease,pad=$WIDTH:$HEIGHT:(ow-iw)/2:(oh-ih)/2,setsar=1" \
    -c:a copy "$trimmed_path"

  trimmed_clips+=("$trimmed_path")
  ((i++))
done < mop_sequence.tsv

# Step 2: Concatenate
LIST="$TEMP_DIR/list.txt"
> "$LIST"
for clip in "${trimmed_clips[@]}"; do
  echo "file '$clip'" >> "$LIST"
done

ffmpeg -y -f concat -safe 0 -i "$LIST" -c copy final_mop_twist.mp4

echo "✅ Final video: $PROJECT_DIR/final_mop_twist.mp4"
