for f in *.mp4; do
  echo "$f: $(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$f")"
done | tee video_sizes.txt
