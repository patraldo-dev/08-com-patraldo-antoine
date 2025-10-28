#!/bin/bash

# Script to randomly concatenate videos with xfade transitions
# Usage: ./xfade_random_concat.sh [transition_duration] [output_name]

TRANSITION_DURATION=${1:-1.5}  # Default 1.5 seconds
OUTPUT_NAME=${2:-"final_xfade.mp4"}
VIDEO_DIR="scaled"  # Change if your videos are elsewhere

# Available transitions
TRANSITIONS=("fade" "wipeleft" "wiperight" "wipeup" "wipedown" 
             "slideleft" "slideright" "slideup" "slidedown"
             "circlecrop" "circleopen" "circleclose" "dissolve"
             "distance" "fadeblack" "fadewhite" "radial"
             "smoothleft" "smoothright" "smoothup" "smoothdown"
             "diagtl" "diagtr" "diagbl" "diagbr")

echo "=== Random XFade Video Concatenator ==="
echo "Transition duration: ${TRANSITION_DURATION}s"
echo ""

# Get all videos and shuffle
mapfile -t VIDEOS < <(find "$VIDEO_DIR" -name "*.mp4" -type f | shuf)

if [ ${#VIDEOS[@]} -eq 0 ]; then
    echo "Error: No videos found in $VIDEO_DIR/"
    exit 1
fi

echo "Found ${#VIDEOS[@]} videos (randomized order):"
for i in "${!VIDEOS[@]}"; do
    echo "  $((i+1)). ${VIDEOS[$i]}"
done
echo ""

# Get durations of all videos
echo "Getting video durations..."
declare -a DURATIONS
for video in "${VIDEOS[@]}"; do
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video")
    DURATIONS+=("$duration")
    echo "  $(basename "$video"): ${duration}s"
done
echo ""

# Build input arguments
INPUTS=""
for video in "${VIDEOS[@]}"; do
    INPUTS="$INPUTS -i \"$video\""
done

# Build filter_complex for xfade
echo "Building xfade filter chain..."
FILTER=""
offset=0

for i in $(seq 1 $((${#VIDEOS[@]} - 1))); do
    # Calculate offset (cumulative duration minus transition overlap)
    prev_duration=${DURATIONS[$((i-1))]}
    offset=$(awk "BEGIN {print $offset + $prev_duration - $TRANSITION_DURATION}")
    
    # Pick random transition
    random_trans=${TRANSITIONS[$RANDOM % ${#TRANSITIONS[@]}]}
    echo "  Transition $i: $random_trans at ${offset}s"
    
    if [ $i -eq 1 ]; then
        FILTER="[0:v][1:v]xfade=transition=$random_trans:duration=$TRANSITION_DURATION:offset=$offset[v1]"
    else
        prev_label="v$((i-1))"
        curr_label="v$i"
        FILTER="$FILTER;[$prev_label][$i:v]xfade=transition=$random_trans:duration=$TRANSITION_DURATION:offset=$offset[$curr_label]"
    fi
done

# Final output label
FINAL_LABEL="v$((${#VIDEOS[@]} - 1))"

echo ""
echo "Building command..."
echo ""

# Build and execute ffmpeg command
CMD="ffmpeg $INPUTS -filter_complex \"$FILTER\" -map \"[$FINAL_LABEL]\" -c:v libx264 -pix_fmt yuv420p -crf 23 -preset medium \"$OUTPUT_NAME\""

# Save command to file for reference
echo "$CMD" > xfade_command.txt
echo "Command saved to: xfade_command.txt"
echo ""

# Execute
echo "Executing ffmpeg..."
echo ""
eval $CMD

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Success! Output: $OUTPUT_NAME"
    
    # Calculate total duration
    total_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_NAME")
    echo "  Final duration: ${total_duration}s"
else
    echo ""
    echo "✗ Error occurred during concatenation"
    exit 1
fi
