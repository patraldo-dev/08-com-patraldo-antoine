#!/bin/bash
# ToolsAndScripts/list_by_client.sh

set -e

PROJECTS_DIR="../Projects"

if [ ! -d "$PROJECTS_DIR" ]; then
  echo "❌ $PROJECTS_DIR not found."
  exit 1
fi

echo "🎨 Projects by Client / Category"
echo "================================"

# Temporary file to collect data
TMP_FILE=$(mktemp)

# Extract client from project name: assume format "ClientName-Project"
# If no hyphen, treat as "Personal"
while IFS= read -r -d '' proj; do
  [ -d "$proj" ] || continue
  proj_base=$(basename "$proj")
  if [[ $proj_base =~ ^[0-9]{3}-[0-9]{8}-(.+)$ ]]; then
    name_part="${BASH_REMATCH[1]}"
    if [[ "$name_part" == *-* ]]; then
      # First part before first hyphen = client
      client=$(echo "$name_part" | cut -d'-' -f1)
    else
      client="Personal"
    fi
    echo "$client|$proj_base" >> "$TMP_FILE"
  fi
done < <(find "$PROJECTS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" -print0 2>/dev/null)

if [ ! -s "$TMP_FILE" ]; then
  echo "📭 No projects found."
else
  # Sort by client, then project
  sort -t'|' -k1,1 -k2,2 "$TMP_FILE" | {
    current_client=""
    while IFS='|' read -r client proj; do
      if [ "$client" != "$current_client" ]; then
        if [ -n "$current_client" ]; then
          echo ""
        fi
        echo "👤 $client:"
        current_client="$client"
      fi
      echo "   • $proj"
    done
  }
fi

rm -f "$TMP_FILE"
echo ""
