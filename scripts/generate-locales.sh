#!/bin/bash
# scripts/generate-locales.sh

set -e

# Supported locales
LOCALES=("es-MX" "en-US" "fr-CA")

# Page keys (match your translations.js loaders)
PAGES=(
  "common"
  "pages.home"
  "pages.about"
  "pages.blog"
  "pages.books"
  "pages.reviews"
  "pages.bookReview"
  "pages.privacy"
  "pages.admin"
  "story.home"
  "story.chapter1"
)

# Base directory
BASE_DIR="src/lib/locales"

echo "📁 Generating locale files..."

# Create base directory if missing
mkdir -p "$BASE_DIR"

# Generate files
for locale in "${LOCALES[@]}"; do
  for page_key in "${PAGES[@]}"; do
    # Convert dot notation to path: "pages.home" → "pages/home.json"
    if [[ "$page_key" == *"."* ]]; then
      dir_part="${page_key%.*}"
      file_part="${page_key##*.}"
      filepath="$BASE_DIR/$locale/$dir_part/$file_part.json"
      mkdir -p "$(dirname "$filepath")"
    else
      # e.g., "common" → "common.json"
      filepath="$BASE_DIR/$locale/$page_key.json"
      mkdir -p "$(dirname "$filepath")"
    fi

    # Only create if file doesn't exist
    if [ ! -f "$filepath" ]; then
      echo "{}" > "$filepath"
      echo "  ✅ Created $filepath"
    else
      echo "  ⏩ Skipped existing $filepath"
    fi
  done
done

echo "✨ Done! All locale files are ready."
echo "👉 Now fill them with real translations."
