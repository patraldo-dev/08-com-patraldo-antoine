ffmpeg \
  -i ~/11ElevenLabs-VoiceStuff/output/MobileFirstoutput_en-US.mp4 \
  -i Starry_Eyed_en_final.mp4 \
  -filter_complex "\
    [0:v]scale=640:1138:force_original_aspect_ratio=decrease,pad=640:1138:(ow-iw)/2:(oh-ih)/2,setsar=1[v0]; \
    [1:v]scale=640:1138:force_original_aspect_ratio=decrease,pad=640:1138:(ow-iw)/2:(oh-ih)/2,setsar=1[v1]; \
    [v0][0:a][v1][1:a]concat=n=2:v=1:a=1[outv][outa]" \
  -map "[outv]" -map "[outa]" \
  -c:v libx264 -profile:v baseline -level 3.0 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  -fps_mode vfr -r 30 \
  concatenated_en.mp4

