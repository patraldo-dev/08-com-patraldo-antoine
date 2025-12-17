#!/bin/bash

# make-particle-bg.sh – Composite artist PNGs as subtle floating particles on a background
# Designed for ImageMagick 6 (e.g., 6.9.11-60 on Debian/Chromebook)

set -euo pipefail

bg_color_hex="121212"   # dark gray (no 0x, no #)
size=1920               # square canvas
opacity=15              # 0–100
seed=42

particles_dir=""
output_file=""

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --particles)
      particles_dir="$2"
      shift 2
      ;;
    --output)
      output_file="$2"
      shift 2
      ;;
    --bg-color)
      bg_color_hex="$2"
      bg_color_hex="${bg_color_hex#0x}"
      bg_color_hex="${bg_color_hex##}"
      shift 2
      ;;
    --size)
      size="$2"
      shift 2
      ;;
    --opacity)
      opacity="$2"
      shift 2
      ;;
    -h|--help)
      cat <<EOF
USAGE:
  make-particle-bg.sh --particles <dir> --output <file.png>

OPTIONS:
  --particles DIR      Folder of transparent PNGs (required)
  --output FILE        Output PNG path (required)
  --bg-color HEX       Color without # or 0x (default: 121212)
  --size N             Canvas size (default: 1920)
  --opacity PCT        Particle opacity 0–100 (default: 15)
EOF
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- Validate ---
if [[ -z "$particles_dir" ]] || [[ -z "$output_file" ]]; then
  echo "❌ Error: --particles and --output are required." >&2
  exit 1
fi

if [[ ! -d "$particles_dir" ]]; then
  echo "❌ Error: Directory not found: $particles_dir" >&2
  exit 1
fi

shopt -s nullglob
png_files=("$particles_dir"/*.png)
shopt -u nullglob

if [[ ${#png_files[@]} -eq 0 ]]; then
  echo "❌ Error: No .png files in: $particles_dir" >&2
  exit 1
fi

# --- Detect IM ---
if command -v magick &> /dev/null; then
  IM_CMD="magick"
elif command -v convert &> /dev/null; then
  IM_CMD="convert"
else
  echo "❌ Error: ImageMagick not found. Run: sudo apt install imagemagick" >&2
  exit 1
fi

# --- Create solid background (IM6-safe) ---
work_file="/tmp/particle_bg_$$.png"
"$IM_CMD" -size "${size}x${size}" "xc:#$bg_color_hex" -depth 8 "$work_file"

# --- Composite particles ---
i=0
for png in "${png_files[@]}"; do
  ((i++))
  rand_x=$(awk -v s="$seed" -v n="$i" 'BEGIN{srand(s+n); print rand()}')
  rand_y=$(awk -v s="$((seed+1000))" -v n="$i" 'BEGIN{srand(s+n); print rand()}')
  rand_scale=$(awk -v s="$((seed+2000))" -v n="$i" 'BEGIN{srand(s+n); print 0.7 + 0.5*rand()}')

  margin=200
  max_x=$((size - margin))
  max_y=$((size - margin))
  x=$(awk -v r="$rand_x" -v m="$margin" -v mx="$max_x" 'BEGIN{print int(m + r*(mx-m))}')
  y=$(awk -v r="$rand_y" -v m="$margin" -v my="$max_y" 'BEGIN{print int(m + r*(my-m))}')
  scale_pct=$(awk -v s="$rand_scale" 'BEGIN{print int(100*s)}')

  echo "🖼️  Placing $(basename "$png") at ($x,$y) scale ${scale_pct}%"

  "$IM_CMD" "$work_file" \
    \( "$png" -resize "${scale_pct}%" -channel A -evaluate multiply "0.$opacity" +channel \) \
    -geometry +$x+$y -composite \
    "$work_file"
done

# --- Save ---
mkdir -p "$(dirname "$output_file")"
mv "$work_file" "$output_file"
echo "✅ Success: $output_file"
