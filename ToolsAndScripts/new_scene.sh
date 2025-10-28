#!/bin/bash
# ToolsAndScripts/new_scene.sh

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 \"ProjectFolderName\" \"SceneName\""
  echo "Example: $0 \"001-20251029-ParisDreams\" \"cafe-with-cat\""
  echo ""
  echo "Existing projects:"
  ls -1 ../Projects/[0-9][0-9][0-9]-* 2>/dev/null | xargs -r basename || echo "  (none)"
  exit 1
fi

PROJECT_FOLDER="$1"
SCENE_NAME="$2"
PROJECT_PATH="../Projects/$PROJECT_FOLDER"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Error: Project not found: $PROJECT_PATH"
  exit 1
fi

mkdir -p "$PROJECT_PATH/scenes"

# Find next scene number
MAX_SCENE_NUM=0
while IFS= read -r -d '' scene_dir; do
  scene_base=$(basename "$scene_dir")
  if [[ $scene_base =~ ^([0-9]{2})- ]]; then
    NUM=${BASH_REMATCH[1]}
    if [ "$NUM" -gt "$MAX_SCENE_NUM" ]; then
      MAX_SCENE_NUM=$NUM
    fi
  fi
done < <(find "$PROJECT_PATH/scenes" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

NEXT_SCENE_NUM=$((MAX_SCENE_NUM + 1))
PADDED_SCENE=$(printf "%02d" "$NEXT_SCENE_NUM")
SCENE_DIR="$PROJECT_PATH/scenes/${PADDED_SCENE}-${SCENE_NAME}"

if [ -e "$SCENE_DIR" ]; then
  echo "Error: Scene already exists: $SCENE_DIR"
  exit 1
fi

mkdir -p "$SCENE_DIR"/{drawings,prompts,wan_output,edited_clips}

echo "✅ Created scene: ${PADDED_SCENE}-${SCENE_NAME}"
echo "   Path: $SCENE_DIR"
