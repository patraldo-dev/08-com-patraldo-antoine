#!/bin/bash
# ToolsAndScripts/new_scene.sh
# Creates a new scene in an existing project

set -e

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 \"ProjectFolderName\" \"scene-name\""
  echo "Example: $0 \"009-20251108-Antoine-MopHairTwist\" \"cat-at-cafe\""
  exit 1
fi

PROJECT_FOLDER="$1"
SCENE_NAME="$2"

# --- 🔑 FIX: Derive Projects dir from script location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$(cd "$SCRIPT_DIR/../../Projects" && pwd)"
PROJECT_PATH="$PROJECTS_DIR/$PROJECT_FOLDER"
# --- END FIX ---

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Error: Project not found: $PROJECT_PATH"
  exit 1
fi

SCENE_DIR="$PROJECT_PATH/scenes/$SCENE_NAME"

if [[ -e "$SCENE_DIR" ]]; then
  echo "Error: Scene already exists: $SCENE_DIR"
  exit 1
fi

mkdir -p "$SCENE_DIR"/{drawings,prompts,wan_output,edited_clips}

echo "✅ Created scene: $SCENE_NAME"
echo "   Path: $SCENE_DIR"
