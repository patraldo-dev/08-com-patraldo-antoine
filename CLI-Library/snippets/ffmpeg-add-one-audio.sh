#!/bin/bash
# Usage: Replace VIDEO.mp4, AUDIO.m4a, and OUTPUT.mp4 below
# Adds a single audio track to a 10s video (or any length), copies video stream

ffmpeg -i VIDEO.mp4 \
       -i AUDIO.m4a \
  -map 0:v -map 1:a \
  -c:v copy -c:a aac -b:a 192k -shortest \
  OUTPUT.mp4
