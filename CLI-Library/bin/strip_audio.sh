#!/bin/bash

# Strip audio from all MP4s in a source folder
INPUT_DIR="${1:-03A_wan_output_compatible}"
OUTPUT_DIR="${2:-03B_wan_output_noaudio}"

mkdir -p "$OUTPUT_DIR"

shopt -s nullglob
files=("$INPUT_DIR"/*.mp4)

if [ ${#files[@]} -eq 0 ]; then
    echo "❌ No MP4 files found in $INPUT_DIR"
    exit 1
fi

echo "🔇 Stripping audio from ${#files[@]} files..."

for input in "${files[@]}"; do
    filename=$(basename "$input")
    output="$OUTPUT_DIR/${filename%.*}_noaudio.mp4"

    if [ -f "$output" ]; then
        echo "⏭️  Skipping (exists): $filename"
        continue
    fi

    echo "✂️  Removing audio: $filename"
    ffmpeg -hide_banner -nostats -i "$input" -c:v copy -an "$output"
done

echo "✅ Done! Silent videos in: $OUTPUT_DIR"
