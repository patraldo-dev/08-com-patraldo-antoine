#!/bin/bash
# scripts/fix-db-binding.sh
# Replaces incorrect DB references with platform.env.DB_stories

set -e

echo "🔍 Finding +page.server.js files..."

# Find all +page.server.js files recursively
files=$(find . -name "+page.server.js" -type f)

if [ -z "$files" ]; then
  echo "❌ No +page.server.js files found."
  exit 1
fi

echo "✏️  Updating DB binding in the following files:"
echo "$files"

# Process each file
while IFS= read -r file; do
  if [ -f "$file" ]; then
    # Replace any variation of env.DB or platform.env.DB with platform.env.DB_stories
    sed -i.bak "
      s/env\.DB/platform.env.DB_stories/g;
      s/platform\.env\.DB/platform.env.DB_stories/g;
      s/const db = .*/const db = platform.env.DB_stories;/g
    " "$file"
    echo "✅ Updated: $file"
  fi
done <<< "$files"

echo "✨ Done! Backup files (.bak) were created in case you need to revert."
