#!/bin/bash

# Usage: ./new_project.sh "MyProjectName"

if [ $# -eq 0 ]; then
  echo "Usage: $0 \"ProjectName\""
  exit 1
fi

PROJECT_NAME="$1"
PROJECTS_DIR="../Projects"

# Ensure the Projects directory exists
mkdir -p "$PROJECTS_DIR"

# Find the highest numeric prefix in existing project folders
MAX_NUM=0
for dir in "$PROJECTS_DIR"/[0-9][0-9][0-9][a-z]-*; do
  if [ -d "$dir" ]; then
    basename_dir=$(basename "$dir")
    NUM=${basename_dir%%[a-z]-*}
    if [[ $NUM =~ ^[0-9]{3}$ ]] && [ "$NUM" -gt "$MAX_NUM" ]; then
      MAX_NUM=$NUM
    fi
  fi
done

NEXT_NUM=$((MAX_NUM + 1))
NEXT_NUM_PADDED=$(printf "%03d" "$NEXT_NUM")

# Find next available letter suffix (a–z)
LETTER="a"
while [ -d "$PROJECTS_DIR/${NEXT_NUM_PADDED}${LETTER}-${PROJECT_NAME}" ]; do
  if [ "$LETTER" = "z" ]; then
    echo "Error: Too many variants for project number $NEXT_NUM_PADDED"
    exit 1
  fi
  LETTER=$(echo "$LETTER" | tr "a-y" "b-z")
done

NEW_DIR="$PROJECTS_DIR/${NEXT_NUM_PADDED}${LETTER}-${PROJECT_NAME}"

echo "Creating project folder: $NEW_DIR"

mkdir -p "$NEW_DIR"/{01_drawings,02_prompts,03_wan_output,04_edited_clips}

echo "✅ Done. Standard subfolders created in $NEW_DIR"
