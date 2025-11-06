#!/bin/bash
# Spin and zoom script - simplified two-pass approach

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

# If zoom is enabled, ask for zoom range
if [ "$apply_zoom" = true ]; then
  read -p "Start size (percentage, e.g., 100 for full size): " start_size
  start_size=${start_size:-100}
  read -p "End size (percentage, e.g., 30 for tiny): " end_size
  end_size=${end_size:-30}
  echo "Will zoom from ${start_size}% to ${end_size}%"
fi

# Prompt for circular mask
read -p "Apply circular mask? (Y/n): " circle_choice
apply_circle=true
if [[ "$circle_choice" == "n" || "$circle_choice" == "N" ]]; then
  apply_circle=false
fi

# Prompt for background color
read -p "Background color (black/white/hex without #, default=black): " bg_color
bg_color=${bg_color:-black}

# Calculate total frames
total_frames=$((output_duration * output_fps))
angle_increment=$(awk "BEGIN {printf \"%.2f\", 360.0 * $num_rotations / $total_frames}")

echo ""
echo "Configuration:"
echo "  Output duration: ${output_duration}s"
echo "  Output framerate: ${output_fps} fps"
echo "  Rotations: $num_rotations"
echo "  Total frames: $total_frames"
echo "  Angle increment: ${angle_increment}°"
echo "  Zoom-out: $apply_zoom"
if [ "$apply_zoom" = true ]; then
  echo "  Zoom range: ${start_size}% → ${end_size}%"
fi
echo "  Circular mask: $apply_circle"
echo "  Background: $bg_color"
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

# Calculate canvas size
canvas_size=$(awk "BEGIN {printf \"%d\", int(sqrt($width*$width + $height*$height)) + 2}")
canvas_size=$((canvas_size + canvas_size % 2))

echo "Canvas size: ${canvas_size}x${canvas_size}"
echo ""

# Create temporary directory
tmpdir=$(mktemp -d)
echo "Temporary directory: $tmpdir"
echo ""

# Set background color
case $bg_color in
  white)
    pad_color="white"
    ;;
  black)
    pad_color="black"
    ;;
  *)
    # Hex color without #
    pad_color="#${bg_color}"
    ;;
esac

# Generate all frames
echo "Generating $total_frames frames..."
for ((i=0; i<total_frames; i++)); do
  angle=$(awk "BEGIN {printf \"%.2f\", $i * $angle_increment}")
  
  if (( total_frames > 1 )); then
    progress=$(awk "BEGIN {printf \"%.6f\", $i / ($total_frames - 1)}")
  else
    progress=0
  fi
  
  timestamp=$(awk "BEGIN {printf \"%.4f\", ($progress * $output_duration) % $duration}")
  
  if [ "$apply_zoom" = true ]; then
    scale_factor=$(awk "BEGIN {printf \"%.6f\", ($start_size - ($start_size - $end_size) * $progress) / 100}")
  else
    scale_factor=1.0
  fi
  
  printf "Frame %d/%d (angle: %.1f°, zoom: %.1f%%)  \r" \
    $((i+1)) $total_frames $angle \
    $(awk "BEGIN {printf \"%.1f\", $scale_factor * 100}")
  
  # Build base transformation filter
  filter="rotate=${angle}*PI/180:ow=max(iw\,ih):oh=max(iw\,ih):c=none"
  
  if [ "$apply_zoom" = true ]; then
    filter="${filter},scale=iw*${scale_factor}:ih*${scale_factor}"
  fi
  
  # Add circular mask if enabled
  if [ "$apply_circle" = true ]; then
    base_radius=$(awk "BEGIN {printf \"%.2f\", (($width < $height ? $width : $height) / 2) * 0.93}")
    radius=$(awk "BEGIN {printf \"%.2f\", $base_radius * $scale_factor}")
    
    # Create with transparency
    filter="${filter},format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(lt(hypot(X-W/2,Y-H/2),${radius}),255,0)'"
  fi
  
  # Pad to canvas with transparency first
  filter="${filter},pad=${canvas_size}:${canvas_size}:(ow-iw)/2:(oh-ih)/2:color=0x00000000"
  
  # Extract frame with alpha
  ffmpeg -loglevel error -ss $timestamp -i "$inputfile" \
    -vf "$filter" \
    -vframes 1 -pix_fmt rgba \
    "$tmpdir/fg_$(printf '%04d' $i).png"
  
  # Composite onto colored background using ImageMagick's convert (more reliable)
  if command -v convert &> /dev/null; then
    convert -size ${canvas_size}x${canvas_size} "xc:${pad_color}" \
      "$tmpdir/fg_$(printf '%04d' $i).png" \
      -composite \
      "$tmpdir/frame_$(printf '%04d' $i).png"
    rm "$tmpdir/fg_$(printf '%04d' $i).png"
  else
    # Fallback: use ffmpeg overlay
    ffmpeg -loglevel error \
      -f lavfi -i "color=${pad_color}:s=${canvas_size}x${canvas_size}:d=1" \
      -i "$tmpdir/fg_$(printf '%04d' $i).png" \
      -filter_complex "[0:v][1:v]overlay" \
      -vframes 1 \
      "$tmpdir/frame_$(printf '%04d' $i).png"
    rm "$tmpdir/fg_$(printf '%04d' $i).png"
  fi
done

echo ""
echo "Frame generation complete!"
echo ""

# Compose output filename
input_dir=$(dirname "$inputfile")
input_base=$(basename "$inputfile")
input_name="${input_base%.*}"
outputfile="${input_dir}/spinning_${input_name}.mp4"

# Create video
echo "Creating spinning video..."
ffmpeg -framerate $output_fps -i "$tmpdir/frame_%04d.png" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p \
  "$outputfile"

# Clean up
rm -rf "$tmpdir"

echo ""
echo "Done! Output file: $outputfile"

# Log to manifest
manifest="manifest.tsv"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
if [ "$apply_zoom" = true ]; then
  zoom_info="${start_size}%→${end_size}%"
else
  zoom_info="none"
fi
logline="$timestamp\t$inputfile\t${output_duration}s\t${num_rotations}x rotations\t$total_frames frames\t${output_fps}fps\tzoom:$zoom_info\tcircle:$apply_circle\tcanvas:${canvas_size}x${canvas_size}\tbg:${bg_color}\t$outputfile"
echo -e "$logline" >> "$manifest"
echo -e "Saved to manifest: $logline"

# Optional: Ask before playing
read -p "Play output file? (Y/n): " play_choice
if [[ "$play_choice" != "n" && "$play_choice" != "N" ]]; then
    ffplay "$outputfile"
fi
