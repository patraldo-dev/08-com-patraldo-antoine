#!/bin/bash

# Default extension
EXT="${2:-mp4}"

# Auto-detect base name from files
BASE=$(printf '%s\n' *."$EXT" 2>/dev/null | sed -E "s/( \([0-9]+\))?\.$EXT$//" | sort -u | head -n1)

if [[ -z "$BASE" ]]; then
  echo "❌ No .$EXT files found in current directory."
  exit 1
fi

# Use first argument as new name, or prompt for it
if [[ -n "$1" ]]; then
  NEWNAME="$1"
else
  read -p "📁 Detected base name: '$BASE'  
✏️  Enter new base name (e.g., DiaDeMuertos): " NEWNAME

  if [[ -z "$NEWNAME" ]]; then
    echo "⚠️  No name provided. Exiting."
    exit 1
  fi
fi

echo "🚀 Renaming .$EXT files from '$BASE' → '$NEWNAME'"

# Rename unnumbered file → 0
if [[ -f "${BASE}.${EXT}" ]]; then
  mv "${BASE}.${EXT}" "${NEWNAME}0.${EXT}"
  echo "✅ ${BASE}.${EXT} → ${NEWNAME}0.${EXT}"
fi

# Rename numbered files
shopt -s nullglob  # avoid errors if no matches
for f in "${BASE} ("*".${EXT}"; do
  if [[ $f =~ \(([0-9]+)\)\.${EXT}$ ]]; then
    mv "$f" "${NEWNAME}${BASH_REMATCH[1]}.${EXT}"
    echo "✅ $f → ${NEWNAME}${BASH_REMATCH[1]}.${EXT}"
  fi
done

echo "✨ Done!"#!/bin/bash
prefix=${1:-NewName}
base="Wan_Image_to_Video_The engraving depicts a witch on a broomstick, a cat on anoth"

mv "$base.mp4" "${prefix}0.mp4" 2>/dev/null || true
for f in "$base ("*.mp4; do
  [[ $f =~ \(([0-9]+)\)\.mp4$ ]] && mv "$f" "${prefix}${BASH_REMATCH[1]}.mp4"
done
