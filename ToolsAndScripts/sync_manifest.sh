#!/bin/bash
# ToolsAndScripts/sync_manifest.sh

set -e

MANIFEST="../Projects/MANIFEST.tsv"
PROJECTS_DIR="../Projects"

mkdir -p "$PROJECTS_DIR"

{
  echo -e "project_id\tproject_name\tdate_created\tscene_id\tscene_name\twan_clips\tedited_clips"
  
  # Process all projects
  while IFS= read -r -d '' proj; do
    [ -d "$proj" ] || continue
    proj_base=$(basename "$proj")
    if [[ $proj_base =~ ^([0-9]{3})-([0-9]{8})-(.+)$ ]]; then
      proj_id="${BASH_REMATCH[1]}"
      date_part="${BASH_REMATCH[2]}"
      proj_name="${BASH_REMATCH[3]}"
    else
      # Fallback for non-standard names
      proj_id="(invalid)"
      date_part="unknown"
      proj_name="$proj_base"
    fi

    scene_found=false
    while IFS= read -r -d '' scene_dir; do
      scene_base=$(basename "$scene_dir")
      if [[ $scene_base =~ ^([0-9]{2})-(.+)$ ]]; then
        scene_id="${BASH_REMATCH[1]}"
        scene_name="${BASH_REMATCH[2]}"
        
        wan_count=$(find "$scene_dir/wan_output" -type f \( -iname "*.mp4" -o -iname "*.gif" \) 2>/dev/null | wc -l)
        edit_count=$(find "$scene_dir/edited_clips" -type f \( -iname "*.mp4" -o -iname "*.gif" \) 2>/dev/null | wc -l)

        echo -e "${proj_id}\t${proj_name}\t${date_part}\t${scene_id}\t${scene_name}\t${wan_count}\t${edit_count}"
        scene_found=true
      fi
    done < <(find "$proj/scenes" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    if [ "$scene_found" = false ]; then
      echo -e "${proj_id}\t${proj_name}\t${date_part}\t-\t(no scenes)\t0\t0"
    fi
  done < <(find "$PROJECTS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" -print0 2>/dev/null)

  # Handle case: no projects at all
  if ! find "$PROJECTS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | grep -q .; then
    echo -e "(none)\t(no projects)\t-\t-\t-\t0\t0"
  fi
} | column -t -s $'\t' > "$MANIFEST"

echo "✅ Manifest updated: $MANIFEST"

# Save raw TSV (machine-readable)
{
  echo -e "project_id\tproject_name\tdate_created\tscene_id\tscene_name\twan_clips\tedited_clips"
  while IFS= read -r -d '' proj; do
    [ -d "$proj" ] || continue
    proj_base=$(basename "$proj")
    if [[ $proj_base =~ ^([0-9]{3})-([0-9]{8})-(.+)$ ]]; then
      proj_id="${BASH_REMATCH[1]}"
      date_part="${BASH_REMATCH[2]}"
      proj_name="${BASH_REMATCH[3]}"
    else
      proj_id="(invalid)"
      date_part="unknown"
      proj_name="$proj_base"
    fi

    scene_found=false
    while IFS= read -r -d '' scene_dir; do
      scene_base=$(basename "$scene_dir")
      if [[ $scene_base =~ ^([0-9]{2})-(.+)$ ]]; then
        scene_id="${BASH_REMATCH[1]}"
        scene_name="${BASH_REMATCH[2]}"
        wan_count=$(find "$scene_dir/wan_output" -type f \( -iname "*.mp4" -o -iname "*.gif" \) 2>/dev/null | wc -l)
        edit_count=$(find "$scene_dir/edited_clips" -type f \( -iname "*.mp4" -o -iname "*.gif" \) 2>/dev/null | wc -l)
        echo -e "${proj_id}\t${proj_name}\t${date_part}\t${scene_id}\t${scene_name}\t${wan_count}\t${edit_count}"
        scene_found=true
      fi
    done < <(find "$proj/scenes" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    if [ "$scene_found" = false ]; then
      echo -e "${proj_id}\t${proj_name}\t${date_part}\t-\t(no scenes)\t0\t0"
    fi
  done < <(find "$PROJECTS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" -print0 2>/dev/null)
} > "${MANIFEST}.raw"

echo "   Raw TSV saved: ${MANIFEST}.raw"
