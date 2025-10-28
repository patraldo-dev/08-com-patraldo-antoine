#!/bin/bash
while IFS= read -r f; do
    echo "Processing: $f"
done < real_mp4_files.txt
