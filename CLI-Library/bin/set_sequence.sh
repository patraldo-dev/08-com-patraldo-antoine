#!/bin/bash
# ToolsAndScripts/set_sequence.sh

set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 \"ProjectFolderName\""
  echo "Example: $0 \"000-20251028-Antoine-Paris\""
  exit 1
fi

PROJECT="$1"
PROJECT_PATH="../Projects/$PROJECT"

if [ ! -d "$PROJECT_PATH/scenes" ]; then
  echo "❌ No scenes found in $PROJECT_PATH/scenes/"
  exit 1
fi

SEQUENCE_FILE="$PROJECT_PATH/edited_clips/sequence.txt"
mkdir -p "$PROJECT_PATH/edited_clips"

# Collect ALL scene folders (no ##- required)
mapfile -t scenes < <(find "$PROJECT_PATH/scenes" -mindepth 1 -maxdepth 1 -type d -not -name ".*" 2>/dev/null | sort | xargs -I{} basename {})

if [ ${#scenes[@]} -eq 0 ]; then
  echo "📭 No scenes found in $PROJECT_PATH/scenes/ (expected folders like 'cat-at-cafe')."
  exit 1
fi

echo "🎬 Scenes in $PROJECT:"
echo "----------------------------------------"
for i in "${!scenes[@]}"; do
  num=$((i+1))
  echo "  [$num] ${scenes[$i]}"
done
echo "----------------------------------------"

echo ""
echo "Enter playback order as scene NUMBERS separated by spaces."
echo "Example: 2 4 1 5 3"
echo ""

read -r -p "Playback order: " -e input

if [ -z "$input" ]; then
  echo "⚠️ No input. Aborting."
  exit 1
fi

# Parse and validate
IFS=' ' read -ra ORDER_NUMS <<< "$input"
sequence=()

for num in "${ORDER_NUMS[@]}"; do
  if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#scenes[@]}" ]; then
    scene_name="${scenes[$((num-1))]}"
    sequence+=("$scene_name")
  else
    echo "⚠️ Warning: '$num' is not a valid scene number (1–${#scenes[@]})"
  fi
done

if [ ${#sequence[@]} -eq 0 ]; then
  echo "❌ No valid scenes selected."
  exit 1
fi

# Save with datestamp
{
  echo "# Sequence last updated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "# Project: $PROJECT"
  printf '%s\n' "${sequence[@]}"
} > "$SEQUENCE_FILE"

# ✅ SHOW FINAL RESULT ON SCREEN
echo ""
echo "✅ Sequence saved successfully!"
echo "📄 File: $SEQUENCE_FILE"
echo ""
echo "📺 Final playback order:"
for i in "${!sequence[@]}"; do
  printf "  %2d. %s\n" $((i+1)) "${sequence[$i]}"
done
echo ""
