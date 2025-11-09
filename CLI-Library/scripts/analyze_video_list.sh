#!/bin/bash
# Analyze video resolution and duration from an FFmpeg concat list (videos.txt)
# Usage: ./analyze_video_list.sh videos.txt

if [[ $# -ne 1 ]] || [[ ! -f "$1" ]]; then
  echo "Usage: $0 videos.txt"
  echo "Example: $0 my_project/videos.txt"
  exit 1
fi

INPUT_LIST="$1"
OUTPUT_REPORT="${INPUT_LIST%.*}_report.txt"

# Extract clean paths
grep "^file" "$INPUT_LIST" | sed "s/file '//; s/'$//" > /tmp/video_paths_$$

# Analyze each
while IFS= read -r video; do
  if [[ -f "$video" ]]; then
    size=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$video" 2>/dev/null)
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video" 2>/dev/null)
    printf "%-50s %12s %8s sec\n" "$video" "$size" "${dur%.*}"
  else
    echo "$video: NOT FOUND"
  fi
done < /tmp/video_paths_$$ | tee "$OUTPUT_REPORT"


# Cleanup
rm -f /tmp/video_paths_$$

echo "✅ Report saved to: $OUTPUT_REPORT"


# Tab completion support
_analyze_video_list_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=($(compgen -f -X '!*.@(txt|tsv|csv)' -- "$cur"))
}
complete -F _analyze_video_list_completion "${BASH_SOURCE[0]##*/}"
complete -F _analyze_video_list_completion "runlib ${BASH_SOURCE[0]##*/}"

# Cleanup
rm -f /tmp/video_paths_$$

echo "✅ Report saved to: $OUTPUT_REPORT"
