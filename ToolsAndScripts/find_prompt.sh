#!/bin/bash
# ToolsAndScripts/find_prompt.sh

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $0 \"search-term\""
  echo "Example: $0 \"cat\""
  echo ""
  echo "Searches all prompt.txt files in Project/ scenes."
  exit 1
fi

SEARCH_TERM="$1"
PROJECTS_DIR="../Projects"

if [ ! -d "$PROJECTS_DIR" ]; then
  echo "❌ No Project/ directory found."
  exit 1
fi

echo "🔍 Searching prompts for: '$SEARCH_TERM'"
echo "----------------------------------------"

# Search all prompt.txt files (case-insensitive)
found=0
while IFS= read -r -d '' prompt_file; do
  if grep -l -i "$SEARCH_TERM" "$prompt_file" > /dev/null; then
    echo "📄 $prompt_file"
    grep -n -i --color=always "$SEARCH_TERM" "$prompt_file"
    echo ""
    found=1
  fi
done < <(find "$PROJECTS_DIR" -path "*/prompts/prompt.txt" -type f -print0 2>/dev/null)

if [ "$found" -eq 0 ]; then
  echo "📭 No matches found for '$SEARCH_TERM'."
fi
