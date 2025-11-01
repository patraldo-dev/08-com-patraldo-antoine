#!/bin/bash
# ToolsAndScripts/new_project.sh

set -e

PROJECT_NAME="$1"
PROJECTS_DIR="../Projects"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: $0 \"ProjectName\""
  echo "Example: $0 \"ParisDreams\""
  exit 1
fi

mkdir -p "$PROJECTS_DIR"

# Find highest project number (000–999)
MAX_NUM=-1
for dir in "$PROJECTS_DIR"/[0-9][0-9][0-9]-*; do
  [ -d "$dir" ] || continue
  BASE=$(basename "$dir")
  NUM=${BASE%%-*}
  if [[ $NUM =~ ^[0-9]{3}$ ]] && [ "$NUM" -gt "$MAX_NUM" ]; then
    MAX_NUM=$NUM
  fi
done

NEXT_NUM=$((MAX_NUM + 1))
if [ "$NEXT_NUM" -gt 999 ]; then
  echo "Error: Max 1000 projects reached (000–999)."
  exit 1
fi

PADDED_NUM=$(printf "%03d" "$NEXT_NUM")
DATE=$(date +%Y%m%d)
PROJECT_DIR="$PROJECTS_DIR/${PADDED_NUM}-${DATE}-${PROJECT_NAME}"

if [ -e "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR already exists."
  exit 1
fi

mkdir -p "$PROJECT_DIR/scenes"
mkdir -p "$PROJECT_DIR/assets/{characters,sound,fonts}" 2>/dev/null

echo "✅ Created project: $(basename "$PROJECT_DIR")"
echo "   Add scenes with: ./new_scene.sh \"$(basename "$PROJECT_DIR")\" \"SceneName\""
