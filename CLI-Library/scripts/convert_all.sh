#!/bin/bash

set -euo pipefail  # safer bash

INPUT_LIST="real_mp4_files.txt"
OUTPUT_DIR="03A_wan_output_compatible"

mkdir -p "$OUTPUT_DIR"

echo "📁 Found $(wc -l < "$INPUT_LIST") MP4 files. Converting to $OUTPUT_DIR..."

while IFS= read -r filepath; do
    # Skip if file disappeared
    if [[ ! -f "$filepath" ]]; then
        echo "⚠️  Missing: $filepath"
        continue
    fi

    # Create flat filename: ./a/b/c.mp4 → a_b_c_compatible.mp4
    flat_name=$(echo "${filepath#./}" | tr '/' '_')
    output="$OUTPUT_DIR/${flat_name%.*}_compatible.mp4"

    if [[ -f "$output" ]]; then
        echo "⏭️  Skipping (exists): $flat_name"
        continue
    fi

    echo "🎬 Converting: $flat_name"
    ffmpeg -hide_banner -nostats -i "$filepath" \
      -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1" \
      -c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -crf 23 \
      -c:a aac -b:a 128k -movflags +faststart \
      "$output"
done < "$INPUT_LIST"

echo
echo "✅ All done! Compatible videos are in: $OUTPUT_DIR"
echo "💡 Tip: Copy this folder to a USB drive and play directly on your Voplls N3."
