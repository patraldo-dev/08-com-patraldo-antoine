#!/bin/bash
# Check input argument (filename)
if [ -z "$1" ]; then
  echo "Usage: $0 <input_video_file>"
  exit 1
fi
inputfile="$1"
if [[ ! -f "$inputfile" ]]; then
  echo "File not found!"
  exit 1
fi

# Prompt for output duration
read -p "Output video duration in seconds? (e.g., 10, 30, 60): " output_duration
if [[ ! "$output_duration" =~ ^[0-9]+$ ]] || (( output_duration < 1 )); then
  echo "Invalid input. Defaulting to 10 seconds."
  output_duration=10
fi

# Prompt for number of full rotations
read -p "How many full 360° rotations? (e.g., 1, 2, 3): " num_rotations
if [[ ! "$num_rotations" =~ ^[0-9]+$ ]] || (( num_rotations < 1 )); then
  echo "Invalid input. Defaulting to 1 rotation."
  num_rotations=1
fi

# Prompt for framerate
read -p "Output framerate (fps)? (e.g., 24, 30, 60): " output_fps
if [[ ! "$output_fps" =~ ^[0-9]+$ ]] || (( output_fps < 1 )); then
  echo "Invalid input. Defaulting to 30 fps."
  output_fps=30
fi

# Prompt for zoom effect
read -p "Apply zoom-out effect? (Y/n): " zoom_choice
apply_zoom=true
if [[ "$zoom_choice" == "n" || "$zoom_choice" == "N" ]]; then
  apply_zoom=false
fi

# Prompt for circular mask
read -p "Apply circular mask? (Y/n): " circle_choice
apply_circle=true
if [[ "$circle_choice" == "n" || "$circle_choice" == "N" ]]; then
  apply_circle=false
fi

# Calculate frames for ONE rotation
frames_per_rotation=$((output_duration * output_fps / num_rotations))
angle_increment=$(awk "BEGIN {printf \"%.2f\", 360.0 / $frames_per_rotation}")
total_output_frames=$((output_duration * output_fps))

echo ""
echo "Configuration:"
echo "  Output duration: ${output_duration}s"
echo "  Output framerate: ${output_fps} fps"
echo "  Rotations: $num_rotations"
echo "  Frames per rotation: $frames_per_rotation"
echo "  Total output frames: $total_output_frames"
echo "  Angle increment: ${angle_increment}°"
echo "  Zoom-out: $apply_zoom"
echo "  Circular mask: $apply_circle"
echo ""

# Get video resolution and duration
width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$inputfile")
height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$inputfile")
duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 "$inputfile")

echo "Source video:"
echo "  Dimensions: ${width}x${height}"
echo "  Duration: ${duration}s"
echo ""

if [[ -z "$width" ]] || [[ -z "$height" ]] || [[ -z "$duration" ]]; then
  echo "Error: Could not determine video properties"
  exit 1
fi

# Create temporary directory for rotated frames
tmpdir=$(mktemp -d)
echo "Temporary directory: $tmpdir"

# Generate frames for ONE rotation only
echo "Generating $frames_per_rotation frames for one rotation..."
for ((i=0; i<frames_per_rotation; i++)); do
  # Calculate rotation angle
  angle=$(awk "BEGIN {printf \"%.2f\", $i * $angle_increment}")
  
  # Calculate progress through ONE rotation (0 to 1)
  progress=$(awk "BEGIN {printf \"%.4f\", $i / ($frames_per_rotation - 1)}")
  
  # Sample from source video, looping through it
  timestamp=$(awk "BEGIN {printf \"%.4f\", ($progress * $duration) % $duration}")
  
  printf "Frame %d/%d (%.2f°, source time: %.2fs)\r" $((i+1)) $frames_per_rotation $angle $timestamp
  
  # Build filter chain
  filter="rotate=${angle}*PI/180:ow=max(iw\,ih):oh=max(iw\,ih):c=none"
  
  # Add zoom-out effect if enabled
  # Note: For looped rotations, zoom applies across ALL rotations
  if [ "$apply_zoom" = true ]; then
    # Calculate progress across entire animation
    overall_progress=$(awk "BEGIN {printf \"%.4f\", $i / ($total_output_frames - 1)}")
    scale_factor=$(awk "BEGIN {printf \"%.4f\", 1.0 - ($overall_progress * 0.5)}")
    filter="${filter},scale=iw*${scale_factor}:ih*${scale_factor}"
  fi
  
  # Add circular mask using proper geq syntax
  if [ "$apply_circle" = true ]; then
    # Calculate radius (use smallest dimension)
    base_radius=$(awk "BEGIN {printf \"%.2f\", (($width < $height ? $width : $height) / 2) * 0.9}")
    
    if [ "$apply_zoom" = true ]; then
      # Adjust radius for zoom
      overall_progress=$(awk "BEGIN {printf \"%.4f\", $i / ($total_output_frames - 1)}")
      scale_factor=$(awk "BEGIN {printf \"%.4f\", 1.0 - ($overall_progress * 0.5)}")
      radius=$(awk "BEGIN {printf \"%.2f\", $base_radius * $scale_factor}")
    else
      radius=$base_radius
    fi
    
    # Use proper geq syntax with lt() function
    filter="${filter},format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(lt(hypot(X-W/2,Y-H/2),${radius}),255,0)'"
  fi
  
  # Extract frame at specific timestamp and apply filters
  ffmpeg -loglevel error -ss $timestamp -i "$inputfile" \
    -vf "$filter" \
    -vframes 1 -q:v 2 \
    "$tmpdir/rotation_$(printf '%04d' $i).png"
done
echo ""
echo "Rotation complete!"

# Compose output filename
input_dir=$(dirname "$inputfile")
input_base=$(basename "$inputfile")
input_name="${input_base%.*}"
outputfile="${input_dir}/spinning_${input_name}.mp4"

# Create video by looping the rotation frames
echo "Creating spinning video (looping $num_rotations times)..."

if [ "$apply_zoom" = true ]; then
  echo "Note: Zoom effect requires generating all frames uniquely, cannot optimize with loops"
  echo "Generating remaining frames with zoom..."
  
  # Need to generate all frames for zoom effect
  for ((i=frames_per_rotation; i<total_output_frames; i++)); do
    rotation_frame=$((i % frames_per_rotation))
    angle=$(awk "BEGIN {printf \"%.2f\", $rotation_frame * $angle_increment}")
    progress=$(awk "BEGIN {printf \"%.4f\", ($rotation_frame * $duration / $frames_per_rotation) % $duration}")
    timestamp=$(awk "BEGIN {printf \"%.4f\", $progress}")
    overall_progress=$(awk "BEGIN {printf \"%.4f\", $i / ($total_output_frames - 1)}")
    scale_factor=$(awk "BEGIN {printf \"%.4f\", 1.0 - ($overall_progress * 0.5)}")
    
    printf "Frame %d/%d (%.2f°)\r" $((i+1)) $total_output_frames $angle
    
    filter="rotate=${angle}*PI/180:ow=max(iw\,ih):oh=max(iw\,ih):c=none,scale=iw*${scale_factor}:ih*${scale_factor}"
    
    if [ "$apply_circle" = true ]; then
      base_radius=$(awk "BEGIN {printf \"%.2f\", (($width < $height ? $width : $height) / 2) * 0.9}")
      radius=$(awk "BEGIN {printf \"%.2f\", $base_radius * $scale_factor}")
      filter="${filter},format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(lt(hypot(X-W/2,Y-H/2),${radius}),255,0)'"
    fi
    
    ffmpeg -loglevel error -ss $timestamp -i "$inputfile" \
      -vf "$filter" \
      -vframes 1 -q:v 2 \
      "$tmpdir/rotation_$(printf '%04d' $i).png"
  done
  echo ""
  
  if [ "$apply_circle" = true ]; then
    ffmpeg -framerate $output_fps -i "$tmpdir/rotation_%04d.png" \
      -c:v libx264 -pix_fmt yuva420p \
      "$outputfile"
  else
    ffmpeg -framerate $output_fps -i "$tmpdir/rotation_%04d.png" \
      -c:v libx264 -pix_fmt yuv420p \
      "$outputfile"
  fi
else
  # Can use efficient looping for non-zoom cases
  # Create a concat file to loop the frames
  concat_file="$tmpdir/concat.txt"
  for ((loop=0; loop<num_rotations; loop++)); do
    for ((i=0; i<frames_per_rotation; i++)); do
      echo "file 'rotation_$(printf '%04d' $i).png'" >> "$concat_file"
      echo "duration $(awk "BEGIN {printf \"%.6f\", 1.0/$output_fps}")" >> "$concat_file"
    done
  done
  # Add the last frame again (ffmpeg concat requirement)
  echo "file 'rotation_$(printf '%04d' $((frames_per_rotation-1))).png'" >> "$concat_file"
  
  if [ "$apply_circle" = true ]; then
    ffmpeg -f concat -safe 0 -i "$concat_file" \
      -c:v libx264 -pix_fmt yuva420p \
      "$outputfile"
  else
    ffmpeg -f concat -safe 0 -i "$concat_file" \
      -c:v libx264 -pix_fmt yuv420p \
      "$outputfile"
  fi
fi

# Clean up
rm -rf "$tmpdir"

echo ""
echo "Done! Output file: $outputfile"

# Log to manifest
manifest="manifest.tsv"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
logline="$timestamp\t$inputfile\t${output_duration}s\t${num_rotations}x rotations\t$frames_per_rotation frames generated\t${output_fps}fps\tzoom:$apply_zoom\tcircle:$apply_circle\t$outputfile"
echo -e "$logline" >> "$manifest"
echo -e "Saved to manifest: $logline"

# Optional: Ask before playing
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
    ffplay "$outputfile"
fi
