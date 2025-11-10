#!/bin/bash

VIDEO="StarryEyed_wXfades.mp4"
MUSIC="../../audio/TheTwist.m4a"

MUSIC_VOLUME_EXPR="if(between(t\,0\,10)\,1\,if(between(t\,10\,15)\,0.2\,if(between(t\,15\,25)\,1\,if(between(t\,25\,30)\,0.2\,if(between(t\,30\,40)\,1\,0.2)))))"

for lang in en es fr; do
  DIALOGUE="11ElevenLabs/audio_timed/star_${lang}_timed.mp3"
  OUTPUT="StarryEyed_${lang}.mp4"

  ffmpeg -y -i "$VIDEO" -i "$DIALOGUE" -i "$MUSIC" -filter_complex "[2:a]volume='$MUSIC_VOLUME_EXPR'[music_adj];[1:a][music_adj]amix=inputs=2:duration=longest[aout]" -map 0:v -map "[aout]" -c:v copy -c:a aac -shortest "$OUTPUT"

  echo "Created $OUTPUT"
done

