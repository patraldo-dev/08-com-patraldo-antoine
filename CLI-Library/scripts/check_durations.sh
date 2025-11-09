#!/bin/bash
# Check duration of all MP4s in a project (or current dir)

TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Usage: $0 [project_path]"
  echo "Example: $0 ~/AGRia-Video-Studio/Projects/009-20251107-Antoine-MopHairTwist"
  exit 1
fi

echo "📹 Checking durations in: $TARGET_DIR"
echo "----------------------------------------"

while IFS= read -r -d '' file; do
  duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null)
  if [[ -n "$duration" ]]; then
    printf "%-10s %s\n" "${duration%.*}s" "$file"
  else
    echo "⚠️  Unknown duration: $file"
  fi
done < <(find "$TARGET_DIR" -name "*.mp4" -type f -print0)

echo "----------------------------------------"
echo "✅ Done."
