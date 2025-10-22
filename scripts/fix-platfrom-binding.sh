#!/bin/bash
# scripts/fix-platform-binding.sh
# Fixes platform/env issues in +page.server.js for SvelteKit + Cloudflare D1

set -e

echo "🔧 Fixing platform and DB binding in +page.server.js files..."

# Find all +page.server.js files
while IFS= read -r file; do
  if [[ -f "$file" ]]; then
    echo "  → Updating: $file"

    # 1. Ensure `platform` is in the load function args
    # Match: load({ ... }) and inject `platform` if missing
    sed -i.bak '
      /^export async function load({/ {
        /platform/! {
          s/load({/load({ platform, /
          s/, }/ }/g
        }
      }
    ' "$file"

    # 2. Replace DB references with platform.env.DB_stories
    sed -i.bak '
      s/env\.DB/platform.env.DB_stories/g;
      s/platform\.env\.DB/platform.env.DB_stories/g;
      s/const db = .*/const db = platform.env.DB_stories;/
    ' "$file"
  fi
done < <(find . -name "+page.server.js" -type f)

echo "✅ Done! All +page.server.js files updated."
echo "ℹ️  Backup files (.bak) created. Remove with: find . -name '*.bak' -delete"
