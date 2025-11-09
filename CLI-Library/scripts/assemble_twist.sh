#!/bin/bash
set -e

PROJECT_DIR="$HOME/AGRia-Video-Studio/Projects/009-20251107-Antoine-MopHairTwist"
cd "$PROJECT_DIR"

# Define clips in order
CLIPS=(
  "scenes/close-up/wan_output/MopHairTwist9x16.mp4"
  "scenes/All-eyes/wan_output/EyesMoving.mp4"
  "scenes/close-up/wan_output/MopHairTwistOriginal.mp4"
  "scenes/close-up/wan_output/MopHairTwist9x16.mp4"
  "scenes/All-eyes/wan_output/EyesMoving.mp4"
  "scenes/blue-leaves-ablowin/wan_output/BlueLeavesAblowin.mp4"
)

# Get durations (for timing)
declare -a DURATIONS
for clip in "${CLIPS[@]}"; do
  dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$clip")
  DURATIONS+=("$dur")
done

# Build filter chain
FILTER=""

# Start with first clip
INPUTS=""
for i in "${!CLIPS[@]}"; do
  INPUTS+="-i \"${CLIPS[i]}\" "
done

# Build xfade chain
# xfade needs: [0][1]xfade=..., [out][2]xfade=..., etc.
FILTER="[0:v][0:a][1:v][1:a]xfade=transition=fade:duration=0.8:offset=${DURATIONS[0]};"
FILTER+="[v0][a0][2:v][2:a]xfade=transition=fade:duration=0.8:offset=$(echo "${DURATIONS[0]} + ${DURATIONS[1]} - 0.8" | bc);"
FILTER+="[v1][a1][3:v][3:a]xfade=transition=fade:duration=0.8:offset=$(echo "${DURATIONS[0]} + ${DURATIONS[1]} + ${DURATIONS[2]} - 0.8" | bc);"
FILTER+="[v2][a2][4:v][4:a]xfade=transition=fade:duration=0.8:offset=$(echo "${DURATIONS[0]} + ${DURATIONS[1]} + ${DURATIONS[2]} + ${DURATIONS[3]} - 0.8" | bc);"
FILTER+="[v3][a3][5:v][5:a]xfade=transition=fade:duration=0.8:offset=$(echo "${DURATIONS[0]} + ${DURATIONS[1]} + ${DURATIONS[2]} + ${DURATIONS[3]} + ${DURATIONS[4]} - 0.8" | bc)"

# Final command
eval "ffmpeg -y $INPUTS -filter_complex \"$FILTER\" -map \"[v4]\" -map \"[a4]\" -c:v libx264 -crf 23 -c:a aac final_xfade.mp4"

echo "✅ Crossfaded video ready: $PROJECT_DIR/final_xfade.mp4"
