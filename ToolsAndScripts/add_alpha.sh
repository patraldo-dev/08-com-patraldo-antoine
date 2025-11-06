#!/bin/bash
# Add alpha channel to MP4 by removing background color

if [ -z "$1" ]; then
  echo "Usage: $0 <input_video_file>"
  exit 1
fi

inputfile="$1"
if [[ ! -f "$inputfile" ]]; then
  echo "File not found!"
  exit 1
fi

echo "Choose background removal method:"
echo "1) Remove specific color (chroma key)"
echo "2) Remove black background"
echo "3) Remove white background"
echo "4) Smart background removal (attempts to detect and remove solid background)"
read -p "Select option (1-4): " method

case $method in
  1)
    read -p "Enter color to remove (hex format, e.g., 00ff00 for green): " color
    read -p "Enter similarity threshold (0.0-1.0, default 0.1): " similarity
    similarity=${similarity:-0.1}
    read -p "Enter blend/smoothness (0.0-1.0, default 0.1): " blend
    blend=${blend:-0.1}
    
    filter="chromakey=0x${color}:${similarity}:${blend}"
    ;;
  2)
    read -p "Enter similarity threshold (0.0-1.0, default 0.1): " similarity
    similarity=${similarity:-0.1}
    read -p "Enter blend/smoothness (0.0-1.0, default 0.1): " blend
    blend=${blend:-0.1}
    
    filter="chromakey=0x000000:${similarity}:${blend}"
    ;;
  3)
    read -p "Enter similarity threshold (0.0-1.0, default 0.1): " similarity
    similarity=${similarity:-0.1}
    read -p "Enter blend/smoothness (0.0-1.0, default 0.1): " blend
    blend=${blend:-0.1}
    
    filter="chromakey=0xffffff:${similarity}:${blend}"
    ;;
  4)
    echo "Using colorkey with automatic black removal..."
    read -p "Enter similarity threshold (0.0-1.0, default 0.3): " similarity
    similarity=${similarity:-0.3}
    read -p "Enter blend/smoothness (0.0-1.0, default 0.1): " blend
    blend=${blend:-0.1}
    
    filter="colorkey=0x000000:${similarity}:${blend}"
    ;;
  *)
    echo "Invalid option, exiting."
    exit 1
    ;;
esac

# Output filename
input_dir=$(dirname "$inputfile")
input_base=$(basename "$inputfile")
input_name="${input_base%.*}"
outputfile="${input_dir}/alpha_${input_name}.mov"

echo ""
echo "Processing video with alpha channel..."
echo "Filter: $filter"
echo ""

# Create video with alpha channel (MOV with ProRes 4444 supports alpha)
ffmpeg -i "$inputfile" \
  -vf "$filter" \
  -c:v prores_ks -profile:v 4444 -pix_fmt yuva444p10le \
  -c:a copy \
  "$outputfile"

echo ""
echo "Done! Output file: $outputfile"
echo "This MOV file now has an alpha channel and can be composited over backgrounds."

# Optional: Ask before playing
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
    ffplay "$outputfile"
fi
