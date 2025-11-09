#!/bin/bash
# ToolsAndScripts/new_project.sh
# Creates a new project with optional client context

set -e

PROJECT_NAME=""
CLIENT_NAME=""

# Parse args
if [[ $# -eq 0 ]]; then
  read -p "🔤 Project name (e.g., MopHairTwist): " PROJECT_NAME
  if [[ -z "$PROJECT_NAME" ]]; then
    echo "❌ Project name is required."
    exit 1
  fi
  read -p "👤 Client name (e.g., Antoine) [optional]: " CLIENT_NAME
elif [[ $# -eq 1 ]]; then
  PROJECT_NAME="$1"
elif [[ $# -eq 2 ]]; then
  PROJECT_NAME="$1"
  CLIENT_NAME="$2"
else
  echo "Usage: $0 [\"ProjectName\" [\"ClientName\"]]"
  exit 1
fi

# --- 🔑 KEY FIX: Derive Projects dir from script location ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$(cd "$SCRIPT_DIR/../../Projects" && pwd)"
# --- END FIX ---

mkdir -p "$PROJECTS_DIR"

# Find highest project number (000–999)
MAX_NUM=-1
for dir in "$PROJECTS_DIR"/[0-9][0-9][0-9]-*; do
  [ -d "$dir" ] || continue
  BASE=$(basename "$dir")
  NUM_STR=${BASE%%-*}
  
  # Handle leading zeros (avoid octal error)
  if [[ $NUM_STR =~ ^0+$ ]]; then
    NUM=0
  else
    NUM=$((10#$NUM_STR))  # force base-10
  fi
  
  if [ "$NUM" -gt "$MAX_NUM" ]; then
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

if [[ -n "$CLIENT_NAME" ]]; then
  DISPLAY_NAME="${CLIENT_NAME}-${PROJECT_NAME}"
else
  DISPLAY_NAME="${PROJECT_NAME}"
fi

PROJECT_DIR="$PROJECTS_DIR/${PADDED_NUM}-${DATE}-${DISPLAY_NAME}"

if [ -e "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR already exists."
  exit 1
fi

mkdir -p "$PROJECT_DIR/scenes"
mkdir -p "$PROJECT_DIR/assets/{characters,sound,fonts}" 2>/dev/null

echo "✅ Created project: $(basename "$PROJECT_DIR")"
if [[ -n "$CLIENT_NAME" ]]; then
  echo "   Client: $CLIENT_NAME"
fi
echo "   Add scenes with: ./new_scene.sh \"$(basename "$PROJECT_DIR")\" \"SceneName\""
