#!/bin/bash

# Script to scale all videos to 720x960
# Creates a 'scaled/' subfolder with output files

# Create output directory
mkdir -p scaled

# Function to scale videos
scale_video() {
    local input="$1"
    local output="scaled/scaled_$(basename "$input")"
    
    echo "Processing: $input"
    
    # Get current dimensions
    dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$input")
    width=$(echo $dimensions | cut -d',' -f1)
    height=$(echo $dimensions | cut -d',' -f2)
    
    echo "  Current size: ${width}x${height}"
    
    # Determine scaling strategy based on dimensions
    if [ "$width" -eq 960 ] && [ "$height" -eq 960 ]; then
        # Square: crop to 720x960 from center
        echo "  Strategy: Crop square to portrait"
        ffmpeg -i "$input" -vf "crop=720:960:120:0" -c:v libx264 -pix_fmt yuv420p -crf 23 "$output" -y
    elif [ "$width" -eq 720 ]; then
        if [ "$height" -ge 960 ]; then
            # 720 width, tall enough: crop height to 960
            y_offset=$(( (height - 960) / 2 ))
            echo "  Strategy: Crop height to 960 (offset: $y_offset)"
            ffmpeg -i "$input" -vf "crop=720:960:0:$y_offset" -c:v libx264 -pix_fmt yuv420p -crf 23 "$output" -y
        else
            # 720 width, too short: pad to 960 height
            echo "  Strategy: Pad height to 960"
            ffmpeg -i "$input" -vf "scale=720:960:force_original_aspect_ratio=decrease,pad=720:960:(ow-iw)/2:(oh-ih)/2:black" -c:v libx264 -pix_fmt yuv420p -crf 23 "$output" -y
        fi
    else
        # Other dimensions (like 622x830): scale and pad
        echo "  Strategy: Scale and pad to 720x960"
        ffmpeg -i "$input" -vf "scale=720:960:force_original_aspect_ratio=decrease,pad=720:960:(ow-iw)/2:(oh-ih)/2:black" -c:v libx264 -pix_fmt yuv420p -crf 23 "$output" -y
    fi
    
    echo "  Output: $output"
    echo ""
}

# Process all MP4 files
for video in *.mp4; do
    if [ -f "$video" ]; then
        scale_video "$video"
    fi
done

echo "All videos scaled to 720x960!"
echo "Output location: scaled/"
echo ""
echo "To concatenate, create a filelist:"
echo "ls -1 scaled/*.mp4 | sed 's/^/file /' > filelist.txt"
echo "ffmpeg -f concat -safe 0 -i filelist.txt -c copy final_concatenated.mp4"
