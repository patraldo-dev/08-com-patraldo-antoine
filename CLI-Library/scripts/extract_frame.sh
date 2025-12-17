#!/bin/bash
# Extract frames from video: precise time, random, or frame number
# Usage:
#   extract_frame.sh video.mp4 00:01:23.450 output.jpg    # precise time
#   extract_frame.sh video.mp4 random output.jpg          # random frame
#   extract_frame.sh video.mp4 123 output.jpg             # frame number
#   extract_frame.sh video.mp4 5-10 output.jpg            # random in range (5-10 seconds)
set -e

INPUT="$1"
TARGET="$2"
OUTPUT="${3:-frame_$(date +%s).jpg}"

show_usage() {
  echo "Usage:"
  echo "  $0 video.mp4 <time|frame_number|random|range> [output.jpg]"
  echo ""
  echo "Examples:"
  echo "  $0 input.mp4 00:01:30.500 frame.jpg    # Extract at precise timestamp"
  echo "  $0 input.mp4 142 frame.jpg              # Extract frame #142"
  echo "  $0 input.mp4 random frame.jpg           # Random frame from entire video"
  echo "  $0 input.mp4 10-20 frame.jpg            # Random frame between 10-20 seconds"
  echo "  $0 input.mp4 random                     # Auto-named output: frame_<timestamp>.jpg"
  exit 1
}

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
  echo "❌ Input file not found: $INPUT"
  show_usage
fi

if [[ -z "$TARGET" ]]; then
  echo "❌ Missing target (time/frame/random)"
  show_usage
fi

# Validate output format
if [[ ! "$OUTPUT" =~ \.(jpg|jpeg|png)$ ]]; then
  echo "⚠️  Warning: Output should be .jpg or .png (got: $OUTPUT)"
  echo "   Proceeding anyway..."
fi

# Get video duration and frame count for validation
DURATION=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT" 2>/dev/null || echo "0")
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=nw=1:nk=1 "$INPUT" 2>/dev/null | awk -F'/' '{print $1/$2}')
TOTAL_FRAMES=$(awk "BEGIN {print int($DURATION * $FPS)}")

if [[ "$TARGET" == "random" ]]; then
  # Random frame from entire video
  RAND_SEC=$(awk -v d="$DURATION" 'BEGIN{srand(); printf "%.3f", rand()*d}')
  ffmpeg -y -ss "$RAND_SEC" -i "$INPUT" -vframes 1 -q:v 2 "$OUTPUT" 2>&1 | grep -v "^frame=" || true
  echo "🎲 Random frame at ${RAND_SEC}s → $OUTPUT"

elif [[ "$TARGET" =~ ^([0-9]+)-([0-9]+)$ ]]; then
  # Random frame in time range (e.g., "10-20" = 10-20 seconds)
  START="${BASH_REMATCH[1]}"
  END="${BASH_REMATCH[2]}"
  
  if (( END > DURATION )); then
    echo "⚠️  End time ${END}s exceeds video duration ${DURATION}s. Using full duration."
    END="$DURATION"
  fi
  
  if (( START >= END )); then
    echo "❌ Invalid range: start ($START) must be less than end ($END)"
    exit 1
  fi
  
  RAND_SEC=$(awk -v s="$START" -v e="$END" 'BEGIN{srand(); printf "%.3f", s + rand()*(e-s)}')
  ffmpeg -y -ss "$RAND_SEC" -i "$INPUT" -vframes 1 -q:v 2 "$OUTPUT" 2>&1 | grep -v "^frame=" || true
  echo "🎲 Random frame in range ${START}-${END}s → extracted at ${RAND_SEC}s → $OUTPUT"

elif [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  # Frame number
  if (( TARGET > TOTAL_FRAMES )); then
    echo "⚠️  Warning: Frame #$TARGET exceeds total frames ($TOTAL_FRAMES). Extracting last frame."
    TARGET="$TOTAL_FRAMES"
  fi
  
  ffmpeg -y -i "$INPUT" -vf "select=eq(n\,$TARGET)" -vframes 1 -q:v 2 "$OUTPUT" 2>&1 | grep -v "^frame=" || true
  echo "🖼️  Frame #$TARGET → $OUTPUT"

else
  # Precise time (00:01:23.450 or just seconds like 83.5)
  # Validate timestamp format
  if [[ ! "$TARGET" =~ ^([0-9]{2}:)?[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]] && [[ ! "$TARGET" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "❌ Invalid time format: $TARGET"
    echo "   Use: HH:MM:SS.mmm or MM:SS.mmm or seconds (e.g., 83.5)"
    exit 1
  fi
  
  ffmpeg -y -ss "$TARGET" -i "$INPUT" -vframes 1 -q:v 2 "$OUTPUT" 2>&1 | grep -v "^frame=" || true
  echo "⏱️  Time $TARGET → $OUTPUT"
fi

# Verify output was created
if [[ ! -f "$OUTPUT" ]]; then
  echo "❌ Failed to extract frame"
  exit 1
fi

# Show file info
SIZE=$(du -h "$OUTPUT" | cut -f1)
DIMS=$(identify -format "%wx%h" "$OUTPUT" 2>/dev/null || echo "unknown")
echo "✅ Success! $OUTPUT ($SIZE, ${DIMS}px)"
