#!/bin/bash
# Add single audio track to video, copy video stream
# Usage: add_audio.sh VIDEO.mp4 AUDIO.m4a [OUTPUT.mp4]

if [[ $# -lt 2 ]]; then
  echo "Usage: add_audio.sh VIDEO.mp4 AUDIO.m4a [OUTPUT.mp4]"
  echo "If OUTPUT not given, uses 'VIDEO-audio.mp4'"
  exit 1
fi

video="$1"
audio="$2"
output="${3:-${video%.*}-audio.mp4}"

if [[ ! -f "$video" ]]; then echo "❌ Video not found: $video"; exit 1; fi
if [[ ! -f "$audio" ]]; then echo "❌ Audio not found: $audio"; exit 1; fi

echo "🎬 Adding audio to: $video"
echo "🔊 Using: $audio"
echo "💾 Output: $output"
echo "----------------------------------------"

ffmpeg -i "$video" -i "$audio" \
  -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k -shortest \
  "$output"

echo "✅ Done: $output"
