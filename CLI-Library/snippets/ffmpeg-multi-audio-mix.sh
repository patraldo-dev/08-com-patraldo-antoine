#!/bin/bash
# Usage: Replace paths and timings below
# Mixes 3 audio tracks with fade/volume and copies video stream

ffmpeg -i VIDEO.mp4 \
       -i AUDIO1.m4a \
       -i AUDIO2.m4a \
       -i AUDIO3.m4a \
  -filter_complex "[1:a]afade=t=out:st=FADE_START:d=FADE_DURATION,volume=VOL1[a1];\
                   [2:a]volume=VOL2[a2];\
                   [3:a]volume=VOL3[a3];\
                   [a1][a2][a3]amix=inputs=3:duration=shortest[aout]" \
  -map 0:v -map "[aout]" \
  -c:v copy -c:a aac -b:a 192k -shortest \
  OUTPUT.mp4
